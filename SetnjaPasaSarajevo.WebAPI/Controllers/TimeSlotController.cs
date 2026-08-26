using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Services;

namespace SetnjaPasaSarajevo.WebAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class TimeSlotsController : ControllerBase
{
    private readonly ITimeSlotService _service;

    public TimeSlotsController(ITimeSlotService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<TimeSlotResponse>>> Get([FromQuery] DateTime date)
    {
        return Ok(await _service.GetByDateAsync(date));
    }
}
