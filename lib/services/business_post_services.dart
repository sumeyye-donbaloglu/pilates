import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class BusinessPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// true  -> foto yüklendi
  /// false -> iptal / hata
  Future<bool> pickAndUploadPost(String businessId) async {
    try {
      // 1️⃣ Foto seç
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75, // 🔹 boyutu düşürür (önemli)
      );

      if (pickedFile == null) {
        return false; // kullanıcı iptal etti
      }

      final File imageFile = File(pickedFile.path);

      // 2️⃣ Dosya adı
      final String fileName =
          DateTime.now().millisecondsSinceEpoch.toString();

      // 3️⃣ Storage reference
      final Reference ref = _storage
          .ref()
          .child('business_posts')
          .child(businessId)
          .child('$fileName.jpg');

      // 4️⃣ UPLOAD (ÖNCE BU)
      await ref.putFile(imageFile);

      // 5️⃣ SONRA download URL
      final String downloadUrl = await ref.getDownloadURL();

      // 6️⃣ Firestore kaydı
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('posts')
          .add({
        'imageUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e, s) {
      // 🔴 HATA YAKALA (debug için çok önemli)
      print('BusinessPostService ERROR: $e');
      print(s);
      return false;
    }
  }
}
