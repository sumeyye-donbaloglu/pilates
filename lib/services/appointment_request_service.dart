import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentRequestService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<bool> sendRequest({
    required String businessId,
    required String slotId,
    required String date,
    required String time,
    required String lessonType, // demo | normal
  }) async {
    final customerId = _auth.currentUser!.uid;

    // Aynı slot için pending talep var mı?
    final existing = await _db
        .collection('appointment_requests')
        .where('customerId', isEqualTo: customerId)
        .where('slotId', isEqualTo: slotId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Bu slot için zaten bekleyen bir talebiniz var.");
    }

    await _db.collection('appointment_requests').add({
      "businessId": businessId,
      "customerId": customerId,
      "slotId": slotId,
      "date": date,
      "time": time,
      "lessonType": lessonType,
      "status": "pending",
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    return true;
  }
}
