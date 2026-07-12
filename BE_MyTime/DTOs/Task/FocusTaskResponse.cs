namespace BE_MyTime.DTOs.Task
{
    public class FocusTaskResponse
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        public int FocusMinutes { get; set; }

        public string Priority { get; set; } = string.Empty;

        public DateTime? Deadline { get; set; }

        public int Difficulty { get; set; }

        public string Status { get; set; } = string.Empty;

        public DateTime? ScheduledDate { get; set; }

        public TimeSpan? StartTime { get; set; }

        public TimeSpan? EndTime { get; set; }

        public string Repeat { get; set; } = string.Empty;

        public bool ReminderEnabled { get; set; }

        public TimeSpan? ReminderTime { get; set; }

        public bool SyncToGoogleCalendar { get; set; }

        public List<FocusOutputResponse> Outputs { get; set; } = new();
    }
}
