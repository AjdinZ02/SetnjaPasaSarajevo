using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SetnjaPasaSarajevo.Services;

namespace SetnjaPasaSarajevo.WebAPI.Controllers;

[Authorize]
[ApiController]
[Route("api/recommendations")]
public class RecommendationsController : ControllerBase
{
    private readonly IRecommendationService _recommendations;
    private readonly IAuthenticatedUserAccessor _currentUser;

    public RecommendationsController(IRecommendationService recommendations, IAuthenticatedUserAccessor currentUser)
    {
        _recommendations = recommendations;
        _currentUser = currentUser;
    }

    [HttpGet("time-slots")]
    public async Task<IActionResult> GetTimeSlots([FromQuery] int limit = 3) =>
        Ok(await _recommendations.GetRecommendedTimeSlotsAsync(
            _currentUser.GetCurrentUserId() ?? throw new UnauthorizedAccessException(), limit));
}
