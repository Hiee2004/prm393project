using BE_MyTime.DTOs.Habits;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using BE_MyTime.Repositories;

namespace BE_MyTime.Services.Habits
{
    public class HabitService : IHabitService
    {
        private const int XpPerCheckIn = 15;
        private readonly HabitRepository _repository;

        public HabitService(HabitRepository repository)
        {
            _repository = repository;
        }

        public async Task<HabitDashboardResponse> GetDashboardAsync(int userId, int days = 84)
        {
            var safeDays = Math.Clamp(days, 28, 140);
            var habits = await _repository.GetByUserIdAsync(userId, includeArchived: false);
            var progress = await _repository.GetOrCreateProgressAsync(userId);
            var fromDate = DateOnly.FromDateTime(DateTime.Today.AddDays(-(safeDays - 1)));

            return new HabitDashboardResponse
            {
                Progress = MapProgress(progress),
                Habits = habits.Select(MapHabit).ToList(),
                Heatmap = BuildHeatmap(habits, fromDate, safeDays)
            };
        }

        public async Task<List<HabitResponse>> GetHabitsAsync(int userId, bool includeArchived = false)
        {
            var habits = await _repository.GetByUserIdAsync(userId, includeArchived);
            return habits.Select(MapHabit).ToList();
        }

        public async Task<HabitResponse?> GetHabitAsync(int id, int userId)
        {
            var habit = await _repository.GetByIdAsync(id, userId);
            return habit == null ? null : MapHabit(habit);
        }

