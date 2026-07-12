using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class FocusTask
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        [Required]
        [MaxLength(180)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        public int FocusMinutes { get; set; } = 25;

        public TaskPriority Priority { get; set; } = TaskPriority.Medium;

        public DateTime? Deadline { get; set; }

        public int Difficulty { get; set; } = 3;

        public FocusTaskStatus Status { get; set; } = FocusTaskStatus.Todo;

        public DateTime? ScheduledDate { get; set; }

        public TimeSpan? StartTime { get; set; }

        public TimeSpan? EndTime { get; set; }

        public TaskRepeat Repeat { get; set; } = TaskRepeat.None;

        public bool ReminderEnabled { get; set; } = false;

        public TimeSpan? ReminderTime { get; set; }

        public bool SyncToGoogleCalendar { get; set; } = false;

        [MaxLength(300)]
        public string? GoogleCalendarEventId { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public ICollection<FocusOutput> Outputs { get; set; } = new List<FocusOutput>();

        public ICollection<FocusSession> Sessions { get; set; } = new List<FocusSession>();

        public ICollection<ScheduledTask> ScheduledTasks { get; set; } = new List<ScheduledTask>();

        public GoogleCalendarLink? GoogleCalendarLink { get; set; }
    }
}
