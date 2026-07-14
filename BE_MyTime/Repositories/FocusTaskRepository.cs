using BE_MyTime.Data;
using BE_MyTime.Models;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Repositories
{
    public class FocusTaskRepository
    {
        private readonly AppDbContext _db;
        public FocusTaskRepository(AppDbContext db)
        {
            _db = db;
        }
        public async Task<List<FocusTask>> GetByUserIdAsync(int userId)
        {
            return await _db.FocusTasks
                .Include(t => t.Outputs)
                .Include(t => t.CompletionLogs)
                .Where(t => t.UserId == userId)
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();
        }

        public async Task<FocusTask?> GetByIdAsync(int id, int userId)
        {
            return await _db.FocusTasks
                .Include(t => t.Outputs)
                .Include(t => t.CompletionLogs)
                .FirstOrDefaultAsync(t => t.Id == id && t.UserId == userId);
        }

        public async Task AddAsync(FocusTask task)
        {
            _db.FocusTasks.Add(task);
            await _db.SaveChangesAsync();
        }

        public async Task UpdateAsync(FocusTask task)
        {
            _db.FocusTasks.Update(task);
            await _db.SaveChangesAsync();
        }

        public async Task DeleteAsync(FocusTask task)
        {
            _db.FocusTasks.Remove(task);
            await _db.SaveChangesAsync();
        }
    }
}

