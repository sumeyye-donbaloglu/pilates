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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF6F6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Vücut Bilgileri",
          style: TextStyle(
            color: Color(0xFF7A4F4F),
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
                  final uid = FirebaseAuth.instance.currentUser!.uid;

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
                      "createdAt": Timestamp.now(),
                    }
                  });

                  // Dashboard'a yönlendir
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerHomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A4F4F),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 40),
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
          labelStyle: const TextStyle(color: Color(0xFF7A4F4F)),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFFDDC3C3)),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF7A4F4F)),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
