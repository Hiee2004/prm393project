using BE_MyTime.DTOs.Ai;

namespace BE_MyTime.DTOs.Schedule
{
    public class SmartScheduleResponse
    {
        public DateTime GeneratedAt { get; set; }

        public string DailySuggestion { get; set; } = string.Empty;

        public List<AiTaskScoreResponse> SuggestedTaskOrder { get; set; } = new();

        public List<ScheduledTaskResponse> ScheduledTasks { get; set; } = new();
    }
}
