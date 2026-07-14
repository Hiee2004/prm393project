namespace BE_MyTime.Models
{
    public class FocusTaskCompletion
    {
        public int Id { get; set; }

        public int FocusTaskId { get; set; }

        public FocusTask FocusTask { get; set; } = null!;

        public DateTime CompletedOn { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
