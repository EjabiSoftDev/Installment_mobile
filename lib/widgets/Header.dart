import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String hello;
  final String subHello;
  final VoidCallback? onSettingsTap;
  const Header({super.key, required this.hello, required this.subHello, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hello,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(subHello, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
        // Settings button
        GestureDetector(
          onTap: onSettingsTap,
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings, color: Color(0xFF0B82FF), size: 20),
          ),
        ),
        // Profile avatar
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Color(0xFF0B82FF)),
        ),
      ],
    );
  }
}
