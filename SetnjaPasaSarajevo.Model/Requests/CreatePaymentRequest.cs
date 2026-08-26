using System.ComponentModel.DataAnnotations;

namespace SetnjaPasaSarajevo.Model.Requests;

public class CreatePaymentRequest
{
    public decimal Amount { get; set; }
    [Required] public string Provider { get; set; } = "PayPal";
}
