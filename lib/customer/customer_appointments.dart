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
  // İPTAL EDİLEBİLİR Mİ? (GÜNCEL KURAL)
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
  // 🔥 GERÇEK İPTAL (TRANSACTION – DÜZELTİLDİ)
  // --------------------------------------------------
  Future<void> _cancelAppointment(
    String appointmentId,
    Map<String, dynamic> appointment,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final String businessId = appointment['businessId'];
    final String date = appointment['date'];
    final String time = appointment['time'];

    final appointmentRef = firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .doc(appointmentId);

    final dailySlotRef = firestore
        .collection('businesses')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

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
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
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
        // ✅ 1) TÜM OKUMALAR EN BAŞTA

        final businessRef =
            firestore.collection('businesses').doc(businessId);
        final businessSnap = await transaction.get(businessRef);
        if (!businessSnap.exists) {
          throw Exception("İşletme bulunamadı.");
        }

        final settings = businessSnap.data()?['settings'] ?? {};
        final int cancelBeforeHours = settings['cancelBeforeHours'] ?? 0;

        final now = DateTime.now();
        final startDateTime = _toDateTime(date, time);
        final diffMinutes = startDateTime.difference(now).inMinutes;

        if (diffMinutes < cancelBeforeHours * 60) {
          throw Exception("İptal süresi geçti. Randevu iptal edilemez.");
        }

        final daySnap = await transaction.get(dailySlotRef);
        if (!daySnap.exists) {
          throw Exception("Slot günü bulunamadı.");
        }

        // ❗ appointmentRef OKUMASI BURAYA ALINDI
        final apptSnap = await transaction.get(appointmentRef);
        if (!apptSnap.exists) {
          throw Exception("Randevu bulunamadı (zaten silinmiş olabilir).");
        }

        // ✅ 2) RAM'DE HESAPLAMA
        final List<Map<String, dynamic>> slots =
            List<Map<String, dynamic>>.from(daySnap.data()?['slots'] ?? []);

        bool found = false;
        for (final slot in slots) {
          if (slot['time'] == time) {
            final List bookedBy = List.from(slot['bookedBy'] ?? []);
            if (!bookedBy.contains(uid)) {
              throw Exception("Bu slotta kullanıcı bulunamadı.");
            }

            bookedBy.remove(uid);
            slot['bookedBy'] = bookedBy;

            final int remaining = (slot['remaining'] ?? 0) as int;
            slot['remaining'] = remaining + 1;

            found = true;
            break;
          }
        }

        if (!found) {
          throw Exception("İlgili slot bulunamadı.");
        }

        // ✅ 3) TÜM YAZMALAR EN SONDA
        transaction.update(dailySlotRef, {'slots': slots});
        transaction.delete(appointmentRef);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Randevu iptal edildi ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
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
        backgroundColor: const Color(0xFF7A4F4F),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Aktif"),
            Tab(text: "Geçmiş"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('appointments')
            .orderBy('date')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final active = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !_isPast(data['date'], data['endTime']);
          }).toList();

          final past = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _isPast(data['date'], data['endTime']);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(active, isActive: true),
              _buildList(past, isActive: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    List<QueryDocumentSnapshot> list, {
    required bool isActive,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Text(isActive ? "Aktif randevun yok" : "Geçmiş randevun yok"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final doc = list[index];
        final data = doc.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                data['businessName'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A4F4F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${data['date']} • ${data['time']} - ${data['endTime']}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E6B6B),
                ),
              ),

              if (isActive)
                FutureBuilder<bool>(
                  future: _canCancel(data),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data == false) {
                      return const SizedBox();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _cancelAppointment(doc.id, data),
                        child: const Text("İptal Et"),
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
