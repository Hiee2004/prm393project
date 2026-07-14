namespace BE_MyTime.DTOs.Notifications
{
    public class NotificationResponse
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        public string Message { get; set; } = string.Empty;

        public string Type { get; set; } = string.Empty;

        public bool IsRead { get; set; }

        public int? FocusTaskId { get; set; }

        public DateTime? ScheduledAt { get; set; }

        public DateTime? SentAt { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
