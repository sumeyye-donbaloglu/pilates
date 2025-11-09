import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFF6F6),
      body: Center(
        child: Text(
          'Müşteri Ana Sayfası (CustomerHomeScreen)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A4F4F),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
