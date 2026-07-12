namespace BE_MyTime.DTOs.Schedule
{
    public class ScheduledTaskResponse
    {
        public int Id { get; set; }

        public int TaskId { get; set; }

        public string Title { get; set; } = string.Empty;

        public DateTime StartTime { get; set; }

        public DateTime EndTime { get; set; }

        public int SessionNumber { get; set; }

        public int EstimatedMinutes { get; set; }

        public int Difficulty { get; set; }

        public int PriorityScore { get; set; }

        public double AiScore { get; set; }

        public bool IsOverlapping { get; set; }
    }
}
