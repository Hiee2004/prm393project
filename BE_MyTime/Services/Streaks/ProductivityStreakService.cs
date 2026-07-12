using BE_MyTime.Data;
using BE_MyTime.DTOs.Streaks;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Services.Streaks
{
    public class ProductivityStreakService : IProductivityStreakService
    {
        private const int MinimumFocusMinutes = 25;
        private readonly AppDbContext _db;

        public ProductivityStreakService(AppDbContext db)
        {
            _db = db;
        }

        public async Task<ProductivityStreakDashboardResponse> GetDashboardAsync(int userId, int days = 180)
        {
            var safeDays = Math.Clamp(days, 90, 366);
            var fromDate = DateTime.UtcNow.Date.AddDays(-(safeDays - 1));

            var completedTasks = await _db.FocusTasks
                .Where(x =>
                    x.UserId == userId &&
                    x.Status == FocusTaskStatus.Completed &&
                    x.CompletedAt != null &&
                    x.CompletedAt >= fromDate)
                .Select(x => new
                {
                    CompletedDate = x.CompletedAt!.Value
                })
                .ToListAsync();

            var focusSessions = await _db.FocusSessions
                .Where(x =>
                    x.UserId == userId &&
                    (x.CompletedAt ?? x.StartedAt) >= fromDate)
                .Select(x => new
                {
                    SessionDate = (x.CompletedAt ?? x.StartedAt),
                    x.ActualFocusSeconds
                })
                .ToListAsync();

            var taskCountByDay = completedTasks
                .GroupBy(x => x.CompletedDate.ToLocalTime().Date)
                .ToDictionary(group => group.Key, group => group.Count());

            var focusSecondsByDay = focusSessions
                .GroupBy(x => x.SessionDate.ToLocalTime().Date)
                .ToDictionary(group => group.Key, group => group.Sum(x => x.ActualFocusSeconds));

            var calendar = new List<ProductivityStreakDayResponse>(safeDays);

            for (var i = 0; i < safeDays; i++)
            {
                var date = fromDate.AddDays(i).Date;
                var completedTaskCount = taskCountByDay.TryGetValue(date, out var taskCount)
                    ? taskCount
                    : 0;
                var focusSeconds = focusSecondsByDay.TryGetValue(date, out var totalFocus)
                    ? totalFocus
                    : 0;

                calendar.Add(new ProductivityStreakDayResponse
                {
                    Date = date,
                    CompletedTaskCount = completedTaskCount,
                    FocusSeconds = focusSeconds,
                    IsProductive = completedTaskCount >= 1 && focusSeconds >= MinimumFocusMinutes * 60
                });
            }

            return new ProductivityStreakDashboardResponse
            {
                CurrentStreak = CalculateCurrentStreak(calendar),
                BestStreak = CalculateBestStreak(calendar),
                TotalProductiveDays = calendar.Count(x => x.IsProductive),
                MinimumFocusMinutes = MinimumFocusMinutes,
                Calendar = calendar
            };
        }

        private static int CalculateCurrentStreak(List<ProductivityStreakDayResponse> calendar)
        {
            if (calendar.Count == 0)
            {
                return 0;
            }

            var streak = 0;

            for (var i = calendar.Count - 1; i >= 0; i--)
            {
                if (!calendar[i].IsProductive)
                {
                    break;
                }

                streak++;
            }

            return streak;
        }

        private static int CalculateBestStreak(List<ProductivityStreakDayResponse> calendar)
        {
            var best = 0;
            var running = 0;

            foreach (var day in calendar)
            {
                if (day.IsProductive)
                {
                    running++;
                    best = Math.Max(best, running);
                }
                else
                {
                    running = 0;
                }
            }

            return best;
        }
    }
}
