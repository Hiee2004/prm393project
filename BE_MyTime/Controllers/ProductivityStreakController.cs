using System.Security.Claims;
using BE_MyTime.DTOs.Streaks;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ProductivityStreakController : ControllerBase
    {
        private readonly IProductivityStreakService _productivityStreakService;

        public ProductivityStreakController(IProductivityStreakService productivityStreakService)
        {
            _productivityStreakService = productivityStreakService;
        }

        [HttpGet("dashboard")]
        public async Task<ActionResult<ProductivityStreakDashboardResponse>> GetDashboard([FromQuery] int days = 180)
        {
            return Ok(await _productivityStreakService.GetDashboardAsync(GetCurrentUserId(), days));
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
