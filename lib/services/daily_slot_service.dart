import 'package:cloud_firestore/cloud_firestore.dart';

class DailySlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------------------------------------------
  // SETTINGS + AVAILABLE REFORMER COUNT
  // ----------------------------------------------------
  Future<Map<String, dynamic>> _loadSettingsAndCapacity(
      String businessId) async {
    final businessRef =
        _firestore.collection('businesses').doc(businessId);

    final businessDoc = await businessRef.get();
    final data = businessDoc.data() ?? {};

    final settings =
        Map<String, dynamic>.from(data['settings'] ?? {});

    final reformersSnap =
        await businessRef.collection('reformers').get();

    final availableCount = reformersSnap.docs.where((doc) {
      final reformer = Map<String, dynamic>.from(doc.data());
      return reformer['status'] == 'available';
    }).length;

    return {
      'weekdayStart': settings['weekday']?['start'] ?? '08:00',
      'weekdayEnd': settings['weekday']?['end'] ?? '22:00',
      'weekendStart': settings['weekend']?['start'] ?? '08:00',
      'weekendEnd': settings['weekend']?['end'] ?? '22:00',
      'sessionDuration': settings['sessionDuration'] ?? 50,
      'breakDuration': settings['breakDuration'] ?? 10,
      'capacity': availableCount,
    };
  }

  DateTime _parseTime(String date, String time) {
    final d = DateTime.parse(date);
    final parts = time.split(':');
    return DateTime(
      d.year,
      d.month,
      d.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ----------------------------------------------------
  // ✅ SLOT OLUŞTUR (BUGÜN PROBLEMİNİN ÇÖZÜLDÜĞÜ YER)
  // ----------------------------------------------------
  Future<void> generateDailySlots(
      String businessId, String date) async {
    final config = await _loadSettingsAndCapacity(businessId);

    final int capacity = config['capacity'];

    if (capacity == 0) {
      throw Exception("Müsait reformer yok. Slot oluşturulamaz.");
    }

    final parsedDate = DateTime.parse(date);
    final isWeekend =
        parsedDate.weekday == 6 || parsedDate.weekday == 7;

    final startStr =
        isWeekend ? config['weekendStart'] : config['weekdayStart'];
    final endStr =
        isWeekend ? config['weekendEnd'] : config['weekdayEnd'];

    final int sessionDuration = config['sessionDuration'];
    final int breakDuration = config['breakDuration'];

    DateTime current = _parseTime(date, startStr);
    final endLimit = _parseTime(date, endStr);

    final batch = _firestore.batch();

    while (current.isBefore(endLimit)) {
      final end =
          current.add(Duration(minutes: sessionDuration));
      if (end.isAfter(endLimit)) break;

      final startTime = _fmt(current);
      final endTime = _fmt(end);

      final slotId =
          '${date}_${startTime.replaceAll(':', '-')}';

      final slotRef = _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('daily_slots')
          .doc(slotId);

      final exists = await slotRef.get();
      if (!exists.exists) {
        batch.set(slotRef, {
          'date': date,
          'time': startTime,
          'endTime': endTime,
          'capacity': capacity,
          'usedCapacity': 0,
          'slotType': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      current = end.add(Duration(minutes: breakDuration));
    }

    await batch.commit();
  }

  // ----------------------------------------------------
  // SLOT GETİR
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> getSlotsForDay(
      String businessId, String date) async {
    final snap = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('daily_slots')
        .where('date', isEqualTo: date)
        .orderBy('time')
        .get();

    return snap.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  }
}
