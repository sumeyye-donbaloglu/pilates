import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';

class AppointmentRequestService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<bool> sendRequest({
    required String businessId,
    required String slotId,
    required String date,
    required String time,
    required String lessonType,
  }) async {
    final customerId = _auth.currentUser!.uid;

    // 1️⃣ Aynı slot için pending kontrolü
    final existing = await _db
        .collection('appointment_requests')
        .where('customerId', isEqualTo: customerId)
        .where('slotId', isEqualTo: slotId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Bu slot için zaten bekleyen bir talebiniz var.");
    }

    // 2️⃣ Appointment request oluştur
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

    // 3️⃣ DM ENTEGRASYONU (SADECE BURADA!)
    final chatService = ChatService();

    await chatService.createChatIfNotExists(
      businessId: businessId,
      customerId: customerId,
    );

    await chatService.sendSystemMessage(
      businessId: businessId,
      customerId: customerId,
      text: '📅 $date $time için randevu talebi oluşturuldu.',
    );

    return true;
  }
}
