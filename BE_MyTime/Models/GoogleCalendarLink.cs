using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class GoogleCalendarLink
    {
        public int Id { get; set; }

        public int FocusTaskId { get; set; }

        public FocusTask FocusTask { get; set; } = null!;

        [Required]
        [MaxLength(300)]
        public string CalendarId { get; set; } = "primary";

        [Required]
        [MaxLength(300)]
        public string EventId { get; set; } = string.Empty;

        public DateTime SyncedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}