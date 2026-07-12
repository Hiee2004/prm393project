using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class ScheduledTask
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        public int FocusTaskId { get; set; }

        public FocusTask FocusTask { get; set; } = null!;

        [MaxLength(180)]
        public string TitleSnapshot { get; set; } = string.Empty;

        public DateTime StartTime { get; set; }

        public DateTime EndTime { get; set; }

        public int SessionNumber { get; set; }

        public double AiScore { get; set; }

        public bool IsOverlapAllowed { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }
    }
}
