import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class IyzicoService {
  static const _apiKey = 'sandbox-AEm1TGnOgsPxTQv2oQ0lAyvjHHXq8RBP';
  static const _secretKey = 'sandbox-KHb7Js8xxXEH3g1gTQfsqyO6RY5M74Tf';
  static const _baseUrl = 'https://sandbox-api.iyzipay.com';

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String _authHeader(String body) {
    final randomKey = _randomString(8);
    final hash = sha1.convert(utf8.encode(_apiKey + randomKey + _secretKey + body));
    final signature = base64.encode(hash.bytes);
    return 'IYZWS apiKey:$_apiKey, randomKey:$randomKey, signature:$signature';
  }

  /// Ödeme oluştur. Başarılıysa status: "success" döner.
  static Future<Map<String, dynamic>> createPayment({
    required String cardHolderName,
    required String cardNumber,
    required String expireMonth,
    required String expireYear,
    required String cvc,
    required double price,
    required String packageName,
    required String buyerId,
    required String buyerEmail,
  }) async {
    final priceStr = price.toStringAsFixed(2);
    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
    final fullYear = expireYear.length == 2 ? '20$expireYear' : expireYear;

    final nameParts = cardHolderName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.last : 'Kullanici';

    final body = {
      'locale': 'tr',
      'conversationId': conversationId,
      'price': priceStr,
      'paidPrice': priceStr,
      'currency': 'TRY',
      'installment': '1',
      'basketId': 'pilates_$conversationId',
      'paymentGroup': 'PRODUCT',
      'paymentCard': {
        'cardHolderName': cardHolderName,
        'cardNumber': cardNumber.replaceAll(' ', ''),
        'expireMonth': expireMonth,
        'expireYear': fullYear,
        'cvc': cvc,
        'registerCard': '0',
      },
      'buyer': {
        'id': buyerId,
        'name': firstName,
        'surname': lastName,
        'gsmNumber': '+905350000000',
        'email': buyerEmail.isNotEmpty ? buyerEmail : 'test@test.com',
        'identityNumber': '74300864791',
        'registrationAddress': 'Turkiye',
        'ip': '85.34.78.112',
        'city': 'Istanbul',
        'country': 'Turkey',
      },
      'shippingAddress': {
        'contactName': cardHolderName,
        'city': 'Istanbul',
        'country': 'Turkey',
        'address': 'Turkiye',
      },
      'billingAddress': {
        'contactName': cardHolderName,
        'city': 'Istanbul',
        'country': 'Turkey',
        'address': 'Turkiye',
      },
      'basketItems': [
        {
          'id': 'pkg_$conversationId',
          'name': packageName,
          'category1': 'Pilates',
          'itemType': 'VIRTUAL',
          'price': priceStr,
        }
      ],
    };

    final bodyJson = jsonEncode(body);

    final response = await http.post(
      Uri.parse('$_baseUrl/payment/auth'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _authHeader(bodyJson),
      },
      body: bodyJson,
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
