using System.Text.Json;
using BE_MyTime.Data;
using BE_MyTime.DTOs.Ai;
using BE_MyTime.DTOs.Schedule;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using BE_MyTime.Repositories;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Services.AI
{
    public class AiTimeManagerService : IAiTimeManagerService
    {
        private readonly FocusTaskRepository _taskRepository;
        private readonly AppDbContext _dbContext;

        public AiTimeManagerService(
            FocusTaskRepository taskRepository,
            AppDbContext dbContext)
        {
            _taskRepository = taskRepository;
            _dbContext = dbContext;
        }

        public async Task<AiPlanResponse> GeneratePlanAsync(int userId)
        {
            var scoredTasks = await GetScoredTasksAsync(userId);
            var activeTasks = scoredTasks
                .Where(x => !x.Task.IsCompleted())
                .ToList();

            if (activeTasks.Count == 0)
            {
                return new AiPlanResponse
                {
                    GeneratedAt = DateTime.Now,
                    DailySuggestion = "No active tasks found. Add a task and AI will build a plan for you."
                };
            }

            var today = DateTime.Today;
            var currentStart = new TimeSpan(8, 0, 0);
            var draftEntities = new List<AiPlanDraft>();
            var draftResponses = new List<AiPlanDraftResponse>();
            var pomodoroSessions = new List<AiPomodoroSessionResponse>();

            foreach (var item in activeTasks)
            {
                var task = item.Task;
                var outputsJson = JsonSerializer.Serialize(
                    task.Outputs
                        .OrderBy(output => output.SortOrder)
                        .Select(output => output.Title));

                var planDate = task.ScheduledDate?.Date ?? today;
                if (planDate < today)
                {
                    planDate = today;
                }

                var draftEntity = new AiPlanDraft
                {
                    UserId = userId,
                    OriginalInput = "auto_daily_plan",
                    SuggestedTitle = task.Title,
                    SuggestedDescription = task.Description,
                    SuggestedDate = planDate,
                    SuggestedStartTime = currentStart,
                    SuggestedEndTime = currentStart.Add(
                        TimeSpan.FromMinutes(task.FocusMinutes)),
                    SuggestedFocusMinutes = task.FocusMinutes,
                    SuggestedPriority = task.Priority,
                    SuggestedOutputsJson = outputsJson,
                    Reason = string.Join(" | ", item.Reasons),
                    Status = AiDraftStatus.Draft,
                    CreatedAt = DateTime.UtcNow
                };

                draftEntities.Add(draftEntity);

                var sessionCursor = currentStart;
                var pomodoroDurations = BuildPomodoroDurations(task.FocusMinutes);

                for (var index = 0; index < pomodoroDurations.Count; index++)
                {
                    var duration = pomodoroDurations[index];
                    var endTime = sessionCursor.Add(TimeSpan.FromMinutes(duration));

                    pomodoroSessions.Add(new AiPomodoroSessionResponse
                    {
                        TaskId = task.Id,
                        TaskTitle = task.Title,
                        SessionNumber = index + 1,
                        DurationMinutes = duration,
                        ScheduledDate = planDate,
                        StartTime = sessionCursor,
                        EndTime = endTime
                    });

                    sessionCursor = endTime;
                    if (index < pomodoroDurations.Count - 1)
                    {
                        sessionCursor = sessionCursor.Add(TimeSpan.FromMinutes(5));
                    }
                }

                currentStart = draftEntity.SuggestedEndTime!.Value
                    .Add(TimeSpan.FromMinutes(5));
            }

            _dbContext.AiPlanDrafts.AddRange(draftEntities);
            await _dbContext.SaveChangesAsync();

            draftResponses = draftEntities
                .Select(entity => new AiPlanDraftResponse
                {
                    Id = entity.Id,
                    TaskId = activeTasks[draftEntities.IndexOf(entity)].Task.Id,
                    SuggestedTitle = entity.SuggestedTitle ?? string.Empty,
                    SuggestedDate = entity.SuggestedDate ?? today,
                    SuggestedStartTime = entity.SuggestedStartTime ?? new TimeSpan(8, 0, 0),
                    SuggestedEndTime = entity.SuggestedEndTime
                        ?? (entity.SuggestedStartTime ?? new TimeSpan(8, 0, 0))
                            .Add(TimeSpan.FromMinutes(entity.SuggestedFocusMinutes)),
                    SuggestedFocusMinutes = entity.SuggestedFocusMinutes,
                    Reason = entity.Reason ?? string.Empty,
                    SuggestedOutputsJson = entity.SuggestedOutputsJson ?? "[]",
                    CreatedAt = entity.CreatedAt
                })
                .ToList();

            var suggestion = BuildSuggestion(activeTasks[0]);

            return new AiPlanResponse
            {
                GeneratedAt = DateTime.Now,
                DailySuggestion = suggestion,
                SortedTasks = activeTasks.Select(MapTaskScore).ToList(),
                Drafts = draftResponses,
                PomodoroSessions = pomodoroSessions
            };
        }

        public async Task<List<AiTaskScoreResponse>> SortTasksAsync(int userId)
        {
            var scoredTasks = await GetScoredTasksAsync(userId);
            return scoredTasks.Select(MapTaskScore).ToList();
        }

        public async Task<List<AiPomodoroSessionResponse>> GeneratePomodoroAsync(int userId)
        {
            var scoredTasks = await GetScoredTasksAsync(userId);
            var activeTasks = scoredTasks
                .Where(x => !x.Task.IsCompleted())
                .ToList();

            var sessions = new List<AiPomodoroSessionResponse>();
            var now = DateTime.Today;
            var cursor = new TimeSpan(8, 0, 0);

            foreach (var item in activeTasks)
            {
                var task = item.Task;
                var date = task.ScheduledDate?.Date ?? now;

                var durations = BuildPomodoroDurations(task.FocusMinutes);
                for (var index = 0; index < durations.Count; index++)
                {
                    var duration = durations[index];
                    var endTime = cursor.Add(TimeSpan.FromMinutes(duration));

                    sessions.Add(new AiPomodoroSessionResponse
                    {
                        TaskId = task.Id,
                        TaskTitle = task.Title,
                        SessionNumber = index + 1,
                        DurationMinutes = duration,
                        ScheduledDate = date,
                        StartTime = cursor,
                        EndTime = endTime
                    });

                    cursor = endTime.Add(TimeSpan.FromMinutes(5));
                }
            }

            return sessions;
        }

        public async Task<AiDailySuggestionResponse> GetDailySuggestionAsync(int userId)
        {
            var scoredTasks = await GetScoredTasksAsync(userId);
            var topTask = scoredTasks.FirstOrDefault();

            if (topTask == null)
            {
                return new AiDailySuggestionResponse
                {
                    Suggestion = "You have no active tasks today. Create a task to receive an AI suggestion."
                };
            }

            return new AiDailySuggestionResponse
            {
                Suggestion = BuildSuggestion(topTask),
                HighlightTaskTitle = topTask.Task.Title,
                HighlightScore = topTask.Score
            };
        }

        public async Task<SmartScheduleResponse> GenerateSmartScheduleAsync(int userId)
        {
            var scoredTasks = await GetScoredTasksAsync(userId);
            var activeTasks = scoredTasks
                .Where(item => !item.Task.IsCompleted())
                .ToList();

            if (activeTasks.Count == 0)
            {
                return new SmartScheduleResponse
                {
                    GeneratedAt = DateTime.Now,
                    DailySuggestion = "No active tasks found. Add a task to generate a smart schedule."
                };
            }

            var setting = await _dbContext.UserSettings
                .AsNoTracking()
                .FirstOrDefaultAsync(item => item.UserId == userId);

            var preferredStart = setting?.PreferredFocusStartTime ?? new TimeSpan(8, 0, 0);
            var preferredEnd = setting?.PreferredFocusEndTime ?? new TimeSpan(20, 0, 0);
            var planningDate = DateTime.Today;

            var existing = await _dbContext.ScheduledTasks
                .Where(item => item.UserId == userId && item.StartTime.Date == planningDate)
                .ToListAsync();

            if (existing.Count > 0)
            {
                _dbContext.ScheduledTasks.RemoveRange(existing);
                await _dbContext.SaveChangesAsync();
            }

            var scheduledEntities = new List<ScheduledTask>();
            var timelineResponses = new List<ScheduledTaskResponse>();
            var remaining = activeTasks.ToList();
            var cursor = preferredStart;

            while (remaining.Count > 0)
            {
                var nextTask = remaining
                    .OrderByDescending(item => item.Score + EnergyBonus(cursor, item.Task))
                    .ThenBy(item => item.Task.Deadline ?? item.Task.ScheduledDate ?? DateTime.MaxValue)
                    .ThenBy(item => item.Task.CreatedAt)
                    .ThenBy(item => item.Task.FocusMinutes)
                    .First();

                var durations = BuildPomodoroDurations(nextTask.Task.FocusMinutes);
                for (var index = 0; index < durations.Count; index++)
                {
                    var duration = durations[index];
                    var startDateTime = planningDate.Add(cursor);
                    var endDateTime = startDateTime.AddMinutes(duration);

                    if (cursor > preferredEnd)
                    {
                        startDateTime = planningDate.Add(preferredEnd);
                        endDateTime = startDateTime.AddMinutes(duration);
                    }

                    var entity = new ScheduledTask
                    {
                        UserId = userId,
                        FocusTaskId = nextTask.Task.Id,
                        TitleSnapshot = nextTask.Task.Title,
                        StartTime = startDateTime,
                        EndTime = endDateTime,
                        SessionNumber = index + 1,
                        AiScore = Math.Round(nextTask.Score + EnergyBonus(cursor, nextTask.Task), 2),
                        IsOverlapAllowed = nextTask.Task.Difficulty <= 2,
                        CreatedAt = DateTime.UtcNow
                    };

                    scheduledEntities.Add(entity);
                    cursor = cursor.Add(TimeSpan.FromMinutes(duration + BufferMinutes(nextTask.Task)));
                }

                remaining.Remove(nextTask);
            }

            _dbContext.ScheduledTasks.AddRange(scheduledEntities);
            await _dbContext.SaveChangesAsync();

            var persisted = await _dbContext.ScheduledTasks
                .Include(item => item.FocusTask)
                .Where(item => item.UserId == userId && item.StartTime.Date == planningDate)
                .OrderBy(item => item.StartTime)
                .ToListAsync();

            timelineResponses = persisted
                .Select(item => MapScheduledTask(item, persisted))
                .ToList();

            return new SmartScheduleResponse
            {
                GeneratedAt = DateTime.Now,
                DailySuggestion = BuildMultiTaskSuggestion(activeTasks),
                SuggestedTaskOrder = activeTasks.Select(MapTaskScore).ToList(),
                ScheduledTasks = timelineResponses
            };
        }

        public async Task<SmartScheduleResponse> GetTodaySmartScheduleAsync(int userId)
        {
            var planningDate = DateTime.Today;
            var scoredTasks = await GetScoredTasksAsync(userId);
            var activeTasks = scoredTasks
                .Where(item => !item.Task.IsCompleted())
                .ToList();

            var persisted = await _dbContext.ScheduledTasks
                .Include(item => item.FocusTask)
                .Where(item => item.UserId == userId && item.StartTime.Date == planningDate)
                .OrderBy(item => item.StartTime)
                .ToListAsync();

            return new SmartScheduleResponse
            {
                GeneratedAt = persisted.FirstOrDefault()?.UpdatedAt
                    ?? persisted.FirstOrDefault()?.CreatedAt
                    ?? DateTime.Now,
                DailySuggestion = BuildMultiTaskSuggestion(activeTasks),
                SuggestedTaskOrder = activeTasks.Select(MapTaskScore).ToList(),
                ScheduledTasks = persisted
                    .Select(item => MapScheduledTask(item, persisted))
                    .ToList()
            };
        }

        public async Task<ScheduledTaskResponse?> UpdateScheduledTaskAsync(
            int userId,
            UpdateScheduledTaskRequest request)
        {
            var scheduledTask = await _dbContext.ScheduledTasks
                .Include(item => item.FocusTask)
                .FirstOrDefaultAsync(item =>
                    item.Id == request.ScheduledTaskId && item.UserId == userId);

            if (scheduledTask == null)
            {
                return null;
            }

            var duration = request.EndTime - request.StartTime;
            if (duration.TotalMinutes <= 0)
            {
                duration = scheduledTask.EndTime - scheduledTask.StartTime;
            }

            var updatedStart = request.StartTime;
            var updatedEnd = updatedStart.Add(duration);

            var siblings = await _dbContext.ScheduledTasks
                .Where(item =>
                    item.UserId == userId &&
                    item.Id != scheduledTask.Id &&
                    item.StartTime.Date == updatedStart.Date)
                .ToListAsync();

            if (!request.AllowOverlap || request.ShiftConflicts)
            {
                while (siblings.Any(item => RangesOverlap(updatedStart, updatedEnd, item.StartTime, item.EndTime)))
                {
                    updatedStart = updatedStart.AddMinutes(15);
                    updatedEnd = updatedStart.Add(duration);
                }
            }

            scheduledTask.StartTime = updatedStart;
            scheduledTask.EndTime = updatedEnd;
            scheduledTask.IsOverlapAllowed = request.AllowOverlap;
            scheduledTask.UpdatedAt = DateTime.UtcNow;

            if (scheduledTask.SessionNumber == 1)
            {
                scheduledTask.FocusTask.ScheduledDate = updatedStart.Date;
                scheduledTask.FocusTask.StartTime = updatedStart.TimeOfDay;
                scheduledTask.FocusTask.EndTime = updatedEnd.TimeOfDay;
                scheduledTask.FocusTask.UpdatedAt = DateTime.UtcNow;
            }

            await _dbContext.SaveChangesAsync();

            var sameDay = await _dbContext.ScheduledTasks
                .Include(item => item.FocusTask)
                .Where(item => item.UserId == userId && item.StartTime.Date == updatedStart.Date)
                .ToListAsync();

            return MapScheduledTask(scheduledTask, sameDay);
        }

        public async Task<AiDailySuggestionResponse> GetDailyScheduleSuggestionAsync(int userId)
        {
            var scoredTasks = await GetScoredTasksAsync(userId);
            var activeTasks = scoredTasks
                .Where(item => !item.Task.IsCompleted())
                .ToList();
            var firstTask = activeTasks.FirstOrDefault();

            return new AiDailySuggestionResponse
            {
                Suggestion = BuildMultiTaskSuggestion(activeTasks),
                HighlightTaskTitle = firstTask?.Task.Title,
                HighlightScore = firstTask?.Score
            };
        }

        private async Task<List<ScoredTask>> GetScoredTasksAsync(int userId)
        {
            var now = DateTime.Now;
            var tasks = await _taskRepository.GetByUserIdAsync(userId);

            return tasks
                .Select(task => ScoreTask(task, now))
                .OrderByDescending(item => item.Score)
                .ThenBy(item => item.Task.Deadline ?? item.Task.ScheduledDate ?? DateTime.MaxValue)
                .ThenBy(item => item.Task.CreatedAt)
                .ThenBy(item => item.Task.FocusMinutes)
                .ToList();
        }

        private static ScoredTask ScoreTask(FocusTask task, DateTime now)
        {
            var score = 0d;
            var reasons = new List<string>();

            var priorityScore = PriorityScore(task.Priority);
            score += priorityScore;
            reasons.Add($"Priority +{priorityScore}");

            var deadlineScore = 10;
            var deadline = task.Deadline ?? task.ScheduledDate;
            if (deadline.HasValue)
            {
                var daysLeft = (deadline.Value.Date - now.Date).TotalDays;
                deadlineScore = daysLeft switch
                {
                    <= 1 => 100,
                    <= 3 => 70,
                    <= 7 => 40,
                    _ => 10
                };
            }
            else
            {
                deadlineScore = 20;
            }

            score += deadlineScore;
            reasons.Add($"Urgency +{deadlineScore}");

            var difficultyScore = Math.Clamp(task.Difficulty, 1, 5) * 12;
            score += difficultyScore;
            reasons.Add($"Difficulty +{difficultyScore}");

            if (task.FocusMinutes <= 30)
            {
                score += 20;
                reasons.Add("Quick win +20");
            }

            if (task.Status == FocusTaskStatus.Processing)
            {
                score += 15;
                reasons.Add("In progress +15");
            }

            return new ScoredTask(task, score, reasons);
        }

        private static AiTaskScoreResponse MapTaskScore(ScoredTask item)
        {
            return new AiTaskScoreResponse
            {
                Id = item.Task.Id,
                Title = item.Task.Title,
                Description = item.Task.Description,
                FocusMinutes = item.Task.FocusMinutes,
                Priority = item.Task.Priority.ToString(),
                Status = item.Task.Status.ToString(),
                ScheduledDate = item.Task.ScheduledDate,
                AiScore = Math.Round(item.Score, 2),
                ScoreReasons = item.Reasons.ToList()
            };
        }

        private static string BuildSuggestion(ScoredTask topTask)
        {
            var task = topTask.Task;
            var deadlineText = (task.Deadline ?? task.ScheduledDate)?.ToString("dd/MM/yyyy")
                ?? "no fixed deadline";
            return $"Start with \"{task.Title}\" first. It has the strongest AI score ({Math.Round(topTask.Score)}) thanks to its priority, urgency, and focus size. Planned date: {deadlineText}.";
        }

        private static string BuildMultiTaskSuggestion(List<ScoredTask> sortedTasks)
        {
            var titles = sortedTasks
                .Take(3)
                .Select(item => item.Task.Title)
                .ToList();

            return titles.Count switch
            {
                0 => "No tasks available for today.",
                1 => $"Today you should do {titles[0]} first.",
                2 => $"Today you should do {titles[0]} -> {titles[1]}.",
                _ => $"Today you should do {titles[0]} -> {titles[1]} -> {titles[2]}.",
            };
        }

        private static int PriorityScore(TaskPriority priority)
        {
            return priority switch
            {
                TaskPriority.High => 100,
                TaskPriority.Medium => 60,
                TaskPriority.Low => 20,
                _ => 40
            };
        }

        private static int EnergyBonus(TimeSpan slot, FocusTask task)
        {
            var hour = slot.Hours;
            var difficulty = Math.Clamp(task.Difficulty, 1, 5);

            if (hour < 11)
            {
                return difficulty >= 4 ? 40 : difficulty >= 3 ? 28 : 14;
            }

            if (hour < 15)
            {
                return difficulty >= 4 ? 24 : difficulty >= 3 ? 30 : 18;
            }

            return difficulty <= 2 ? 30 : difficulty == 3 ? 18 : 8;
        }

        private static int BufferMinutes(FocusTask task)
        {
            var difficulty = Math.Clamp(task.Difficulty, 1, 5);

            return difficulty switch
            {
                <= 2 => 2,
                3 => 5,
                4 => 8,
                _ => 10
            };
        }

        private static List<int> BuildPomodoroDurations(int focusMinutes)
        {
            if (focusMinutes <= 0)
            {
                return new List<int> { 25 };
            }

            if (focusMinutes <= 30)
            {
                return new List<int> { 25 };
            }

            if (focusMinutes <= 60)
            {
                return new List<int> { 25, Math.Max(1, focusMinutes - 25) };
            }

            var durations = new List<int>();
            var remaining = focusMinutes;

            while (remaining > 0)
            {
                if (remaining <= 30)
                {
                    durations.Add(remaining);
                    break;
                }

                durations.Add(25);
                remaining -= 25;
            }

            if (durations.Count >= 2 && durations[^1] < 15)
            {
                durations[^2] += durations[^1];
                durations.RemoveAt(durations.Count - 1);
            }

            return durations;
        }

        private static bool RangesOverlap(
            DateTime startA,
            DateTime endA,
            DateTime startB,
            DateTime endB)
        {
            return startA < endB && endA > startB;
        }

        private static ScheduledTaskResponse MapScheduledTask(
            ScheduledTask task,
            List<ScheduledTask> allScheduled)
        {
            return new ScheduledTaskResponse
            {
                Id = task.Id,
                TaskId = task.FocusTaskId,
                Title = task.TitleSnapshot,
                StartTime = task.StartTime,
                EndTime = task.EndTime,
                SessionNumber = task.SessionNumber,
                EstimatedMinutes = (int)Math.Round((task.EndTime - task.StartTime).TotalMinutes),
                Difficulty = task.FocusTask.Difficulty,
                PriorityScore = PriorityScore(task.FocusTask.Priority),
                AiScore = task.AiScore,
                IsOverlapping = allScheduled.Any(item =>
                    item.Id != task.Id &&
                    RangesOverlap(task.StartTime, task.EndTime, item.StartTime, item.EndTime)),
            };
        }

        private sealed record ScoredTask(
            FocusTask Task,
            double Score,
            List<string> Reasons);
    }

    internal static class FocusTaskAiExtensions
    {
        public static bool IsCompleted(this FocusTask task)
        {
            return task.Status == FocusTaskStatus.Completed;
        }
    }
}
