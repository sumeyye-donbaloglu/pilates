import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../reformer_management.dart';
import '../randevu_management.dart';
import 'business_settings.dart';
import '../welcome.dart';
import 'business_profile_screen.dart';
import 'business_requests.dart';
import '../customer/notifications.dart';
import '../screen/chat/chat_list_screen.dart'; // ✅ MESAJLAR

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

  // --------------------------------------------------
  // BUSINESS INFO
  // --------------------------------------------------
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

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final businessId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("İşletme Paneli"),
        backgroundColor: const Color(0xFFE48989),
        elevation: 0,
        actions: [
          // 🔔 Bildirim Zili
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: businessId)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final hasUnread =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications),
                    if (hasUnread)
                      const Positioned(
                        right: 2,
                        top: 2,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --------------------------------------------------
                // HEADER
                // --------------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE48989),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Merhaba,",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        businessName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // --------------------------------------------------
                // GRID MENU
                // --------------------------------------------------
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _menuCard(
                          "Profilim",
                          Icons.person_outline,
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

                        // 💬 MESAJLAR
                        _menuCard(
                          "Mesajlar",
                          Icons.chat_bubble_outline,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChatListScreen(
                                  isBusiness: true,
                                ),
                              ),
                            );
                          },
                        ),

                        _menuCard(
                          "Randevular",
                          Icons.calendar_month_outlined,
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

                        _menuCard(
                          "Randevu Talepleri",
                          Icons.mark_email_unread_outlined,
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

                        // 👥 ÜYELERİM
                        _menuCard(
                          "Üyelerim",
                          Icons.group_outlined,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Üyelerim ekranı yakında"),
                              ),
                            );
                          },
                        ),

                        _menuCard(
                          "Reformer Yönetimi",
                          Icons.self_improvement,
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
                          Icons.settings_outlined,
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
                ),
              ],
            ),
    );
  }

  // --------------------------------------------------
  // MENU CARD
  // --------------------------------------------------
  Widget _menuCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: const Color(0xFFE48989)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A4E4E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
