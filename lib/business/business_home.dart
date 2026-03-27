import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../firestore_paths.dart';
import '../reformer_management.dart';
import '../randevu_management.dart';
import 'business_settings.dart';
import '../welcome.dart';
import 'business_profile_screen.dart';
import 'business_requests.dart';
import 'members_screen.dart';
import 'membership_requests_screen.dart';
import '../customer/notifications.dart';
import '../screen/chat/chat_list_screen.dart';
import '../theme/app_colors.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  String businessName = "";
  String location = "";
  bool loading = true;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      });
    } else {
      fetchBusinessInfo();
    }
  }

  Future<void> fetchBusinessInfo() async {
    if (currentUser == null) return;
    final doc = await FirestorePaths.businessDoc(currentUser!.uid).get();
    if (!doc.exists) {
      setState(() => loading = false);
      return;
    }
    final info = doc.data()?['businessInfo'] ?? {};
    if (!mounted) return;
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
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final businessId = currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── GRADIENT SLIVER APP BAR
                SliverAppBar(
                  expandedHeight: 185,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "İşletme Paneli",
                                    style: GoogleFonts.playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _NotifButton(userId: businessId),
                                      IconButton(
                                        icon: const Icon(Icons.logout_rounded,
                                            color: Colors.white70, size: 22),
                                        onPressed: logout,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                "Merhaba,",
                                style: GoogleFonts.nunito(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                businessName,
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded,
                                        color: Colors.white54, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      location,
                                      style: GoogleFonts.nunito(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── GRID MENU
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    delegate: SliverChildListDelegate([
                      _MenuCard(
                        title: "Profilim",
                        icon: Icons.person_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BusinessProfileScreen(businessId: businessId),
                          ),
                        ),
                      ),
                      _MenuCard(
                        title: "Mesajlar",
                        icon: Icons.chat_bubble_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatListScreen(isBusiness: true),
                          ),
                        ),
                      ),
                      _MenuCard(
                        title: "Randevular",
                        icon: Icons.calendar_month_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RandevuManagementScreen(businessId: businessId),
                          ),
                        ),
                      ),
                      _MenuCard(
                        title: "Talepler",
                        icon: Icons.inbox_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF472B6), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessRequestsScreen(),
                          ),
                        ),
                      ),
                      _MenuCard(
                        title: "Üyelerim",
                        icon: Icons.group_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MembersScreen(),
                          ),
                        ),
                      ),
                      _MenuCard(
                        title: "Reformer",
                        icon: Icons.fitness_center_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF472B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReformerManagementScreen(),
                          ),
                        ),
                      ),
                      _MenuCard(
                        title: "Ayarlar",
                        icon: Icons.tune_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF14B8A6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BusinessSettingsScreen(),
                          ),
                        ),
                      ),
                    ]),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
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

// ── Menü kartı
class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepIndigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
