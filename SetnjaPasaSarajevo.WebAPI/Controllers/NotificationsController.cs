using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SetnjaPasaSarajevo.Services;

namespace SetnjaPasaSarajevo.WebAPI.Controllers;

[Authorize]
[ApiController]
[Route("api/notifications")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _service;

    public NotificationsController(INotificationService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> Get([FromQuery] int limit = 50)
        => Ok(await _service.GetForCurrentUserAsync(limit));

    [HttpPut("{id:int}/read")]
    public async Task<IActionResult> MarkAsRead(int id)
    {
        await _service.MarkAsReadAsync(id);
        return NoContent();
    }
}
