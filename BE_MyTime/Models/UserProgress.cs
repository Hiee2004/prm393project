namespace BE_MyTime.Models
{
    public class UserProgress
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        public int Xp { get; set; }

        public int Level { get; set; } = 1;

        public int CurrentStreak { get; set; }

        public int BestStreak { get; set; }

        public int TotalHabitCompletions { get; set; }

        public DateTime? LastCompletedOn { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}
