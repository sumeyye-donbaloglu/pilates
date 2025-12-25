import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BusinessRequestsScreen extends StatelessWidget {
  const BusinessRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Randevu Talepleri"),
        backgroundColor: const Color(0xFFE48989),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .collection('appointmentRequests')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Bekleyen randevu talebi yok",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return _RequestCard(
                requestId: doc.id,
                businessId: businessId,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}







class _RequestCard extends StatelessWidget {
  final String requestId;
  final String businessId;
  final Map<String, dynamic> data;

  const _RequestCard({
    required this.requestId,
    required this.businessId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['customerName'] ?? 'Müşteri',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text("${data['date']} • ${data['time']} - ${data['endTime']}"),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _approveRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Onayla"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _rejectRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Reddet"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ------------------------------------------------
  // ❌ REDDET
  // ------------------------------------------------
  Future<void> _rejectRequest(BuildContext context) async {
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('appointmentRequests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  // ------------------------------------------------
  // ✅ ONAYLA (TRANSACTION)
  // ------------------------------------------------
  Future<void> _approveRequest(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((tx) async {
      final requestRef = firestore
          .collection('businesses')
          .doc(businessId)
          .collection('appointmentRequests')
          .doc(requestId);

      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) {
        throw Exception("Talep bulunamadı");
      }

      final req = requestSnap.data()!;
      final date = req['date'];
      final time = req['time'];
      final customerId = req['customerId'];

      // 🔹 Günlük slot
      final dayRef = firestore
          .collection('businesses')
          .doc(businessId)
          .collection('dailySlots')
          .doc(date);

      final daySnap = await tx.get(dayRef);
      if (!daySnap.exists) {
        throw Exception("Slot günü yok");
      }

      final slots =
          List<Map<String, dynamic>>.from(daySnap['slots']);

      bool updated = false;

      for (final slot in slots) {
        if (slot['time'] == time) {
          if (slot['remaining'] <= 0) {
            throw Exception("Slot dolu");
          }
          slot['remaining']--;
          slot['bookedBy'].add(customerId);
          updated = true;
        }
      }

      if (!updated) {
        throw Exception("Slot bulunamadı");
      }

      // 🔹 Slot güncelle
      tx.update(dayRef, {'slots': slots});

      // 🔹 Müşteri randevusu
      final customerAppointmentRef = firestore
          .collection('users')
          .doc(customerId)
          .collection('appointments')
          .doc();

      tx.set(customerAppointmentRef, {
        'businessId': businessId,
        'date': date,
        'time': time,
        'endTime': req['endTime'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Talep durumu
      tx.update(requestRef, {'status': 'approved'});
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Randevu onaylandı ✅"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
