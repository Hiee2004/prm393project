using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class UserSetting
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        public int DefaultFocusMinutes { get; set; } = 25;

        public bool NotificationEnabled { get; set; } = true;

        public bool AutoSyncGoogleCalendar { get; set; } = false;

        public bool DailyReviewEnabled { get; set; } = true;

        public TimeSpan? DailyReviewTime { get; set; } = new TimeSpan(21, 0, 0);

        public TimeSpan? PreferredFocusStartTime { get; set; } = new TimeSpan(8, 0, 0);

        public TimeSpan? PreferredFocusEndTime { get; set; } = new TimeSpan(22, 0, 0);

        [MaxLength(80)]
        public string TimeZone { get; set; } = "Asia/Ho_Chi_Minh";

        [MaxLength(30)]
        public string ThemeMode { get; set; } = "Light";

        [MaxLength(2000)]
        public string? EnergyProfileJson { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}
