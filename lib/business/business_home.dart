import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_paths.dart';
import '../reformer_management.dart';
import '../randevu_management.dart';
import 'business_settings.dart';
import '../welcome.dart';
import 'business_profile_screen.dart';
import 'business_requests.dart'; 


class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  String businessName = "";
  String location = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchBusinessInfo();
  }

  Future<void> fetchBusinessInfo() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirestorePaths.businessDoc(uid).get();
    if (!doc.exists) return;

    final info = doc.data()!['businessInfo'] ?? {};
    setState(() {
      businessName = info['name'] ?? "Salon";
      location = info['location'] ?? "";
      loading = false;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("İşletme Paneli"),
        backgroundColor: const Color(0xFFE48989),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _menuCard(
                    "Profilim",
                    Icons.person,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessProfileScreen(
                            businessId: businessId,
                          ),
                        ),
                      );
                    },
                  ),
                  _menuCard(
                    "Randevular",
                    Icons.calendar_month,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RandevuManagementScreen(
                            businessId: businessId,
                          ),
                        ),
                      );
                    },
                  ),

                  // ✅ YENİ KART — RANDEVU TALEPLERİ
                  _menuCard(
                    "Randevu Talepleri",
                    Icons.mark_email_unread,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BusinessRequestsScreen(),
                        ),
                      );
                    },
                  ),

                  _menuCard(
                    "Reformer Yönetimi",
                    Icons.fitness_center,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ReformerManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _menuCard(
                    "Ayarlar",
                    Icons.settings,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const BusinessSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _menuCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFFE48989)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//commit update 
