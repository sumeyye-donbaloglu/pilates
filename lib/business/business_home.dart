import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Ekranlar
import '../reformer_management.dart';
import 'business_settings.dart';
import '../randevu_management.dart';

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

  /// 🔥 ARTIK USERS DEĞİL → businessSettings koleksiyonu
  Future<void> fetchBusinessInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('businessSettings')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          businessName = doc['businessName'] ?? "Salon Adı";
          location = doc['location'] ?? "Konum bilgisi";
          loading = false;
        });
      } else {
        setState(() {
          businessName = "Salon Adı";
          location = "Konum bilgisi";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        businessName = "Salon Adı";
        location = "Konum bilgisi";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("İşletme Paneli"),
        backgroundColor: const Color(0xFFE48989),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÜST KART
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // DASHBOARD KUTULARI
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        // 1) Randevular — BAĞLANDI!
                        _menuCard(
                          "Randevular",
                          Icons.calendar_month,
                          () {
                            final businessId =
                                FirebaseAuth.instance.currentUser!.uid;

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

                        // 2) Reformer Yönetimi
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

                        // 3) Ayarlar
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: const Color(0xFFE48989)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
