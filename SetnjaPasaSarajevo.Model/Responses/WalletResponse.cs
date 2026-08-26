namespace SetnjaPasaSarajevo.Model.Responses;

public class WalletResponse
{
    public decimal Balance { get; set; }
    public decimal ReservationPrice { get; set; }
    public string Currency { get; set; } = "EUR";
}

public class PaymentReturnInfo
{
    public int PaymentId { get; set; }
    public string ProviderOrderId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Currency { get; set; } = "EUR";
    public DateTime? CompletedAt { get; set; }
}

public class CaptureReturnResponse
{
    public bool Success { get; set; }
    public WalletResponse? Wallet { get; set; }
    public PaymentReturnInfo? Payment { get; set; }
    public string Message { get; set; } = string.Empty;
}
