namespace BE_MyTime.DTOs.Habits
{
    public class HabitDashboardResponse
    {
        public UserProgressResponse Progress { get; set; } = new();

        public List<HabitResponse> Habits { get; set; } = [];

        public List<HabitHeatmapCellResponse> Heatmap { get; set; } = [];
    }
}
