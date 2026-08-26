using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Model.SearchObjects;
using SetnjaPasaSarajevo.Services;

namespace SetnjaPasaSarajevo.WebAPI.Controllers;

[Authorize]
[Route("api/[controller]")]
public sealed class PetsController : BaseCRUDController<
    PetResponse,
    PetSearch,
    PetInsertRequest,
    PetUpdateRequest,
    IPetService>
{
    private readonly IAuthenticatedUserAccessor _currentUser;

    public PetsController(IPetService service, IAuthenticatedUserAccessor currentUser)
        : base(service)
    {
        _currentUser = currentUser;
    }

    [HttpGet("my")]
    public async Task<ActionResult<IReadOnlyList<PetResponse>>> GetMy()
    {
        var userId = _currentUser.GetCurrentUserId();
        if (!userId.HasValue)
            return Unauthorized();

        return Ok(await _service.GetByUserAsync(userId.Value));
    }
}
