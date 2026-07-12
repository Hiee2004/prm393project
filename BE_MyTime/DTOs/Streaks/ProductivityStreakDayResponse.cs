namespace BE_MyTime.DTOs.Streaks
{
    public class ProductivityStreakDayResponse
    {
        public DateTime Date { get; set; }

        public int CompletedTaskCount { get; set; }

        public int FocusSeconds { get; set; }

        public bool IsProductive { get; set; }
    }
}
