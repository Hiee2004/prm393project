namespace BE_MyTime.DTOs.Schedule
{
    public class UpdateScheduledTaskRequest
    {
        public int ScheduledTaskId { get; set; }

        public DateTime StartTime { get; set; }

        public DateTime EndTime { get; set; }

        public bool AllowOverlap { get; set; } = true;

        public bool ShiftConflicts { get; set; } = false;
    }
}
