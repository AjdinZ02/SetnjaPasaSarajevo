using System.Text;
using System.Text.Json;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using Microsoft.EntityFrameworkCore;
using SetnjaPasaSarajevo.Services.Database;

namespace SetnjaPasaSarajevo.Worker;

public sealed class Worker : BackgroundService
{
    private readonly ILogger<Worker> _logger;
    private readonly IConfiguration _configuration;
    private readonly IDbContextFactory<SetnjaPasaSarajevoDbContext> _dbContextFactory;
    private IConnection? _connection;
    private IModel? _channel;

    public Worker(
        ILogger<Worker> logger,
        IConfiguration configuration,
        IDbContextFactory<SetnjaPasaSarajevoDbContext> dbContextFactory)
    {
        _logger = logger;
        _configuration = configuration;
        _dbContextFactory = dbContextFactory;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var factory = new ConnectionFactory
        {
            HostName = _configuration["RabbitMQ:Host"] ?? "rabbitmq",
            Port = int.TryParse(_configuration["RabbitMQ:Port"], out var port) ? port : 5672,
            UserName = _configuration["RabbitMQ:Username"] ?? "guest",
            Password = _configuration["RabbitMQ:Password"] ?? "guest"
        };

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();
                _channel.QueueDeclare("setnja-events", true, false, false);
                var consumer = new AsyncEventingBasicConsumer(_channel);
                consumer.Received += async (_, args) =>
                {
                    var message = Encoding.UTF8.GetString(args.Body.ToArray());
                    await ProcessEventAsync(message, stoppingToken);
                    _channel.BasicAck(args.DeliveryTag, false);
                };
                _channel.BasicConsume("setnja-events", false, consumer);
                await Task.Delay(Timeout.Infinite, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception exception)
            {
                _logger.LogError(exception, "RabbitMQ worker connection failed; retrying.");
                await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
            }
        }
    }

    private async Task ProcessEventAsync(string message, CancellationToken cancellationToken)
    {
        using var document = JsonDocument.Parse(message);
        var eventName = document.RootElement.GetProperty("eventName").GetString() ?? "unknown";
        var payload = document.RootElement.GetProperty("payload");
        var userId = payload.GetProperty("userId").GetInt32();
        var reservationId = payload.TryGetProperty("reservationId", out var reservationValue)
            ? reservationValue.GetInt32()
            : (int?)null;
        var title = eventName switch
        {
            "reservation.created" => "Reservation created",
            "reservation.cancelled" => "Reservation cancelled",
            "reservation.status-changed" => "Reservation status changed",
            "payment.completed" => "Payment completed",
            _ => "Reservation update"
        };
        var status = payload.TryGetProperty("status", out var statusValue)
            ? $" Status: {statusValue.GetString()}."
            : string.Empty;
        await using var db = await _dbContextFactory.CreateDbContextAsync(cancellationToken);
        db.Notifications.Add(new Notification
        {
            UserId = userId,
            ReservationId = reservationId,
            Title = title,
            Message = reservationId.HasValue
                ? $"Your reservation #{reservationId} was updated.{status}"
                : "Your PayPal payment was completed successfully."
        });
        await db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Processed event {EventName}", eventName);
    }

    public override void Dispose()
    {
        _channel?.Dispose();
        _connection?.Dispose();
        base.Dispose();
    }
}
