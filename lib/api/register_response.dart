class Customer {
  final int id;
  final String name;
  final String phone;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? json['Id'] ?? 0,
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['Phone']?.toString() ?? '',
    );
  }
}

class RegisterResponse {
  final bool success;
  final String message;
  final int? customerId;
  final String? sentTo;
  final Customer? customer;

  const RegisterResponse({
    required this.success,
    required this.message,
    this.customerId,
    this.sentTo,
    this.customer,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final rawSuccess = json['success'];
    return RegisterResponse(
      success: rawSuccess is bool
          ? rawSuccess
          : rawSuccess.toString().toLowerCase() == 'true',
      message: json['message']?.toString() ?? '',
      customerId: json['customerId'] is int
          ? json['customerId'] as int
          : int.tryParse('${json['customerId']}'),
      sentTo: json['sentTo']?.toString(),
      customer: json['customer'] != null 
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
    );
  }
}
