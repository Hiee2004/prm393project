using BE_MyTime.Data;
using BE_MyTime.Models;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Repositories
{
    public class UserRepository
    {
        private readonly AppDbContext _db;
        public UserRepository(AppDbContext db)
        {
            _db = db;
        }
        public async Task<User?> GetByIdWithSettingAsync(int userId)
        {
            return await _db.Users.Include(x => x.Setting).FirstOrDefaultAsync(x => x.Id == userId);
        }
        public async Task<bool> EmailExistsAsync(string email, int exceptUserId)
        {
            return await _db.Users
                .AnyAsync(x => x.Email == email && x.Id != exceptUserId);
        }

        public async Task SaveChangesAsync()
        {
            await _db.SaveChangesAsync();
        }
    }   
    
}
