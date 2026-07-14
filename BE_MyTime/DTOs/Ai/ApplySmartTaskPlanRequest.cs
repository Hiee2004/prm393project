using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Ai
{
    public class ApplySmartTaskPlanRequest
    {
        [Range(1, 300)]
        public int SuggestedFocusMinutes { get; set; }

        [Range(1, 5)]
        public int SuggestedDifficulty { get; set; }

        [MinLength(1)]
        public List<string> BreakdownTitles { get; set; } = new();

        [MaxLength(30)]
        public string RecommendedFocusMode { get; set; } = string.Empty;
    }
}
