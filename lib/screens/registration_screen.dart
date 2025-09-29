import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../widgets/secondary_otp_dialog.dart';
import '../api/api_client.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isArabic;
  const RegistrationScreen({super.key, this.isArabic = false});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  // New controllers
  final TextEditingController _secondaryPhoneController = TextEditingController();
  final TextEditingController _secondaryOwnerNameController = TextEditingController();
  final TextEditingController _secondaryRelationController = TextEditingController();
  final TextEditingController _employerNameController = TextEditingController();
  final TextEditingController _employerPhoneController = TextEditingController();
  final TextEditingController _workLocationController = TextEditingController();
  
  // Customer data and status
  Map<String, dynamic>? _customerData;
  int? _statusId;
  bool _isLoading = true;

Country _secondarySelectedCountry = const Country(code: 'JO', dialCode: '962', flag: '🇯🇴', name: 'Jordan');

    File? _idImageFile;
  File? _salarySlipImageFile;
  List<File> _supportingDocs = <File>[];
  final ImagePicker _picker = ImagePicker();
  bool _isSecondaryPhoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    const storage = FlutterSecureStorage();
    final customerDataString = await storage.read(key: 'customer_data');
    print('🔍 Registration - Loading customer data: $customerDataString');
    
    if (customerDataString != null) {
      final parsedData = Map<String, dynamic>.from(
        Uri.splitQueryString(customerDataString)
      );
      print('🔍 Registration - Parsed customer data: $parsedData');
      
      setState(() {
        _customerData = parsedData;
        _statusId = int.tryParse(parsedData['StatusId']?.toString() ?? '');
        _isLoading = false;
      });
      
      // Pre-fill data for status 2 (existing data) and status 3 (approved - fill only)
      if (_statusId == 2 || _statusId == 3) {
        _prefillDataFromLogin();
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _prefillDataFromLogin() {
    if (_customerData == null) return;
    
    _nameController.text = _customerData!['FullName'] ?? '';
    _addressController.text = _customerData!['ResidenceAddress'] ?? '';
    _nationalIdController.text = _customerData!['NationalId'] ?? '';
    _secondaryPhoneController.text = _customerData!['SecondaryPhone'] ?? '';
    _secondaryOwnerNameController.text = _customerData!['SecondaryPhoneName'] ?? '';
    _secondaryRelationController.text = _customerData!['SecondaryPhoneRelationName'] ?? '';
    _employerNameController.text = _customerData!['EmployerName'] ?? '';
    _employerPhoneController.text = _customerData!['EmployerPhone'] ?? '';
    _workLocationController.text = _customerData!['WorkLocation'] ?? '';
    
    print('🔍 Registration - Data pre-filled for status 3');
  }

  bool get _isAllFilledAndReadyToSubmit {
    final bool textsFilled =
        _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _nationalIdController.text.trim().isNotEmpty &&
        _secondaryPhoneController.text.trim().isNotEmpty &&
        _secondaryOwnerNameController.text.trim().isNotEmpty &&
        _secondaryRelationController.text.trim().isNotEmpty &&
        _employerNameController.text.trim().isNotEmpty &&
        _employerPhoneController.text.trim().isNotEmpty &&
        _workLocationController.text.trim().isNotEmpty;

    final bool uploadsReady = _idImageFile != null && _salarySlipImageFile != null && _supportingDocs.isNotEmpty;

    return textsFilled && uploadsReady && _isSecondaryPhoneVerified;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _nationalIdController.dispose();
    _secondaryPhoneController.dispose();
    _secondaryOwnerNameController.dispose();
    _secondaryRelationController.dispose();
    _employerNameController.dispose();
    _employerPhoneController.dispose();
    _workLocationController.dispose();
    super.dispose();
  }

  // Removed primary phone country picker

  Future<void> _captureIdImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, imageQuality: 80);
    if (file != null) {
      setState(() => _idImageFile = File(file.path));
    }
  }

  // Removed profile image capture

  Future<void> _captureSalarySlip() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear, imageQuality: 80);
    if (file != null) {
      setState(() => _salarySlipImageFile = File(file.path));
    }
  }

  Future<void> _pickSupportingDocs() async {
    final List<XFile> files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) {
      setState(() {
        _supportingDocs.addAll(files.map((f) => File(f.path)));
      });
    }
  }

  Future<void> _pickSecondaryCountry() async {
    final Country? picked = await showModalBottomSheet<Country>(
      context: context,
      builder: (ctx) => _CountryPicker(
        selected: _secondarySelectedCountry,
        countries: const [
          Country(code: 'JO', dialCode: '962', flag: '🇯🇴', name: 'Jordan'),
          Country(code: 'LB', dialCode: '961', flag: '🇱🇧', name: 'Lebanon'),
          Country(code: 'SA', dialCode: '966', flag: '🇸🇦', name: 'Saudi Arabia'),
          Country(code: 'AE', dialCode: '971', flag: '🇦🇪', name: 'UAE'),
          Country(code: 'EG', dialCode: '20', flag: '🇪🇬', name: 'Egypt'),
        ],
      ),
    );
    if (picked != null) {
      setState(() => _secondarySelectedCountry = picked);
    }
  }

  void _verifySecondaryPhone() async {
    if (_secondaryPhoneController.text.trim().isEmpty) {
      final msg = widget.isArabic ? 'أدخل رقم الجوال الثانوي' : 'Enter secondary phone number';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    final String fullPhone = '+${_secondarySelectedCountry.dialCode}${_secondaryPhoneController.text.trim()}';
    try {
      final sentResp = await ApiClient.instance.sendSecondaryOtp(
        customerId: 1, // TODO: replace with actual logged-in customer id
        secondaryPhone: fullPhone,
      );
      if (sentResp.isEmpty) {
        final m = widget.isArabic ? 'فشل إرسال رمز التحقق' : 'Failed to send OTP';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SecondaryOtpDialog(
        phone: fullPhone,
        customerId: 1, // TODO: replace with actual id
      ),
    );
    if (ok == true) {
      setState(() => _isSecondaryPhoneVerified = true);
    }
  }

  // Helper method to convert File to base64
  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  // Helper method to convert multiple files to base64
  Future<List<String>> _filesToBase64(List<File> files) async {
    final List<String> base64List = [];
    for (final file in files) {
      final base64 = await _fileToBase64(file);
      base64List.add(base64);
    }
    return base64List;
  }

  // Location picker method
  void _showLocationPicker(BuildContext context) async {
    final bool isAr = widget.isArabic;
    final List<String> commonLocations = [
      'Amman',
      'Zarqa',
      'Irbid',
      'Aqaba',
      'Salt',
      'Madaba',
      'Jerash',
      'Ajloun',
      'Karak',
      'Tafilah',
      'Ma\'an',
      'Mafraq',
    ];

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAr ? 'اختر مكان العمل' : 'Choose Work Location',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: commonLocations.length,
                itemBuilder: (context, index) {
                  final location = commonLocations[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(location),
                    onTap: () => Navigator.of(context).pop(location),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
          ],
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _workLocationController.text = selected;
      });
    }
  }

  void _register() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_idImageFile == null) {
      final msg = widget.isArabic ? 'الرجاء رفع/التقاط صورة الهوية/الجواز' : 'Please upload/capture the ID/Passport photo';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    if (_salarySlipImageFile == null) {
      final msg = widget.isArabic ? 'الرجاء رفع قسيمة الراتب' : 'Please upload the salary slip';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    if (!_isSecondaryPhoneVerified) {
      final msg = widget.isArabic ? 'تحقق من رقم الجوال الثانوي عبر رمز التحقق' : 'Please verify the secondary phone via OTP';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Convert images to base64
      final nationalIdImageBase64 = await _fileToBase64(_idImageFile!);
      final salarySlipBase64 = await _fileToBase64(_salarySlipImageFile!);
      final additionalDocsBase64 = await _filesToBase64(_supportingDocs);

      // Get customer ID from stored data
      final customerId = int.tryParse(_customerData?['Id']?.toString() ?? '1') ?? 1;

      // Submit KYC data
      final result = await ApiClient.instance.submitKyc(
        customerId: customerId,
        fullName: _nameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        residenceAddress: _addressController.text.trim(),
        secondaryPhone: '+${_secondarySelectedCountry.dialCode}${_secondaryPhoneController.text.trim()}',
        secondaryPhoneName: _secondaryOwnerNameController.text.trim(),
        secondaryPhoneRelationId: 1, // Default relation ID
        employerName: _employerNameController.text.trim(),
        employerPhone: _employerPhoneController.text.trim(),
        workLocation: _workLocationController.text.trim(),
        nationalIdImage: nationalIdImageBase64,
        salarySlip: salarySlipBase64,
        additionalDocuments: additionalDocsBase64,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        final isAr = widget.isArabic;
        final msg = isAr ? 'تم التسجيل بنجاح' : 'Registered successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to main screen
        Navigator.of(context).pop();
      } else {
        final errorMsg = result['message'] ?? (widget.isArabic ? 'فشل في التسجيل' : 'Registration failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      final errorMsg = widget.isArabic ? 'خطأ في التسجيل: $e' : 'Registration error: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Handle different statuses
    switch (_statusId) {
      case 3:
        return _buildStatus3Screen();
      case 4:
        return _buildRejectedScreen();
      case 5:
        return _buildAdminNoteScreen();
      default:
        return _buildRegistrationForm();
    }
  }

  Widget _buildStatus3Screen() {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('approved_data'.tr()),
        backgroundColor: const Color(0xFF0B82FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: direction,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B82FF),
                Color(0xFFF2F6FF),
              ],
              stops: [0.0, 0.3],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Status Header Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAr ? 'تم الموافقة على طلبك' : 'Your Application is Approved',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAr 
                                ? 'تم ملء جميع البيانات المطلوبة'
                                : 'All required information has been completed',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Data Display Cards
                  _buildDataCard(
                    title: isAr ? 'البيانات الشخصية' : 'Personal Information',
                    icon: Icons.person,
                    children: [
                      _buildDataRow(
                        label: isAr ? 'الاسم الكامل' : 'Full Name',
                        value: _customerData?['FullName'] ?? '',
                        icon: Icons.badge,
                      ),
                      _buildDataRow(
                        label: isAr ? 'الهاتف الرئيسي' : 'Primary Phone',
                        value: _customerData?['Phone'] ?? '',
                        icon: Icons.phone,
                      ),
                      _buildDataRow(
                        label: isAr ? 'الهوية الوطنية' : 'National ID',
                        value: _customerData?['NationalId'] ?? '',
                        icon: Icons.credit_card,
                      ),
                      _buildDataRow(
                        label: isAr ? 'جواز السفر' : 'Passport',
                        value: _customerData?['Passport'] ?? '',
                        icon: Icons.airplane_ticket,
                      ),
                      _buildDataRow(
                        label: isAr ? 'عنوان السكن' : 'Residence Address',
                        value: _customerData?['ResidenceAddress'] ?? '',
                        icon: Icons.home,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDataCard(
                    title: isAr ? 'بيانات جهة العمل' : 'Employment Information',
                    icon: Icons.work,
                    children: [
                      _buildDataRow(
                        label: isAr ? 'اسم جهة العمل' : 'Employer Name',
                        value: _customerData?['EmployerName'] ?? '',
                        icon: Icons.business,
                      ),
                      _buildDataRow(
                        label: isAr ? 'هاتف جهة العمل' : 'Work Phone',
                        value: _customerData?['EmployerPhone'] ?? '',
                        icon: Icons.phone_in_talk,
                      ),
                      _buildDataRow(
                        label: isAr ? 'مكان العمل' : 'Work Location',
                        value: _customerData?['WorkLocation'] ?? '',
                        icon: Icons.location_on,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDataCard(
                    title: isAr ? 'بيانات الهاتف الثانوي' : 'Secondary Phone Information',
                    icon: Icons.phone_android,
                    children: [
                      _buildDataRow(
                        label: isAr ? 'الهاتف الثانوي' : 'Secondary Phone',
                        value: _customerData?['SecondaryPhone'] ?? '',
                        icon: Icons.phone_android,
                      ),
                      _buildDataRow(
                        label: isAr ? 'اسم صاحب الهاتف' : 'Phone Owner Name',
                        value: _customerData?['SecondaryPhoneName'] ?? '',
                        icon: Icons.person_pin,
                      ),
                      _buildDataRow(
                        label: isAr ? 'صلة القرابة' : 'Relation',
                        value: _customerData?['SecondaryPhoneRelationName'] ?? '',
                        icon: Icons.family_restroom,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(isAr ? 'العودة' : 'Go Back'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr ? 'تم حفظ البيانات' : 'Data saved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: Text(isAr ? 'حفظ' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B82FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedScreen() {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('registration'.tr()),
        backgroundColor: const Color(0xFF0B82FF),
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: direction,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 24),
                Text(
                  isAr ? 'تم رفض طلبك' : 'Your application has been rejected',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isAr 
                      ? 'عذراً، تم رفض طلبك. يرجى التواصل مع الدعم الفني لمزيد من المعلومات.'
                      : 'Sorry, your application has been rejected. Please contact support for more information.',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B82FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(isAr ? 'العودة' : 'Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminNoteScreen() {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final String adminNote = _customerData?['AdminNote'] ?? '';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('admin_note'.tr()),
        backgroundColor: const Color(0xFF0B82FF),
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: direction,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.orange),
                          const SizedBox(width: 12),
                          Text(
                            isAr ? 'ملاحظة الإدارة' : 'Admin Note',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Text(
                          adminNote.isEmpty 
                              ? (isAr ? 'لا توجد ملاحظات من الإدارة' : 'No admin notes available')
                              : adminNote,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isAr 
                    ? 'يرجى مراجعة الملاحظة أعلاه وإكمال البيانات المطلوبة'
                    : 'Please review the note above and complete the required information',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isAr ? 'العودة' : 'Go Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _statusId = 1; // Change to normal registration
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B82FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isAr ? 'إكمال البيانات' : 'Complete Data'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    final bool isAr = widget.isArabic;
    final ui.TextDirection direction = isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    final String nameHint = isAr ? 'الاسم الكامل' : 'Full name';
    final String addressHint = isAr ? 'العنوان' : 'Address';
    final String nidHint = isAr ? 'الرقم الوطني أو رقم الجواز' : 'National ID or Passport number';
    final String idPhoto = isAr ? 'صورة الهوية/الجواز' : 'ID/Passport photo';
    final String secondaryPhoneHint = isAr ? 'رقم الجوال الثانوي' : 'Secondary phone number';
    final String verifySecondaryText = isAr ? 'تحقق من الرقم' : 'Verify number';
    final String secondaryOwnerNameHint = isAr ? 'اسم صاحب الرقم الثانوي' : 'Secondary phone owner name';
    final String secondaryRelationHint = isAr ? 'صلة القرابة' : 'Relation to user';
    final String employerNameHint = isAr ? 'اسم جهة العمل' : 'Employer name';
    final String employerPhoneHint = isAr ? 'هاتف جهة العمل' : 'Employer phone';
    final String workLocationHint = isAr ? 'مكان العمل' : 'Work location';
    final String salarySlip = isAr ? 'قسيمة الراتب' : 'Salary slip';
    final String otherDocs = isAr ? 'مستندات داعمة (متعددة)' : 'Other supporting documents (multiple)';
    final String registerText = isAr ? 'تسجيل' : 'Register';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg_main.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Directionality(
              textDirection: direction,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _RoundedField(
                        child: TextFormField(
                          controller: _nameController,
                          enabled: _statusId != 3, // Disable for status 3
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: nameHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل الاسم' : 'Enter your name') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      // Removed email and primary phone fields
                      const SizedBox(height: 14),
                      _RoundedField(
                        child: TextFormField(
                          controller: _addressController,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: addressHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل العنوان' : 'Enter address') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RoundedField(
                        child: TextFormField(
                          controller: _nationalIdController,
                          keyboardType: TextInputType.number,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: nidHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل الرقم الوطني' : 'Enter national ID') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Secondary phone + OTP verify
                      _RoundedField(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickSecondaryCountry,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Text(_secondarySelectedCountry.flag, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 6),
                                    Text('+${_secondarySelectedCountry.dialCode}', style: const TextStyle(color: Colors.grey)),
                                    const VerticalDivider(width: 16, thickness: 1),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _secondaryPhoneController,
                                keyboardType: TextInputType.phone,
                                textAlign: isAr ? TextAlign.right : TextAlign.left,
                                decoration: InputDecoration(
                                  hintText: secondaryPhoneHint,
                                  border: InputBorder.none,
                                  suffixIcon: _isSecondaryPhoneVerified ? const Icon(Icons.verified, color: Colors.green) : null,
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل الرقم الثانوي' : 'Enter secondary phone') : null,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _verifySecondaryPhone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSecondaryPhoneVerified ? Colors.green : const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(_isSecondaryPhoneVerified ? (isAr ? 'تم التحقق' : 'Verified') : verifySecondaryText),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Show all fields for StatusId 1 & 2
                      if (_statusId == 1 || _statusId == 2) ...[
                        _RoundedField(
                          child: TextFormField(
                            controller: _secondaryOwnerNameController,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: secondaryOwnerNameHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل اسم صاحب الرقم' : 'Enter secondary owner name') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _secondaryRelationController,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: secondaryRelationHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل صلة القرابة' : 'Enter relation') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _employerNameController,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: employerNameHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل اسم جهة العمل' : 'Enter employer name') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _employerPhoneController,
                            keyboardType: TextInputType.phone,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: employerPhoneHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل هاتف جهة العمل' : 'Enter employer phone') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _workLocationController,
                                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                                  decoration: InputDecoration(hintText: workLocationHint, border: InputBorder.none),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل مكان العمل' : 'Enter work location') : null,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showLocationPicker(context),
                                icon: const Icon(Icons.location_on, color: Color(0xFF2196F3)),
                                tooltip: isAr ? 'اختر الموقع' : 'Pick Location',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ImageCaptureTile(
                          label: idPhoto,
                          file: _idImageFile,
                          onCapture: _captureIdImage,
                        ),
                        const SizedBox(height: 12),
                        _ImageCaptureTile(
                          label: salarySlip,
                          file: _salarySlipImageFile,
                          onCapture: _captureSalarySlip,
                        ),
                        const SizedBox(height: 12),
                        _SupportingDocsSection(
                          label: otherDocs,
                          files: _supportingDocs,
                          onAdd: _pickSupportingDocs,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: 220,
                          child: ElevatedButton(
                            onPressed: _isAllFilledAndReadyToSubmit ? _register : null,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                return const Color(0xFF2196F3);
                              }),
                              foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                return Colors.white;
                              }),
                              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              elevation: MaterialStateProperty.all(0),
                            ),
                            child: Text(registerText),
                          ),
                        ),
                      ] else if (_isSecondaryPhoneVerified) ...[
                        // Show fields only after secondary phone verification for other statuses
                        _RoundedField(
                          child: TextFormField(
                            controller: _secondaryOwnerNameController,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: secondaryOwnerNameHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل اسم صاحب الرقم' : 'Enter secondary owner name') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _secondaryRelationController,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: secondaryRelationHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل صلة القرابة' : 'Enter relation') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _employerNameController,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: employerNameHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل اسم جهة العمل' : 'Enter employer name') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: TextFormField(
                            controller: _employerPhoneController,
                            keyboardType: TextInputType.phone,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            decoration: InputDecoration(hintText: employerPhoneHint, border: InputBorder.none),
                            validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل هاتف جهة العمل' : 'Enter employer phone') : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RoundedField(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _workLocationController,
                                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                                  decoration: InputDecoration(hintText: workLocationHint, border: InputBorder.none),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل مكان العمل' : 'Enter work location') : null,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showLocationPicker(context),
                                icon: const Icon(Icons.location_on, color: Color(0xFF2196F3)),
                                tooltip: isAr ? 'اختر الموقع' : 'Pick Location',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ImageCaptureTile(
                          label: idPhoto,
                          file: _idImageFile,
                          onCapture: _captureIdImage,
                        ),
                        const SizedBox(height: 12),
                        _ImageCaptureTile(
                          label: salarySlip,
                          file: _salarySlipImageFile,
                          onCapture: _captureSalarySlip,
                        ),
                        const SizedBox(height: 12),
                        _SupportingDocsSection(
                          label: otherDocs,
                          files: _supportingDocs,
                          onAdd: _pickSupportingDocs,
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: 220,
                          child: ElevatedButton(
                            onPressed: _isAllFilledAndReadyToSubmit ? _register : null,
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                return const Color(0xFF2196F3);
                              }),
                              foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                return Colors.white;
                              }),
                              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12)),
                              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                              elevation: MaterialStateProperty.all(0),
                            ),
                            child: Text(registerText),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B82FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0B82FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B82FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final bool isAr = widget.isArabic;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    value.isEmpty ? (isAr ? 'غير محدد' : 'Not specified') : value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final Widget child;
  const _RoundedField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: child,
    );
  }
}

class _ImageCaptureTile extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onCapture;
  const _ImageCaptureTile({required this.label, required this.file, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: file != null
                ? Image.file(file!, fit: BoxFit.cover)
                : const Icon(Icons.camera_alt, color: Color(0xFF2196F3)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: onCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Capture'),
          ),
        ],
      ),
    );
  }
}

class _SupportingDocsSection extends StatelessWidget {
  final String label;
  final List<File> files;
  final VoidCallback onAdd;
  const _SupportingDocsSection({required this.label, required this.files, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (files.isEmpty)
            const Text(
              'No documents added',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in files)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F0FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.file(f, fit: BoxFit.cover),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class Country {
  final String code;
  final String dialCode;
  final String flag;
  final String name;
  const Country({required this.code, required this.dialCode, required this.flag, required this.name});
}

class _CountryPicker extends StatelessWidget {
  final List<Country> countries;
  final Country selected;
  const _CountryPicker({required this.countries, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final c = countries[index];
          final bool isSelected = c.code == selected.code;
          return ListTile(
            leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
            title: Text(c.name),
            subtitle: Text('+${c.dialCode}'),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () => Navigator.of(context).pop(c),
          );
        },
      ),
    );
  }
}

class Register {
  final String fullName;
  final String residence;
  final String nationalIdOrPassport;
  final String secondaryPhone;
  final String secondaryOwnerName;
  final String secondaryRelation;
  final String employerName;
  final String employerPhone;
  final String workLocation;
  final File idOrPassportPhoto;
  final File salarySlipPhoto;
  final List<File> supportingDocuments;

  const Register({
    required this.fullName,
    required this.residence,
    required this.nationalIdOrPassport,
    required this.secondaryPhone,
    required this.secondaryOwnerName,
    required this.secondaryRelation,
    required this.employerName,
    required this.employerPhone,
    required this.workLocation,
    required this.idOrPassportPhoto,
    required this.salarySlipPhoto,
    required this.supportingDocuments,
  });
}


