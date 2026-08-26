using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace SetnjaPasaSarajevo.WebAPI.Controllers
{
    [ApiController]
    [Route("api/users")]
    [Authorize]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _service;

        public UsersController(IUserService userService)
        {
            _service = userService;
        }

        // ✅ OVO TI FALI — GET ALL USERS
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var data = await _service.GetAllAsync(); // ✅ koristi ono što već imaš
            return Ok(data);
        }

        // ✅ GET USER BY ID
        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var data = await _service.GetWithRoleByIdAsync(id);
            return Ok(data);
        }

        // ✅ UPDATE CURRENT USER
        [HttpPut("me")]
        public async Task<IActionResult> UpdateMyProfile([FromBody] UserUpdateRequest request)
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)
                        ?? User.FindFirst("Id");

            if (claim == null)
                return Unauthorized();

            int userId = int.Parse(claim.Value);

            var result = await _service.UpdateAsync(userId, request);

            return Ok(result);
        }

        // ✅ CHANGE PASSWORD
        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] UserPasswordChangeRequest request)
        {
            await _service.ChangePasswordAsync(request);
            return Ok();
        }

        // ✅ UPLOAD IMAGE
        [HttpPost("upload-image")]
        public async Task<IActionResult> UploadImage([FromBody] Dictionary<string, string> request)
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)
                        ?? User.FindFirst("Id");

            if (claim == null)
                return Unauthorized();

            int userId = int.Parse(claim.Value);

            var base64 = request["image"];

            if (base64.Contains(","))
                base64 = base64.Split(',')[1];

            await _service.UploadProfileImage(userId, base64);

            return Ok();
        }
    }
}