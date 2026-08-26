import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:setnjapasasarajevo_mobile/providers/auth_provider.dart';
import 'package:setnjapasasarajevo_mobile/utils/api_config.dart';

class WalletProvider {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AuthProvider.accesstoken}',
      };

  Future<Map<String, dynamic>> getWallet() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.getFullUrl('/api/payments')}/wallet'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception(response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPayPalPayment(double amount) async {
    final response = await http.post(
      Uri.parse(ApiConfig.getFullUrl('/api/payments')),
      headers: _headers,
      body: jsonEncode({'amount': amount, 'provider': 'PayPal'}),
    );
    if (response.statusCode != 200) throw Exception(response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> capturePayPalPayment(int paymentId, String orderId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.getFullUrl('/api/payments')}/$paymentId/capture'),
      headers: _headers,
      body: jsonEncode({'providerOrderId': orderId}),
    );
    if (response.statusCode != 200) throw Exception(response.body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
