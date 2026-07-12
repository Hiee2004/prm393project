namespace BE_MyTime.DTOs.Habits
{
    public class HabitResponse
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        public string FrequencyType { get; set; } = "Daily";

        public List<int> WeekDays { get; set; } = [];

        public int TargetCount { get; set; }

        public TimeSpan? ReminderTime { get; set; }

        public string ColorHex { get; set; } = "#58CC02";

        public string IconName { get; set; } = "local_fire_department_rounded";

        public bool IsArchived { get; set; }

        public int CurrentStreak { get; set; }

        public int BestStreak { get; set; }

        public int CompletedCountToday { get; set; }

        public bool CompletedToday { get; set; }

        public double CompletionRate { get; set; }
    }
}
