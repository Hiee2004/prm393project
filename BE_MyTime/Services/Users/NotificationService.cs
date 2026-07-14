using BE_MyTime.Data;
using BE_MyTime.DTOs.Notifications;
using BE_MyTime.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace BE_MyTime.Services.Users
{
    public class NotificationService : INotificationService
    {
        private readonly AppDbContext _db;

        public NotificationService(AppDbContext db)
        {
            _db = db;
        }

        public async Task<List<NotificationResponse>> GetNotificationsAsync(int userId)
        {
            var notifications = await _db.Notifications
                .AsNoTracking()
                .Where(item => item.UserId == userId)
                .OrderBy(item => item.IsRead)
                .ThenByDescending(item => item.CreatedAt)
                .ToListAsync();

            return notifications.Select(MapToResponse).ToList();
        }

        public async Task<NotificationResponse?> MarkAsReadAsync(int id, int userId)
        {
            var notification = await _db.Notifications
                .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId);

            if (notification == null)
            {
                return null;
            }

            notification.IsRead = true;
            await _db.SaveChangesAsync();

            return MapToResponse(notification);
        }

        public async Task<int> MarkAllAsReadAsync(int userId)
        {
            var notifications = await _db.Notifications
                .Where(item => item.UserId == userId && !item.IsRead)
                .ToListAsync();

            foreach (var notification in notifications)
            {
                notification.IsRead = true;
            }

            await _db.SaveChangesAsync();
            return notifications.Count;
        }

        private static NotificationResponse MapToResponse(Models.Notification notification)
        {
            return new NotificationResponse
            {
                Id = notification.Id,
                Title = notification.Title,
                Message = notification.Message,
                Type = notification.Type.ToString(),
                IsRead = notification.IsRead,
                FocusTaskId = notification.FocusTaskId,
                ScheduledAt = notification.ScheduledAt,
                SentAt = notification.SentAt,
                CreatedAt = notification.CreatedAt
            };
        }
    }
}
