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
              // 🌸 MODERN PEMBE SLIVER APP BAR
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
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white,
                          child: Text(
                            name.isNotEmpty ? name[0] : "S",
                            style: const TextStyle(
                              fontSize: 42,
                              color: Color(0xFFE48989),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 📍 BİLGİ + CTA
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 18,
                              color: Color(0xFFE48989)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9E6B6B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bio,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7A4F4F),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 🌸 RANDEVU AL BUTONU
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Randevu Al",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 📸 FOTO GALERİ (AYNI MANTIK, DAHA ŞIK)
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
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            "Henüz fotoğraf yok",
                            style: TextStyle(color: Color(0xFF9E6B6B)),
                          ),
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
                          final imageUrl = data['imageUrl'];

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
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
}
