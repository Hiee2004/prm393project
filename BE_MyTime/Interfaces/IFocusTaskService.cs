using BE_MyTime.DTOs.Task;

namespace BE_MyTime.Interfaces
{
    public interface IFocusTaskService
    {
        Task<List<FocusTaskResponse>> GetTasksAsync(int userId);

        Task<FocusTaskResponse?> GetTaskAsync(int id, int userId);

        Task<FocusTaskResponse> CreateTaskAsync(
            int userId,
            CreateFocusTaskRequest request);

        Task<FocusTaskResponse?> UpdateTaskAsync(
            int id,
            int userId,
            UpdateFocusTaskRequest request);

        Task<bool> DeleteTaskAsync(int id, int userId);
    }
}
