import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

Country _secondarySelectedCountry = const Country(code: 'JO', dialCode: '962', flag: '🇯🇴', name: 'Jordan');

    File? _idImageFile;
  File? _salarySlipImageFile;
  List<File> _supportingDocs = <File>[];
  final ImagePicker _picker = ImagePicker();
  bool _isSecondaryPhoneVerified = false;

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

  void _register() {
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

    final registration = Register(
      fullName: _nameController.text.trim(),
      residence: _addressController.text.trim(),
      nationalIdOrPassport: _nationalIdController.text.trim(),
      secondaryPhone: '+${_secondarySelectedCountry.dialCode}${_secondaryPhoneController.text.trim()}',
      secondaryOwnerName: _secondaryOwnerNameController.text.trim(),
      secondaryRelation: _secondaryRelationController.text.trim(),
      employerName: _employerNameController.text.trim(),
      employerPhone: _employerPhoneController.text.trim(),
      workLocation: _workLocationController.text.trim(),
      idOrPassportPhoto: _idImageFile!,
      salarySlipPhoto: _salarySlipImageFile!,
      supportingDocuments: _supportingDocs,
    );
    final isAr = widget.isArabic;
    final msg = isAr ? 'تم التسجيل بنجاح' : 'Registered successfully';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    // ignore: avoid_print
    // print(registration);
  }

  @override
  Widget build(BuildContext context) {
    final bool isAr = widget.isArabic;
    final TextDirection direction = isAr ? TextDirection.rtl : TextDirection.ltr;

    final String nameHint = isAr ? 'الاسم الكامل' : 'Full name';
    // Removed email/primary phone hints
    final String addressHint = isAr ? 'العنوان' : 'Address';
    final String nidHint = isAr ? 'الرقم الوطني أو رقم الجواز' : 'National ID or Passport number';
    final String idPhoto = isAr ? 'صورة الهوية/الجواز' : 'ID/Passport photo';
    // Removed profile photo label
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
                      if (_isSecondaryPhoneVerified) _RoundedField(
                        child: TextFormField(
                          controller: _secondaryOwnerNameController,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: secondaryOwnerNameHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل اسم صاحب الرقم' : 'Enter secondary owner name') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 14),
                      if (_isSecondaryPhoneVerified) _RoundedField(
                        child: TextFormField(
                          controller: _secondaryRelationController,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: secondaryRelationHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل صلة القرابة' : 'Enter relation') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 14),
                      if (_isSecondaryPhoneVerified) _RoundedField(
                        child: TextFormField(
                          controller: _employerNameController,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: employerNameHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل اسم جهة العمل' : 'Enter employer name') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 14),
                      if (_isSecondaryPhoneVerified) _RoundedField(
                        child: TextFormField(
                          controller: _employerPhoneController,
                          keyboardType: TextInputType.phone,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: employerPhoneHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل هاتف جهة العمل' : 'Enter employer phone') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 14),
                      if (_isSecondaryPhoneVerified) _RoundedField(
                        child: TextFormField(
                          controller: _workLocationController,
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          decoration: InputDecoration(hintText: workLocationHint, border: InputBorder.none),
                          validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'أدخل مكان العمل' : 'Enter work location') : null,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 16),
                      if (_isSecondaryPhoneVerified) _ImageCaptureTile(
                        label: idPhoto,
                        file: _idImageFile,
                        onCapture: _captureIdImage,
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 12),
                      // Removed profile photo field
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 12),
                      if (_isSecondaryPhoneVerified) _ImageCaptureTile(
                        label: salarySlip,
                        file: _salarySlipImageFile,
                        onCapture: _captureSalarySlip,
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 12),
                      if (_isSecondaryPhoneVerified) _SupportingDocsSection(
                        label: otherDocs,
                        files: _supportingDocs,
                        onAdd: _pickSupportingDocs,
                      ),
                      if (_isSecondaryPhoneVerified) const SizedBox(height: 22),
                      if (_isSecondaryPhoneVerified) SizedBox(
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


