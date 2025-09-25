import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final String hello;
  final String subHello;
  const Header({super.key, required this.hello, required this.subHello});

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
        const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Color(0xFF0B82FF)),
        ),
      ],
    );
  }
}
