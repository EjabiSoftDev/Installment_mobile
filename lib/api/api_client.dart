import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'register_response.dart';
// TODO: point this to your actual Product model file
import '../models/product.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();

  final String baseUrl = 'http://192.168.1.124:1245'; // ✅ set once here
  final http.Client _http = http.Client();

  ApiClient._internal();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Uri _uriWithQuery(String path, Map<String, String?> params) {
    // make sure all keys exist (even if value is empty string)
    final qp = <String, String>{
      for (final e in params.entries) e.key: e.value ?? '',
    };
    return Uri.parse('$baseUrl$path').replace(queryParameters: qp);
  }

  /// Make relative URLs absolute (e.g. `/uploads/...`)
  String toAbsolute(String maybeRelative) {
    if (maybeRelative.startsWith('http')) return maybeRelative;
    return '$baseUrl${maybeRelative.startsWith('/') ? '' : '/'}$maybeRelative';
  }

  // -------------------- Customers / OTP --------------------

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
    // print('API Register body: $body');

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

    // print('API Verify OTP body: $body');

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
    final url =
        Uri.parse('$baseUrl/api/otp/verify'); // adjust endpoint if needed
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
        throw ApiException(body['message'] ?? 'OTP verification failed');
      }
    } else {
      throw ApiException('Server error: ${response.statusCode}');
    }
  }
  Future<RegisterResponse> loginCustomer({
    required String phone,
    required String password,
    required int languageId,
  }) async {
    final body = {
      'Phone': phone,
      'Password': password,
      'LanguageId': languageId,
    };

    http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/Customers/login'),
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

  Future<bool> resendOtp({required String phone}) async {
    final body = {
      'Phone': phone,
    };

    http.Response res;
    try {
      res = await _http
          .post(
            _uri('/api/Customers/resend-otp'),
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
  // -------------------- Products --------------------

  /// Same signature/behavior as the previous ProductsApi.fetchProducts.
  /// Builds the endpoint exactly like:
  /// `/api/Products?search=Sam&minPrice=&maxPrice=3500&brandId=&mainGroupId=1&subGroupId=1&sortBy=&sortOrder=`
  Future<List<Product>> fetchProducts({
    String search = 'Sam',
    String? minPrice, // empty when null
    String? maxPrice = '3500',
    String? brandId, // empty when null
    String? mainGroupId = '1',
    String? subGroupId = '1',
    String? sortBy, // empty when null
    String? sortOrder, // empty when null
  }) async {
    http.Response res;
    try {
      final uri = _uriWithQuery('/api/Products', {
        'search': search,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'brandId': brandId,
        'mainGroupId': mainGroupId,
        'subGroupId': subGroupId,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      });

      res = await _http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
    }

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map || decoded['success'] != true) {
        throw ApiException('Unexpected payload: $decoded');
      }
      final List data = decoded['data'] ?? [];
      // map to Product model
      return data
          .map<Product>((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

  /// If you prefer the raw maps instead of typed Product list.
  Future<List<Map<String, dynamic>>> fetchProductsRaw({
    String search = 'Sam',
    String? minPrice,
    String? maxPrice = '3500',
    String? brandId,
    String? mainGroupId = '1',
    String? subGroupId = '1',
    String? sortBy,
    String? sortOrder,
  }) async {
    final uri = _uriWithQuery('/api/Products', {
      'search': search,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'brandId': brandId,
      'mainGroupId': mainGroupId,
      'subGroupId': subGroupId,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    });

    final res = await _http.get(uri, headers: const {
      'Accept': 'application/json'
    }).timeout(const Duration(seconds: 20));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map || decoded['success'] != true) {
      throw ApiException('Unexpected payload: $decoded');
    }
    final List data = decoded['data'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // removed duplicate LoginResponse-based methods to avoid conflicts
}
