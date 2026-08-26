using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Services.Database;

/// <summary>An immutable entry in a user's credit wallet. Positive values add credit.</summary>
public class WalletTransaction
{
    [Key] public int Id { get; set; }
    public int UserId { get; set; }
    public User User { get; set; } = null!;
    public decimal Amount { get; set; }
    [MaxLength(3)] public string Currency { get; set; } = "EUR";
    [MaxLength(40)] public string Type { get; set; } = string.Empty;
    [MaxLength(200)] public string Reference { get; set; } = string.Empty;
    [MaxLength(300)] public string? Description { get; set; }
    public int? ReservationId { get; set; }
    public Reservation? Reservation { get; set; }
    public int? PaymentId { get; set; }
    public Payment? Payment { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
