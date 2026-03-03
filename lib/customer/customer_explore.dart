import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/business_post_services.dart';
import '../business/business_profile_screen.dart';
import 'comment_screen.dart';

class CustomerExploreScreen extends StatelessWidget {
  const CustomerExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = BusinessPostService();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAtClient', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return const Center(
            child: Text(
              "Henüz paylaşım yok",
              style: TextStyle(color: Color(0xFF7A4F4F)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final doc = posts[index];
            final postId = doc.id;
            final data = doc.data() as Map<String, dynamic>;

            final imageUrl = data['imageUrl'] ?? '';
            final businessId = data['businessId'];
            final likeCount = data['likeCount'] ?? 0;
            final commentCount = data['commentCount'] ?? 0;
            final businessName = data['businessName'] ?? 'İşletme';

            return Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 🔹 BUSINESS HEADER
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessProfileScreen(
                            businessId: businessId,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                const Color(0xFFEFE3E3),
                            child: const Icon(
                              Icons.store,
                              color: Color(0xFF7A4F4F),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              businessName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7A4F4F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// FOTO
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),

                  /// LIKE + COMMENT BAR
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [

                        /// LIKE
                        StreamBuilder<bool>(
                          stream: service.likeStatusStream(
                            postId: postId,
                            userId: uid,
                          ),
                          builder: (context, likeSnap) {
                            final isLiked =
                                likeSnap.data ?? false;

                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(),
                              onPressed: () async {
                                await service.toggleLike(
                                  postId: postId,
                                  userId: uid,
                                );
                              },
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked
                                    ? Colors.red
                                    : const Color(0xFF7A4F4F),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 6),

                        Text(
                          "$likeCount",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF7A4F4F),
                          ),
                        ),

                        const SizedBox(width: 20),

                        /// COMMENT
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(),
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFF7A4F4F),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CommentScreen(
                                  postId: postId,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 6),

                        Text(
                          "$commentCount",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF7A4F4F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}