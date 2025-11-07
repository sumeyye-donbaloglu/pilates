import 'package:flutter/material.dart';
import 'business_account.dart';
import 'customer_account.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6), // daha yumuşak bir pembe ton
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🩰 Üst kısım (logo + yazı)
              Column(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 100,
                    color: Color(0xFFB07C7C), // pastel pembe-kahve tonu
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Reformerly\'e Hoşgeldiniz',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7A4F4F), // başlıkta daha koyu ton
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pilates salonları ve üyeler için randevu yönetim sistemi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF8C6B6B), // açıklama yazısı soft gri-pembe
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              // 🎀 Butonlar
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDBB5B5), // açık pembe
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerAccount(),
                          ),
                        );
                      },
                      child: const Text(
                        'Müşteri Olarak Devam Et',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF987070), // koyu pembe çerçeve
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessAccount(),
                          ),
                        );
                      },
                      child: const Text(
                        'İşletme Hesabı Oluştur',
                        style: TextStyle(
                          color: Color(0xFF987070),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ✨ Alt kısım (boşluk)
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
