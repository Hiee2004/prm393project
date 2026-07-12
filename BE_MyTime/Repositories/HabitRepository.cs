using BE_MyTime.Data;
using BE_MyTime.Models;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Repositories
{
    public class HabitRepository
    {
        private readonly AppDbContext _db;

        public HabitRepository(AppDbContext db)
        {
            _db = db;
        }

        public async Task<List<Habit>> GetByUserIdAsync(int userId, bool includeArchived)
        {
            var query = _db.Habits
                .Include(x => x.Logs)
                .Where(x => x.UserId == userId);

            if (!includeArchived)
            {
                query = query.Where(x => !x.IsArchived);
            }

            return await query
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();
        }

        public async Task<Habit?> GetByIdAsync(int id, int userId)
        {
            return await _db.Habits
                .Include(x => x.Logs)
                .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);
        }

        public async Task<UserProgress> GetOrCreateProgressAsync(int userId)
        {
            var progress = await _db.UserProgresses.FirstOrDefaultAsync(x => x.UserId == userId);
            if (progress != null)
            {
                return progress;
            }

            progress = new UserProgress
            {
                UserId = userId,
                CreatedAt = DateTime.UtcNow,
            };

            _db.UserProgresses.Add(progress);
            await _db.SaveChangesAsync();
            return progress;
        }

        public async Task AddHabitAsync(Habit habit)
        {
            _db.Habits.Add(habit);
            await _db.SaveChangesAsync();
        }

        public async Task SaveChangesAsync()
        {
            await _db.SaveChangesAsync();
        }

        public async Task DeleteHabitAsync(Habit habit)
        {
            _db.Habits.Remove(habit);
            await _db.SaveChangesAsync();
        }
    }
}
