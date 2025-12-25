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
  Future<void> requestSlot(Map<String, dynamic> slot) async {
    if (loading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Randevu Talebi"),
        content: Text(
          "${widget.date} • ${slot['time']} - ${slot['endTime']}\n"
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
      // 🔒 Aynı slot için daha önce talep var mı?
      final existing = await firestore
          .collection('businesses')
          .doc(widget.businessId)
          .collection('appointmentRequests')
          .where('customerId', isEqualTo: uid)
          .where('date', isEqualTo: widget.date)
          .where('time', isEqualTo: slot['time'])
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("Bu seans için zaten bir talep gönderdin.");
      }

      // 👤 Müşteri adı
      final userDoc =
          await firestore.collection('users').doc(uid).get();
      final customerName = userDoc.data()?['name'] ?? 'Müşteri';

      // 📨 Talep oluştur
      await firestore
          .collection('businesses')
          .doc(widget.businessId)
          .collection('appointmentRequests')
          .add({
        'customerId': uid,
        'customerName': customerName,
        'date': widget.date,
        'time': slot['time'],
        'endTime': slot['endTime'],
        'type': 'normal', // demo | normal
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Talebin işletmeye iletildi ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
          ),
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .collection('dailySlots')
            .doc(widget.date)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text("Bu tarih için seans yok."),
            );
          }

          final slots =
              List<Map<String, dynamic>>.from(snapshot.data!['slots']);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];

              return GestureDetector(
                onTap: () => requestSlot(slot),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
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
                      const Text(
                        "Talep Gönder",
                        style: TextStyle(
                          color: Color(0xFF7A4F4F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
