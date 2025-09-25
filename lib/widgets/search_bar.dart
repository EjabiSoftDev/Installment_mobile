import 'package:flutter/material.dart';

class SearchBarBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearchTap;
  const SearchBarBox({super.key, required this.controller, this.onSubmitted, this.onChanged, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: const InputDecoration(
                hintText: '....',
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          if (onSearchTap != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF0B82FF)),
              onPressed: onSearchTap,
            ),
        ],
      ),
    );
  }
}
