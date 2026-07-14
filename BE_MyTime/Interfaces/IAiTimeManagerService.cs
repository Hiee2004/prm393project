using BE_MyTime.DTOs.Ai;
using BE_MyTime.DTOs.Schedule;
using BE_MyTime.DTOs.Task;

namespace BE_MyTime.Interfaces
{
    public interface IAiTimeManagerService
    {
        Task<AiPlanResponse> GeneratePlanAsync(int userId);

        Task<List<AiTaskScoreResponse>> SortTasksAsync(int userId);

        Task<List<AiPomodoroSessionResponse>> GeneratePomodoroAsync(int userId);

        Task<AiDailySuggestionResponse> GetDailySuggestionAsync(int userId);

        Task<SmartScheduleResponse> GenerateSmartScheduleAsync(int userId);

        Task<SmartScheduleResponse> GetTodaySmartScheduleAsync(int userId);

        Task<AiSmartTaskPlanResponse> GenerateSmartTaskPlanAsync(
            int userId,
            int taskId,
            string mode);

        Task<FocusTaskResponse> ApplySmartTaskPlanAsync(
            int userId,
            int taskId,
            ApplySmartTaskPlanRequest request);

        Task<ScheduledTaskResponse?> UpdateScheduledTaskAsync(
            int userId,
            UpdateScheduledTaskRequest request);

        Task<AiDailySuggestionResponse> GetDailyScheduleSuggestionAsync(int userId);
    }
}
