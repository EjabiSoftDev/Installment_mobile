import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'register_response.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();

  final String baseUrl = 'http://192.168.1.124:1245'; // ✅ set once here
  final http.Client _http = http.Client();

  ApiClient._internal();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  // Secondary phone OTP
  Future<Map<String, dynamic>> sendSecondaryOtp({
    required int customerId,
    required String secondaryPhone,
  }) async {
    final body = {
      'CustomerId': customerId,
      'SecondaryPhone': secondaryPhone,
    };
    http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/Customers/secondary-phone/send-otp'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json; // may contain { CustomerId, Otp }
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

  Future<bool> verifySecondaryOtp({
    required int customerId,
    required String secondaryPhone,
    required String otp,
  }) async {
    final body = {
      'CustomerId': customerId,
      'SecondaryPhone': secondaryPhone,
      'Otp': otp,
    };
    http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/Customers/secondary-phone/verify-otp'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['success'] == true;
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

  Future<bool> sendOtp({
    required String phone,
    String? name,
  }) async {
    final body = {
      'Phone': phone,
      if (name != null) 'Name': name,
    };
    http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/Customers/send-otp'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['success'] == true;
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

  Future<RegisterResponse> registerCustomer({
    required String phone,
    required String name,
    String? phoneSerial,
    required String password,
  }) async {
    final body = {
      'Phone': phone,
      'Name': name,
      'PhoneSerial': phoneSerial ?? '',
      'Password': password,
    };
    print('API Register body: $body');

    http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/Customers/register'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
    }

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return RegisterResponse.fromJson(json);
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }



  Future<bool> verifyOtp({
  required String phone,
  required String otp,
}) async {
  final body = {
    'Phone': phone,
    'Otp': otp,
  };

  print('API Verify OTP body: $body');

  http.Response res;
  try {
    res = await _http
        .post(
          _uri('/api/Customers/verify-otp'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
  } on Exception catch (e) {
    throw ApiException('Network error: ${e.toString()}');
  }

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
  }

  try {
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    // assume { "success": true/false, "message": "..." }
    final success = json['success'] == true;
    if (!success) {
      throw ApiException(json['message']?.toString() ?? 'OTP failed');
    }
    return success;
  } on Object catch (e) {
    throw ApiException('Invalid response: ${e.toString()}');
  }
}

  Future<Map<String, dynamic>> verifyOtpDetails({
    required String phone,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/api/otp/verify'); // adjust endpoint
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "Phone": phone,
        "Otp": otp,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return body; // contains customer info
      } else {
        throw Exception(body['message'] ?? 'OTP verification failed');
      }
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }
}

///////////

///////////////