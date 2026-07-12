using BE_MyTime.DTOs.FocusSessions;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FocusSessionsController : ControllerBase
    {
        private readonly IFocusSessionService _focusSessionService;

        public FocusSessionsController(IFocusSessionService focusSessionService)
        {
            _focusSessionService = focusSessionService;
        }

        [HttpGet]
        public async Task<ActionResult<List<FocusSessionResponse>>> GetSessions()
        {
            var userId = GetCurrentUserId();

            var sessions = await _focusSessionService.GetSessionsAsync(userId);

            return Ok(sessions);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<FocusSessionResponse>> GetSession(int id)
        {
            var userId = GetCurrentUserId();

            var session = await _focusSessionService.GetSessionAsync(id, userId);

            if (session == null)
            {
                return NotFound(new { message = "Focus session not found." });
            }

            return Ok(session);
        }

        [HttpPost]
        public async Task<ActionResult<FocusSessionResponse>> CreateSession(
            CreateFocusSessionRequest request)
        {
            var userId = GetCurrentUserId();

            var session = await _focusSessionService.CreateSessionAsync(
                userId,
                request
            );

            return CreatedAtAction(
                nameof(GetSession),
                new { id = session.Id },
                session
            );
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteSession(int id)
        {
            var userId = GetCurrentUserId();

            var deleted = await _focusSessionService.DeleteSessionAsync(
                id,
                userId
            );

            if (!deleted)
            {
                return NotFound(new { message = "Focus session not found." });
            }

            return NoContent();
        }

        private int GetCurrentUserId()
        {
            var userIdValue = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrWhiteSpace(userIdValue))
            {
                throw new UnauthorizedAccessException(
                    "User id not found in token."
                );
            }

            return int.Parse(userIdValue);
        }
    }
}
