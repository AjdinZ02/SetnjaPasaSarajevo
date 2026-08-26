using System.Collections.Generic;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using SetnjaPasaSarajevo.Model.Exceptions;
using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Model.Responses;
using SetnjaPasaSarajevo.Services.Database;

namespace SetnjaPasaSarajevo.Services;

public class PaymentService : IPaymentService
{
    private const string Currency = "EUR";
    private readonly SetnjaPasaSarajevoDbContext _db;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly IEventPublisher _eventPublisher;

    public PaymentService(SetnjaPasaSarajevoDbContext db, IHttpClientFactory httpClientFactory, IConfiguration configuration, IEventPublisher eventPublisher)
    {
        _db = db;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _eventPublisher = eventPublisher;
    }

    public decimal ReservationPrice => 10m;

    public async Task<WalletResponse> GetWalletAsync(int userId)
    {
        var balance = await _db.WalletTransactions.Where(t => t.UserId == userId).SumAsync(t => (decimal?)t.Amount) ?? 0m;
        return new WalletResponse { Balance = balance, ReservationPrice = ReservationPrice, Currency = Currency };
    }

    public async Task<CreatePaymentResponse> CreatePaymentAsync(int userId, CreatePaymentRequest request)
    {
        if (!string.Equals(request.Provider, "PayPal", StringComparison.OrdinalIgnoreCase))
            throw new ClinetException("Unsupported payment provider.");
        if(request.Amount<1m || request.Amount>1000m)
            throw new ClinetException("Payment amount must be between 1.00 and 1000.00.");

        var token = await GetPayPalAccessTokenAsync();
        var client = CreatePayPalClient(token);
        client.DefaultRequestHeaders.Add("Prefer", "return=representation");
        var appContext = new Dictionary<string, object>
        {
            ["shipping_preference"] = "NO_SHIPPING",
            ["user_action"] = "PAY_NOW"
        };
        // If a return URL is configured in app settings, use it so PayPal redirects back to the server which will then redirect/open the app.
        var configuredReturn = _configuration["PayPal:ReturnUrl"];
        if (!string.IsNullOrWhiteSpace(configuredReturn))
        {
            appContext["return_url"] = configuredReturn;
            appContext["cancel_url"] = configuredReturn + "?cancel=1";
        }

        var response = await client.PostAsJsonAsync("/v2/checkout/orders", new
        {
            intent = "CAPTURE",
            purchase_units = new[] { new { amount = new { currency_code = Currency, value = request.Amount.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture) } } },
            application_context = appContext
        });
        if (!response.IsSuccessStatusCode)
            throw new ClinetException("PayPal could not create the payment. Please try again.");

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = document.RootElement;
        var orderId = root.GetProperty("id").GetString();
        var approvalLink = root.GetProperty("links").EnumerateArray()
            .FirstOrDefault(link =>
                string.Equals(link.GetProperty("rel").GetString(), "payer-action", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(link.GetProperty("rel").GetString(), "approve", StringComparison.OrdinalIgnoreCase));
        var approvalUrl = approvalLink.ValueKind == JsonValueKind.Undefined
            ? null
            : approvalLink.GetProperty("href").GetString();
        if (string.IsNullOrWhiteSpace(orderId) || string.IsNullOrWhiteSpace(approvalUrl))
            throw new ClinetException("PayPal returned an incomplete payment order.");

        var payment = new Payment { UserId = userId, Amount = request.Amount, Currency = Currency, Provider = PaymentProvider.PayPal, ProviderOrderId = orderId };
        _db.Payments.Add(payment);
        await _db.SaveChangesAsync();
        return new CreatePaymentResponse { PaymentId = payment.Id, ProviderOrderId = orderId, ApprovalUrl = approvalUrl };
    }

