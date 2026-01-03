import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

class ReformerManagementScreen extends StatefulWidget {
  const ReformerManagementScreen({super.key});

  @override
  State<ReformerManagementScreen> createState() =>
      _ReformerManagementScreenState();
}

class _ReformerManagementScreenState extends State<ReformerManagementScreen> {
  late final String businessId;

  @override
  void initState() {
    super.initState();
    businessId = FirebaseAuth.instance.currentUser!.uid;
  }

  /// ➕ Reformer ekle
  Future<void> addReformer() async {
    final businessRef = FirestorePaths.businessDoc(businessId);
    final reformersRef = FirestorePaths.businessReformers(businessId);

    final snapshot = await reformersRef.get();
    final newName = "Reformer ${snapshot.docs.length + 1}";

    await reformersRef.add({
      'name': newName,
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await businessRef.update({
      'reformerCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ❌ Reformer sil
  Future<void> deleteReformer(String reformerId) async {
    final businessRef = FirestorePaths.businessDoc(businessId);
    final reformersRef = FirestorePaths.businessReformers(businessId);

    await reformersRef.doc(reformerId).delete();

    await businessRef.update({
      'reformerCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔁 Durum güncelle
  Future<void> updateStatus(String reformerId, String status) async {
    await FirestorePaths.businessReformers(businessId)
        .doc(reformerId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF7BCFA1);
      case 'maintenance':
        return const Color(0xFFF4B266);
      case 'unavailable':
        return const Color(0xFFE57373);
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'available':
        return "Müsait";
      case 'maintenance':
        return "Bakımda";
      case 'unavailable':
        return "Kullanım Dışı";
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Reformer Yönetimi"),
        backgroundColor: const Color(0xFFE48989),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: addReformer,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestorePaths.businessReformers(businessId)
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reformers = snapshot.data!.docs;

          if (reformers.isEmpty) {
            return const Center(
              child: Text(
                "Henüz reformer eklenmemiş",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9E6B6B),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reformers.length,
            itemBuilder: (context, index) {
              final doc = reformers[index];
              final id = doc.id;
              final name = doc['name'];
              final status = doc['status'];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    // 🟢 STATUS DOT
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),

                    // 📋 INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A4F4F),
                            ),
                          ),
                          const SizedBox(height: 6),

                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: status,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFFE48989),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'available',
                                  child: Text("Müsait"),
                                ),
                                DropdownMenuItem(
                                  value: 'maintenance',
                                  child: Text("Bakımda"),
                                ),
                                DropdownMenuItem(
                                  value: 'unavailable',
                                  child: Text("Kullanım Dışı"),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  updateStatus(id, value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ❌ DELETE
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFE57373),
                      ),
                      onPressed: () => deleteReformer(id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
