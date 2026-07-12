using BE_MyTime.DTOs.Users;

namespace BE_MyTime.Interfaces
{
    public interface IUserService
    {
        Task<UserProfileResponse> GetMeAsync(int userId);

        Task<UserProfileResponse> UpdateProfileAsync(int userId, UpdateUserProfileRequest request);

        Task<UserSettingResponse> GetSettingsAsync(int userId);

        Task<UserSettingResponse> UpdateSettingsAsync(int userId, UpdateUserSettingRequest request);
    }
}
