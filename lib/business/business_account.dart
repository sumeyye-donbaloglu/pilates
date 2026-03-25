import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';
import '../theme/app_colors.dart';

class BusinessAccount extends StatefulWidget {
  const BusinessAccount({super.key});

  @override
  State<BusinessAccount> createState() => _BusinessAccountState();
}

class _BusinessAccountState extends State<BusinessAccount> {
  final _businessName = TextEditingController();
  final _location = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _auth = FirebaseAuth.instance;
  bool _loading = false;

  // --------------------------------------------------
  // REGISTER BUSINESS
  // --------------------------------------------------
  Future<void> registerBusiness() async {
    setState(() => _loading = true);

    try {
      // 1️⃣ AUTH
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;

      // 2️⃣ USERS → kimlik & rol
      await FirestorePaths.userDoc(uid).set({
        "uid": uid,
        "name": _businessName.text.trim(), // ✅ EKLENDİ
        "email": _email.text.trim(),
        "role": "business",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 3️⃣ BUSINESSES → işletme ana dokümanı
      await FirestorePaths.businessDoc(uid).set({
        "businessInfo": {
          "name": _businessName.text.trim(),
          "location": _location.text.trim(),
          "email": _email.text.trim(),
        },
        "settings": {
          "weekday": {"start": "08:00", "end": "22:00"},
          "weekend": {"start": "08:00", "end": "22:00"},
          "sessionDuration": 50,
          "breakDuration": 10,
        },
        "reformerCount": 0,
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İşletme hesabı oluşturuldu"),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Bir hata oluştu")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --------------------------------------------------
  // INPUT
  // --------------------------------------------------
  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: AppColors.deepIndigo),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("İşletme Hesabı Oluştur"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),

              const Text(
                "İşletme Bilgileri",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepIndigo,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Salonunu oluştur, randevu almaya hemen başla",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _businessName,
                decoration: _input(
                    "İşletme Adı", Icons.storefront_outlined),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _location,
                decoration:
                    _input("Konum", Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    _input("E-posta", Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _password,
                obscureText: true,
                decoration:
                    _input("Şifre", Icons.lock_outline),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _loading ? null : registerBusiness,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "İşletme Hesabını Oluştur"),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppColors.primary),
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Geri Dön",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepIndigo,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}