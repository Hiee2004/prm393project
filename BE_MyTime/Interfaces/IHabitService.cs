using BE_MyTime.DTOs.Habits;

namespace BE_MyTime.Interfaces
{
    public interface IHabitService
    {
        Task<HabitDashboardResponse> GetDashboardAsync(int userId, int days = 84);

        Task<List<HabitResponse>> GetHabitsAsync(int userId, bool includeArchived = false);

        Task<HabitResponse?> GetHabitAsync(int id, int userId);

        Task<HabitResponse> CreateHabitAsync(int userId, CreateHabitRequest request);

        Task<HabitResponse?> UpdateHabitAsync(int id, int userId, UpdateHabitRequest request);

        Task<HabitResponse?> CheckInAsync(int id, int userId, HabitCheckInRequest request);

        Task<bool> DeleteHabitAsync(int id, int userId);
    }
}
