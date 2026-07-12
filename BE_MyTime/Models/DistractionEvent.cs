namespace BE_MyTime.Models
{
    public class DistractionEvent
    {
        public int Id { get; set; }

        public int FocusSessionId { get; set; }

        public FocusSession FocusSession { get; set; } = null!;

        public DistractionType Type { get; set; }

        public int DurationSeconds { get; set; }

        public DateTime OccurredAt { get; set; } = DateTime.UtcNow;

        public string? Note { get; set; }
    }
}