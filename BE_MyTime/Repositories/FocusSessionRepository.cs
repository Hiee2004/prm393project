using BE_MyTime.Data;
using BE_MyTime.Models;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Repositories
{
    public class FocusSessionRepository
    {
        private readonly AppDbContext _db;
        public FocusSessionRepository(AppDbContext db)
        {
            _db = db;
        }
        public async Task<List<FocusSession>> GetByUserIdAsync(int userId)
        {
            return await _db.FocusSessions
                .Include(x => x.FocusTask)
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CompletedAt)
                .ToListAsync();
        }

        public async Task<FocusSession?> GetByIdAsync(int id, int userId)
        {
            return await _db.FocusSessions
                .Include(x => x.FocusTask)
                .FirstOrDefaultAsync(x =>
                    x.Id == id &&
                    x.UserId == userId);
        }

        public async Task AddAsync(FocusSession session)
        {
            _db.FocusSessions.Add(session);
            await _db.SaveChangesAsync();
        }

        public async Task UpdateAsync(FocusSession session)
        {
            _db.FocusSessions.Update(session);
            await _db.SaveChangesAsync();
        }

        public async Task DeleteAsync(FocusSession session)
        {
            _db.FocusSessions.Remove(session);
            await _db.SaveChangesAsync();
        }
    }
}

