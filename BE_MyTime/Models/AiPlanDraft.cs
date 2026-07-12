using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class AiPlanDraft
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public User User { get; set; } = null!;

        [Required]
        [MaxLength(300)]
        public string OriginalInput { get; set; } = string.Empty;

        [MaxLength(300)]
        public string? SuggestedTitle { get; set; }

        [MaxLength(1000)]
        public string? SuggestedDescription { get; set; }

        public DateTime? SuggestedDate { get; set; }

        public TimeSpan? SuggestedStartTime { get; set; }

        public TimeSpan? SuggestedEndTime { get; set; }

        public int SuggestedFocusMinutes { get; set; } = 25;

        public TaskPriority SuggestedPriority { get; set; } = TaskPriority.Medium;

        // Lưu JSON danh sách output AI gợi ý.
        [MaxLength(4000)]
        public string? SuggestedOutputsJson { get; set; }

        // Lưu lý do AI gợi ý lịch này.
        [MaxLength(1000)]
        public string? Reason { get; set; }

        public AiDraftStatus Status { get; set; } = AiDraftStatus.Draft;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ConfirmedAt { get; set; }
    }
}