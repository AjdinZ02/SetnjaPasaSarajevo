using Microsoft.EntityFrameworkCore;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Services.Database;

namespace SetnjaPasaSarajevo.Services;

public class NotificationService : INotificationService
{
    private readonly SetnjaPasaSarajevoDbContext _dbContext;
    private readonly IAuthenticatedUserAccessor _currentUser;

    public NotificationService(
        SetnjaPasaSarajevoDbContext dbContext,
        IAuthenticatedUserAccessor currentUser)
    {
        _dbContext = dbContext;
        _currentUser = currentUser;
    }

    public async Task<IReadOnlyList<NotificationResponse>> GetForCurrentUserAsync(int limit = 50)
    {
        var userId = _currentUser.GetCurrentUserId()
            ?? throw new UnauthorizedAccessException("Authenticated user is required.");
        var safeLimit = Math.Clamp(limit, 1, 100);

        return await _dbContext.Notifications
            .AsNoTracking()
            .Where(notification => notification.UserId == userId)
            .OrderByDescending(notification => notification.CreatedAt)
            .Take(safeLimit)
            .Select(notification => new NotificationResponse
            {
                Id = notification.Id,
                Title = notification.Title,
                Message = notification.Message,
                IsRead = notification.IsRead,
                CreatedAt = notification.CreatedAt,
                ReservationId = notification.ReservationId
            })
            .ToListAsync();
    }

    public async Task MarkAsReadAsync(int notificationId)
    {
        var userId = _currentUser.GetCurrentUserId()
            ?? throw new UnauthorizedAccessException("Authenticated user is required.");
        var notification = await _dbContext.Notifications
            .FirstOrDefaultAsync(item => item.Id == notificationId && item.UserId == userId);

        if (notification == null)
            throw new KeyNotFoundException("Notification not found.");

        if (!notification.IsRead)
        {
            notification.IsRead = true;
            await _dbContext.SaveChangesAsync();
        }
    }
}
