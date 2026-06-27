using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class Notification
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        public int? FocusTaskId { get; set; }

        public FocusTask? FocusTask { get; set; }

        [Required]
        [MaxLength(160)]
        public string Title { get; set; } = string.Empty;

        [Required]
        [MaxLength(1000)]
        public string Message { get; set; } = string.Empty;

        public NotificationType Type { get; set; } = NotificationType.System;

        public bool IsRead { get; set; } = false;

        public DateTime? ScheduledAt { get; set; }

        public DateTime? SentAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}