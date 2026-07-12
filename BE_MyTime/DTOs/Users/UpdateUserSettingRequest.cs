using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Users
{
    public class UpdateUserSettingRequest
    {
        [Range(1, 300)]
        public int DefaultFocusMinutes { get; set; } = 25;

        public bool NotificationEnabled { get; set; } = true;

        public bool AutoSyncGoogleCalendar { get; set; }

        public bool DailyReviewEnabled { get; set; } = true;

        public TimeSpan? DailyReviewTime { get; set; }

        public TimeSpan? PreferredFocusStartTime { get; set; }

        public TimeSpan? PreferredFocusEndTime { get; set; }

        [MaxLength(80)]
        public string TimeZone { get; set; } = "Asia/Ho_Chi_Minh";

        [MaxLength(50)]
        public string ThemeMode { get; set; } = "Light";

        public string? EnergyProfileJson { get; set; }
    }
}
