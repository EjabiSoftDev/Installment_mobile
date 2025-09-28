import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'LoginScreen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  void _goToNext(int languageId) async {
    // Set the locale based on language ID
    final locale = languageId == 2 ? const Locale('ar') : const Locale('en');
    
    print('🌍 Setting locale to: $locale (Language ID: $languageId)');
    
    // Update the app's locale
    await context.setLocale(locale);
    
    // Wait a bit for the locale to be set
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginScreen(isArabic: languageId == 2), // Arabic = 2, English = 1
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🌍 Language Selection Screen - Current locale: ${context.locale}');
    
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_main.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: MediaQuery.of(context).size.width * 0.6,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'shopping_pleasure'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _goToNext(1), // English = 1
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('english'.tr()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _goToNext(2), // Arabic = 2
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('arabic'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}


