import 'package:cloud_firestore/cloud_firestore.dart';

class DailySlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// --------------------------------------------
  /// 1) YENİ SETTINGS FORMATINI YÜKLE
  /// --------------------------------------------
  Future<Map<String, dynamic>> _loadSettings(String businessId) async {
    final doc = await _firestore.collection('users').doc(businessId).get();
    final data = doc.data() ?? {};

    final settings = data["settings"] ?? {};

    return {
      'weekdayStart': settings["weekday"]?["start"] ?? "08:00",
      'weekdayEnd': settings["weekday"]?["end"] ?? "22:00",
      'weekendStart': settings["weekend"]?["start"] ?? "08:00",
      'weekendEnd': settings["weekend"]?["end"] ?? "22:00",
      'sessionDuration': settings["sessionDuration"] ?? 50,
      'breakDuration': settings["breakDuration"] ?? 10,
      'reformerCount': settings["reformerCount"] ?? 1,
    };
  }

  /// String → DateTime
  DateTime _parseTime(String date, String time) {
    final parts = time.split(":");
    return DateTime(
      DateTime.parse(date).year,
      DateTime.parse(date).month,
      DateTime.parse(date).day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// DateTime → HH:mm
  String _fmt(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// --------------------------------------------
  /// 2) SLOT OLUŞTURMA - ARTIK MOLALI VE DOĞRU
  /// --------------------------------------------
  Future<void> generateDailySlots(String businessId, String date) async {
    final dayRef = _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    if ((await dayRef.get()).exists) return;

    final settings = await _loadSettings(businessId);

    final isWeekend =
        DateTime.parse(date).weekday == 6 ||
        DateTime.parse(date).weekday == 7;

    final String startStr = isWeekend
        ? settings['weekendStart']
        : settings['weekdayStart'];

    final String endStr = isWeekend
        ? settings['weekendEnd']
        : settings['weekdayEnd'];

    final sessionDuration = settings['sessionDuration'];
    final breakDuration = settings['breakDuration'];
    final reformerCount = settings['reformerCount'];

    DateTime currentStart = _parseTime(date, startStr);
    DateTime endLimit = _parseTime(date, endStr);

    final List<Map<String, dynamic>> slots = [];

    while (currentStart.isBefore(endLimit)) {
      DateTime currentEnd =
          currentStart.add(Duration(minutes: sessionDuration));

      if (currentEnd.isAfter(endLimit)) break;

      slots.add({
        'time': _fmt(currentStart),
        'endTime': _fmt(currentEnd),
        'capacity': reformerCount,
        'remaining': reformerCount,
        'bookedBy': <String>[],
        'demo': false,
        'demoCapacity': 2,
        'demoReserved': 0,
        'demoUsers': <String>[],
      });

      /// MOLA SÜRESİ EKLENDİ
      currentStart =
          currentEnd.add(Duration(minutes: breakDuration));
    }

    await dayRef.set({
      'date': date,
      'slots': slots,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// --------------------------------------------
  /// 3) GÜNÜN SLOTLARINI ÇEK
  /// --------------------------------------------
  Future<List<Map<String, dynamic>>> getSlotsForDay(
      String businessId, String date) async {
    final doc = await _firestore
        .collection('users')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date)
        .get();

    if (!doc.exists) return [];

    return List<Map<String, dynamic>>.from(doc.data()?['slots'] ?? []);
  }

  /// --------------------------------------------
  /// 4) NORMAL REZERVASYON
  /// --------------------------------------------
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

    final slots = List<Map<String, dynamic>>.from(doc.data()?['slots'] ?? []);

    for (var slot in slots) {
      if (slot['time'] == time && !slot['demo']) {
        if (slot['remaining'] > 0) {
          if (!slot['bookedBy'].contains(customerId)) {
            slot['bookedBy'].add(customerId);
            slot['remaining']--;
            await ref.update({'slots': slots});
            return true;
          }
        }
      }
    }

    return false;
  }

  /// --------------------------------------------
  /// 5) DEMO TALEBİ ARTIK GLOBAL KOLEKSİYONDA
  /// --------------------------------------------
  Future<void> sendDemoRequest({
    required String businessId,
    required String date,
    required String time,
    required String customerId,
    required String name,
  }) async {
    await _firestore
        .collection('users')
        .doc(businessId)
        .collection('demoRequests')
        .add({
      'date': date,
      'time': time,
      'customerId': customerId,
      'name': name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// --------------------------------------------
  /// 6) GÜNÜ RESETLE
  /// --------------------------------------------
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
