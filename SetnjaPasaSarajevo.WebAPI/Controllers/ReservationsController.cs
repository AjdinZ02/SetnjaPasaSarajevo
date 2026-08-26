using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Services;
using System.Security.Claims;

namespace SetnjaPasaSarajevo.WebAPI.Controllers
{
    public class UpdateStatusRequest
    {
        public string Status { get; set; } = "";
    }

    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class ReservationsController : ControllerBase
    {
        private readonly IReservationService _service;

        public ReservationsController(IReservationService service)
        {
            _service = service;
        }

        // ✅ CREATE
        [HttpPost]
        public async Task<IActionResult> Insert([FromBody] ReservationInsertRequest request)
        {
            var result = await _service.InsertAsync(request);
            return Ok(result);
        }

        // ✅ ADMIN
        [Authorize(Roles = "Admin")]
        [HttpGet("all")]
        public async Task<IActionResult> GetAll()
        {
            var data = await _service.GetAllReservations();
            return Ok(data);
        }

        // ✅ USER
        [HttpGet("my")]
        public async Task<IActionResult> GetMy()
        {
            var claim = User.FindFirst(ClaimTypes.NameIdentifier)
                        ?? User.FindFirst("Id");

            if (claim == null)
                return Unauthorized();

            int userId = int.Parse(claim.Value);

            var data = await _service.GetReservationsByUser(userId);
            return Ok(data);
        }

        // ✅ UPDATE STATUS (ADMIN)
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateStatusRequest request)
        {
            await _service.UpdateStatus(id, request.Status);
            return Ok();
        }

        // ✅ FIXED DELETE (USER + ADMIN)
        [HttpDelete("{id}")]
public async Task<IActionResult> Delete(int id)
{
    var claim = User.FindFirst(ClaimTypes.NameIdentifier)
                ?? User.FindFirst("Id");

    if (claim == null)
        return Unauthorized();

    int userId = int.Parse(claim.Value);

    // ✅ uzmi sve njegove rezervacije
    var userReservations = await _service.GetReservationsByUser(userId);

    // ✅ provjeri da li postoji ta rezervacija i da li je njegova
    var reservation = userReservations.FirstOrDefault(r => r.Id == id);

    // ✅ ako nije njegova i nije admin → zabrani
    if (reservation == null && !User.IsInRole("Admin"))
        return Forbid();

    await _service.DeleteReservation(id);
    return Ok();
}

    }
}
