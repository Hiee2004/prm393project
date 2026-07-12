using System.Security.Claims;
using BE_MyTime.DTOs.Habits;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class HabitsController : ControllerBase
    {
        private readonly IHabitService _habitService;

        public HabitsController(IHabitService habitService)
        {
            _habitService = habitService;
        }

        [HttpGet("dashboard")]
        public async Task<ActionResult<HabitDashboardResponse>> GetDashboard([FromQuery] int days = 84)
        {
            return Ok(await _habitService.GetDashboardAsync(GetCurrentUserId(), days));
        }

        [HttpGet]
        public async Task<ActionResult<List<HabitResponse>>> GetHabits([FromQuery] bool includeArchived = false)
        {
            return Ok(await _habitService.GetHabitsAsync(GetCurrentUserId(), includeArchived));
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<HabitResponse>> GetHabit(int id)
        {
            var habit = await _habitService.GetHabitAsync(id, GetCurrentUserId());
            if (habit == null)
            {
                return NotFound(new { message = "Habit not found." });
            }

            return Ok(habit);
        }

        [HttpPost]
        public async Task<ActionResult<HabitResponse>> CreateHabit(CreateHabitRequest request)
        {
            var habit = await _habitService.CreateHabitAsync(GetCurrentUserId(), request);
            return CreatedAtAction(nameof(GetHabit), new { id = habit.Id }, habit);
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<HabitResponse>> UpdateHabit(int id, UpdateHabitRequest request)
        {
            var habit = await _habitService.UpdateHabitAsync(id, GetCurrentUserId(), request);
            if (habit == null)
            {
                return NotFound(new { message = "Habit not found." });
            }

            return Ok(habit);
        }

        [HttpPost("{id:int}/check-in")]
        public async Task<ActionResult<HabitResponse>> CheckIn(int id, HabitCheckInRequest request)
        {
            var habit = await _habitService.CheckInAsync(id, GetCurrentUserId(), request);
            if (habit == null)
            {
                return NotFound(new { message = "Habit not found." });
            }

            return Ok(habit);
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteHabit(int id)
        {
            var deleted = await _habitService.DeleteHabitAsync(id, GetCurrentUserId());
            if (!deleted)
            {
                return NotFound(new { message = "Habit not found." });
            }

            return NoContent();
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
