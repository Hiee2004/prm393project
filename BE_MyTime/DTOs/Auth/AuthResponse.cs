namespace BE_MyTime.DTOs.Auth
{
    public class AuthResponse
    {
        public string Token { get; set; } = string.Empty;

        public DateTime ExpiresAt { get; set; }

        public UserAuthResponse User { get; set; } = new();
    }

    public class UserAuthResponse
    {
        public int Id { get; set; }

        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string AuthProvider { get; set; } = string.Empty;

        public string? AvatarUrl { get; set; }
    }
}
