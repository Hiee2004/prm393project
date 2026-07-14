using System.Security.Claims;
using BE_MyTime.DTOs.Notifications;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationsController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        [HttpGet]
        public async Task<ActionResult<List<NotificationResponse>>> GetNotifications()
        {
            return Ok(await _notificationService.GetNotificationsAsync(GetCurrentUserId()));
        }

        [HttpPost("{id:int}/read")]
        public async Task<ActionResult<NotificationResponse>> MarkAsRead(int id)
        {
            var notification = await _notificationService.MarkAsReadAsync(id, GetCurrentUserId());
            if (notification == null)
            {
                return NotFound(new { message = "Notification not found." });
            }

            return Ok(notification);
        }

        [HttpPost("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var count = await _notificationService.MarkAllAsReadAsync(GetCurrentUserId());
            return Ok(new { updatedCount = count });
        }

        private int GetCurrentUserId()
        {
            var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdValue, out var userId))
            {
                throw new UnauthorizedAccessException("Invalid user token.");
            }

            return userId;
        }
    }
}
