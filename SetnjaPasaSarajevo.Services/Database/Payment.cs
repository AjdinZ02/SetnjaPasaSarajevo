using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Services.Database;

/// <summary>Tracks a provider payment before it is allowed to credit a wallet.</summary>
public class Payment
{
    [Key]
    public int Id { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public decimal Amount { get; set; }
    [MaxLength(3)] public string Currency { get; set; } = "EUR";
    public PaymentProvider Provider { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Created;
    [MaxLength(200)] public string ProviderOrderId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }
}
