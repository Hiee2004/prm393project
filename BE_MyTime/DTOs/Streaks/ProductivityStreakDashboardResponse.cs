namespace BE_MyTime.DTOs.Streaks
{
    public class ProductivityStreakDashboardResponse
    {
        public int CurrentStreak { get; set; }

        public int BestStreak { get; set; }

        public int TotalProductiveDays { get; set; }

        public int MinimumFocusMinutes { get; set; }

        public List<ProductivityStreakDayResponse> Calendar { get; set; } = [];
    }
}
