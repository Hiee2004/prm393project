using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Task
{
    public class UpdateFocusTaskRequest
    {
        [Required]
        [MaxLength(180)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        public int FocusMinutes { get; set; } = 25;

        public string Priority { get; set; } = "Medium";

        public DateTime? Deadline { get; set; }

        public int Difficulty { get; set; } = 3;

        public string Status { get; set; } = "Todo";

        public DateTime? ScheduledDate { get; set; }

        public TimeSpan? StartTime { get; set; }

        public TimeSpan? EndTime { get; set; }

        public string Repeat { get; set; } = "None";

        public bool ReminderEnabled { get; set; }

        public TimeSpan? ReminderTime { get; set; }

        public bool SyncToGoogleCalendar { get; set; }

        public List<string> Outputs { get; set; } = new();
    }
}
