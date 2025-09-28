import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import 'catalog_home_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';
import 'Loginscreen.dart';
import 'registration_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool isArabic;
  final String userName;

  const MainNavigationScreen({
    super.key,
    required this.isArabic,
    required this.userName,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  Map<String, dynamic>? _customerData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);

    // Load customer data
    _loadCustomerData();

    // Ensure system navigation bar is hidden
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top], // Only show status bar
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Ensure system navigation bar stays hidden when app resumes
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top],
      );
    }
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  void _onTabTapped(int index) {
    // Jump instantly to the target page (no intermediate swipe animation)
    _pageController.jumpToPage(index);
    // setState not required; onPageChanged will update _currentIndex
  }

  Future<void> _showLogoutDialog() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('logout'.tr()),
          content: Text('logout_confirmation'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('logout'.tr()),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _performLogout();
    }
  }

  Future<void> _performLogout() async {
    const storage = FlutterSecureStorage();
    
    // Only clear session-related data, preserve ALL user data and biometric settings
    await storage.delete(key: 'customer_data');
    
    // Clear session cookie
    await ApiClient.instance.clearSessionCookie();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(isArabic: widget.isArabic),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _loadCustomerData() async {
    const storage = FlutterSecureStorage();
    final customerDataString = await storage.read(key: 'customer_data');
    print('🔍 Loading customer data string: $customerDataString');
    if (customerDataString != null) {
      final parsedData = Map<String, dynamic>.from(
        Uri.splitQueryString(customerDataString),
      );
      print('🔍 Parsed customer data: $parsedData');
      print('🔍 StatusId from storage: ${parsedData['StatusId']}');
      if (!mounted) return;
      setState(() {
        _customerData = parsedData;
      });
    } else {
      print('🔍 No customer data found in storage');
    }
  }

  String _getStatusText(int? statusId) {
    switch (statusId) {
      case 1:
        return widget.isArabic
            ? 'مسجل ويحتاج إكمال البيانات الشخصية بدون بيانات سابقة'
            : 'Registered and need to complete KYC but there is no previous data';
      case 2:
        return widget.isArabic
            ? 'تم إكمال البيانات الشخصية (املأ البيانات ويمكنك التقديم مرة أخرى)'
            : 'KYC done (fill the data and be able to apply KYC again)';
      case 3:
        return widget.isArabic ? 'تم الموافقة - املأ فقط' : 'Approved fill only';
      case 4:
        return widget.isArabic ? 'نافذة حوار فقط' : 'Only dialog';
      case 5:
        return widget.isArabic
            ? 'انظر إلى ملاحظة الإدارة واملأ البيانات والتحقق من الهوية مرة أخرى'
            : 'Look at the AdminNote and fill the data and KYC again';
      default:
        return widget.isArabic ? 'غير محدد' : 'Unknown';
    }
  }

  Color _getStatusColor(int? statusId) {
    switch (statusId) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui.TextDirection direction =
        widget.isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: null,
        body: Stack(
          children: [
            // Custom Header Overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120, // AppBar height + status bar
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0B82FF),
                      Color(0xFF0B82FF),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getAppBarTitle(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _showLogoutDialog,
                          icon: const Icon(Icons.logout, color: Colors.white),
                          tooltip: 'logout'.tr(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Page Content
            Positioned(
              top: 120, // Start below custom header
              left: 0,
              right: 0,
              bottom: 0,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // disable manual swiping
                onPageChanged: _onPageChanged,
                children: [
                  // Home/Catalog Page
                  CatalogHomeScreen(
                    isArabic: widget.isArabic,
                    userName: widget.userName,
                    showHeader: false, // We'll handle header in main screen
                  ),
                  // Orders Page
                  OrdersScreen(
                    isArabic: widget.isArabic,
                    userName: widget.userName,
                    showHeader: false,
                  ),
                  // Installments Page (placeholder for now)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'installments'.tr(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isArabic
                              ? 'قريباً - صفحة الأقساط'
                              : 'Coming Soon - Installments Page',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Account Page
                  _buildAccountPage(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, -2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomItem(
                icon: Icons.home,
                label: 'home'.tr(),
                selected: _currentIndex == 0,
                onTap: () => _onTabTapped(0),
              ),
              _BottomItem(
                icon: Icons.assignment,
                label: 'orders'.tr(),
                selected: _currentIndex == 1,
                onTap: () => _onTabTapped(1),
              ),
              _BottomItem(
                icon: Icons.credit_card,
                label: 'installments'.tr(),
                selected: _currentIndex == 2,
                onTap: () => _onTabTapped(2),
              ),
              _BottomItem(
                icon: Icons.person,
                label: 'account'.tr(),
                selected: _currentIndex == 3,
                onTap: () => _onTabTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountPage() {
    final statusId = _customerData?['StatusId'] != null
        ? int.tryParse(_customerData!['StatusId'].toString())
        : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // User Info Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF0B82FF),
                        child: Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _customerData?['Phone'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Status Section
                  Text(
                    widget.isArabic ? 'الحالة:' : 'Status:',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(statusId),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: _getStatusColor(statusId),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getStatusText(statusId),
                            style: TextStyle(
                              color: _getStatusColor(statusId),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SettingsScreen(isArabic: widget.isArabic),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label:
                      Text(widget.isArabic ? 'الإعدادات' : 'Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B82FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrationScreen(
                            isArabic: widget.isArabic),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: Text(widget.isArabic ? 'المعلومات' : 'Info'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.isArabic ? 'معلومات الحساب' : 'Account Information'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(widget.isArabic ? 'الاسم الكامل:' : 'Full Name:', _customerData?['FullName'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'الهاتف:' : 'Phone:', _customerData?['Phone'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'الهوية الوطنية:' : 'National ID:', _customerData?['NationalId'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'جواز السفر:' : 'Passport:', _customerData?['Passport'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'عنوان السكن:' : 'Residence Address:', _customerData?['ResidenceAddress'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'الهاتف الثانوي:' : 'Secondary Phone:', _customerData?['SecondaryPhone'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'اسم صاحب الهاتف الثانوي:' : 'Secondary Phone Name:', _customerData?['SecondaryPhoneName'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'صلة القرابة:' : 'Relation:', _customerData?['SecondaryPhoneRelationName'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'اسم صاحب العمل:' : 'Employer Name:', _customerData?['EmployerName'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'هاتف العمل:' : 'Work Phone:', _customerData?['EmployerPhone'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'موقع العمل:' : 'Work Location:', _customerData?['WorkLocation'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'ملاحظة الإدارة:' : 'Admin Note:', _customerData?['AdminNote'] ?? ''),
                _buildInfoRow(widget.isArabic ? 'تاريخ الإنشاء:' : 'Created At:', _customerData?['CreatedAt'] ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.isArabic ? 'إغلاق' : 'Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value.isEmpty
                ? (widget.isArabic ? 'غير محدد' : 'Not specified')
                : value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'home'.tr();
      case 1:
        return 'orders'.tr();
      case 2:
        return 'installments'.tr();
      case 3:
        return 'account'.tr();
      default:
        return 'app_title'.tr();
    }
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _BottomItem(
      {required this.icon, required this.label, this.selected = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? const Color(0xFF0B82FF) : Colors.grey),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: selected ? const Color(0xFF0B82FF) : Colors.grey,
                fontSize: 12)),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: content,
      ),
    );
  }
}
