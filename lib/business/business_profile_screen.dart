import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../firestore_paths.dart';
import '../customer/business_detail.dart';
import 'business_add_post.dart';
import '../screen/chat/chat_detail_screen.dart';
import 'post_detail_screen.dart';
import 'business_edit_profile_screen.dart';

class BusinessProfileScreen extends StatelessWidget {
  final String businessId;

  const BusinessProfileScreen({
    super.key,
    required this.businessId,
  });

  Future<void> _openOrCreateChat(
    BuildContext context, {
    required String businessId,
    required String businessName,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final customerId = currentUser.uid;
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    final existingChat = await chatsRef
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    late String chatId;
    if (existingChat.docs.isNotEmpty) {
      chatId = existingChat.docs.first.id;
    } else {
      final chatDoc = await chatsRef.add({
        'businessId': businessId,
        'customerId': customerId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '💬 Sohbet başlatıldı',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForBusiness': 1,
        'unreadForCustomer': 0,
      });
      chatId = chatDoc.id;
      await chatsRef.doc(chatId).collection('messages').add({
        'senderId': 'system',
        'text': '💬 Müşteri sohbet başlattı',
        'type': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          otherUserName: businessName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        FirebaseAuth.instance.currentUser?.uid == businessId;

    return Scaffold(
      backgroundColor: AppColors.background,
      // StreamBuilder ile dinliyoruz — düzenleme sonrası otomatik güncellenir
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestorePaths.businessDoc(businessId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("İşletme bulunamadı"));
          }

          final data = snapshot.data!.data()!;
          final info = Map<String, dynamic>.from(data['businessInfo'] ?? {});

          final name     = info['name']     as String? ?? 'Salon';
          final location = info['location'] as String? ?? '';
          final bio      = info['bio']      as String? ?? '';
          final photoUrl = info['photoUrl'] as String?;

          return CustomScrollView(
            slivers: [
              // ── SLIVER APP BAR
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                elevation: 0,
                backgroundColor: AppColors.primary,
                actions: [
                  // Fotoğraf ekle (post)
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      tooltip: "Fotoğraf Ekle",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BusinessAddPostScreen(),
                        ),
                      ),
                    ),
                  // Profili düzenle
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: "Profili Düzenle",
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessEditProfileScreen(
                            businessId: businessId,
                          ),
                        ),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.only(left: 60, bottom: 14, right: 16),
                  title: Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient arka plan
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Profil fotoğrafı — ortada
                      Positioned(
                        bottom: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: photoUrl != null
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _defaultAvatar(),
                                    )
                                  : _defaultAvatar(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── BİLGİLER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Konum
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.lavender, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Açıklama
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: bio.isNotEmpty
                            ? Text(
                                bio,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: AppColors.text,
                                  height: 1.6,
                                ),
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.edit_note_rounded,
                                      color: AppColors.lavender, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isOwner
                                          ? "Henüz açıklama eklenmedi. Profili Düzenle'ye dokun."
                                          : "Bu işletme henüz açıklama eklemedi.",
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 16),

                      // Randevu Al
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.event_available_rounded),
                          label: const Text("Randevu Al"),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessDetailScreen(
                                businessId: businessId,
                                name: name,
                                location: location,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      // Müşteriye özel butonlar
                      if (!isOwner) ...[
                        const SizedBox(height: 10),
                        // Üyelik isteği butonu
                        _MembershipButton(businessId: businessId),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text("Mesaj Gönder"),
                            onPressed: () => _openOrCreateChat(
                              context,
                              businessId: businessId,
                              businessName: name,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Paylaşılan Fotoğraflar başlığı
                      Text(
                        "Fotoğraflar",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepIndigo,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // ── FOTO GALERİ
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('businessId', isEqualTo: businessId)
                    .orderBy('createdAtClient', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            "Henüz fotoğraf paylaşılmadı",
                            style: GoogleFonts.nunito(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final postData = docs[index].data()
                              as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailScreen(
                                  postId: docs[index].id,
                                  postData: postData,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                postData['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.surfaceTint,
                                  child: const Icon(Icons.broken_image_rounded,
                                      color: AppColors.lavender),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: docs.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppColors.surfaceTint,
      child: const Icon(Icons.store_rounded,
          color: AppColors.lavender, size: 40),
    );
  }
}

// ── Üyelik İsteği Butonu
class _MembershipButton extends StatelessWidget {
  final String businessId;
  const _MembershipButton({required this.businessId});

  Future<void> _sendRequest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final customerName =
        userDoc.data()?['name'] as String? ?? 'Müşteri';

    await FirebaseFirestore.instance
        .collection('membershipRequests')
        .add({
      'customerId':   user.uid,
      'customerName': customerName,
      'businessId':   businessId,
      'status':       'pending',
      'createdAt':    FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Üyelik isteğin gönderildi!",
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: AppColors.accentTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    // Önce üye mi kontrol et
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('members')
          .doc(uid)
          .snapshots(),
      builder: (context, memberSnap) {
        final isMember = memberSnap.data?.exists == true;

        if (isMember) {
          return _StatusButton(
            icon: Icons.verified_rounded,
            label: "Üyesiniz ✓",
            color: AppColors.accentTeal,
            onTap: null,
          );
        }

        // Bekleyen istek var mı?
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('membershipRequests')
              .where('customerId', isEqualTo: uid)
              .where('businessId', isEqualTo: businessId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, reqSnap) {
            final isPending =
                (reqSnap.data?.docs.isNotEmpty) == true;

            if (isPending) {
              return _StatusButton(
                icon: Icons.hourglass_top_rounded,
                label: "İstek Gönderildi — Bekleniyor",
                color: AppColors.lavender,
                onTap: null,
              );
            }

            return _StatusButton(
              icon: Icons.person_add_alt_1_rounded,
              label: "Üyelik İsteği Gönder",
              color: AppColors.primary,
              onTap: () => _sendRequest(context),
            );
          },
        );
      },
    );
  }
}

class _StatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _StatusButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(
          label,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap != null ? color : color.withOpacity(0.6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
