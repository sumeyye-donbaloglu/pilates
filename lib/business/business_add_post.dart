import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/business_post_services.dart';

class BusinessAddPostScreen extends StatelessWidget {
  const BusinessAddPostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String businessId =
        FirebaseAuth.instance.currentUser!.uid;

    final service = BusinessPostService();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Fotoğraf Ekle"),
        backgroundColor: const Color(0xFFE48989),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text("Galeriden Fotoğraf Seç"),
          onPressed: () async {
            final success =
                await service.pickAndUploadPost(businessId);

            if (!context.mounted) return;

            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fotoğraf yüklendi ✅"),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
