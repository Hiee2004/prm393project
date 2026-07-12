using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.FocusSessions
{
    public class CreateFocusSessionRequest
    {
        [Range(1, int.MaxValue)]
        public int FocusTaskId { get; set; }

        [Range(0, 86400)]
        public int PlannedSeconds { get; set; }

        [Range(0, 86400)]
        public int ActualFocusSeconds { get; set; }

        [Range(0, int.MaxValue)]
        public int CompletedOutputs { get; set; }

        [Range(0, int.MaxValue)]
        public int TotalOutputs { get; set; }

        [Range(0, int.MaxValue)]
        public int DistractionCount { get; set; }

        [Range(0, 86400)]
        public int TotalDistractionSeconds { get; set; }

        public DateTime StartedAt { get; set; } = DateTime.UtcNow;

        public DateTime? CompletedAt { get; set; }
    }
}
