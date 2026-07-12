namespace BE_MyTime.DTOs.Ai
{
    public class AiPlanDraftResponse
    {
        public int Id { get; set; }

        public int TaskId { get; set; }

        public string SuggestedTitle { get; set; } = string.Empty;

        public DateTime SuggestedDate { get; set; }

        public TimeSpan SuggestedStartTime { get; set; }

        public TimeSpan SuggestedEndTime { get; set; }

        public int SuggestedFocusMinutes { get; set; }

        public string Reason { get; set; } = string.Empty;

        public string SuggestedOutputsJson { get; set; } = "[]";

        public DateTime CreatedAt { get; set; }
    }
}
