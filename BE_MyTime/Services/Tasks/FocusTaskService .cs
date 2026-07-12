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
            var task = new FocusTask
            {
                UserId = userId,
                Title = request.Title.Trim(),
                Description = request.Description,
                FocusMinutes = request.FocusMinutes,
                Priority = ParseEnum(request.Priority, TaskPriority.Medium),
                Deadline = request.Deadline ?? request.ScheduledDate,
                Difficulty = Math.Clamp(request.Difficulty, 1, 5),
                Status = FocusTaskStatus.Todo,
                ScheduledDate = request.ScheduledDate,
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
            var task = await _repository.GetByIdAsync(id, userId);
            if (task == null) return null;

            task.Title = request.Title.Trim();
            task.Description = request.Description;
            task.FocusMinutes = request.FocusMinutes;
            task.Priority = ParseEnum(request.Priority, TaskPriority.Medium);
            task.Deadline = request.Deadline ?? request.ScheduledDate;
            task.Difficulty = Math.Clamp(request.Difficulty, 1, 5);
            task.Status = ParseEnum(request.Status, FocusTaskStatus.Todo);
            task.ScheduledDate = request.ScheduledDate;
            task.StartTime = request.StartTime;
            task.EndTime = request.EndTime;
            task.Repeat = ParseEnum(request.Repeat, TaskRepeat.None);
            task.ReminderEnabled = request.ReminderEnabled;
            task.ReminderTime = request.ReminderTime;
            task.SyncToGoogleCalendar = request.SyncToGoogleCalendar;
            task.UpdatedAt = DateTime.UtcNow;

            task.Outputs.Clear();

            foreach (var item in request.Outputs.Select((title, index) => new { title, index }))
            {
                task.Outputs.Add(new FocusOutput
                {
                    FocusTaskId = task.Id,
                    Title = item.title.Trim(),
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
                Outputs = task.Outputs
                    .OrderBy(o => o.SortOrder)
                    .Select(o => new FocusOutputResponse
                    {
                        Id = o.Id,
                        Title = o.Title,
                        IsCompleted = o.IsCompleted,
                        SortOrder = o.SortOrder
                    })
                    .ToList()
            };
        }
    }
}
