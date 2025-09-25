class RegisterResponse {
  final bool success;
  final String message;
  final int? customerId;
  final String? sentTo;

  const RegisterResponse({
    required this.success,
    required this.message,
    this.customerId,
    this.sentTo,
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
    );
  }
}
