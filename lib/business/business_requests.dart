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
            .collection('appointment_requests')
            .where('businessId', isEqualTo: businessId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt')
            .snapshots(),
        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Firestore hatası:\n\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // EMPTY
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Bekleyen randevu talebi yok",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // DATA
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

// ------------------------------------------------------------
// REQUEST CARD
// ------------------------------------------------------------
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
          Text("${data['date']} • ${data['time']}"),
          const SizedBox(height: 6),
          Text(
            data['lessonType'] == 'demo'
                ? "Demo Dersi"
                : "Normal Ders",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Onayla"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _rejectRequest(context),
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
  // REDDET
  // ------------------------------------------------
  Future<void> _rejectRequest(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((tx) async {
      final ref =
          firestore.collection('appointment_requests').doc(requestId);

      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data()!;
      final customerId = data['customerId'];

      tx.update(ref, {'status': 'rejected'});

      tx.set(firestore.collection('notifications').doc(), {
        'userId': customerId,
        'title': 'Randevu Reddedildi',
        'message':
            '${data['date']} ${data['time']} randevu talebin reddedildi',
        'type': 'appointment',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ------------------------------------------------
  // ONAYLA (TEK VE DOĞRU YER)
  // ------------------------------------------------
  Future<void> _approveRequest(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.runTransaction((tx) async {
      final requestRef =
          firestore.collection('appointment_requests').doc(requestId);

      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) {
        throw Exception("Talep bulunamadı");
      }

      final req = requestSnap.data()!;
      final customerId = req['customerId'];
      final slotId = req['slotId'];
      final lessonType = req['lessonType'];

      // 🔹 BUSINESS INFO (isim için)
      final businessRef =
          firestore.collection('businesses').doc(businessId);
      final businessSnap = await tx.get(businessRef);
      final businessName =
          businessSnap.data()?['businessInfo']?['name'] ?? 'Salon';

      final slotRef = businessRef
          .collection('daily_slots')
          .doc(slotId);

      final slotSnap = await tx.get(slotRef);
      if (!slotSnap.exists) {
        throw Exception("Slot bulunamadı");
      }

      final slot = slotSnap.data()!;
      final used = slot['usedCapacity'] ?? 0;
      final capacity = slot['capacity'];
      final slotType = slot['slotType'];

      if (slotType != null && slotType != lessonType) {
        throw Exception("Slot farklı ders türüne kilitli");
      }

      if (used >= capacity) {
        throw Exception("Slot dolu");
      }

      // SLOT UPDATE
      tx.update(slotRef, {
        'usedCapacity': used + 1,
        'slotType': slotType ?? lessonType,
      });

      // APPOINTMENT (SADECE BURADA YAZILIYOR)
      tx.set(firestore.collection('appointments').doc(), {
        'businessId': businessId,
        'businessName': businessName,
        'customerId': customerId,
        'slotId': slotId,
        'date': req['date'],
        'time': req['time'],
        'lessonType': lessonType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // REQUEST STATUS
      tx.update(requestRef, {'status': 'approved'});

      // NOTIFICATION (TEK)
      tx.set(firestore.collection('notifications').doc(), {
        'userId': customerId,
        'title': 'Randevu Onaylandı',
        'message':
            '${req['date']} ${req['time']} randevun onaylandı',
        'type': 'appointment',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
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
