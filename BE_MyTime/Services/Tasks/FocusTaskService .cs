using BE_MyTime.DTOs.Task;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using BE_MyTime.Repositories;

namespace BE_MyTime.Services.Tasks
{
    public class FocusTaskService : IFocusTaskService
    {
        private readonly FocusTaskRepository _repository;

        public FocusTaskService(FocusTaskRepository repository)
        {
            _repository = repository;
        }

        public async Task<List<FocusTaskResponse>> GetTasksAsync(int userId)
        {
            var tasks = await _repository.GetByUserIdAsync(userId);
            return tasks.Select(MapToResponse).ToList();
        }

        public async Task<FocusTaskResponse?> GetTaskAsync(int id, int userId)
        {
            var task = await _repository.GetByIdAsync(id, userId);
            return task == null ? null : MapToResponse(task);
        }

        public async Task<FocusTaskResponse> CreateTaskAsync(
            int userId,
            CreateFocusTaskRequest request)
        {
            ValidateCreateRequest(request.Title, request.Outputs);
            var normalizedScheduledDate = NormalizeUtc(request.ScheduledDate);
            var normalizedDeadline = NormalizeUtc(request.Deadline) ?? normalizedScheduledDate;

            var task = new FocusTask
            {
                UserId = userId,
                Title = request.Title.Trim(),
                Description = request.Description,
                FocusMinutes = request.FocusMinutes,
                Priority = ParseEnum(request.Priority, TaskPriority.Medium),
                Deadline = normalizedDeadline,
                Difficulty = Math.Clamp(request.Difficulty, 1, 5),
                Status = FocusTaskStatus.Todo,
                ScheduledDate = normalizedScheduledDate,
                StartTime = request.StartTime,
                EndTime = request.EndTime,
                Repeat = ParseEnum(request.Repeat, TaskRepeat.None),
                ReminderEnabled = request.ReminderEnabled,
                ReminderTime = request.ReminderTime,
                SyncToGoogleCalendar = request.SyncToGoogleCalendar,
                CreatedAt = DateTime.UtcNow,
                Outputs = request.Outputs.Select((title, index) => new FocusOutput
                {
                    Title = title.Trim(),
                    SortOrder = index,
                    CreatedAt = DateTime.UtcNow
                }).ToList()
            };

            await _repository.AddAsync(task);

            return MapToResponse(task);
        }

