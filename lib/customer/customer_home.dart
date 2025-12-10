import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ÜST BAŞLIK
              const Text(
                "Hoş geldiniz!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A4F4F),
                ),
              ),
              const SizedBox(height: 6),

              const Text(
                "Vücut analizini ve reformer yolculuğunu takip et!",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9E6B6B),
                ),
              ),

              const SizedBox(height: 25),

              // VÜCUT DURUMU KARTI
              _BodyInfoCard(),

              const SizedBox(height: 35),

              // SALONLARA GİT CTA
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigator.push(...);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7A4F4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Reformer Salonlarını Keşfet",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// VÜCUT BİLGİSİ KART WIDGET'I
class _BodyInfoCard extends StatelessWidget {
  const _BodyInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Vücut Durumu",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A4F4F),
            ),
          ),
          const SizedBox(height: 12),

          // ÖRNEK DEĞERLER - Sonradan Firestore’dan gelecek
          const Text(
            "Biyolojik Yaş: 29",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF7A4F4F),
            ),
          ),
          const SizedBox(height: 6),

          const Text(
            "Son Ölçüm: 3 gün önce",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E6B6B),
            ),
          ),
          const SizedBox(height: 6),

          const Text(
            "Bu Ayki Değişim: -1.2 kg",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E6B6B),
            ),
          ),

          const SizedBox(height: 14),

          // DETAY BUTONU
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navigator.push(...);
              },
              child: const Text(
                "Detaylı Gör →",
                style: TextStyle(
                  color: Color(0xFF7A4F4F),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
