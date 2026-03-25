import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../customer/customer_home.dart';

class BodyInfoOnboardingScreen extends StatefulWidget {
  const BodyInfoOnboardingScreen({super.key});

  @override
  State<BodyInfoOnboardingScreen> createState() =>
      _BodyInfoOnboardingScreenState();
}

class _BodyInfoOnboardingScreenState extends State<BodyInfoOnboardingScreen> {
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipController = TextEditingController();
  final TextEditingController fatController = TextEditingController();

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    waistController.dispose();
    hipController.dispose();
    fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Vücut Bilgileri",
          style: TextStyle(
            color: AppColors.deepIndigo,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField("Boy (cm)", heightController),
            _buildField("Kilo (kg)", weightController),
            _buildField("Bel Çevresi (cm)", waistController),
            _buildField("Kalça Çevresi (cm)", hipController),
            _buildField("Yağ Oranı (%) - opsiyonel", fatController),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  // 🔐 GÜVENLİ AUTH KONTROLÜ
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Kullanıcı oturumu henüz hazır değil"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final uid = user.uid;

                  try {
                    final now = Timestamp.now();

                    // Ana kullanıcı dokümanını güncelle
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(uid)
                        .update({
                      "bodyInfoCompleted": true,
                      "bodyInfo": {
                        "height": heightController.text.trim(),
                        "weight": weightController.text.trim(),
                        "waist": waistController.text.trim(),
                        "hip": hipController.text.trim(),
                        "fatPercent": fatController.text.trim(),
                        "createdAt": now,
                      }
                    });

                    // İlk ölçümü subcollection'a da kaydet (grafik için)
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(uid)
                        .collection("bodyMeasurements")
                        .add({
                      "weight": double.tryParse(weightController.text.trim()) ?? 0,
                      "waist":  double.tryParse(waistController.text.trim()) ?? 0,
                      "hip":    double.tryParse(hipController.text.trim()) ?? 0,
                      "fatPercent": double.tryParse(fatController.text.trim()) ?? 0,
                      "date":      now,
                      "createdAt": FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;

                    // Dashboard'a yönlendir
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerHomeScreen(),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll("Exception: ", ""),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepIndigo,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Devam Et",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.deepIndigo),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.deepIndigo),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
