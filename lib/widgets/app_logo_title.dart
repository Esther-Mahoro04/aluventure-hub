import 'package:flutter/material.dart';

class AppLogoTitle extends StatelessWidget {
  final String pageName;

  const AppLogoTitle({super.key, required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/alu-logo.png',
          height: 34,
        ),
        const SizedBox(width: 6),
        Text(
          '-',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          pageName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}