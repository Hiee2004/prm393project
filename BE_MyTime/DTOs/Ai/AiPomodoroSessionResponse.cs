namespace BE_MyTime.DTOs.Ai
{
    public class AiPomodoroSessionResponse
    {
        public int TaskId { get; set; }

        public string TaskTitle { get; set; } = string.Empty;

        public int SessionNumber { get; set; }

        public int DurationMinutes { get; set; }

        public DateTime ScheduledDate { get; set; }

        public TimeSpan StartTime { get; set; }

        public TimeSpan EndTime { get; set; }
    }
}
