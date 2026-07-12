namespace BE_MyTime.DTOs.Ai
{
    public class AiTaskScoreResponse
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        public string? Description { get; set; }

        public int FocusMinutes { get; set; }

        public string Priority { get; set; } = string.Empty;

        public string Status { get; set; } = string.Empty;

        public DateTime? ScheduledDate { get; set; }

        public double AiScore { get; set; }

        public List<string> ScoreReasons { get; set; } = new();
    }
}
