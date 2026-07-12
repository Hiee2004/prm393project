namespace BE_MyTime.DTOs.Ai
{
    public class AiPlanResponse
    {
        public DateTime GeneratedAt { get; set; }

        public string DailySuggestion { get; set; } = string.Empty;

        public List<AiTaskScoreResponse> SortedTasks { get; set; } = new();

        public List<AiPlanDraftResponse> Drafts { get; set; } = new();

        public List<AiPomodoroSessionResponse> PomodoroSessions { get; set; } = new();
    }
}
