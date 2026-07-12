namespace BE_MyTime.DTOs.Ai
{
    public class AiDailySuggestionResponse
    {
        public string Suggestion { get; set; } = string.Empty;

        public string? HighlightTaskTitle { get; set; }

        public double? HighlightScore { get; set; }
    }
}
