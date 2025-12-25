import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class BusinessPostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// true = foto yüklendi
  /// false = iptal edildi
  Future<bool> pickAndUploadPost(String businessId) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      return false; // 👈 İPTAL
    }

    final File imageFile = File(pickedFile.path);

    final String fileName =
        DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage
        .ref()
        .child('business_posts')
        .child(businessId)
        .child('$fileName.jpg');

    await ref.putFile(imageFile);

    final String downloadUrl = await ref.getDownloadURL();

    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('posts')
        .add({
      'imageUrl': downloadUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return true;
  }
}
