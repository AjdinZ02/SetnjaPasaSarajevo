using System.Security.Claims;
using SetnjaPasaSarajevo.Services;
using SetnjaPasaSarajevo.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Http;

namespace SetnjaPasaSarajevo.WebAPI.Services;

public class HttpAuthenticatedUserAccessor : IAuthenticatedUserAccessor
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public HttpAuthenticatedUserAccessor(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int? GetUserId()
    {
        return GetCurrentUserId();
    }

    public int? GetCurrentUserId()
    {
        var user = _httpContextAccessor.HttpContext?.User;

        if (user?.Identity?.IsAuthenticated != true)
        {
            return null;
        }

        var id =
            user.FindFirstValue(ClaimNames.Id) ??
            user.FindFirstValue(ClaimTypes.NameIdentifier);

        if (string.IsNullOrEmpty(id) || !int.TryParse(id, out var userId))
        {
            return null;
        }

        return userId;
    }

    public bool IsInRole(string role)
    {
        var user = _httpContextAccessor.HttpContext?.User;

        if (user?.Identity?.IsAuthenticated != true)
        {
            return false;
        }

        var roles = user.FindAll(ClaimTypes.Role)
            .Select(r => r.Value)
            .ToList();

        return roles.Contains(role);
    }
}