using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Users
{
    public class UpdateUserProfileRequest
    {
        [Required]
        [MaxLength(120)]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(180)]
        public string Email { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? AvatarUrl { get; set; }
    }
}
