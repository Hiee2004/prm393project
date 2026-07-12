using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class FocusOutput
    {
        public int Id { get; set; }

        public int FocusTaskId { get; set; }

        public FocusTask FocusTask { get; set; } = null!;

        [Required]
        [MaxLength(250)]
        public string Title { get; set; } = string.Empty;

        public bool IsCompleted { get; set; } = false;

        public DateTime? CompletedAt { get; set; }

        public int SortOrder { get; set; } = 0;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}