namespace BE_MyTime.DTOs.Habits
{
    public class UpdateHabitRequest
    {
        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        public string FrequencyType { get; set; } = "Daily";

        public List<int> WeekDays { get; set; } = [];

        public int TargetCount { get; set; } = 1;

        public TimeSpan? ReminderTime { get; set; }

        public string? ColorHex { get; set; }

        public string? IconName { get; set; }

        public bool IsArchived { get; set; }
    }
}
