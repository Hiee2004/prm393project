using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.FocusSessions
{
    public class CreateFocusSessionRequest
    {
        [Required]
        public int FocusTaskId { get; set; }

        public int PlannedSeconds { get; set; }

        public int ActualFocusSeconds { get; set; }

        public int CompletedOutputs { get; set; }

        public int TotalOutputs { get; set; }

        public int DistractionCount { get; set; }

        public int TotalDistractionSeconds { get; set; }

        public DateTime StartedAt { get; set; } = DateTime.UtcNow;

        public DateTime? CompletedAt { get; set; }
    }
}
