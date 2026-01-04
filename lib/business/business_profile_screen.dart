import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_paths.dart';
import '../customer/business_detail.dart';
import 'business_add_post.dart';
import '../screen/chat/chat_detail_screen.dart'; // ✅ CHAT DETAIL
import '../screen/chat/chat_list_screen.dart'; // (opsiyonel ama sorun olmaz)

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

    // 🔍 Daha önce chat var mı?
    final existingChat = await chatsRef
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .limit(1)
        .get();

    late String chatId;

    if (existingChat.docs.isNotEmpty) {
      // ✅ VAR → mevcut chat
      chatId = existingChat.docs.first.id;
    } else {
      // ❌ YOK → yeni chat oluştur
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

      // 🟡 SYSTEM MESSAGE
      await chatsRef.doc(chatId).collection('messages').add({
        'senderId': 'system',
        'text': '💬 Müşteri sohbet başlattı',
        'type': 'system',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 👉 CHAT DETAIL’E GİT
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
      backgroundColor: const Color(0xFFFFF6F6),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirestorePaths.businessDoc(businessId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("İşletme bulunamadı"));
          }

          final data = snapshot.data!.data()!;
          final info =
              Map<String, dynamic>.from(data['businessInfo'] ?? {});

          final name = info['name'] ?? 'Salon';
          final location = info['location'] ?? '';
          final bio = info['bio'] ?? 'Henüz açıklama eklenmedi';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                elevation: 0,
                backgroundColor: const Color(0xFFE48989),
                actions: [
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.add_a_photo),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const BusinessAddPostScreen(),
                          ),
                        );
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(name),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE48989),
                          Color(0xFFB07C7C),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location),
                      const SizedBox(height: 8),
                      Text(bio),
                      const SizedBox(height: 18),

                      // 🌸 RANDEVU AL
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessDetailScreen(
                                  businessId: businessId,
                                  name: name,
                                  location: location,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE48989),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Randevu Al"),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 💬 MESAJ GÖNDER (MODEL 2)
                      if (!isOwner)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text("Mesaj Gönder"),
                            onPressed: () {
                              _openOrCreateChat(
                                context,
                                businessId: businessId,
                                businessName: name,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFFE48989),
                              side: const BorderSide(
                                  color: Color(0xFFE48989)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 📸 FOTO GALERİ (AYNI)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('businesses')
                    .doc(businessId)
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                            child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text("Henüz fotoğraf yok"),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(8),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final data = docs[index].data()
                              as Map<String, dynamic>;
                          return Image.network(
                            data['imageUrl'],
                            fit: BoxFit.cover,
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
}
