namespace BE_MyTime.DTOs.FocusSessions
{
    public class FocusSessionResponse
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public int FocusTaskId { get; set; }

        public string TaskTitle { get; set; } = string.Empty;

        public int PlannedSeconds { get; set; }

        public int ActualFocusSeconds { get; set; }

        public int CompletedOutputs { get; set; }

        public int TotalOutputs { get; set; }

        public int DistractionCount { get; set; }

        public int TotalDistractionSeconds { get; set; }

        public double FocusScore { get; set; }

        public string? FeedbackTitle { get; set; }

        public string? FeedbackMessage { get; set; }

        public DateTime StartedAt { get; set; }

        public DateTime? CompletedAt
        {
            get; set;
        }
    }
}
