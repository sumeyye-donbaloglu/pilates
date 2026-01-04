import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/business_post_services.dart';

class BusinessAddPostScreen extends StatefulWidget {
  const BusinessAddPostScreen({super.key});

  @override
  State<BusinessAddPostScreen> createState() =>
      _BusinessAddPostScreenState();
}

class _BusinessAddPostScreenState
    extends State<BusinessAddPostScreen> {
  bool uploading = false;

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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 40,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Color(0xFFE48989),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Galeriden bir fotoğraf seçerek\nprofilinde paylaş",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF7A4F4F),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(
                        uploading
                            ? "Yükleniyor..."
                            : "Galeriden Fotoğraf Seç",
                      ),
                      onPressed: uploading
                          ? null
                          : () async {
                              setState(() {
                                uploading = true;
                              });

                              final success =
                                  await service.pickAndUploadPost(
                                businessId,
                              );

                              if (!mounted) return;

                              setState(() {
                                uploading = false;
                              });

                              if (success) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Fotoğraf yüklendi ✅"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Fotoğraf yüklenemedi ❌"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFE48989),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
