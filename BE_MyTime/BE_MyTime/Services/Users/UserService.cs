using BE_MyTime.DTOs.Users;
using BE_MyTime.Interfaces;
using BE_MyTime.Models;
using BE_MyTime.Repositories;

namespace BE_MyTime.Services.Users
{
    public class UserService : IUserService
    {
        private readonly UserRepository _userRepository;

        public UserService(UserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        public async Task<UserProfileResponse> GetMeAsync(int userId)
        {
            var user = await GetUserOrThrowAsync(userId);
            await EnsureSettingAsync(user);

            return ToProfileResponse(user);
        }

        public async Task<UserProfileResponse> UpdateProfileAsync(
            int userId,
            UpdateUserProfileRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FullName))
            {
                throw new InvalidOperationException("Full name is required.");
            }

            if (string.IsNullOrWhiteSpace(request.Email))
            {
                throw new InvalidOperationException("Email is required.");
            }

            if (!request.Email.Contains('@'))
            {
                throw new InvalidOperationException("Email is not valid.");
            }

            var email = request.Email.Trim().ToLowerInvariant();
            var emailExists = await _userRepository.EmailExistsAsync(email, userId);
            if (emailExists)
            {
                throw new InvalidOperationException("Email already exists.");
            }

            var user = await GetUserOrThrowAsync(userId);
            user.FullName = request.FullName.Trim();
            user.Email = email;
            user.AvatarUrl = string.IsNullOrWhiteSpace(request.AvatarUrl)
                ? null
                : request.AvatarUrl.Trim();
            user.UpdatedAt = DateTime.UtcNow;

            await EnsureSettingAsync(user);
            await _userRepository.SaveChangesAsync();

            return ToProfileResponse(user);
        }

        public async Task<UserSettingResponse> GetSettingsAsync(int userId)
        {
            var user = await GetUserOrThrowAsync(userId);
            await EnsureSettingAsync(user);

            return ToSettingResponse(user.Setting!);
        }

        public async Task<UserSettingResponse> UpdateSettingsAsync(
            int userId,
            UpdateUserSettingRequest request)
        {
            if (request.DefaultFocusMinutes < 1 || request.DefaultFocusMinutes > 240)
            {
                throw new InvalidOperationException("Default focus minutes must be between 1 and 240.");
            }

            if (string.IsNullOrWhiteSpace(request.TimeZone))
            {
                throw new InvalidOperationException("Time zone is required.");
            }

            if (string.IsNullOrWhiteSpace(request.ThemeMode))
            {
                throw new InvalidOperationException("Theme mode is required.");
            }

            if (request.PreferredFocusStartTime.HasValue
                && request.PreferredFocusEndTime.HasValue
                && request.PreferredFocusStartTime >= request.PreferredFocusEndTime)
            {
                throw new InvalidOperationException("Preferred focus start time must be earlier than end time.");
            }

            var user = await GetUserOrThrowAsync(userId);
            await EnsureSettingAsync(user);

            var setting = user.Setting!;
            setting.DefaultFocusMinutes = request.DefaultFocusMinutes;
            setting.NotificationEnabled = request.NotificationEnabled;
            setting.AutoSyncGoogleCalendar = request.AutoSyncGoogleCalendar;
            setting.DailyReviewEnabled = request.DailyReviewEnabled;
            setting.DailyReviewTime = request.DailyReviewTime;
            setting.PreferredFocusStartTime = request.PreferredFocusStartTime;
            setting.PreferredFocusEndTime = request.PreferredFocusEndTime;
            setting.TimeZone = request.TimeZone.Trim();
            setting.ThemeMode = request.ThemeMode.Trim();
            setting.UpdatedAt = DateTime.UtcNow;

            await _userRepository.SaveChangesAsync();

            return ToSettingResponse(setting);
        }

        private async Task<User> GetUserOrThrowAsync(int userId)
        {
            var user = await _userRepository.GetByIdWithSettingAsync(userId);
            if (user is null)
            {
                throw new UnauthorizedAccessException("User not found.");
            }

            return user;
        }

        private async Task EnsureSettingAsync(User user)
        {
            if (user.Setting is not null)
            {
                return;
            }

            user.Setting = new UserSetting
            {
                UserId = user.Id,
                CreatedAt = DateTime.UtcNow
            };

            await _userRepository.SaveChangesAsync();
        }

        private static UserProfileResponse ToProfileResponse(User user)
        {
            return new UserProfileResponse
            {
                Id = user.Id,
                FullName = user.FullName,
                Email = user.Email,
                AuthProvider = user.AuthProvider.ToString(),
                AvatarUrl = user.AvatarUrl,
                Setting = ToSettingResponse(user.Setting!)
            };
        }

        private static UserSettingResponse ToSettingResponse(UserSetting setting)
        {
            return new UserSettingResponse
            {
                DefaultFocusMinutes = setting.DefaultFocusMinutes,
                NotificationEnabled = setting.NotificationEnabled,
                AutoSyncGoogleCalendar = setting.AutoSyncGoogleCalendar,
                DailyReviewEnabled = setting.DailyReviewEnabled,
                DailyReviewTime = setting.DailyReviewTime,
                PreferredFocusStartTime = setting.PreferredFocusStartTime,
                PreferredFocusEndTime = setting.PreferredFocusEndTime,
                TimeZone = setting.TimeZone,
                ThemeMode = setting.ThemeMode
            };
        }
    }
}
    