    public async Task<WalletResponse> CapturePaymentAsync(int userId, int paymentId, CapturePaymentRequest request)
    {
        var payment = await _db.Payments.SingleOrDefaultAsync(p => p.Id == paymentId && p.UserId == userId)
            ?? throw new ClinetException("Payment not found.");
        if (payment.Status == PaymentStatus.Completed)
            return await GetWalletAsync(userId);
        if (!string.Equals(payment.ProviderOrderId, request.ProviderOrderId, StringComparison.Ordinal))
            throw new ClinetException("Payment order does not match.");

        var token = await GetPayPalAccessTokenAsync();
        var client = CreatePayPalClient(token);
        client.DefaultRequestHeaders.Add("Prefer", "return=representation");
        var orderResponse = await client.GetAsync($"/v2/checkout/orders/{Uri.EscapeDataString(payment.ProviderOrderId)}");
        if (!orderResponse.IsSuccessStatusCode)
            throw new ClinetException("PayPal narudžba se ne može provjeriti.");

        using var orderDocument = JsonDocument.Parse(await orderResponse.Content.ReadAsStringAsync());
        var orderRoot = orderDocument.RootElement;
        var orderStatus = orderRoot.TryGetProperty("status", out var statusProperty)
            ? statusProperty.GetString()
            : null;
        if (IsCompletedCapture(orderRoot))
            return await CompletePaymentAsync(paymentId, userId);
        if (!string.Equals(orderStatus, "APPROVED", StringComparison.OrdinalIgnoreCase))
            throw new ClinetException($"PayPal narudžba nije odobrena. Trenutni status: {orderStatus ?? "nepoznat"}.");

        JsonDocument? captureDocument = null;
        string? providerError = null;
        for (var attempt = 0; attempt < 3; attempt++)
        {
            using var captureRequest = new HttpRequestMessage(
                HttpMethod.Post,
                $"/v2/checkout/orders/{Uri.EscapeDataString(payment.ProviderOrderId)}/capture")
            {
                Content = new StringContent("{}", System.Text.Encoding.UTF8, "application/json")
            };
            var response = await client.SendAsync(captureRequest);
            if (response.IsSuccessStatusCode)
            {
                captureDocument = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
                break;
            }

            providerError = await response.Content.ReadAsStringAsync();
            if ((int)response.StatusCode == 422)
            {
                var retryOrderResponse = await client.GetAsync($"/v2/checkout/orders/{Uri.EscapeDataString(payment.ProviderOrderId)}");
                if (retryOrderResponse.IsSuccessStatusCode)
                {
                    var retryOrderDocument = JsonDocument.Parse(await retryOrderResponse.Content.ReadAsStringAsync());
                    if (IsCompletedCapture(retryOrderDocument.RootElement))
                    {
                        captureDocument = retryOrderDocument;
                        break;
                    }
                    retryOrderDocument.Dispose();
                }
                break;
            }

            if (attempt < 2)
                await Task.Delay(TimeSpan.FromSeconds(1));
        }

        if (captureDocument == null || !IsCompletedCapture(captureDocument.RootElement))
            throw new ClinetException($"PayPal nije odobrio naplatu. Završite plaćanje na PayPal stranici i pokušajte ponovo. Detalji: {GetPayPalError(providerError)}");

        return await CompletePaymentAsync(paymentId, userId);
    }

    private async Task<WalletResponse> CompletePaymentAsync(int paymentId, int userId)
    {
        var payment = await _db.Payments.SingleOrDefaultAsync(p => p.Id == paymentId && p.UserId == userId)
            ?? throw new ClinetException("Payment not found.");
        _db.Entry(payment).State = EntityState.Detached;
        await using var transaction = await _db.Database.BeginTransactionAsync(System.Data.IsolationLevel.Serializable);
        payment = await _db.Payments.SingleOrDefaultAsync(p => p.Id == paymentId && p.UserId == userId)
            ?? throw new ClinetException("Payment not found.");
        if (payment.Status == PaymentStatus.Completed)
        {
            await transaction.RollbackAsync();
            return await GetWalletAsync(userId);
        }

        payment.Status = PaymentStatus.Completed;
        payment.CompletedAt = DateTime.UtcNow;
        _db.WalletTransactions.Add(new WalletTransaction
        {
            UserId = userId, Amount = payment.Amount, Currency = payment.Currency, Type = "TopUp",
            Reference = payment.ProviderOrderId, Description = "PayPal wallet top-up", PaymentId = payment.Id
        });
        await _db.SaveChangesAsync();
        await transaction.CommitAsync();
        await _eventPublisher.PublishAsync("payment.completed", new
        {
            paymentId = payment.Id,
            userId,
            amount = payment.Amount,
            currency = payment.Currency
        });
        return await GetWalletAsync(userId);
    }

