using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Model.Requests;

public class CapturePaymentRequest
{
    [Required] public string ProviderOrderId { get; set; } = string.Empty;
}
