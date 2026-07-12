namespace BE_MyTime.Models
{
    public enum AuthProvider
    {
        Local = 1,
        Google = 2
    }

    public enum TaskPriority
    {
        Low = 1,
        Medium = 2,
        High = 3
    }

    public enum FocusTaskStatus
    {
        Todo = 1,
        Processing = 2,
        Completed = 3,
        Cancelled = 4
    }

    public enum TaskRepeat
    {
        None = 1,
        Daily = 2,
        Weekly = 3,
        Monthly = 4
    }

    public enum DistractionType
    {
        AppBackground = 1,
        LeftFocusScreen = 2,
        InactiveTooLong = 3,
        TooManyPauses = 4,
        LowOutputProgress = 5,
        Manual = 6
    }

    public enum DistractionLevel
    {
        Low = 1,
        Medium = 2,
        High = 3
    }

    public enum NotificationType
    {
        Reminder = 1,
        FocusCompleted = 2,
        TaskOverdue = 3,
        DailyReview = 4,
        System = 5
    }

    public enum AiDraftStatus
    {
        Draft = 1,
        Confirmed = 2,
        Cancelled = 3
    }

    public enum HabitFrequencyType
    {
        Daily = 1,
        Weekly = 2
    }
}
