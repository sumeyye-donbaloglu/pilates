import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'membership_requests_screen.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  String get _bizId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Üyelerim",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Bekleyen istek sayısı badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('membershipRequests')
                .where('businessId', isEqualTo: _bizId)
                .where('status', isEqualTo: 'pending')
                .snapshots()
                .handleError((_) {}),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded,
                        color: Colors.white),
                    tooltip: "Üyelik Talepleri",
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MembershipRequestsScreen(),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(_bizId)
            .collection('members')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Hata: ${snapshot.error}",
                  style: GoogleFonts.nunito(color: Colors.red)),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Client tarafında tarihe göre sırala
          final docs = snapshot.data!.docs
            ..sort((a, b) {
              final aTime = (a.data()
                      as Map<String, dynamic>)['joinedAt'] as Timestamp?;
              final bTime = (b.data()
                      as Map<String, dynamic>)['joinedAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

          if (docs.isEmpty) {
            return _EmptyMembers(
              onGoRequests: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MembershipRequestsScreen(),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Üye sayısı başlık
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.gradientStart,
                      AppColors.gradientEnd
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.group_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      "${docs.length} aktif üye",
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    return _MemberCard(data: data);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Üye kartı
class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MemberCard({required this.data});

  String get _name       => data['name']       as String? ?? 'Müşteri';
  String get _phone      => data['phone']      as String? ?? '';
  String get _gender     => data['gender']     as String? ?? '';
  String get _healthNote => data['healthNote'] as String? ?? '';
  DateTime? get _birthDate {
    final ts = data['birthDate'];
    if (ts is Timestamp) return ts.toDate();
    return null;
  }
  DateTime? get _joinedAt {
    final ts = data['joinedAt'];
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  Future<void> _callPhone(BuildContext context) async {
    if (_phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Telefon numarası bulunamadı",
              style: GoogleFonts.nunito()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final uri = Uri.parse('tel:$_phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  int? _age() {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month &&
            now.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.gradientStart,
                  AppColors.gradientEnd
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _name.isNotEmpty ? _name[0].toUpperCase() : '?',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            _name,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.deepIndigo,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_gender.isNotEmpty)
                Text(
                  _gender + (_age() != null ? ' · ${_age()} yaş' : ''),
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              if (_joinedAt != null)
                Text(
                  "Üyelik: ${DateFormat('d MMM y', 'tr_TR').format(_joinedAt!)}",
                  style: GoogleFonts.nunito(
                      fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          // Telefon arama butonu — her zaman görünür
          trailing: GestureDetector(
            onTap: () => _callPhone(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_rounded,
                color: AppColors.accentTeal,
                size: 22,
              ),
            ),
          ),

          // Genişletince detaylar
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 6),

                  // Telefon satırı
                  if (_phone.isNotEmpty)
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: "Telefon",
                      value: _phone,
                      onTap: () => _callPhone(context),
                    ),

                  // Sağlık notu
                  if (_healthNote.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.orange.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            color: Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sağlık Notu",
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _healthNote,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: AppColors.text,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Ara butonu (büyük)
                  if (_phone.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _callPhone(context),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(
                          "Ara — $_phone",
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.lavender),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: GoogleFonts.nunito(
                fontSize: 13, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onTap != null
                  ? AppColors.primary
                  : AppColors.text,
              decoration:
                  onTap != null ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Boş durum
class _EmptyMembers extends StatelessWidget {
  final VoidCallback onGoRequests;
  const _EmptyMembers({required this.onGoRequests});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              "Henüz üye yok",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Müşteriler salonunuzu keşfedip\nüyelik isteği gönderebilir.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onGoRequests,
              icon: const Icon(Icons.inbox_rounded),
              label: Text(
                "Gelen İsteklere Bak",
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                    color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
