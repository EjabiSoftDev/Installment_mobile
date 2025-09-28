class Customer {
  final int id;
  final String name;
  final String phone;
  final String fullName;
  final String nationalId;
  final String passport;
  final String residenceAddress;
  final String secondaryPhone;
  final String secondaryPhoneName;
  final int secondaryPhoneRelationId;
  final String secondaryPhoneRelationName;
  final String employerName;
  final String employerPhone;
  final String workLocation;
  final String adminNote;
  final int statusId;
  final String statusName;
  final String createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.fullName = '',
    this.nationalId = '',
    this.passport = '',
    this.residenceAddress = '',
    this.secondaryPhone = '',
    this.secondaryPhoneName = '',
    this.secondaryPhoneRelationId = 0,
    this.secondaryPhoneRelationName = '',
    this.employerName = '',
    this.employerPhone = '',
    this.workLocation = '',
    this.adminNote = '',
    this.statusId = 3,
    this.statusName = 'Approved',
    this.createdAt = '',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? json['Id'] ?? 0,
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['Phone']?.toString() ?? '',
      fullName: json['FullName']?.toString() ?? '',
      nationalId: json['NationalId']?.toString() ?? '',
      passport: json['Passport']?.toString() ?? '',
      residenceAddress: json['ResidenceAddress']?.toString() ?? '',
      secondaryPhone: json['SecondaryPhone']?.toString() ?? '',
      secondaryPhoneName: json['SecondaryPhoneName']?.toString() ?? '',
      secondaryPhoneRelationId: json['SecondaryPhoneRelationId'] is int 
          ? json['SecondaryPhoneRelationId'] as int 
          : int.tryParse('${json['SecondaryPhoneRelationId']}') ?? 0,
      secondaryPhoneRelationName: json['SecondaryPhoneRelationName']?.toString() ?? '',
      employerName: json['EmployerName']?.toString() ?? '',
      employerPhone: json['EmployerPhone']?.toString() ?? '',
      workLocation: json['WorkLocation']?.toString() ?? '',
      adminNote: json['AdminNote']?.toString() ?? '',
      statusId: json['StatusId'] is int 
          ? json['StatusId'] as int 
          : int.tryParse('${json['StatusId']}') ?? 3,
      statusName: json['StatusName']?.toString() ?? 'Approved',
      createdAt: json['CreatedAt']?.toString() ?? '',
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
