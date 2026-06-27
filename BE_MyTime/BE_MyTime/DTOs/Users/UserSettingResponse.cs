namespace BE_MyTime.DTOs.Users
{
    public class UserSettingResponse
    {
        public int DefaultFocusMinutes { get; set; }

        public bool NotificationEnabled { get; set; }

        public bool AutoSyncGoogleCalendar { get; set; }

        public bool DailyReviewEnabled { get; set; }

        public TimeSpan? DailyReviewTime { get; set; }

        public TimeSpan? PreferredFocusStartTime { get; set; }

        public TimeSpan? PreferredFocusEndTime { get; set; }

        public string TimeZone { get; set; } = string.Empty;

        public string ThemeMode { get; set; } = string.Empty;
    }
}
