using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Task
{
    public class FocusTaskOutputUpsertRequest
    {
        public int? Id { get; set; }

        [Required]
        [MaxLength(250)]
        public string Title { get; set; } = string.Empty;

        public bool IsCompleted { get; set; }

        public DateTime? CompletedAt { get; set; }

        public int SortOrder { get; set; }
    }
}
