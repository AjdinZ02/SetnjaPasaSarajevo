using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;

namespace SetnjaPasaSarajevo.Services;

public interface IPaymentService
{
    Task<WalletResponse> GetWalletAsync(int userId);
    Task<CreatePaymentResponse> CreatePaymentAsync(int userId, CreatePaymentRequest request);
    Task<WalletResponse> CapturePaymentAsync(int userId, int paymentId, CapturePaymentRequest request);

    // Capture a PayPal payment by provider order id (used for PayPal return redirect handling)
    Task<SetnjaPasaSarajevo.Model.Responses.CaptureReturnResponse> CapturePaymentByProviderOrderIdAsync(string providerOrderId);
}
