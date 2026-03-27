import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class MembershipRequestsScreen extends StatelessWidget {
  const MembershipRequestsScreen({super.key});

  String get _bizId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Üyelik Talepleri",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('membershipRequests')
            .where('businessId', isEqualTo: _bizId)
            .where('status', isEqualTo: 'pending')
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
                      as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime = (b.data()
                      as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      size: 48,
                      color: AppColors.lavender,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Bekleyen istek yok",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepIndigo,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Yeni üyelik istekleri burada görünür",
                    style: GoogleFonts.nunito(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final doc  = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['customerName'] as String? ?? 'Müşteri';
              final date = (data['createdAt'] as Timestamp?)?.toDate();

              return _RequestCard(
                requestId:    doc.id,
                customerId:   data['customerId'] as String,
                customerName: name,
                date:         date,
                businessId:   _bizId,
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String requestId;
  final String customerId;
  final String customerName;
  final DateTime? date;
  final String businessId;

  const _RequestCard({
    required this.requestId,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.businessId,
  });

  Future<void> _accept(BuildContext context) async {
    try {
      // Müşteri bilgilerini çek
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
      final userData = userDoc.data() ?? {};

      // İsteği güncelle
      await FirebaseFirestore.instance
          .collection('membershipRequests')
          .doc(requestId)
          .update({'status': 'accepted'});

      // İşletmenin members subcollection'ına ekle
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(customerId)
          .set({
        'userId':     customerId,
        'name':       userData['name']       ?? customerName,
        'phone':      userData['phone']      ?? '',
        'gender':     userData['gender']     ?? '',
        'healthNote': userData['healthNote'] ?? '',
        'birthDate':  userData['birthDate'],
        'joinedAt':   FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$customerName üyeliğe kabul edildi ✓",
                style: GoogleFonts.nunito()),
            backgroundColor: AppColors.accentTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('membershipRequests')
        .doc(requestId)
        .update({'status': 'rejected'});

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("İstek reddedildi",
              style: GoogleFonts.nunito()),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                customerName.isNotEmpty
                    ? customerName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // İsim + tarih
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepIndigo,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM y, HH:mm', 'tr_TR').format(date!),
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),

          // Reddet
          IconButton(
            onPressed: () => _reject(context),
            icon: const Icon(Icons.close_rounded, color: Colors.red),
            tooltip: "Reddet",
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 8),

          // Kabul et
          IconButton(
            onPressed: () => _accept(context),
            icon: const Icon(Icons.check_rounded,
                color: AppColors.accentTeal),
            tooltip: "Kabul Et",
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accentTeal.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
