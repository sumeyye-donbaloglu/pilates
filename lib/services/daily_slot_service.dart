import 'package:cloud_firestore/cloud_firestore.dart';

class DailySlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 İşletme ayarlarını çek
  Future<Map<String, dynamic>> _loadSettings(String businessId) async {
    final doc = await _firestore.collection('users').doc(businessId).get();
    final data = doc.data() ?? {};

    return {
      'weekdayStart': data['weekdayStart'] ?? '08:00',
      'weekdayEnd': data['weekdayEnd'] ?? '22:00',
      'weekendStart': data['weekendStart'] ?? '08:00',
      'weekendEnd': data['weekendEnd'] ?? '22:00',
      'sessionDuration': data['sessionDuration'] ?? 50, // dk
      'reformerCount': data['reformerCount'] ?? 1,
    };
  }

  /// 🔹 "HH:mm" içinden sadece saat bilgisini al
  int _extractHour(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]);
  }

  /// 🔹 DateTime → "HH:mm"
  String _timeToStr(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// 🔥 Belirli bir GÜN için SLOT OLUŞTUR (tam saat başı)
  ///
  /// Örn: date = "2025-12-01"
  Future<void> generateDailySlots(String businessId, String date) async {
    final dayRef = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    // Zaten varsa yeniden oluşturma (şimdilik)
    if ((await dayRef.get()).exists) {
      // İstersen buraya "overwrite" opsiyonu ekleriz
      return;
    }

    final settings = await _loadSettings(businessId);

    final sessionDuration = settings['sessionDuration'] as int; // dk
    final reformerCount = settings['reformerCount'] as int;

    final dt = DateTime.parse(date);
    final isWeekend =
        dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;

    final startStr =
        isWeekend ? settings['weekendStart'] as String : settings['weekdayStart'] as String;
    final endStr =
        isWeekend ? settings['weekendEnd'] as String : settings['weekdayEnd'] as String;

    final startHour = _extractHour(startStr); // 08:00 → 8
    final endHour = _extractHour(endStr);     // 22:00 → 22

    final List<Map<String, dynamic>> slots = [];

    // 🔥 Tam saat başı slotlar:
    // 08:00, 09:00, 10:00 ... (endHour dahil değil)
    for (int hour = startHour; hour < endHour; hour++) {
      final start = DateTime(dt.year, dt.month, dt.day, hour, 0);
      final end = start.add(Duration(minutes: sessionDuration));

      slots.add({
        'time': _timeToStr(start),          // "08:00"
        'endTime': _timeToStr(end),         // "08:50" gibi
        'capacity': reformerCount,          // normal kapasite (cihaz sayısı)
        'remaining': reformerCount,
        'bookedBy': <String>[],
        'demo': false,
        'demoReserved': 0,
        'demoCapacity': 2,                  // demo max 2 kişi
        'demoUsers': <String>[],
      });
    }

    await dayRef.set({
      'date': date,
      'slots': slots,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Günün slotlarını çek
  Future<List<Map<String, dynamic>>> getSlotsForDay(
      String businessId, String date) async {
    final doc = await _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date)
        .get();

    if (!doc.exists) return [];

    final raw = doc.data()?['slots'] as List<dynamic>? ?? [];
    return List<Map<String, dynamic>>.from(raw);
  }

  /// 🔥 NORMAL slot rezervasyonu
  Future<bool> bookSlot({
    required String businessId,
    required String date,
    required String time,
    required String customerId,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    final doc = await ref.get();
    if (!doc.exists) return false;

    final List<dynamic> slots = doc.data()?['slots'] ?? [];
    bool updated = false;

    for (var slot in slots) {
      if (slot['time'] == time && slot['demo'] == false) {
        if ((slot['remaining'] ?? 0) > 0) {
          final List booked = slot['bookedBy'] ?? [];
          if (!booked.contains(customerId)) {
            booked.add(customerId);
            slot['bookedBy'] = booked;
            slot['remaining'] = (slot['remaining'] ?? 0) - 1;
            updated = true;
          }
        }
        break;
      }
    }

    if (updated) {
      await ref.update({'slots': slots});
      return true;
    }

    return false;
  }

  /// 🔥 DEMO TALEBİ OLUŞTUR (ALT KOLEKSİYON!)
  Future<void> sendDemoRequest({
    required String businessId,
    required String date,
    required String time,
    required String customerId,
    required String name,
  }) async {
    final reqRef = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date)
        .collection('demoRequests')
        .doc(time); // time bazlı id

    await reqRef.set({
      'customerId': customerId,
      'name': name,          // müşterinin adı
      'date': date,          // kolay filtre için
      'time': time,          // ekranda göstermek için
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔥 DEMO ONAYLA
  Future<void> approveDemo({
    required String businessId,
    required String date,
    required String time,
    required String customerId,
  }) async {
    final dayRef = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    final doc = await dayRef.get();
    if (!doc.exists) return;

    final List<dynamic> slots = doc.data()?['slots'] ?? [];

    for (var slot in slots) {
      if (slot['time'] == time) {
        slot['demo'] = true;
        final currentDemoReserved = (slot['demoReserved'] ?? 0) as int;
        final List demoUsers = slot['demoUsers'] ?? [];

        if (!demoUsers.contains(customerId)) {
          demoUsers.add(customerId);
          slot['demoUsers'] = demoUsers;
          slot['demoReserved'] = currentDemoReserved + 1;
        }
        break;
      }
    }

    await dayRef.update({'slots': slots});

    await _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date)
        .collection('demoRequests')
        .doc(time)
        .update({'status': 'approved'});
  }

  /// 🔥 DEMO REDDET
  Future<void> rejectDemo({
    required String businessId,
    required String date,
    required String time,
  }) async {
    await _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date)
        .collection('demoRequests')
        .doc(time)
        .update({'status': 'rejected'});
  }

  /// 🔹 Normal randevu iptali
  Future<void> cancelSlot({
    required String businessId,
    required String date,
    required String time,
    required String customerId,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    final doc = await ref.get();
    if (!doc.exists) return;

    final List<dynamic> slots = doc.data()?['slots'] ?? [];

    for (var slot in slots) {
      if (slot['time'] == time) {
        final List booked = slot['bookedBy'] ?? [];
        if (booked.contains(customerId)) {
          booked.remove(customerId);
          slot['bookedBy'] = booked;
          slot['remaining'] = (slot['remaining'] ?? 0) + 1;
        }
        break;
      }
    }

    await ref.update({'slots': slots});
  }

  /// 🔹 Tek bir slotu tamamen sil (fizyoterapist istemezse)
  Future<void> deleteSlot({
    required String businessId,
    required String date,
    required String time,
  }) async {
    final ref = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    final doc = await ref.get();
    if (!doc.exists) return;

    final List<dynamic> slots = doc.data()?['slots'] ?? [];
    slots.removeWhere((slot) => slot['time'] == time);

    await ref.update({'slots': slots});
  }

  /// 🔹 İstenirse tüm günü resetleyip tekrar slot oluşturmak için
  Future<void> regenerateDay(String businessId, String date) async {
    final ref = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    await ref.delete();
    await generateDailySlots(businessId, date);
  }
}
