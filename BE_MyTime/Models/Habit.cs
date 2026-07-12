using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class Habit
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        [Required]
        [MaxLength(160)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(600)]
        public string? Description { get; set; }

        public HabitFrequencyType FrequencyType { get; set; } = HabitFrequencyType.Daily;

        [MaxLength(60)]
        public string? WeekDaysCsv { get; set; }

        public int TargetCount { get; set; } = 1;

        public TimeSpan? ReminderTime { get; set; }

        [MaxLength(20)]
        public string ColorHex { get; set; } = "#58CC02";

        [MaxLength(40)]
        public string IconName { get; set; } = "local_fire_department_rounded";

        public bool IsArchived { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public ICollection<HabitLog> Logs { get; set; } = new List<HabitLog>();
    }
}
