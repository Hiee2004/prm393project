using BE_MyTime.DTOs.Auth;

namespace BE_MyTime.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> RegisterAsync(RegisterRequest request);

        Task<AuthResponse> LoginAsync(LoginRequest request);

        Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request);
    }
}
