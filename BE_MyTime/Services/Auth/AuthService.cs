using System.Text.Json;
using System.Text.Json.Serialization;
using BE_MyTime.Data;
using BE_MyTime.DTOs.Auth;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Services.Auth
{
    public class AuthService : IAuthService
    {
        private readonly AppDbContext _dbContext;
        private readonly PasswordService _passwordService;
        private readonly JwtService _jwtService;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;

        public AuthService(
            AppDbContext dbContext,
            PasswordService passwordService,
            JwtService jwtService,
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _dbContext = dbContext;
            _passwordService = passwordService;
            _jwtService = jwtService;
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            ValidateRegisterRequest(request);

            var email = NormalizeEmail(request.Email);
            var emailExists = await _dbContext.Users.AnyAsync(x => x.Email == email);
            if (emailExists)
            {
                throw new InvalidOperationException("Email already exists.");
            }

            var user = new User
            {
                FullName = request.FullName.Trim(),
                Email = email,
                PasswordHash = _passwordService.HashPassword(request.Password),
                AuthProvider = AuthProvider.Local,
                CreatedAt = DateTime.UtcNow,
                Setting = new UserSetting()
            };

            _dbContext.Users.Add(user);
            await _dbContext.SaveChangesAsync();

            return CreateAuthResponse(user);
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            ValidateLoginRequest(request);

            var email = NormalizeEmail(request.Email);
            var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Email == email);
            if (user?.PasswordHash is null || !_passwordService.VerifyPassword(request.Password, user.PasswordHash))
            {
                throw new UnauthorizedAccessException("Invalid email or password.");
            }

            return CreateAuthResponse(user);
        }

        public async Task<AuthResponse> GoogleLoginAsync(GoogleLoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.IdToken))
            {
                throw new InvalidOperationException("Google id token is required.");
            }

            var googleUser = await VerifyGoogleTokenAsync(request.IdToken);
            var email = NormalizeEmail(googleUser.Email);

            var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.GoogleId == googleUser.Sub)
                ?? await _dbContext.Users.FirstOrDefaultAsync(x => x.Email == email);

            if (user is null)
            {
                user = new User
                {
                    FullName = string.IsNullOrWhiteSpace(googleUser.Name) ? email : googleUser.Name,
                    Email = email,
                    AuthProvider = AuthProvider.Google,
                    GoogleId = googleUser.Sub,
                    AvatarUrl = googleUser.Picture,
                    CreatedAt = DateTime.UtcNow,
                    Setting = new UserSetting()
                };

                _dbContext.Users.Add(user);
            }
            else
            {
                user.AuthProvider = AuthProvider.Google;
                user.GoogleId = googleUser.Sub;
                user.AvatarUrl = googleUser.Picture ?? user.AvatarUrl;
                user.UpdatedAt = DateTime.UtcNow;

                if (string.IsNullOrWhiteSpace(user.FullName) && !string.IsNullOrWhiteSpace(googleUser.Name))
                {
                    user.FullName = googleUser.Name;
                }
            }

            await _dbContext.SaveChangesAsync();

            return CreateAuthResponse(user);
        }

        private async Task<GoogleTokenInfo> VerifyGoogleTokenAsync(string idToken)
        {
            var httpClient = _httpClientFactory.CreateClient();
            var tokenInfoUrl = $"https://oauth2.googleapis.com/tokeninfo?id_token={Uri.EscapeDataString(idToken)}";
            using var response = await httpClient.GetAsync(tokenInfoUrl);

            if (!response.IsSuccessStatusCode)
            {
                throw new UnauthorizedAccessException("Invalid Google token.");
            }

            await using var contentStream = await response.Content.ReadAsStreamAsync();
            var tokenInfo = await JsonSerializer.DeserializeAsync<GoogleTokenInfo>(
                contentStream,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
            );

            if (tokenInfo is null || string.IsNullOrWhiteSpace(tokenInfo.Sub) || string.IsNullOrWhiteSpace(tokenInfo.Email))
            {
                throw new UnauthorizedAccessException("Invalid Google token payload.");
            }

            if (!string.Equals(tokenInfo.EmailVerified, "true", StringComparison.OrdinalIgnoreCase))
            {
                throw new UnauthorizedAccessException("Google email is not verified.");
            }

            ValidateGoogleAudience(tokenInfo.Aud);
            ValidateGoogleExpiration(tokenInfo.Exp);

            return tokenInfo;
        }

        private void ValidateGoogleAudience(string? audience)
        {
            var clientId = _configuration["Authentication:Google:ClientId"] ?? _configuration["Google:ClientId"];
            if (!string.IsNullOrWhiteSpace(clientId) && !string.Equals(audience, clientId, StringComparison.Ordinal))
            {
                throw new UnauthorizedAccessException("Google token audience does not match configured client id.");
            }
        }

        private static void ValidateGoogleExpiration(string? exp)
        {
            if (!long.TryParse(exp, out var expSeconds))
            {
                throw new UnauthorizedAccessException("Google token expiration is invalid.");
            }

            if (DateTimeOffset.FromUnixTimeSeconds(expSeconds) <= DateTimeOffset.UtcNow)
            {
                throw new UnauthorizedAccessException("Google token is expired.");
            }
        }

        private AuthResponse CreateAuthResponse(User user)
        {
            var jwt = _jwtService.GenerateToken(user);

            return new AuthResponse
            {
                Token = jwt.Token,
                ExpiresAt = jwt.ExpiresAt,
                User = new UserAuthResponse
                {
                    Id = user.Id,
                    FullName = user.FullName,
                    Email = user.Email,
                    AuthProvider = user.AuthProvider.ToString(),
                    AvatarUrl = user.AvatarUrl
                }
            };
        }

        private static void ValidateRegisterRequest(RegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FullName))
            {
                throw new InvalidOperationException("Full name is required.");
            }

            ValidateLoginRequest(new LoginRequest { Email = request.Email, Password = request.Password });

            if (request.Password.Length < 6)
            {
                throw new InvalidOperationException("Password must be at least 6 characters.");
            }
        }

        private static void ValidateLoginRequest(LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email))
            {
                throw new InvalidOperationException("Email is required.");
            }

            if (string.IsNullOrWhiteSpace(request.Password))
            {
                throw new InvalidOperationException("Password is required.");
            }
        }

        private static string NormalizeEmail(string email)
        {
            return email.Trim().ToLowerInvariant();
        }

        private sealed class GoogleTokenInfo
        {
            [JsonPropertyName("sub")]
            public string Sub { get; set; } = string.Empty;

            [JsonPropertyName("email")]
            public string Email { get; set; } = string.Empty;

            [JsonPropertyName("email_verified")]
            public string? EmailVerified { get; set; }

            [JsonPropertyName("name")]
            public string? Name { get; set; }

            [JsonPropertyName("picture")]
            public string? Picture { get; set; }

            [JsonPropertyName("aud")]   
            public string? Aud { get; set; }

            [JsonPropertyName("exp")]
            public string? Exp { get; set; }
        }
    }
}
