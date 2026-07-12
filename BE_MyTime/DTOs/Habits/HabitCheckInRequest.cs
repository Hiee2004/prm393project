namespace BE_MyTime.DTOs.Habits
{
    public class HabitCheckInRequest
    {
        public DateTime? CompletedOn { get; set; }

        public int IncrementBy { get; set; } = 1;
    }
}
