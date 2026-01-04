import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'body_info.dart';
import 'business_list.dart';
import 'customer_appointments.dart';
import '../welcome.dart';
import 'notifications.dart';
import 'package:pilates/screen/chat/chat_list_screen.dart';
 

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

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F6),
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          // 🔔 Bildirim
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final hasUnread =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications,
                        color: Color(0xFFE48989)),
                    if (hasUnread)
                      const Positioned(
                        right: 0,
                        top: 0,
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
            icon: const Icon(Icons.logout, color: Color(0xFFE48989)),
            onPressed: logout,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hoş geldiniz",
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF9E6B6B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9E6B6B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Randevularınızı ve mesajlarınızı buradan yönetebilirsiniz",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFB07C7C),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _BodyInfoCard(bodyInfo: bodyInfo!),
                        const SizedBox(height: 20),

                        // ✅ RANDEVULARIM
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CustomerAppointmentsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.event_note),
                            label: const Text("Randevularım"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE48989),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 💬 MESAJLAR (DM) – YENİ EKLENEN
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatListScreen(
                                    isBusiness: false,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text("Mesajlar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFE48989),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0xFFE48989),
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 🌸 REFORMER KEŞFET
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BusinessListScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE48989),
                                  Color(0xFFB07C7C),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFE48989)
                                      .withOpacity(0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.explore,
                                    color: Colors.white, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  "Reformer Salonlarını Keşfet",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// --------------------------------------------------

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
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
              color: Color(0xFFE48989),
            ),
          ),
          const SizedBox(height: 12),
          _info("Boy", "${bodyInfo['height']} cm"),
          _info("Kilo", "${bodyInfo['weight']} kg"),
          _info("Bel", "${bodyInfo['waist']} cm"),
          _info("Kalça", "${bodyInfo['hip']} cm"),
          if (bodyInfo['fatPercent'] != null &&
              bodyInfo['fatPercent'].toString().isNotEmpty)
            _info("Yağ Oranı", "%${bodyInfo['fatPercent']}"),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
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
