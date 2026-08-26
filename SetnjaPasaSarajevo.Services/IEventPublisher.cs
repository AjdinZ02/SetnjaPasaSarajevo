namespace SetnjaPasaSarajevo.Services;

public interface IEventPublisher
{
    Task PublishAsync(string eventName, object payload, CancellationToken cancellationToken = default);
}
