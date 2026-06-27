using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class AiFocusEvaluation
    {
        public int Id { get; set; }

        public int FocusSessionId { get; set; }

        public FocusSession FocusSession { get; set; } = null!;

        public DistractionLevel DistractionLevel { get; set; } = DistractionLevel.Low;

        public double DistractionScore { get; set; }

        public double FocusScore { get; set; }

        [MaxLength(120)]
        public string FeedbackTitle { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string FeedbackMessage { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string Suggestion { get; set; } = string.Empty;

        [MaxLength(2000)]
        public string? RawAiResponse { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}