using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Habits
{
    public class HabitCheckInRequest
    {
        public DateTime? CompletedOn { get; set; }

        [Range(1, 50)]
        public int IncrementBy { get; set; } = 1;
    }
}
