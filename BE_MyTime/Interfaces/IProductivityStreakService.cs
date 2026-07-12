using BE_MyTime.DTOs.Streaks;

namespace BE_MyTime.Interfaces
{
    public interface IProductivityStreakService
    {
        Task<ProductivityStreakDashboardResponse> GetDashboardAsync(int userId, int days = 180);
    }
}
