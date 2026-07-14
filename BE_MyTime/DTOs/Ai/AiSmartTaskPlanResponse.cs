namespace BE_MyTime.DTOs.Ai
{
    public class AiSmartTaskPlanResponse
    {
        public int TaskId { get; set; }

        public string TaskTitle { get; set; } = string.Empty;

        public string PlanMode { get; set; } = "Detailed";

        public int SuggestedDifficulty { get; set; }

        public int SuggestedFocusMinutes { get; set; }

        public string RecommendedFocusMode { get; set; } = string.Empty;

        public string BestTimeOfDay { get; set; } = string.Empty;

        public string Recommendation { get; set; } = string.Empty;

        public List<AiSmartTaskStepResponse> Breakdown { get; set; } = new();

        public List<AiSmartTaskPomodoroResponse> PomodoroPlan { get; set; } = new();

        public DateTime GeneratedAt { get; set; }
    }

    public class AiSmartTaskStepResponse
    {
        public int Order { get; set; }

        public string Title { get; set; } = string.Empty;

        public int Minutes { get; set; }
    }

    public class AiSmartTaskPomodoroResponse
    {
        public string Label { get; set; } = string.Empty;

        public int Minutes { get; set; }

        public bool IsBreak { get; set; }
    }
}
