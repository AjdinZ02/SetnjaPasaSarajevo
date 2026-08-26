namespace SetnjaPasaSarajevo.Model.Responses;

public class CreatePaymentResponse
{
    public int PaymentId { get; set; }
    public string ProviderOrderId { get; set; } = string.Empty;
    public string ApprovalUrl { get; set; } = string.Empty;
}
