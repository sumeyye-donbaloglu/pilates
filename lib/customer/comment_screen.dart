import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> _addComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser!;
    final userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    final userData = userDoc.data() as Map<String, dynamic>;
    final role = userData['role'];

    /// ❌ Eğer business ise yorum atamaz
    if (role == 'business') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İşletmeler yorum yapamaz."),
        ),
      );
      return;
    }

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': userData['name'] ?? 'Kullanıcı',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('posts')
        .doc(widget.postId)
        .update({
      'commentCount': FieldValue.increment(1),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yorumlar"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return const Center(
                    child: Text("Henüz yorum yok"),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index]
                        .data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                        data['userName'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(data['text'] ?? ''),
                    );
                  },
                );
              },
            ),
          ),

          /// YORUM YAZMA ALANI
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Yorum yaz...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _addComment,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}