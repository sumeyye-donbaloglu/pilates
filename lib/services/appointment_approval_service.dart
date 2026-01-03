import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentApprovalService {
  final _db = FirebaseFirestore.instance;

  Future<void> approveRequest({
    required String requestId,
    required String businessId,
    required String slotId,
    required String lessonType, // demo | normal
    required int reformerCount,
  }) async {
    final requestRef =
        _db.collection('appointment_requests').doc(requestId);
    final slotRef = _db
        .collection('businesses')
        .doc(businessId)
        .collection('daily_slots')
        .doc(slotId);

    await _db.runTransaction((tx) async {
      final requestSnap = await tx.get(requestRef);
      final slotSnap = await tx.get(slotRef);

      if (!requestSnap.exists || !slotSnap.exists) {
        throw Exception("Veri bulunamadı");
      }

      final slotData = slotSnap.data()!;
      final used = slotData['usedCapacity'] ?? 0;
      final slotType = slotData['slotType'];

      if (slotType != null && slotType != lessonType) {
        throw Exception("Bu slot farklı ders türüne kilitli");
      }

      if (used >= reformerCount) {
        throw Exception("Slot dolu");
      }

      tx.update(slotRef, {
        "usedCapacity": used + 1,
        "slotType": slotType ?? lessonType,
      });

      tx.update(requestRef, {
        "status": "approved",
        "updatedAt": FieldValue.serverTimestamp(),
      });

      tx.set(_db.collection('appointments').doc(), {
        "businessId": businessId,
        "customerId": requestSnap['customerId'],
        "slotId": slotId,
        "date": requestSnap['date'],
        "time": requestSnap['time'],
        "lessonType": lessonType,
        "createdAt": FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _db
        .collection('appointment_requests')
        .doc(requestId)
        .update({
      "status": "rejected",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}
