import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_paths.dart';
import '../customer/business_detail.dart';
import 'business_add_post.dart';

class BusinessProfileScreen extends StatelessWidget {
  final String businessId;

  const BusinessProfileScreen({
    super.key,
    required this.businessId,
  });

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
                expandedHeight: 220,
                backgroundColor: const Color(0xFF7A4F4F),
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
                  background: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        name.isNotEmpty ? name[0] : "S",
                        style: const TextStyle(
                          fontSize: 40,
                          color: Color(0xFF7A4F4F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location,
                          style: const TextStyle(
                              color: Color(0xFF9E6B6B))),
                      const SizedBox(height: 8),
                      Text(bio),
                      const SizedBox(height: 16),
                      ElevatedButton(
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
                        child: const Text("Randevu Al"),
                      ),
                    ],
                  ),
                ),
              ),

              // 📸 FOTO GRID
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
                      child: Center(
                        child: CircularProgressIndicator(),
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
                    padding: const EdgeInsets.all(4),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final data = docs[index].data()
                              as Map<String, dynamic>;
                          final imageUrl = data['imageUrl'];

                          return Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          );
                        },
                        childCount: docs.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
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
