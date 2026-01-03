// ⚠️ BU DOSYADA HİÇBİR LOGIC SATIRI SİLİNMEDİ
// ⚠️ SADECE RENK + BUTON BOYUTLARI GÜNCELLENDİ

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerAppointmentsScreen extends StatefulWidget {
  const CustomerAppointmentsScreen({super.key});

  @override
  State<CustomerAppointmentsScreen> createState() =>
      _CustomerAppointmentsScreenState();
}

class _CustomerAppointmentsScreenState
    extends State<CustomerAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // DateTime yardımcıları
  // --------------------------------------------------
  DateTime _toDateTime(String date, String time) {
    final d = date.split('-');
    final t = time.split(':');
    return DateTime(
      int.parse(d[0]),
      int.parse(d[1]),
      int.parse(d[2]),
      int.parse(t[0]),
      int.parse(t[1]),
    );
  }

  // --------------------------------------------------
  // RANDEVU GEÇMİŞ Mİ?
  // --------------------------------------------------
  bool _isPast(String date, String endTime) {
    final now = DateTime.now();
    final endDateTime = _toDateTime(date, endTime);
    return endDateTime.isBefore(now);
  }

  // --------------------------------------------------
  // İPTAL EDİLEBİLİR Mİ?
  // --------------------------------------------------
  Future<bool> _canCancel(Map<String, dynamic> appointment) async {
    final businessId = appointment['businessId'];

    final businessDoc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .get();

    final settings = businessDoc.data()?['settings'] ?? {};
    final int cancelBeforeHours = settings['cancelBeforeHours'] ?? 0;

    final now = DateTime.now();
    final startDateTime = _toDateTime(appointment['date'], appointment['time']);

    final diffMinutes = startDateTime.difference(now).inMinutes;
    final requiredMinutes = cancelBeforeHours * 60;

    return diffMinutes >= requiredMinutes;
  }

  // --------------------------------------------------
  // 🔥 GERÇEK İPTAL (TRANSACTION)
  // --------------------------------------------------
  Future<void> _cancelAppointment(
    String appointmentId,
    Map<String, dynamic> appointment,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final String businessId = appointment['businessId'];
    final String date = appointment['date'];
    final String time = appointment['time'];
    final String? slotId = appointment['slotId'];

    final appointmentRef =
        firestore.collection('appointments').doc(appointmentId);

    final DocumentReference<Map<String, dynamic>>? slotRef = (slotId == null)
        ? null
        : firestore
            .collection('businesses')
            .doc(businessId)
            .collection('daily_slots')
            .doc(slotId);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Randevu İptali"),
        content: const Text("Bu randevuyu iptal etmek istiyor musun?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2B6B6),
              foregroundColor: const Color(0xFF7A4F4F),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("İptal Et"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await firestore.runTransaction((transaction) async {
        final businessRef =
            firestore.collection('businesses').doc(businessId);
        final businessSnap = await transaction.get(businessRef);

        final settings = businessSnap.data()?['settings'] ?? {};
        final int cancelBeforeHours = settings['cancelBeforeHours'] ?? 0;

        final startDateTime = _toDateTime(date, time);
        final diffMinutes =
            startDateTime.difference(DateTime.now()).inMinutes;

        if (diffMinutes < cancelBeforeHours * 60) {
          throw Exception("İptal süresi geçti.");
        }

        if (slotRef != null) {
          final slotSnap = await transaction.get(slotRef);
          if (slotSnap.exists) {
            final used = slotSnap.data()?['usedCapacity'] ?? 0;
            final newUsed = used > 0 ? used - 1 : 0;

            transaction.update(slotRef, {
              'usedCapacity': newUsed,
              if (newUsed == 0) 'slotType': null,
            });
          }
        }

        transaction.delete(appointmentRef);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Randevu iptal edildi"),
          backgroundColor: Color(0xFFE48989),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
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
        title: const Text("Randevularım"),
        backgroundColor: const Color(0xFFE48989),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Aktif"),
            Tab(text: "Geçmiş"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('customerId', isEqualTo: uid)
            .orderBy('date')
            .orderBy('time')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final active = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _toDateTime(data['date'], data['time'])
                .isAfter(DateTime.now());
          }).toList();

          final past = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _toDateTime(data['date'], data['time'])
                .isBefore(DateTime.now());
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(active, true),
              _buildList(past, false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> list, bool isActive) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isActive ? "Aktif randevun yok" : "Geçmiş randevun yok",
          style: const TextStyle(color: Color(0xFFB07C7C)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final doc = list[index];
        final data = doc.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['businessName'] ?? "Salon",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE48989),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${data['date']} • ${data['time']}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E6B6B),
                ),
              ),
              if (isActive)
                FutureBuilder<bool>(
                  future: _canCancel(data),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "🔒 İptal süresi geçti",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFF2B6B6),
                            foregroundColor:
                                const Color(0xFF7A4F4F),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              _cancelAppointment(doc.id, data),
                          child: const Text(
                            "İptal Et",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
