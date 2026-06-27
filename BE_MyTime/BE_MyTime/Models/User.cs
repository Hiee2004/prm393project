using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.Models
{
    public class User
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(120)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [MaxLength(180)]
        public string Email { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? PasswordHash { get; set; }

        public AuthProvider AuthProvider { get; set; } = AuthProvider.Local;

        [MaxLength(200)]
        public string? GoogleId { get; set; }

        [MaxLength(500)]
        public string? AvatarUrl { get; set; }

        // Dùng khi cần Google Calendar.
        [MaxLength(2000)]
        public string? GoogleAccessToken { get; set; }

        [MaxLength(2000)]
        public string? GoogleRefreshToken { get; set; }

        public DateTime? GoogleTokenExpiredAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? UpdatedAt { get; set; }

        public UserSetting? Setting { get; set; }

        public ICollection<FocusTask> FocusTasks { get; set; } = new List<FocusTask>();

        public ICollection<FocusSession> FocusSessions { get; set; } = new List<FocusSession>();

        public ICollection<Notification> Notifications { get; set; } = new List<Notification>();

        public ICollection<AiPlanDraft> AiPlanDrafts { get; set; } = new List<AiPlanDraft>();
    }
}
