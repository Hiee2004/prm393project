using System.ComponentModel.DataAnnotations;

namespace BE_MyTime.DTOs.Auth
{
    public class LoginRequest
    {
        [Required]
        [EmailAddress]
        [MaxLength(180)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        [MaxLength(100)]
        public string Password { get; set; } = string.Empty;
    }
}
