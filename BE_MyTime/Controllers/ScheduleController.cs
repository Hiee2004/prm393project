using System.Security.Claims;
using BE_MyTime.DTOs.Ai;
using BE_MyTime.DTOs.Schedule;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ScheduleController : ControllerBase
    {
        private readonly IAiTimeManagerService _aiTimeManagerService;

        public ScheduleController(IAiTimeManagerService aiTimeManagerService)
        {
            _aiTimeManagerService = aiTimeManagerService;
        }

        [HttpPost("smart")]
        public async Task<ActionResult<SmartScheduleResponse>> GenerateSmartSchedule()
        {
            var response = await _aiTimeManagerService.GenerateSmartScheduleAsync(GetCurrentUserId());
            return Ok(response);
        }

        [HttpGet("today")]
        public async Task<ActionResult<SmartScheduleResponse>> GetTodaySchedule()
        {
            var response = await _aiTimeManagerService.GetTodaySmartScheduleAsync(GetCurrentUserId());
            return Ok(response);
        }

        [HttpPost("update")]
        public async Task<ActionResult<ScheduledTaskResponse>> UpdateSchedule(
            UpdateScheduledTaskRequest request)
        {
            var response = await _aiTimeManagerService.UpdateScheduledTaskAsync(
                GetCurrentUserId(),
                request);

            if (response == null)
            {
                return NotFound(new { message = "Scheduled task not found." });
            }

            return Ok(response);
        }

        [HttpGet("daily-suggestion")]
        public async Task<ActionResult<AiDailySuggestionResponse>> GetDailySuggestion()
        {
            var response = await _aiTimeManagerService.GetDailyScheduleSuggestionAsync(
                GetCurrentUserId());
            return Ok(response);
        }

        private int GetCurrentUserId()
        {
            var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrWhiteSpace(userIdValue))
            {
                throw new UnauthorizedAccessException("User id not found in token.");
            }

            return int.Parse(userIdValue);
        }
    }
}
