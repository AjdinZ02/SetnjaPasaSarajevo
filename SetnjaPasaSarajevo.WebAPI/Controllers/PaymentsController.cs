using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SetnjaPasaSarajevo.Model.Requests;
using SetnjaPasaSarajevo.Services;

namespace SetnjaPasaSarajevo.WebAPI.Controllers;

[Authorize]
[ApiController]
[Route("api/payments")]
public class PaymentsController : ControllerBase
{
    private readonly IPaymentService _payments;
    private readonly IAuthenticatedUserAccessor _currentUser;
    public PaymentsController(IPaymentService payments, IAuthenticatedUserAccessor currentUser) { _payments = payments; _currentUser = currentUser; }

    [HttpGet("wallet")]
    public async Task<IActionResult> Wallet() => Ok(await _payments.GetWalletAsync(GetUserId()));

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePaymentRequest request) => Ok(await _payments.CreatePaymentAsync(GetUserId(), request));

    [HttpPost("{paymentId:int}/capture")]
    public async Task<IActionResult> Capture(int paymentId, [FromBody] CapturePaymentRequest request) => Ok(await _payments.CapturePaymentAsync(GetUserId(), paymentId, request));

    [AllowAnonymous]
    [HttpGet("return")]
    public async Task<IActionResult> Return([FromQuery] string token)
    {
        if (string.IsNullOrWhiteSpace(token)) return BadRequest("Missing token");
        try
        {
            // Capture payment by provider order id (token returned by PayPal)
            var result = await _payments.CapturePaymentByProviderOrderIdAsync(token);
            if (!result.Success)
            {
                var errHtml = $"<!doctype html><html><head><meta charset='utf-8' /><meta name='viewport' content='width=device-width,initial-scale=1' /><title>Greška pri uplati</title><style>body{{font-family:Arial,Helvetica,sans-serif;padding:20px;text-align:center}}</style></head><body><h1>Došlo je do greške</h1><p>{System.Net.WebUtility.HtmlEncode(result.Message)}</p></body></html>";
                return Content(errHtml, "text/html");
            }

            var payment = result.Payment!;
            var completed = payment.CompletedAt.HasValue ? payment.CompletedAt.Value.ToUniversalTime().ToString("yyyy-MM-dd HH:mm 'UTC'") : "-";
            // Build deep link with details encoded
            var deepLink = $"setnjapasa://wallet?success=1&paymentId={payment.PaymentId}&providerOrderId={System.Net.WebUtility.UrlEncode(payment.ProviderOrderId)}&amount={payment.Amount.ToString(System.Globalization.CultureInfo.InvariantCulture)}";

            var html = $@"<!doctype html>
<html>
  <head>
    <meta charset='utf-8' />
    <meta name='viewport' content='width=device-width,initial-scale=1' />
    <title>Potvrda uplate</title>
    <style>
      body{{font-family:Inter, 'Segoe UI', Roboto, Arial, Helvetica, sans-serif;background:#f4f6f8;margin:0;padding:20px}}
      .card{{max-width:760px;margin:24px auto;background:#fff;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,0.06);padding:24px}}
      .brand{{color:#1976d2;font-weight:700;font-size:20px}}
      .amount{{font-size:28px;font-weight:700;margin-top:8px}}
      .meta{{color:#6b7280;margin-top:12px}}
      .actions{{margin-top:20px;display:flex;gap:12px;justify-content:center}}
      .btn{{padding:12px 18px;border-radius:8px;text-decoration:none;font-weight:600}}
      .primary{{background:#1976d2;color:#fff}}
      .secondary{{background:#e5e7eb;color:#111}}
      .details{{text-align:left;margin-top:18px;border-top:1px solid #eef2f7;padding-top:12px;color:#374151}}
      @media (max-width:480px){{.card{{padding:16px}}.amount{{font-size:22px}}}}
    </style>
    <script>
      function openApp(){{ window.location = '{deepLink}'; }}
      function copyRef(){{ navigator.clipboard.writeText('{System.Net.WebUtility.HtmlEncode(payment.ProviderOrderId)}'); alert('Referenca kopirana u međuspremnik'); }}
      window.onload = function(){{ setTimeout(openApp, 800); }}
    </script>
  </head>
  <body>
    <div class='card'>
      <div class='brand'>Setnja Pasa Sarajevo</div>
      <h2 style='margin-top:8px'>Uplata uspješna</h2>
      <div class='amount'>{payment.Amount.ToString("0.00")} {payment.Currency}</div>
      <div class='meta'>Krediti su dodani na vaš račun. Hvala na uplati!</div>
      <div class='actions'>
        <a class='btn primary' href='{deepLink}'>Otvori aplikaciju</a>
        <a class='btn secondary' href='javascript:copyRef()'>Kopiraj referencu</a>
      </div>
      <div class='details'>
        <div><strong>ID uplate:</strong> {payment.PaymentId}</div>
        <div style='margin-top:6px'><strong>PayPal referenca:</strong> {System.Net.WebUtility.HtmlEncode(payment.ProviderOrderId)}</div>
        <div style='margin-top:6px'><strong>Vrijeme:</strong> {completed}</div>
      </div>
    </div>
  </body>
</html>";
            return Content(html, "text/html");
        }
        catch (Exception ex)
        {
            var html = $"<html><body><h1>Došlo je do greške</h1><p>{System.Net.WebUtility.HtmlEncode(ex.Message)}</p></body></html>";
            return Content(html, "text/html");
        }
    }

    private int GetUserId() => _currentUser.GetCurrentUserId() ?? throw new UnauthorizedAccessException();
}
