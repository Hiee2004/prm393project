using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Habits
{
    public class UpdateHabitRequest
    {
        [Required]
        [MaxLength(120)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string? Description { get; set; }

        [MaxLength(20)]
        public string FrequencyType { get; set; } = "Daily";

        public List<int> WeekDays { get; set; } = [];

        [Range(1, 50)]
        public int TargetCount { get; set; } = 1;

        public TimeSpan? ReminderTime { get; set; }

        [MaxLength(9)]
        public string? ColorHex { get; set; }

        [MaxLength(80)]
        public string? IconName { get; set; }

        public bool IsArchived { get; set; }
    }
}
