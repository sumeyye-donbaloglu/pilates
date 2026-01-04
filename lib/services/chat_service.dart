import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  String _chatId(String businessId, String customerId) {
    return '${businessId}_$customerId';
  }

  Future<void> createChatIfNotExists({
    required String businessId,
    required String customerId,
  }) async {
    final chatRef = _db.collection('chats').doc(_chatId(businessId, customerId));

    final snap = await chatRef.get();
    if (snap.exists) return;

    await chatRef.set({
      'businessId': businessId,
      'customerId': customerId,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'unreadForBusiness': 0,
      'unreadForCustomer': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔴 BU METOT ŞART
  Future<void> sendSystemMessage({
    required String businessId,
    required String customerId,
    required String text,
  }) async {
    final chatRef = _db.collection('chats').doc(_chatId(businessId, customerId));

    await chatRef.collection('messages').add({
      'senderId': 'system',
      'receiverId': businessId,
      'text': text,
      'type': 'system',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadForBusiness': FieldValue.increment(1),
    });
  }
}
