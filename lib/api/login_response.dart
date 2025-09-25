class LoginResponse {
  final bool success;
  final String message;
  final LoginCustomer? customer;

  const LoginResponse({
    required this.success,
    required this.message,
    this.customer,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    return LoginResponse(
      success: rawSuccess is bool ? rawSuccess : rawSuccess.toString().toLowerCase() == 'true',
      message: json['message']?.toString() ?? '',
      customer: json['customer'] is Map<String, dynamic>
          ? LoginCustomer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LoginCustomer {
  final int id;
  final String phone;
  final String name;

  const LoginCustomer({
    required this.id,
    required this.phone,
    required this.name,
  });

  factory LoginCustomer.fromJson(Map<String, dynamic> json) {
    return LoginCustomer(
      id: json['Id'] is int ? json['Id'] as int : int.tryParse('${json['Id']}') ?? 0,
      phone: json['Phone']?.toString() ?? '',
      name: json['Name']?.toString() ?? '',
    );
  }
}

