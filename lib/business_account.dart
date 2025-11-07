import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessAccount extends StatefulWidget {
  const BusinessAccount({super.key});

  @override
  State<BusinessAccount> createState() => _BusinessAccountState();
}

class _BusinessAccountState extends State<BusinessAccount> {
  // 🔹 Controller'lar
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  // 🔹 İşletme hesabı oluşturma fonksiyonu
  Future<void> _registerBusiness() async {
    setState(() => _loading = true);

    try {
      // Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Firestore'a işletme bilgilerini kaydet
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'businessName': _businessNameController.text.trim(),
          'email': _emailController.text.trim(),
          'location': _locationController.text.trim(),
          'role': 'business', // 🔹 işletme rolü
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşletme hesabı başarıyla oluşturuldu!')),
        );

        print("İşletme UID: ${user.uid}");
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta adresi zaten kayıtlı.';
      } else if (e.code == 'weak-password') {
        message = 'Şifre en az 6 karakter olmalı.';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi.';
      } else {
        message = 'Bir hata oluştu: ${e.message}';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İşletme Hesabı Oluştur'),
        backgroundColor: const Color(0xFFB07C7C),
        centerTitle: true,
        elevation: 2,
      ),
      backgroundColor: const Color(0xFFFFF6F6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'İşletme Bilgileri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A4F4F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // İşletme adı
              TextField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'İşletme Adı',
                  labelStyle: TextStyle(color: Color(0xFF987070)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Konum
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Konum',
                  labelStyle: TextStyle(color: Color(0xFF987070)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // E-posta
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  labelStyle: TextStyle(color: Color(0xFF987070)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  labelStyle: TextStyle(color: Color(0xFF987070)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Kayıt butonu
              ElevatedButton(
                onPressed: _loading ? null : _registerBusiness,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDBB5B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Hesabı Oluştur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Geri dön
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF987070), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(
                    color: Color(0xFF987070),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
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
