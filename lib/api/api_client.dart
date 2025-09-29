import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_exception.dart';
import 'register_response.dart';
// TODO: point this to your actual Product model file
import '../models/product.dart';
import '../models/GroupName.dart';
import '../models/order.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();

  final String baseUrl = 'http://192.168.1.124:1245'; // ✅ set once here
  final http.Client _http = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _sessionCookie;

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

  /// Extract session cookie from response headers
  void _extractSessionCookie(http.Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      for (final cookie in cookies.split(',')) {
        if (cookie.contains('.AspNetCore.Session')) {
          _sessionCookie = cookie.split(';')[0].trim();
          print('🔐 Session cookie extracted: $_sessionCookie');
          // Store session cookie securely
          _storage.write(key: 'session_cookie', value: _sessionCookie);
          break;
        }
      }
    }
  }

  /// Get headers with session cookie if available
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?additionalHeaders,
    };
    
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
      print('🍪 Adding session cookie to headers: $_sessionCookie');
    }
    
    return headers;
  }

  /// Load session cookie from storage
  Future<void> loadSessionCookie() async {
    _sessionCookie = await _storage.read(key: 'session_cookie');
    if (_sessionCookie != null) {
      print('🔄 Session cookie loaded from storage: $_sessionCookie');
    }
  }

  /// Clear session cookie
  Future<void> clearSessionCookie() async {
    _sessionCookie = null;
    await _storage.delete(key: 'session_cookie');
    print('🗑️ Session cookie cleared');
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

    // Extract session cookie from login response
    _extractSessionCookie(res);
    print('📝 Login response headers: ${res.headers}');

    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      print('🔍 Login response JSON: $json');
      print('🔍 Customer data: ${json['customer']}');
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
  Future<List<Product>> fetchProducts({
    String? search,
    String? minPrice, // empty when null
    String? maxPrice ,
    String? brandId, // empty when null
    String? mainGroupId,
    String? subGroupId,
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
      print('decoded: $decoded');
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

  Future<List<Map<String, dynamic>>> fetchProductsRaw({
    String? search ,
    String? minPrice,
    String? maxPrice ,
    String? brandId,
    String? mainGroupId,
    String? subGroupId,
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

  /// Fetch list of main groups (categories) for products
  Future<List<GroupName>> fetchMainGroups() async {
    http.Response res;
    try {
      res = await _http
          .get(
            _uri('/api/Products/main-groups'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
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
      return data
          .map<GroupName>((e) => GroupName.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

  // -------------------- Product Details --------------------
  Future<Map<String, dynamic>> fetchProductDetails(int productId) async {
    http.Response res;
    try {
      final uri = _uriWithQuery('/api/Products/productbyid', {
        'pid': productId.toString(),
      });

      print('🔍 Fetching product details for ID: $productId');
      print('🔍 Request URL: $uri');

      res = await _http.get(
        uri,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 20));

      print('🔍 Product details response status: ${res.statusCode}');
      print('🔍 Product details response body: ${res.body}');

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        print('🔍 Product details JSON: $json');
        
        if (json['success'] == true && json['data'] != null) {
          return json['data'] as Map<String, dynamic>;
        } else {
          throw ApiException('Product not found or invalid response');
        }
      } else {
        throw ApiException('HTTP ${res.statusCode}: ${res.body}');
      }
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

  // -------------------- KYC Submission --------------------
  Future<Map<String, dynamic>> submitKyc({
    required int customerId,
    required String fullName,
    required String nationalId,
    required String residenceAddress,
    required String secondaryPhone,
    required String secondaryPhoneName,
    required int secondaryPhoneRelationId,
    required String employerName,
    required String employerPhone,
    required String workLocation,
    String? passport,
    String? nationalIdImage,
    String? passportImage,
    String? salarySlip,
    List<String>? additionalDocuments,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'CustomerId': customerId,
        'FullName': fullName,
        'NationalId': nationalId,
        'ResidenceAddress': residenceAddress,
        'SecondaryPhone': secondaryPhone,
        'SecondaryPhoneName': secondaryPhoneName,
        'SecondaryPhoneRelationId': secondaryPhoneRelationId,
        'EmployerName': employerName,
        'EmployerPhone': employerPhone,
        'WorkLocation': workLocation,
      };

      // Add optional fields if provided
      if (passport != null && passport.isNotEmpty) {
        body['Passport'] = passport;
      }
      if (nationalIdImage != null && nationalIdImage.isNotEmpty) {
        body['NationalIdImage'] = nationalIdImage;
      }
      if (passportImage != null && passportImage.isNotEmpty) {
        body['PassportImage'] = passportImage;
      }
      if (salarySlip != null && salarySlip.isNotEmpty) {
        body['SalarySlip'] = salarySlip;
      }
      if (additionalDocuments != null && additionalDocuments.isNotEmpty) {
        body['AdditionalDocuments'] = additionalDocuments;
      }

      final response = await http.post(
        _uri('/api/Customers/kyc'),
        headers: _getHeaders(additionalHeaders: {'Content-Type': 'application/json'}),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json;
      } else {
        throw ApiException('KYC submission failed: ${response.statusCode}');
      }
    } catch (e) {
      throw ApiException('KYC submission error: $e');
    }
  }

  // -------------------- Order Creation --------------------
  Future<Map<String, dynamic>> createOrder({
    required double totalAmount,
    required int itemId,
    required int numberOfMonths,
    required double installmentAmount,
  }) async {
    http.Response res;
    try {
      final uri = _uri('/api/orders/create');

      final body = {
        'totalAmount': totalAmount,
        'itemId': itemId,
        'numberOfMonths': numberOfMonths,
        'installmentAmount': installmentAmount,
      };

      print('🔍 Creating order:');
      print('🔍 Request URL: $uri');
      print('🔍 Request body: $body');

      res = await _http.post(
        uri,
        headers: _getHeaders(additionalHeaders: {'Content-Type': 'application/json'}),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      print('🔍 Order creation response status: ${res.statusCode}');
      print('🔍 Order creation response body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        print('🔍 Order creation JSON: $json');
        return json;
      } else {
        throw ApiException('HTTP ${res.statusCode}: ${res.body}');
      }
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

  // -------------------- Special Requests --------------------
  Future<Map<String, dynamic>> createSpecialRequest({
    required String title,
    required String externalStoreName,
    required String productLink,
    required double quotedPrice,
    List<http.MultipartFile>? documents,
  }) async {
    try {
      final uri = _uri('/api/SpecialRequests/create');

      print('🔍 Creating special request:');
      print('🔍 Request URL: $uri');
      print('🔍 Title: $title');
      print('🔍 External Store: $externalStoreName');
      print('🔍 Product Link: $productLink');
      print('🔍 Quoted Price: $quotedPrice');
      print('🔍 Documents count: ${documents?.length ?? 0}');

      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      final headers = _getHeaders();
      request.headers.addAll(headers);
      
      // Add form fields
      request.fields['Title'] = title;
      request.fields['ExternalStoreName'] = externalStoreName;
      request.fields['ProductLink'] = productLink;
      request.fields['QuotedPrice'] = quotedPrice.toString();
      
      // Add documents if any
      if (documents != null && documents.isNotEmpty) {
        request.files.addAll(documents);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print('🔍 Special request response status: ${response.statusCode}');
      print('🔍 Special request response body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('🔍 Special request JSON: $json');
        return json;
      } else {
        throw ApiException('HTTP ${response.statusCode}: ${response.body}');
      }
    } on Exception catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    } on Object catch (e) {
      throw ApiException('Invalid response: ${e.toString()}');
    }
  }

// -------------------- Orders --------------------
Future<List<Order>> fetchOrders() async {
  http.Response res;
  late final Uri reqUri;

  try {
    final uri = _uri('/api/orders/orders');
    // Log request URL once for debugging
    // ignore: avoid_print
    print('[GET] $uri');
    reqUri = uri;

    res = await _http
        .get(
          uri,
          headers: _getHeaders(),
        )
        .timeout(const Duration(seconds: 20));
  } on Exception catch (e) {
    throw ApiException('Network error: ${e.toString()}');
  }

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException('HTTP ${res.statusCode}: ${res.reasonPhrase ?? ''}');
  }

  // ignore: avoid_print
  print('[RESP ${res.statusCode}] ${res.request?.url ?? reqUri}');
  // ignore: avoid_print
  print(res.body);

  try {
    final decoded = jsonDecode(res.body);

    // Tolerate multiple envelope shapes
    List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final hasSuccess = decoded.containsKey('success') ? decoded['success'] == true : true;
      if (!hasSuccess) {
        throw ApiException('Server reported failure: ${res.body}');
      }
      final dynamic maybeOrders = decoded['orders'] ?? decoded['data'];
      if (maybeOrders is List) {
        list = maybeOrders;
      } else {
        // Nothing list-like inside; treat as empty result
        list = const [];
      }
    } else {
      throw ApiException('Unexpected payload type: ${decoded.runtimeType}');
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map<Order>((e) => Order.fromJson(e))
        .toList();
  } on ApiException {
    rethrow;
  } on Object catch (e) {
    throw ApiException('Invalid response: ${e.toString()}');
  }
}


  // removed duplicate LoginResponse-based methods to avoid conflicts
}
