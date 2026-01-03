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
  // 📨 RANDEVU TALEBİ GÖNDER
  // --------------------------------------------------
  Future<void> requestSlot({
    required String slotId,
    required String time,
    required String endTime,
  }) async {
    if (loading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Randevu Talebi"),
        content: Text(
          "${widget.date} • $time - $endTime\n"
          "Bu seans için talep göndermek istiyor musun?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Talep Gönder"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => loading = true);
    final firestore = FirebaseFirestore.instance;

    try {
      // 🔒 Aynı slot için pending talep var mı?
      final existing = await firestore
          .collection('appointment_requests')
          .where('customerId', isEqualTo: uid)
          .where('slotId', isEqualTo: slotId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("Bu seans için zaten bekleyen bir talebin var.");
      }

      // 👤 Müşteri adı
      final userDoc =
          await firestore.collection('users').doc(uid).get();
      final customerName = userDoc.data()?['name'] ?? 'Müşteri';

      // 📨 Talep oluştur
      await firestore.collection('appointment_requests').add({
        'businessId': widget.businessId,
        'customerId': uid,
        'customerName': customerName,
        'slotId': slotId,
        'date': widget.date,
        'time': time,
        'lessonType': 'normal', // demo | normal (şimdilik normal)
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Talebin işletmeye iletildi ⏳"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
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
            return const Center(
              child: Text("Bu tarih için seans yok."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slotDoc = slots[index];
              final slot = slotDoc.data() as Map<String, dynamic>;

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
                      reqSnap.hasData && reqSnap.data!.docs.isNotEmpty;

                  return GestureDetector(
                    onTap: hasPending
                        ? null
                        : () => requestSlot(
                              slotId: slotDoc.id,
                              time: slot['time'],
                              endTime: slot['endTime'],
                            ),
                    child: Opacity(
                      opacity: hasPending ? 0.6 : 1,
                      child: Container(
                        margin:
                            const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6),
                          ],
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
                            hasPending
                                ? const Text(
                                    "⏳ Talep Gönderildi",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  )
                                : const Text(
                                    "Talep Gönder",
                                    style: TextStyle(
                                      color:
                                          Color(0xFF7A4F4F),
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
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
}
