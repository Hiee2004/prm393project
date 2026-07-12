namespace BE_MyTime.DTOs.Habits
{
    public class UserProgressResponse
    {
        public int Xp { get; set; }

        public int Level { get; set; }

        public int CurrentStreak { get; set; }

        public int BestStreak { get; set; }

        public int TotalHabitCompletions { get; set; }

        public int NextLevelXp { get; set; }
    }
}
