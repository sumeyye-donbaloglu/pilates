import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'body_info.dart';
import 'business_list.dart';
import 'customer_appointments.dart';
import 'customer_packages.dart';
import '../welcome.dart';
import 'notifications.dart';
import 'package:pilates/screen/chat/chat_list_screen.dart';
import 'customer_explore.dart';
import 'customer_discover.dart';
import 'body_progress_screen.dart';
import '../theme/app_colors.dart';

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
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    if (data['bodyInfoCompleted'] != true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BodyInfoOnboardingScreen()),
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
      backgroundColor: AppColors.background,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── GRADIENT HEADER
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 8, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Üst satır
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Reformerly",
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _NotifButton(userId: uid),
                                    IconButton(
                                      icon: const Icon(Icons.logout_rounded,
                                          color: Colors.white70, size: 22),
                                      onPressed: logout,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Hoş geldiniz,",
                              style: GoogleFonts.nunito(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Randevularınızı ve salonları buradan yönetin",
                              style: GoogleFonts.nunito(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── İÇERİK
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Vücut bilgileri kartı
                      _BodyInfoCard(bodyInfo: bodyInfo!),
                      const SizedBox(height: 20),

                      // Hızlı aksiyon butonları
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: "Randevularım",
                              icon: Icons.event_note_rounded,
                              color: AppColors.primary,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerAppointmentsScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: "Mesajlar",
                              icon: Icons.chat_bubble_rounded,
                              color: AppColors.purple,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChatListScreen(isBusiness: false),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Paketlerim banner
                      _PackagesBanner(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerPackagesScreen(),
                          ),
                        ),
                        uid: uid,
                      ),
                      const SizedBox(height: 14),

                      // İlerleme kartı
                      _ProgressBanner(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BodyProgressScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Keşfet banner
                      _ExploreBanner(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomerDiscoverScreen(),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Bildirim butonu
class _NotifButton extends StatelessWidget {
  final String userId;
  const _NotifButton({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
              if (hasUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        );
      },
    );
  }
}

// ── Aksiyon butonu (ikon + yazı)
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── İlerleme banner
class _ProgressBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ProgressBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.show_chart_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Vücut İlerlemem",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Ölçümlerini takip et, grafikte gör",
                    style: GoogleFonts.nunito(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Paketlerim banner
class _PackagesBanner extends StatelessWidget {
  final VoidCallback onTap;
  final String uid;
  const _PackagesBanner({required this.onTap, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activePackages')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Paketlerim",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count > 0
                            ? "$count aktif paketiniz var"
                            : "Henüz aktif paketiniz yok",
                        style: GoogleFonts.nunito(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Keşfet banner
class _ExploreBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ExploreBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.explore_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reformer Salonlarını Keşfet",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Sana en yakın salonu bul",
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Vücut bilgileri kartı
class _BodyInfoCard extends StatelessWidget {
  final Map<String, dynamic> bodyInfo;
  const _BodyInfoCard({required this.bodyInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.monitor_weight_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                "Vücut Bilgileri",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (bodyInfo['height'] != null)
                _InfoChip(label: "Boy", value: "${bodyInfo['height']} cm",
                    color: const Color(0xFF6366F1)),
              if (bodyInfo['weight'] != null)
                _InfoChip(label: "Kilo", value: "${bodyInfo['weight']} kg",
                    color: const Color(0xFF7C3AED)),
              if (bodyInfo['waist'] != null)
                _InfoChip(label: "Bel", value: "${bodyInfo['waist']} cm",
                    color: const Color(0xFF0EA5E9)),
              if (bodyInfo['hip'] != null)
                _InfoChip(label: "Kalça", value: "${bodyInfo['hip']} cm",
                    color: const Color(0xFF14B8A6)),
              if (bodyInfo['fatPercent'] != null &&
                  bodyInfo['fatPercent'].toString().isNotEmpty)
                _InfoChip(label: "Yağ", value: "%${bodyInfo['fatPercent']}",
                    color: const Color(0xFFF472B6)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
