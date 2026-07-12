namespace BE_MyTime.Models
{
    public class HabitLog
    {
        public int Id { get; set; }

        public int HabitId { get; set; }

        public Habit Habit { get; set; } = null!;

        public DateTime CompletedOn { get; set; }

        public int Count { get; set; } = 1;

        public bool IsCompleted { get; set; }

        public int EarnedXp { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}
