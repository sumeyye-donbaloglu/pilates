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
  // 🔥 GERÇEK İPTAL (TRANSACTION – YENİ MODELE UYARLANDI)
  // --------------------------------------------------
  Future<void> _cancelAppointment(
    String appointmentId,
    Map<String, dynamic> appointment,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final String businessId = appointment['businessId'];
    final String date = appointment['date'];
    final String time = appointment['time'];
    final String? slotId = appointment['slotId']; // ✅ yeni modelde var

    // ✅ Appointment artık root collection’da
    final appointmentRef =
        firestore.collection('appointments').doc(appointmentId);

    // ✅ Slot artık daily_slots/{slotId}
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
        // ✅ 1) OKUMALAR

        final businessRef = firestore.collection('businesses').doc(businessId);
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

        final apptSnap = await transaction.get(appointmentRef);
        if (!apptSnap.exists) {
          throw Exception("Randevu bulunamadı (zaten silinmiş olabilir).");
        }

        // ✅ Slot varsa kapasiteyi geri al
        if (slotRef != null) {
          final slotSnap = await transaction.get(slotRef);
          if (slotSnap.exists) {
            final slotData = slotSnap.data() ?? {};
            final int used = (slotData['usedCapacity'] ?? 0) as int;

            final int newUsed = (used - 1) < 0 ? 0 : (used - 1);

            // ✅ FIX: used 0 olunca slotType null
            transaction.update(slotRef, {
              'usedCapacity': newUsed,
              if (newUsed == 0) 'slotType': null,
            });
          }
        }

        // ✅ 3) YAZMALAR
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
          indicatorColor: const Color(0xFFE48989),
          tabs: const [
            Tab(text: "Aktif"),
            Tab(text: "Geçmiş"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments') // ✅ yeni model
            .where('customerId', isEqualTo: uid)
            // ✅ FIX: tarih aynıysa saatle de sıralasın (daha stabil)
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

            // endTime yoksa: aktif/past ayrımını sadece "başlangıç"tan yap (daha güvenli)
            final String date = (data['date'] ?? '').toString();
            final String time = (data['time'] ?? '').toString();
            final String? endTime = data['endTime'];

            if (date.isEmpty || time.isEmpty) return true;

            if (endTime == null || endTime.toString().isEmpty) {
              // fallback: start time geçmişse past say
              return _toDateTime(date, time).isAfter(DateTime.now());
            }

            return !_isPast(date, endTime.toString());
          }).toList();

          final past = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            final String date = (data['date'] ?? '').toString();
            final String time = (data['time'] ?? '').toString();
            final String? endTime = data['endTime'];

            if (date.isEmpty || time.isEmpty) return false;

            if (endTime == null || endTime.toString().isEmpty) {
              return _toDateTime(date, time).isBefore(DateTime.now());
            }

            return _isPast(date, endTime.toString());
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
        child: Text(
          isActive ? "Aktif randevun yok" : "Geçmiş randevun yok",
          style: const TextStyle(color: Color(0xFF7A4F4F)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final doc = list[index];
        final data = doc.data() as Map<String, dynamic>;

        final String businessName =
            (data['businessName'] ?? "Salon").toString();
        final String date = (data['date'] ?? "").toString();
        final String time = (data['time'] ?? "").toString();
        final String endTime = (data['endTime'] ?? "").toString();

        final bool hasEnd = endTime.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : const Color(0xFFF3ECEC),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
            border: Border.all(
              color: isActive
                  ? const Color(0xFFE8CFCF)
                  : const Color(0xFFE2D6D6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                businessName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A4F4F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasEnd ? "$date • $time - $endTime" : "$date • $time",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E6B6B),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ Geçmiş ise pasif etiketi
              if (!isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Tamamlandı",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              // ✅ Aktif ise iptal kontrolü + açıklama
              if (isActive)
                FutureBuilder<bool>(
                  future: _canCancel(data),
                  builder: (context, snapshot) {
                    final can = snapshot.data == true;

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(height: 8);
                    }

                    if (!can) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "🔒 İptal süresi geçti",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _cancelAppointment(doc.id, data),
                          child: const Text("İptal Et"),
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
