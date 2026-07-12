using System.Security.Claims;
using BE_MyTime.DTOs.Ai;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AiController : ControllerBase
    {
        private readonly IAiTimeManagerService _aiTimeManagerService;

        public AiController(IAiTimeManagerService aiTimeManagerService)
        {
            _aiTimeManagerService = aiTimeManagerService;
        }

        [HttpPost("generate-plan")]
        public async Task<ActionResult<AiPlanResponse>> GeneratePlan()
        {
            var response = await _aiTimeManagerService.GeneratePlanAsync(GetCurrentUserId());
            return Ok(response);
        }

        [HttpPost("sort-tasks")]
        public async Task<ActionResult<List<AiTaskScoreResponse>>> SortTasks()
        {
            var response = await _aiTimeManagerService.SortTasksAsync(GetCurrentUserId());
            return Ok(response);
        }

        [HttpPost("pomodoro")]
        public async Task<ActionResult<List<AiPomodoroSessionResponse>>> GeneratePomodoro()
        {
            var response = await _aiTimeManagerService.GeneratePomodoroAsync(GetCurrentUserId());
            return Ok(response);
        }

        [HttpGet("daily-suggestion")]
        public async Task<ActionResult<AiDailySuggestionResponse>> DailySuggestion()
        {
            var response = await _aiTimeManagerService.GetDailySuggestionAsync(GetCurrentUserId());
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
