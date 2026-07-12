using BE_MyTime.DTOs.FocusSessions;

namespace BE_MyTime.Interfaces
{
    public interface IFocusSessionService
    {
        Task<List<FocusSessionResponse>> GetSessionsAsync(int userId);

        Task<FocusSessionResponse?> GetSessionAsync(int id, int userId);

        Task<FocusSessionResponse> CreateSessionAsync(
            int userId,
            CreateFocusSessionRequest request);

        Task<bool> DeleteSessionAsync(int id, int userId);
    }
}
