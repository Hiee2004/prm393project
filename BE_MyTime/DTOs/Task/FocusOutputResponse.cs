namespace BE_MyTime.DTOs.Task
{
    public class FocusOutputResponse
    {
        public int Id { get; set; }

        public string Title { get; set; } = string.Empty;

        public bool IsCompleted { get; set; }

        public int SortOrder { get; set; }
    }
}