        public async Task<HabitResponse> CreateHabitAsync(int userId, CreateHabitRequest request)
        {
            var habit = new Habit
            {
                UserId = userId,
                Title = request.Title.Trim(),
                Description = CleanText(request.Description),
                FrequencyType = ParseFrequency(request.FrequencyType),
                WeekDaysCsv = SerializeWeekDays(request.WeekDays),
                TargetCount = Math.Max(1, request.TargetCount),
                ReminderTime = request.ReminderTime,
                ColorHex = NormalizeColor(request.ColorHex),
                IconName = string.IsNullOrWhiteSpace(request.IconName)
                    ? "local_fire_department_rounded"
                    : request.IconName.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            await _repository.AddHabitAsync(habit);
            return MapHabit(habit);
        }

        public async Task<HabitResponse?> UpdateHabitAsync(int id, int userId, UpdateHabitRequest request)
        {
            var habit = await _repository.GetByIdAsync(id, userId);
            if (habit == null)
            {
                return null;
            }

            habit.Title = request.Title.Trim();
            habit.Description = CleanText(request.Description);
            habit.FrequencyType = ParseFrequency(request.FrequencyType);
            habit.WeekDaysCsv = SerializeWeekDays(request.WeekDays);
            habit.TargetCount = Math.Max(1, request.TargetCount);
            habit.ReminderTime = request.ReminderTime;
            habit.ColorHex = NormalizeColor(request.ColorHex);
            habit.IconName = string.IsNullOrWhiteSpace(request.IconName)
                ? habit.IconName
                : request.IconName.Trim();
            habit.IsArchived = request.IsArchived;
            habit.UpdatedAt = DateTime.UtcNow;

            await _repository.SaveChangesAsync();
            return MapHabit(habit);
        }

        public async Task<HabitResponse?> CheckInAsync(int id, int userId, HabitCheckInRequest request)
        {
            var habit = await _repository.GetByIdAsync(id, userId);
            if (habit == null)
            {
                return null;
            }

            var completedOn = (request.CompletedOn ?? DateTime.Now).Date;
            var incrementBy = Math.Max(1, request.IncrementBy);
            var log = habit.Logs.FirstOrDefault(x => x.CompletedOn.Date == completedOn);
            if (log == null)
            {
                log = new HabitLog
                {
                    CompletedOn = completedOn,
                    CreatedAt = DateTime.UtcNow
                };
                habit.Logs.Add(log);
            }

            log.Count += incrementBy;
            log.IsCompleted = log.Count >= Math.Max(1, habit.TargetCount);
            log.EarnedXp += incrementBy * XpPerCheckIn;
            log.UpdatedAt = DateTime.UtcNow;
            habit.UpdatedAt = DateTime.UtcNow;

            var progress = await _repository.GetOrCreateProgressAsync(userId);
            progress.Xp += incrementBy * XpPerCheckIn;
            progress.TotalHabitCompletions += incrementBy;
            progress.LastCompletedOn = completedOn;
            progress.UpdatedAt = DateTime.UtcNow;
            ApplyProgressStreaks(progress, habit.Logs.Select(x => x.CompletedOn.Date));

            await _repository.SaveChangesAsync();
            return MapHabit(habit);
        }

        public async Task<bool> DeleteHabitAsync(int id, int userId)
        {
            var habit = await _repository.GetByIdAsync(id, userId);
            if (habit == null)
            {
                return false;
            }

            await _repository.DeleteHabitAsync(habit);
            return true;
        }

        private static HabitResponse MapHabit(Habit habit)
        {
            var weekDays = ParseWeekDays(habit.WeekDaysCsv);
            var today = DateOnly.FromDateTime(DateTime.Today);
            var groupedCounts = habit.Logs
                .GroupBy(x => DateOnly.FromDateTime(x.CompletedOn.Date))
                .ToDictionary(group => group.Key, group => group.Sum(x => x.Count));

            var currentStreak = CalculateCurrentStreak(habit, groupedCounts);
            var bestStreak = CalculateBestStreak(habit, groupedCounts);
            var todayCount = groupedCounts.TryGetValue(today, out var count) ? count : 0;

            return new HabitResponse
            {
                Id = habit.Id,
                Title = habit.Title,
                Description = habit.Description,
                FrequencyType = habit.FrequencyType.ToString(),
                WeekDays = weekDays,
                TargetCount = habit.TargetCount,
                ReminderTime = habit.ReminderTime,
                ColorHex = habit.ColorHex,
                IconName = habit.IconName,
                IsArchived = habit.IsArchived,
                CurrentStreak = currentStreak,
                BestStreak = bestStreak,
                CompletedCountToday = todayCount,
                CompletedToday = todayCount >= Math.Max(1, habit.TargetCount),
                CompletionRate = CalculateCompletionRate(habit, groupedCounts)
            };
        }

        private static UserProgressResponse MapProgress(UserProgress progress)
        {
            var level = Math.Max(1, (progress.Xp / 100) + 1);
            progress.Level = level;

            return new UserProgressResponse
            {
                Xp = progress.Xp,
                Level = level,
                CurrentStreak = progress.CurrentStreak,
                BestStreak = progress.BestStreak,
                TotalHabitCompletions = progress.TotalHabitCompletions,
                NextLevelXp = level * 100
            };
        }

        private static List<HabitHeatmapCellResponse> BuildHeatmap(
            IEnumerable<Habit> habits,
            DateOnly fromDate,
            int days)
        {
            var counts = habits
                .SelectMany(x => x.Logs)
                .GroupBy(x => DateOnly.FromDateTime(x.CompletedOn.Date))
                .ToDictionary(group => group.Key, group => group.Sum(x => x.Count));

            var maxCount = counts.Count == 0 ? 1 : counts.Values.Max();
            var result = new List<HabitHeatmapCellResponse>(days);

            for (var i = 0; i < days; i++)
            {
                var date = fromDate.AddDays(i);
                var count = counts.TryGetValue(date, out var total) ? total : 0;
                result.Add(new HabitHeatmapCellResponse
                {
                    Date = date.ToDateTime(TimeOnly.MinValue),
                    Count = count,
                    Intensity = MapIntensity(count, maxCount)
                });
            }

            return result;
        }

        private static int MapIntensity(int count, int maxCount)
        {
            if (count <= 0) return 0;
            if (maxCount <= 1) return 4;

            var ratio = (double)count / maxCount;
            if (ratio >= 0.75) return 4;
            if (ratio >= 0.5) return 3;
            if (ratio >= 0.25) return 2;
            return 1;
        }

        private static double CalculateCompletionRate(
            Habit habit,
            IReadOnlyDictionary<DateOnly, int> groupedCounts)
        {
            var today = DateOnly.FromDateTime(DateTime.Today);
            var start = today.AddDays(-13);
            var eligibleDays = 0;
            var completedDays = 0;

            for (var date = start; date <= today; date = date.AddDays(1))
            {
                if (!IsScheduledForDate(habit, date))
                {
                    continue;
                }

                eligibleDays++;
                var count = groupedCounts.TryGetValue(date, out var total) ? total : 0;
                if (count >= Math.Max(1, habit.TargetCount))
                {
                    completedDays++;
                }
            }

            if (eligibleDays == 0)
            {
                return 0;
            }

            return Math.Round((double)completedDays / eligibleDays, 2);
        }

        private static int CalculateCurrentStreak(
            Habit habit,
            IReadOnlyDictionary<DateOnly, int> groupedCounts)
        {
            var streak = 0;
            var date = DateOnly.FromDateTime(DateTime.Today);

            while (true)
            {
                if (!IsScheduledForDate(habit, date))
                {
                    date = date.AddDays(-1);
                    continue;
                }

                var count = groupedCounts.TryGetValue(date, out var total) ? total : 0;
                if (count < Math.Max(1, habit.TargetCount))
                {
                    break;
                }

                streak++;
                date = date.AddDays(-1);
            }

            return streak;
        }

        private static int CalculateBestStreak(
            Habit habit,
            IReadOnlyDictionary<DateOnly, int> groupedCounts)
        {
            var start = DateOnly.FromDateTime(habit.CreatedAt.Date);
            var end = DateOnly.FromDateTime(DateTime.Today);
            var best = 0;
            var current = 0;

            for (var date = start; date <= end; date = date.AddDays(1))
            {
                if (!IsScheduledForDate(habit, date))
                {
                    continue;
                }

                var count = groupedCounts.TryGetValue(date, out var total) ? total : 0;
                if (count >= Math.Max(1, habit.TargetCount))
                {
                    current++;
                    best = Math.Max(best, current);
                }
                else
                {
                    current = 0;
                }
            }

            return best;
        }

        private static bool IsScheduledForDate(Habit habit, DateOnly date)
        {
            if (habit.FrequencyType == HabitFrequencyType.Daily)
            {
                return true;
            }

            var weekDays = ParseWeekDays(habit.WeekDaysCsv);
            if (weekDays.Count == 0)
            {
                return false;
            }

            var dayNumber = date.DayOfWeek == DayOfWeek.Sunday
                ? 7
                : (int)date.DayOfWeek;

            return weekDays.Contains(dayNumber);
        }

        private static void ApplyProgressStreaks(UserProgress progress, IEnumerable<DateTime> completionDates)
        {
            var dates = completionDates
                .Select(x => DateOnly.FromDateTime(x.Date))
                .Distinct()
                .OrderBy(x => x)
                .ToList();

            if (dates.Count == 0)
            {
                progress.CurrentStreak = 0;
                progress.BestStreak = 0;
                progress.Level = Math.Max(1, (progress.Xp / 100) + 1);
                return;
            }

            var best = 1;
            var running = 1;

            for (var i = 1; i < dates.Count; i++)
            {
                if (dates[i - 1].AddDays(1) == dates[i])
                {
                    running++;
                    best = Math.Max(best, running);
                }
                else
                {
                    running = 1;
                }
            }

            var current = 1;
            for (var i = dates.Count - 1; i > 0; i--)
            {
                if (dates[i - 1].AddDays(1) == dates[i])
                {
                    current++;
                }
                else
                {
                    break;
                }
            }

            progress.CurrentStreak = current;
            progress.BestStreak = Math.Max(progress.BestStreak, best);
            progress.Level = Math.Max(1, (progress.Xp / 100) + 1);
        }

        private static HabitFrequencyType ParseFrequency(string? value)
        {
            return Enum.TryParse<HabitFrequencyType>(value, true, out var frequency)
                ? frequency
                : HabitFrequencyType.Daily;
        }

        private static List<int> ParseWeekDays(string? csv)
        {
            if (string.IsNullOrWhiteSpace(csv))
            {
                return [];
            }

            return csv
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(value => int.TryParse(value, out var day) ? day : 0)
                .Where(day => day is >= 1 and <= 7)
                .Distinct()
                .OrderBy(day => day)
                .ToList();
        }

        private static string? SerializeWeekDays(IEnumerable<int>? weekDays)
        {
            if (weekDays == null)
            {
                return null;
            }

            var normalized = weekDays
                .Where(day => day is >= 1 and <= 7)
                .Distinct()
                .OrderBy(day => day)
                .ToList();

            return normalized.Count == 0 ? null : string.Join(',', normalized);
        }

        private static string NormalizeColor(string? colorHex)
        {
            if (string.IsNullOrWhiteSpace(colorHex))
            {
                return "#58CC02";
            }

            var trimmed = colorHex.Trim();
            return trimmed.StartsWith('#') ? trimmed : $"#{trimmed}";
        }

        private static string? CleanText(string? value)
        {
            return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
        }
    }
}
