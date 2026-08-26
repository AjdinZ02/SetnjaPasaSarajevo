using SetnjaPasaSarajevo.Model.Responses;

namespace SetnjaPasaSarajevo.Services;

public interface INotificationService
{
    Task<IReadOnlyList<NotificationResponse>> GetForCurrentUserAsync(int limit = 50);
    Task MarkAsReadAsync(int notificationId);
}
