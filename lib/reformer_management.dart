import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReformerManagementScreen extends StatefulWidget {
  const ReformerManagementScreen({super.key});

  @override
  State<ReformerManagementScreen> createState() =>
      _ReformerManagementScreenState();
}

class _ReformerManagementScreenState extends State<ReformerManagementScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  /// 🔹 Reformer ekle ve users.reformerCount'u 1 artır
  Future<void> addReformer() async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final reformersRef = userRef.collection('reformers');

    // mevcut cihaz sayısını öğren (sıradaki isim için)
    final current = await reformersRef.get();
    final newName = "Reformer ${current.docs.length + 1}";

    await reformersRef.add({
      'name': newName,
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // kullanıcı dokümanındaki reformerCount'u artır
    await userRef.update({
      'reformerCount': FieldValue.increment(1),
    });
  }

  /// 🔹 Reformer sil ve users.reformerCount'u 1 azalt
  Future<void> deleteReformer(String id) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final reformersRef = userRef.collection('reformers');

    await reformersRef.doc(id).delete();

    await userRef.update({
      'reformerCount': FieldValue.increment(-1),
    });
  }

  /// 🔹 Cihaz durumunu güncelle (müsait/bakımda/kullanım dışı)
  Future<void> updateStatus(String id, String value) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reformers')
        .doc(id)
        .update({'status': value});
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
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('reformers')
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
                style: TextStyle(fontSize: 18, color: Colors.black54),
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
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // İsim + durum seçimi
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

                    // Silme butonu
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
