import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:setnjapasasarajevo_mobile/providers/wallet_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amount = TextEditingController(text: '10');
  final _wallet = WalletProvider();
  final _appLinks = AppLinks();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _pendingPayment;
  bool _loading = true;

  StreamSubscription<Uri?>? _sub;

  @override
  void initState() { super.initState(); _load(); _initDeepLinkListener(); }

  void _initDeepLinkListener() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);
    } catch (_) {}
    _sub = _appLinks.uriLinkStream.listen((uri) { if (uri != null) _handleUri(uri); }, onError: (_) {});
  }

  void _handleUri(Uri uri) {
    // Expecting scheme 'setnjapasa' and query param success=1
    if (uri.scheme == 'setnjapasa' && uri.queryParameters['success'] == '1') {
      // Refresh wallet
      _load();
      // Clear pending payment if any
      _pendingPayment = null;

      // If detailed info is present, show a confirmation dialog with transaction details
      final paymentId = uri.queryParameters['paymentId'];
      final providerOrderId = uri.queryParameters['providerOrderId'];
      final amount = uri.queryParameters['amount'];

      if (mounted) {
        if (paymentId != null || amount != null || providerOrderId != null) {
          showDialog<void>(context: context, builder: (c) {
            return AlertDialog(
              title: const Text('Uplata uspješna'),
              content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (amount != null) Text('Iznos: $amount EUR', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (paymentId != null) Padding(padding: const EdgeInsets.only(top:8.0), child: Text('ID uplate: $paymentId')),
                if (providerOrderId != null) Padding(padding: const EdgeInsets.only(top:8.0), child: Text('PayPal referenca: $providerOrderId')),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Zatvori')),
              ],
            );
          });
        } else {
          _message('Krediti su dodani na vaš račun.', success: true);
        }
      }
    }
  }

  Future<void> _load() async {
    try { _data = await _wallet.getWallet(); } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _startPayPal() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (value == null || value < 1) { _message('Unesite iznos od najmanje 1 EUR.'); return; }
    setState(() => _loading = true);
    try {
      final payment = await _wallet.createPayPalPayment(value);
      _pendingPayment = payment;
      final opened = await launchUrl(Uri.parse(payment['approvalUrl'] as String), mode: LaunchMode.externalApplication);
      if (!opened) _message('Nije moguće otvoriti PayPal.');
    } catch (e) { _message(e.toString()); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirmPayPal() async {
    final payment = _pendingPayment;
    if (payment == null) return;
    setState(() => _loading = true);
    try {
      _data = await _wallet.capturePayPalPayment(payment['paymentId'] as int, payment['providerOrderId'] as String);
      _pendingPayment = null;
      _message('Krediti su dodani na vaš račun.', success: true);
    } catch (e) { _message('Uplata još nije potvrđena: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  void _message(String text, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: success ? Colors.green : Colors.red));
  }

  @override
  void dispose() { _sub?.cancel(); _amount.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final balance = (_data?['balance'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final price = (_data?['reservationPrice'] as num?)?.toStringAsFixed(2) ?? '—';
    return Scaffold(
      appBar: AppBar(title: const Text('Krediti na računu')),
      body: _loading && _data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Trenutni kredit', style: TextStyle(fontSize: 16)),
                Text('$balance EUR', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                Text('Jedna rezervacija: $price EUR'),
              ]))),
              const SizedBox(height: 24),
              const Text('Dodaj kredit putem PayPal-a', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Iznos (EUR)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              ElevatedButton.icon(onPressed: _loading ? null : _startPayPal, icon: const Icon(Icons.account_balance_wallet), label: const Text('Nastavi na PayPal')),
              if (_pendingPayment != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _loading ? null : _confirmPayPal, child: const Text('Završio/la sam PayPal plaćanje')),
              ],
            ]),
    );
  }
}
