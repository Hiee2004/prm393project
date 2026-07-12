using System.Security.Claims;
using BE_MyTime.DTOs.Users;
using BE_MyTime.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BE_MyTime.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;

        public UsersController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpGet("me")]
        public async Task<ActionResult<UserProfileResponse>> GetMe()
        {
            try
            {
                return Ok(await _userService.GetMeAsync(GetCurrentUserId()));
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        [HttpPut("me/profile")]
        public async Task<ActionResult<UserProfileResponse>> UpdateProfile(UpdateUserProfileRequest request)
        {
            try
            {
                return Ok(await _userService.UpdateProfileAsync(GetCurrentUserId(), request));
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        [HttpGet("me/settings")]
        public async Task<ActionResult<UserSettingResponse>> GetSettings()
        {
            try
            {
                return Ok(await _userService.GetSettingsAsync(GetCurrentUserId()));
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        [HttpPut("me/settings")]
        public async Task<ActionResult<UserSettingResponse>> UpdateSettings(UpdateUserSettingRequest request)
        {
            try
            {
                return Ok(await _userService.UpdateSettingsAsync(GetCurrentUserId(), request));
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
        }

        private int GetCurrentUserId()
        {
            var userIdText = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdText, out var userId))
            {
                throw new UnauthorizedAccessException("Invalid user token.");
            }

            return userId;
        }
    }
}