        public async Task<FocusTaskResponse?> UpdateTaskAsync(
            int id,
            int userId,
            UpdateFocusTaskRequest request)
        {
            ValidateUpdateRequest(request.Title, request.Outputs);

            var task = await _repository.GetByIdAsync(id, userId);
            if (task == null) return null;
            var normalizedScheduledDate = NormalizeUtc(request.ScheduledDate);
            var normalizedDeadline = NormalizeUtc(request.Deadline) ?? normalizedScheduledDate;

            var previousStatus = task.Status;

            task.Title = request.Title.Trim();
            task.Description = request.Description;
            task.FocusMinutes = request.FocusMinutes;
            task.Priority = ParseEnum(request.Priority, TaskPriority.Medium);
            task.Deadline = normalizedDeadline;
            task.Difficulty = Math.Clamp(request.Difficulty, 1, 5);
            task.Status = ParseEnum(request.Status, FocusTaskStatus.Todo);
            task.ScheduledDate = normalizedScheduledDate;
            task.StartTime = request.StartTime;
            task.EndTime = request.EndTime;
            task.Repeat = ParseEnum(request.Repeat, TaskRepeat.None);
            task.ReminderEnabled = request.ReminderEnabled;
            task.ReminderTime = request.ReminderTime;
            task.SyncToGoogleCalendar = request.SyncToGoogleCalendar;
            task.UpdatedAt = DateTime.UtcNow;
            var occurrenceDate = request.OccurrenceDate?.Date;

            if (task.Repeat != TaskRepeat.None && occurrenceDate.HasValue)
            {
                var existingCompletion = task.CompletionLogs
                    .FirstOrDefault(item => item.CompletedOn.Date == occurrenceDate.Value);

                if (task.Status == FocusTaskStatus.Completed)
                {
                    if (existingCompletion == null)
                    {
                        task.CompletionLogs.Add(new FocusTaskCompletion
                        {
                            FocusTaskId = task.Id,
                            CompletedOn = occurrenceDate.Value,
                            CreatedAt = DateTime.UtcNow
                        });
                    }
                }
                else if (existingCompletion != null)
                {
                    task.CompletionLogs.Remove(existingCompletion);
                }

                task.Status = previousStatus == FocusTaskStatus.Processing
                    ? FocusTaskStatus.Processing
                    : FocusTaskStatus.Todo;
                task.CompletedAt = task.CompletionLogs
                    .OrderByDescending(item => item.CompletedOn)
                    .Select(item => (DateTime?)item.CompletedOn)
                    .FirstOrDefault();
            }
            else
            {
                if (task.Status == FocusTaskStatus.Completed)
                {
                    if (previousStatus != FocusTaskStatus.Completed || task.CompletedAt == null)
                    {
                        task.CompletedAt = DateTime.UtcNow;
                    }
                }
                else
                {
                    task.CompletedAt = null;
                }
            }

            var existingOutputs = task.Outputs.ToDictionary(output => output.Id);
            var incomingOutputIds = request.Outputs
                .Where(output => output.Id.HasValue && output.Id.Value > 0)
                .Select(output => output.Id!.Value)
                .ToHashSet();

            var outputsToRemove = task.Outputs
                .Where(output => !incomingOutputIds.Contains(output.Id))
                .ToList();

            foreach (var output in outputsToRemove)
            {
                task.Outputs.Remove(output);
            }

            foreach (var item in request.Outputs.Select((output, index) => new { output, index }))
            {
                var requestedOutput = item.output;
                var normalizedTitle = requestedOutput.Title.Trim();
                DateTime? completedAt = requestedOutput.IsCompleted
                    ? NormalizeUtc(requestedOutput.CompletedAt) ?? DateTime.UtcNow
                    : null;

                if (requestedOutput.Id.HasValue &&
                    existingOutputs.TryGetValue(requestedOutput.Id.Value, out var existingOutput))
                {
                    existingOutput.Title = normalizedTitle;
                    existingOutput.IsCompleted = requestedOutput.IsCompleted;
                    existingOutput.CompletedAt = completedAt;
                    existingOutput.SortOrder = item.index;
                    continue;
                }

                task.Outputs.Add(new FocusOutput
                {
                    FocusTaskId = task.Id,
                    Title = normalizedTitle,
                    IsCompleted = requestedOutput.IsCompleted,
                    CompletedAt = completedAt,
                    SortOrder = item.index,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await _repository.UpdateAsync(task);

            return MapToResponse(task);
        }

        public async Task<bool> DeleteTaskAsync(int id, int userId)
        {
            var task = await _repository.GetByIdAsync(id, userId);
            if (task == null) return false;

            await _repository.DeleteAsync(task);
            return true;
        }

        private static TEnum ParseEnum<TEnum>(string? value, TEnum fallback)
            where TEnum : struct
        {
            if (string.IsNullOrWhiteSpace(value)) return fallback;

            return Enum.TryParse<TEnum>(value, true, out var result)
                ? result
                : fallback;
        }

        private static DateTime? NormalizeUtc(DateTime? value)
        {
            if (!value.HasValue)
            {
                return null;
            }

            return value.Value.Kind switch
            {
                DateTimeKind.Utc => value.Value,
                DateTimeKind.Local => value.Value.ToUniversalTime(),
                _ => DateTime.SpecifyKind(value.Value, DateTimeKind.Utc)
            };
        }

        private static void ValidateCreateRequest(string? title, List<string>? outputs)
        {
            if (string.IsNullOrWhiteSpace(title))
            {
                throw new InvalidOperationException("Task title is required.");
            }

            if (outputs == null || outputs.Count == 0)
            {
                throw new InvalidOperationException("At least one output is required.");
            }

            if (outputs.Any(output => string.IsNullOrWhiteSpace(output)))
            {
                throw new InvalidOperationException("Outputs cannot be empty.");
            }
        }

        private static void ValidateUpdateRequest(
            string? title,
            List<FocusTaskOutputUpsertRequest>? outputs)
        {
            if (string.IsNullOrWhiteSpace(title))
            {
                throw new InvalidOperationException("Task title is required.");
            }

            if (outputs == null || outputs.Count == 0)
            {
                throw new InvalidOperationException("At least one output is required.");
            }

            if (outputs.Any(output => string.IsNullOrWhiteSpace(output.Title)))
            {
                throw new InvalidOperationException("Outputs cannot be empty.");
            }
        }

        private static FocusTaskResponse MapToResponse(FocusTask task)
        {
            return new FocusTaskResponse
            {
                Id = task.Id,
                Title = task.Title,
                Description = task.Description,
                FocusMinutes = task.FocusMinutes,
                Priority = task.Priority.ToString(),
                Deadline = task.Deadline,
                Difficulty = task.Difficulty,
                Status = task.Status.ToString(),
                ScheduledDate = task.ScheduledDate,
                StartTime = task.StartTime,
                EndTime = task.EndTime,
                Repeat = task.Repeat.ToString(),
                ReminderEnabled = task.ReminderEnabled,
                ReminderTime = task.ReminderTime,
                SyncToGoogleCalendar = task.SyncToGoogleCalendar,
                CompletedAt = task.CompletedAt,
                Outputs = task.Outputs
                    .OrderBy(o => o.SortOrder)
                    .Select(o => new FocusOutputResponse
                    {
                        Id = o.Id,
                        Title = o.Title,
                        IsCompleted = o.IsCompleted,
                        CompletedAt = o.CompletedAt,
                        SortOrder = o.SortOrder
                    })
                    .ToList(),
                CompletionDates = task.CompletionLogs
                    .OrderBy(item => item.CompletedOn)
                    .Select(item => item.CompletedOn)
                    .ToList()
            };
        }
    }
}
