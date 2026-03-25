import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';

class BusinessPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// true  -> foto yüklendi
  /// false -> iptal / hata
  Future<bool> pickAndUploadPost(String businessId) async {
    try {
      // 1️⃣ Foto seç
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) return false;

      final File imageFile = File(pickedFile.path);

      // 2️⃣ Cloudinary'ye yükle ve URL al
      final String? downloadUrl = await CloudinaryService.uploadImage(imageFile);
      if (downloadUrl == null) return false;

      // 3️⃣ BUSINESS İSMİNİ ÇEK
      final businessDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .get();

      final businessData =
          businessDoc.data() as Map<String, dynamic>?;

      final businessInfo =
          businessData?['businessInfo']
              as Map<String, dynamic>?;

      final businessName =
          businessInfo?['name'] ?? 'İşletme';

      // 4️⃣ Firestore post kaydı
      await _firestore.collection('posts').add({
        'businessId': businessId,
        'businessName': businessName,   // ✅ EKLENDİ
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtClient': DateTime.now().millisecondsSinceEpoch,
        'likeCount': 0,
        'commentCount': 0,
      });

      return true;
    } catch (e, s) {
      print('BusinessPostService ERROR: $e');
      print(s);
      return false;
    }
  }

  // ✅ LIKE DURUMU
  Stream<bool> likeStatusStream({
    required String postId,
    required String userId,
  }) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ✅ LIKE/UNLIKE
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    await _firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);

      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
      }
    });
  }
}