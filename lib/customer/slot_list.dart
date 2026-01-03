import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SlotListScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final String date;

  const SlotListScreen({
    super.key,
    required this.businessId,
    required this.businessName,
    required this.date,
  });

  @override
  State<SlotListScreen> createState() => _SlotListScreenState();
}

class _SlotListScreenState extends State<SlotListScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  bool loading = false;

  // --------------------------------------------------
  // 📨 RANDEVU TALEBİ + 🔔 İŞLETME BİLDİRİMİ
  // --------------------------------------------------
  Future<void> requestSlot({
    required String slotId,
    required String time,
    required String endTime,
  }) async {
    if (loading) return;

    String lessonType = 'normal';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.date} • $time - $endTime",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text("Ders Türü"),
                  RadioListTile(
                    title: const Text("Normal Ders"),
                    value: 'normal',
                    groupValue: lessonType,
                    onChanged: (v) =>
                        setStateSheet(() => lessonType = v!),
                  ),
                  RadioListTile(
                    title: const Text("Demo Dersi"),
                    value: 'demo',
                    groupValue: lessonType,
                    onChanged: (v) =>
                        setStateSheet(() => lessonType = v!),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text("Talep Gönder"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    setState(() => loading = true);
    final firestore = FirebaseFirestore.instance;

    try {
      // 🔎 Aynı slot için bekleyen talep var mı?
      final existing = await firestore
          .collection('appointment_requests')
          .where('customerId', isEqualTo: uid)
          .where('slotId', isEqualTo: slotId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("Bu seans için bekleyen talebin var.");
      }

      // 👤 Müşteri adı
      final userDoc =
          await firestore.collection('users').doc(uid).get();
      final customerName = userDoc.data()?['name'] ?? 'Müşteri';

      // 📌 TALEP OLUŞTUR
      final requestRef =
          await firestore.collection('appointment_requests').add({
        'businessId': widget.businessId,
        'customerId': uid,
        'customerName': customerName,
        'slotId': slotId,
        'date': widget.date,
        'time': time,
        'lessonType': lessonType,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔔 İŞLETMEYE BİLDİRİM
      await firestore.collection('notifications').add({
        'userId': widget.businessId, // 🔴 İŞLETME UID
        'title': 'Yeni Randevu Talebi',
        'message':
            '$customerName • ${widget.date} $time için randevu talebi gönderdi',
        'type': 'appointment_request',
        'isRead': false,
        'relatedRequestId': requestRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Talep gönderildi ⏳"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: Text("Seanslar · ${widget.date}"),
        backgroundColor: const Color(0xFF7A4F4F),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .collection('daily_slots')
            .where('date', isEqualTo: widget.date)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final slots = snapshot.data!.docs;

          if (slots.isEmpty) {
            return const Center(child: Text("Seans yok"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slotDoc = slots[index];
              final slot =
                  slotDoc.data() as Map<String, dynamic>;

              final used = slot['usedCapacity'] ?? 0;
              final capacity = slot['capacity'];
              final slotType = slot['slotType'];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointment_requests')
                    .where('customerId', isEqualTo: uid)
                    .where('slotId', isEqualTo: slotDoc.id)
                    .where('status', isEqualTo: 'pending')
                    .limit(1)
                    .snapshots(),
                builder: (context, reqSnap) {
                  final hasPending =
                      reqSnap.hasData &&
                          reqSnap.data!.docs.isNotEmpty;

                  final isDisabled =
                      hasPending || used >= capacity;

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () => requestSlot(
                              slotId: slotDoc.id,
                              time: slot['time'],
                              endTime: slot['endTime'],
                            ),
                    child: Opacity(
                      opacity: isDisabled ? 0.6 : 1,
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${slot['time']} - ${slot['endTime']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _buildBadge(
                              hasPending: hasPending,
                              used: used,
                              capacity: capacity,
                              slotType: slotType,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // BADGE
  // --------------------------------------------------
  Widget _buildBadge({
    required bool hasPending,
    required int used,
    required int capacity,
    required String? slotType,
  }) {
    if (hasPending) {
      return const Text(
        "⏳ Talep Gönderildi",
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (used >= capacity) {
      return const Text(
        "🚫 Dolu",
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (slotType == 'demo') {
      return const Text(
        "🔒 Demo",
        style: TextStyle(
          color: Colors.purple,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (slotType == 'normal') {
      return const Text(
        "🔒 Normal",
        style: TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return const Text(
      "Talep Gönder",
      style: TextStyle(
        color: Color(0xFF7A4F4F),
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
