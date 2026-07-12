using BE_MyTime.DTOs.Task;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class FocusTasksController : ControllerBase
    {
        private readonly IFocusTaskService _focusTaskService;

        public FocusTasksController(IFocusTaskService focusTaskService)
        {
            _focusTaskService = focusTaskService;
        }

        [HttpGet]
        public async Task<ActionResult<List<FocusTaskResponse>>> GetTasks()
        {
            var userId = GetCurrentUserId();

            var tasks = await _focusTaskService.GetTasksAsync(userId);

            return Ok(tasks);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<FocusTaskResponse>> GetTask(int id)
        {
            var userId = GetCurrentUserId();

            var task = await _focusTaskService.GetTaskAsync(id, userId);

            if (task == null)
            {
                return NotFound(new { message = "Focus task not found." });
            }

            return Ok(task);
        }

        [HttpPost]
        public async Task<ActionResult<FocusTaskResponse>> CreateTask(
            CreateFocusTaskRequest request)
        {
            var userId = GetCurrentUserId();

            var task = await _focusTaskService.CreateTaskAsync(userId, request);

            return CreatedAtAction(
                nameof(GetTask),
                new { id = task.Id },
                task
            );
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<FocusTaskResponse>> UpdateTask(
            int id,
            UpdateFocusTaskRequest request)
        {
            var userId = GetCurrentUserId();

            var task = await _focusTaskService.UpdateTaskAsync(id, userId, request);

            if (task == null)
            {
                return NotFound(new { message = "Focus task not found." });
            }

            return Ok(task);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteTask(int id)
        {
            var userId = GetCurrentUserId();

            var deleted = await _focusTaskService.DeleteTaskAsync(id, userId);

            if (!deleted)
            {
                return NotFound(new { message = "Focus task not found." });
            }

            return NoContent();
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
