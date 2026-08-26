using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using SetnjaPasaSarajevo.Services;

namespace SetnjaPasaSarajevo.WebAPI.Services;

public sealed class RabbitMqEventPublisher : IEventPublisher, IDisposable
{
    private readonly IConfiguration _configuration;
    private IConnection? _connection;
    private IModel? _channel;

    public RabbitMqEventPublisher(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public Task PublishAsync(string eventName, object payload, CancellationToken cancellationToken = default)
    {
        var factory = new ConnectionFactory
        {
            HostName = _configuration["RabbitMQ:Host"] ?? "localhost",
            Port = int.TryParse(_configuration["RabbitMQ:Port"], out var port) ? port : 5672,
            UserName = _configuration["RabbitMQ:Username"] ?? "guest",
            Password = _configuration["RabbitMQ:Password"] ?? "guest"
        };

        _connection ??= factory.CreateConnection();
        _channel ??= _connection.CreateModel();
        _channel.QueueDeclare("setnja-events", durable: true, exclusive: false, autoDelete: false);

        var message = JsonSerializer.Serialize(new { eventName, payload, createdAt = DateTime.UtcNow });
        var body = Encoding.UTF8.GetBytes(message);
        _channel.BasicPublish(string.Empty, "setnja-events", basicProperties: null, body);
        return Task.CompletedTask;
    }

    public void Dispose()
    {
        _channel?.Dispose();
        _connection?.Dispose();
    }
}
