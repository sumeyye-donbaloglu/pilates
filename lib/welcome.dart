import 'package:flutter/material.dart';

import 'business/business_account.dart';
import 'customer/customer_account.dart';
import 'login_screen.dart';
import 'theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --------------------------------------------------
              // 🔝 LOGO + BAŞLIK
              // --------------------------------------------------
              Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.self_improvement, // ✅ REFORMER / PILATES UYUMLU
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Reformerly'e Hoş Geldiniz",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepIndigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Pilates salonları ve üyeler için\nmodern randevu yönetim sistemi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),

              // --------------------------------------------------
              // 🔘 BUTONLAR
              // --------------------------------------------------
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerAccount(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Müşteri Olarak Devam Et",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessAccount(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                        foregroundColor: AppColors.deepIndigo,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        "İşletme Hesabı Oluştur",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Zaten hesabım var, giriş yap",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepIndigo,
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
