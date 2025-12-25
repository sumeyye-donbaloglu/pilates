import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'body_info.dart';
import 'business_list.dart';
import 'customer_appointments.dart';
import '../welcome.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  bool loading = true;

  String name = "";
  Map<String, dynamic>? bodyInfo;

  @override
  void initState() {
    super.initState();
    loadCustomerData();
  }

  Future<void> loadCustomerData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final completed = data['bodyInfoCompleted'] == true;

    // 🔁 Body bilgisi yoksa onboarding
    if (!completed) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BodyInfoOnboardingScreen(),
        ),
      );
      return;
    }

    setState(() {
      name = data['name'] ?? "";
      bodyInfo = Map<String, dynamic>.from(data['bodyInfo'] ?? {});
      loading = false;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    // ✅ Login yerine Welcome'a dön
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F6),
        elevation: 0,

        // ✅ sola geri gibi değil ama solda bir ikon istiyorsan buraya koyarız
        leading: const SizedBox.shrink(),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF7A4F4F)),
            onPressed: logout,
          ),
        ],
      ),

      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👋 Selamlama
                    Text(
                      "Hoş geldin $name 👋",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7A4F4F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Vücut durumunu ve randevularını buradan takip edebilirsin",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF9E6B6B),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // 📊 Vücut Bilgileri
                    _BodyInfoCard(bodyInfo: bodyInfo!),

                    const SizedBox(height: 18),

                    // ✅ RANDEVULARIM (EKSİK OLAN KISIM BUYDU)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerAppointmentsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_note),
                        label: const Text(
                          "Randevularım",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB07C7C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 🚀 Salonlar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BusinessListScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A4F4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Reformer Salonlarını Keşfet",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),
      ),
    );
  }
}

/// 📦 VÜCUT BİLGİSİ KARTI
class _BodyInfoCard extends StatelessWidget {
  final Map<String, dynamic> bodyInfo;

  const _BodyInfoCard({required this.bodyInfo});

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
            "Vücut Bilgileri",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7A4F4F),
            ),
          ),
          const SizedBox(height: 12),
          _infoRow("Boy", "${bodyInfo['height']} cm"),
          _infoRow("Kilo", "${bodyInfo['weight']} kg"),
          _infoRow("Bel", "${bodyInfo['waist']} cm"),
          _infoRow("Kalça", "${bodyInfo['hip']} cm"),
          if (bodyInfo['fatPercent'] != null &&
              bodyInfo['fatPercent'].toString().isNotEmpty)
            _infoRow("Yağ Oranı", "%${bodyInfo['fatPercent']}"),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF7A4F4F),
        ),
      ),
    );
  }
}
