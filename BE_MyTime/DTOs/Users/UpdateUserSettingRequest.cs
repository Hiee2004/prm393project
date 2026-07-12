namespace BE_MyTime.DTOs.Users
{
    public class UpdateUserSettingRequest
    {
        public int DefaultFocusMinutes { get; set; } = 25;

        public bool NotificationEnabled { get; set; } = true;

        public bool AutoSyncGoogleCalendar { get; set; }

        public bool DailyReviewEnabled { get; set; } = true;

        public TimeSpan? DailyReviewTime { get; set; }

        public TimeSpan? PreferredFocusStartTime { get; set; }

        public TimeSpan? PreferredFocusEndTime { get; set; }

        public string TimeZone { get; set; } = "Asia/Ho_Chi_Minh";

        public string ThemeMode { get; set; } = "Light";

        public string? EnergyProfileJson { get; set; }
    }
}
