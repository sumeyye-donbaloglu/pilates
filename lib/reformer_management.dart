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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Reformer Yönetimi"),
        backgroundColor: const Color(0xFFE48989),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: reformers.length,
            itemBuilder: (context, index) {
              final doc = reformers[index];
              final id = doc.id;
              final name = doc['name'];
              final status = doc['status'];

              return Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DropdownButton<String>(
                          value: status,
                          underline: Container(),
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
                      ],
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.delete, color: Colors.red),
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
