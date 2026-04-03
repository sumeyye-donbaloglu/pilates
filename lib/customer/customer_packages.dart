import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class CustomerPackagesScreen extends StatelessWidget {
  const CustomerPackagesScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Paketlerim",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('activePackages')
            .orderBy('purchasedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded,
                      size: 64, color: AppColors.border),
                  const SizedBox(height: 16),
                  Text(
                    "Aktif paketiniz yok",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Bir salona giderek paket satın alabilirsiniz",
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return _CustomerPackageCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class _CustomerPackageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CustomerPackageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['packageName'] as String? ?? 'Paket';
    final businessName = data['businessName'] as String? ?? 'Salon';
    final total = data['totalSessions'] as int? ?? 0;
    final remaining = data['remainingSessions'] as int? ?? 0;
    final used = total - remaining;
    final progress = total > 0 ? used / total : 0.0;

    DateTime? expiresAt;
    if (data['expiresAt'] != null) {
      expiresAt = (data['expiresAt'] as Timestamp).toDate();
    }

    final isExpired = expiresAt != null && expiresAt.isBefore(DateTime.now());
    final daysLeft = expiresAt != null
        ? expiresAt.difference(DateTime.now()).inDays
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isExpired
              ? Colors.red.withOpacity(0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepIndigo,
                        ),
                      ),
                      Text(
                        businessName,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Süresi Doldu",
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                  )
                else if (daysLeft != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: daysLeft <= 7
                          ? Colors.orange.withOpacity(0.1)
                          : AppColors.accentTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$daysLeft gün kaldı",
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: daysLeft <= 7
                            ? Colors.orange
                            : AppColors.accentTeal,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Seans sayacı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$remaining seans kaldı",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepIndigo,
                  ),
                ),
                Text(
                  "$used / $total kullanıldı",
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.border,
                color: isExpired
                    ? Colors.red
                    : remaining <= 2
                        ? Colors.orange
                        : AppColors.accentTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
