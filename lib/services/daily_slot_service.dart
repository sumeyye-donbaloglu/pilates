import 'package:cloud_firestore/cloud_firestore.dart';

class DailySlotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ----------------------------------------------------
  /// 🔹 SETTINGS + AVAILABLE REFORMER SAYISI
  /// ----------------------------------------------------
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
      final reformer =
          Map<String, dynamic>.from(doc.data());
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
    final parts = time.split(':');
    final d = DateTime.parse(date);
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

  /// ----------------------------------------------------
  /// 🔹 GÜNLÜK SLOT OLUŞTUR
  /// ----------------------------------------------------
  Future<void> generateDailySlots(
      String businessId, String date) async {
    final ref = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date);

    if ((await ref.get()).exists) return;

    final config = await _loadSettingsAndCapacity(businessId);

    final int capacity = config['capacity'] as int;

    if (capacity == 0) {
      throw Exception(
          'Müsait reformer yok. Slot oluşturulamaz.');
    }

    final parsedDate = DateTime.parse(date);
    final isWeekend =
        parsedDate.weekday == 6 || parsedDate.weekday == 7;

    final startStr =
        isWeekend ? config['weekendStart'] : config['weekdayStart'];
    final endStr =
        isWeekend ? config['weekendEnd'] : config['weekdayEnd'];

    final int sessionDuration =
        config['sessionDuration'] as int;
    final int breakDuration =
        config['breakDuration'] as int;

    DateTime current = _parseTime(date, startStr);
    final endLimit = _parseTime(date, endStr);

    final List<Map<String, dynamic>> slots = [];

    while (current.isBefore(endLimit)) {
      final end =
          current.add(Duration(minutes: sessionDuration));
      if (end.isAfter(endLimit)) break;

      slots.add({
        'time': _fmt(current),
        'endTime': _fmt(end),
        'capacity': capacity,
        'remaining': capacity,
        'bookedBy': <String>[],
      });

      current = end.add(Duration(minutes: breakDuration));
    }

    await ref.set({
      'date': date,
      'slots': slots,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ----------------------------------------------------
  /// 🔹 SLOT LİSTELE
  /// ----------------------------------------------------
  Future<List<Map<String, dynamic>>> getSlotsForDay(
      String businessId, String date) async {
    final doc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('dailySlots')
        .doc(date)
        .get();

    if (!doc.exists) return [];

    final data =
        Map<String, dynamic>.from(doc.data()!);
    final List rawSlots = data['slots'] ?? [];

    return rawSlots
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