    private static bool IsCompletedCapture(JsonElement root)
    {
        if (root.TryGetProperty("status", out var status) &&
            string.Equals(status.GetString(), "COMPLETED", StringComparison.OrdinalIgnoreCase))
            return true;

        if (!root.TryGetProperty("purchase_units", out var purchaseUnits) ||
            purchaseUnits.ValueKind != JsonValueKind.Array)
            return false;

        foreach (var purchaseUnit in purchaseUnits.EnumerateArray())
        {
            if (!purchaseUnit.TryGetProperty("payments", out var payments) ||
                !payments.TryGetProperty("captures", out var captures) ||
                captures.ValueKind != JsonValueKind.Array)
                continue;

            foreach (var capture in captures.EnumerateArray())
            {
                if (capture.TryGetProperty("status", out var captureStatus) &&
                    string.Equals(captureStatus.GetString(), "COMPLETED", StringComparison.OrdinalIgnoreCase))
                    return true;
            }
        }

        return false;
    }

    private static string GetPayPalError(string? responseBody)
    {
        if (string.IsNullOrWhiteSpace(responseBody))
            return "PayPal nije vratio detalje greške.";

        try
        {
            using var document = JsonDocument.Parse(responseBody);
            var root = document.RootElement;
            var name = root.TryGetProperty("name", out var nameProperty) ? nameProperty.GetString() : null;
            var message = root.TryGetProperty("message", out var messageProperty) ? messageProperty.GetString() : null;
            var details = root.TryGetProperty("details", out var detailsProperty) &&
                          detailsProperty.ValueKind == JsonValueKind.Array
                ? string.Join("; ", detailsProperty.EnumerateArray().Select(detail =>
                    detail.TryGetProperty("issue", out var issue) ? issue.GetString() : null)
                    .Where(issue => !string.IsNullOrWhiteSpace(issue)))
                : null;

            return string.Join(": ", new[] { name, message, details }
                .Where(value => !string.IsNullOrWhiteSpace(value)));
        }
        catch (JsonException)
        {
            return "PayPal je vratio neočekivan odgovor.";
        }
    }

    public async Task<CaptureReturnResponse> CapturePaymentByProviderOrderIdAsync(string providerOrderId)
    {
        var result = new CaptureReturnResponse();
        if (string.IsNullOrWhiteSpace(providerOrderId))
        {
            result.Success = false;
            result.Message = "Provider order id is required.";
            return result;
        }

        var payment = await _db.Payments.SingleOrDefaultAsync(p => p.ProviderOrderId == providerOrderId);
        if (payment == null)
        {
            result.Success = false;
            result.Message = "Payment not found.";
            return result;
        }

        try
        {
            var wallet = await CapturePaymentAsync(payment.UserId, payment.Id, new CapturePaymentRequest { ProviderOrderId = providerOrderId });
            var updated = await _db.Payments.SingleOrDefaultAsync(p => p.Id == payment.Id);
            result.Success = true;
            result.Wallet = wallet;
            result.Payment = new PaymentReturnInfo
            {
                PaymentId = updated!.Id,
                ProviderOrderId = updated.ProviderOrderId,
                Amount = updated.Amount,
                Currency = updated.Currency,
                CompletedAt = updated.CompletedAt
            };
            return result;
        }
        catch (Exception ex)
        {
            // Return failure with message
            result.Success = false;
            result.Message = ex.Message;
            return result;
        }
    }

    private async Task<string> GetPayPalAccessTokenAsync()
    {
        var clientId = _configuration["PayPal:ClientId"];
        var secret = _configuration["PayPal:ClientSecret"];
        if (string.IsNullOrWhiteSpace(clientId) || string.IsNullOrWhiteSpace(secret))
            throw new ClinetException("PayPal is not configured. Add PayPal:ClientId and PayPal:ClientSecret to the server configuration.");
        var client = _httpClientFactory.CreateClient();
        client.BaseAddress = new Uri(_configuration["PayPal:BaseUrl"] ?? "https://api-m.sandbox.paypal.com");
        var authorization = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes($"{clientId}:{secret}"));
        using var message = new HttpRequestMessage(HttpMethod.Post, "/v1/oauth2/token") { Content = new FormUrlEncodedContent(new Dictionary<string, string> { ["grant_type"] = "client_credentials" }) };
        message.Headers.Authorization = new AuthenticationHeaderValue("Basic", authorization);
        var response = await client.SendAsync(message);
        if (!response.IsSuccessStatusCode) throw new ClinetException("PayPal authentication failed.");
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return document.RootElement.GetProperty("access_token").GetString() ?? throw new ClinetException("PayPal did not return an access token.");
    }

    private HttpClient CreatePayPalClient(string token)
    {
        var client = _httpClientFactory.CreateClient();
        client.BaseAddress = new Uri(_configuration["PayPal:BaseUrl"] ?? "https://api-m.sandbox.paypal.com");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }
}
