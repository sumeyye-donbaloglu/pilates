import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
  });

  @override
  State<PostDetailScreen> createState() =>
      _PostDetailScreenState();
}

class _PostDetailScreenState
    extends State<PostDetailScreen> {
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();

  void _openCommentsSheet(
      BuildContext context,
      DocumentReference postRef) {
    final commentsRef =
        postRef.collection('comments');
    final userId = _auth.currentUser!.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                        top: Radius.circular(24)),
              ),
              child: Column(
                children: [

                  const SizedBox(height: 12),

                  /// Üst çizgi
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Yorumlar",
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// YORUMLAR
                  Expanded(
                    child: StreamBuilder<
                        QuerySnapshot>(
                      stream: commentsRef
                          .orderBy('createdAt',
                              descending: true)
                          .snapshots(),
                      builder:
                          (context, snapshot) {
                        if (!snapshot
                            .hasData) {
                          return const Center(
                            child:
                                CircularProgressIndicator(),
                          );
                        }

                        final docs =
                            snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                                "Henüz yorum yok"),
                          );
                        }

                        return ListView.builder(
                          controller:
                              scrollController,
                          itemCount:
                              docs.length,
                          itemBuilder:
                              (context,
                                  index) {
                            final data =
                                docs[index].data()
                                    as Map<
                                        String,
                                        dynamic>;

                            final username =
                                data['username'] ??
                                    "Kullanıcı";
                            final text =
                                data['text'] ??
                                    "";

                            return Padding(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                      horizontal:
                                          16,
                                      vertical:
                                          8),
                              child: RichText(
                                text:
                                    TextSpan(
                                  style:
                                      const TextStyle(
                                    color: Colors
                                        .black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          "$username ",
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    TextSpan(
                                        text:
                                            text),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  /// YORUM INPUT
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                            horizontal: 12,
                            vertical: 8),
                    decoration:
                        const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color:
                                Colors.grey),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              TextField(
                            controller:
                                _commentController,
                            decoration:
                                const InputDecoration(
                              hintText:
                                  "Yorum yaz...",
                              border:
                                  InputBorder
                                      .none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(
                            Icons.send,
                            color: Color(
                                0xFF9B3030),
                          ),
                          onPressed:
                              () async {
                            if (_commentController
                                .text
                                .trim()
                                .isEmpty) return;

                            final userDoc =
                                await FirebaseFirestore
                                    .instance
                                    .collection(
                                        'users')
                                    .doc(userId)
                                    .get();

                            final userData =
                                userDoc.data()
                                    as Map<
                                        String,
                                        dynamic>?;

                            final username =
                                userData?[
                                        'name'] ??
                                    "Kullanıcı";

                            await commentsRef
                                .add({
                              "userId":
                                  userId,
                              "username":
                                  username,
                              "text":
                                  _commentController
                                      .text
                                      .trim(),
                              "createdAt":
                                  FieldValue
                                      .serverTimestamp(),
                            });

                            _commentController
                                .clear();
                          },
                        )
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

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser!.uid;

    final postRef =
        FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId);

    final likesRef =
        postRef.collection('likes');

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        title: const Text("Post"),
        centerTitle: true,
      ),
      body:
          StreamBuilder<QuerySnapshot>(
        stream: likesRef.snapshots(),
        builder:
            (context, likeSnapshot) {
          if (!likeSnapshot
              .hasData) {
            return const Center(
                child:
                    CircularProgressIndicator());
          }

          final likeDocs =
              likeSnapshot.data!.docs;

          final isLiked =
              likeDocs.any((doc) {
            final data = doc
                .data()
                as Map<
                    String,
                    dynamic>?;
            final storedUserId =
                data?['userId'] ??
                    doc.id;
            return storedUserId ==
                userId;
          });

          final likeCount =
              likeDocs.length;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.only(
                    bottom: 40),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [

                const SizedBox(
                    height: 24),

                Center(
                  child:
                      ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                                20),
                    child:
                        SizedBox(
                      width: MediaQuery.of(
                                  context)
                              .size
                              .width *
                          0.9,
                      child:
                          AspectRatio(
                        aspectRatio:
                            1,
                        child:
                            Image.network(
                          widget.postData[
                              'imageUrl'],
                          fit: BoxFit
                              .cover,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                    height: 16),

                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                          horizontal:
                              16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked
                              ? Icons
                                  .favorite
                              : Icons
                                  .favorite_border,
                          color: isLiked
                              ? Colors
                                  .red
                              : Colors
                                  .grey,
                        ),
                        onPressed:
                            () async {
                          final userLikeDoc =
                              likesRef
                                  .doc(
                                      userId);

                          if (isLiked) {
                            await userLikeDoc
                                .delete();
                          } else {
                            await userLikeDoc
                                .set({
                              'userId':
                                  userId,
                              'createdAt':
                                  FieldValue
                                      .serverTimestamp(),
                            });
                          }
                        },
                      ),

                      Text(
                        "$likeCount beğeni",
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                          width: 16),

                      /// YORUM İKONU
                      IconButton(
                        icon: const Icon(
                            Icons
                                .chat_bubble_outline),
                        onPressed: () =>
                            _openCommentsSheet(
                                context,
                                postRef),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height: 8),

                if (widget.postData[
                            'caption'] !=
                        null &&
                    widget.postData[
                            'caption']
                        .toString()
                        .isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                            horizontal:
                                16),
                    child: Text(
                      widget.postData[
                          'caption'],
                      style:
                          const TextStyle(
                              fontSize:
                                  16),
                    ),
                  ),

                const SizedBox(
                    height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}