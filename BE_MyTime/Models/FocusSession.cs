namespace BE_MyTime.Models
{
    public class FocusSession
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        public int FocusTaskId { get; set; }

        public FocusTask FocusTask { get; set; } = null!;

        public int PlannedSeconds { get; set; }

        public int ActualFocusSeconds { get; set; }

        public int CompletedOutputs { get; set; }

        public int TotalOutputs { get; set; }

        public int DistractionCount { get; set; }

        public int TotalDistractionSeconds { get; set; }

        public double FocusScore { get; set; }

        public string? FeedbackTitle { get; set; }

        public string? FeedbackMessage { get; set; }

        public DateTime StartedAt { get; set; } = DateTime.UtcNow;

        public DateTime? CompletedAt { get; set; }

        public ICollection<DistractionEvent> DistractionEvents { get; set; } = new List<DistractionEvent>();

        public AiFocusEvaluation? AiFocusEvaluation { get; set; }
    }
}