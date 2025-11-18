import 'package:flutter/material.dart';
import 'business_account.dart';
import 'customer_account.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 100,
                    color: Color(0xFFE8CFCF),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Reformerly'e Hoşgeldiniz",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A4E4E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Pilates salonları ve üyeler için randevu yönetim sistemi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8C6B6B),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8CFCF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CustomerAccount()));
                      },
                      child: const Text(
                        "Müşteri Olarak Devam Et",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFBFA9A9),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const BusinessAccount()));
                      },
                      child: const Text(
                        "İşletme Hesabı Oluştur",
                        style: TextStyle(
                          color: Color(0xFF6A4E4E),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text(
                      "Zaten hesabım var, giriş yap",
                      style: TextStyle(
                        color: Color(0xFF6A4E4E),
                        fontSize: 15,
                        decoration: TextDecoration.underline,
                      ),
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
}
