using BE_MyTime.DTOs.Notifications;

namespace BE_MyTime.Interfaces
{
    public interface INotificationService
    {
        Task<List<NotificationResponse>> GetNotificationsAsync(int userId);

        Task<NotificationResponse?> MarkAsReadAsync(int id, int userId);

        Task<int> MarkAllAsReadAsync(int userId);
    }
}
