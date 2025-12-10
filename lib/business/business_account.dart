import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  Future<void> registerBusiness() async {
    setState(() => _loading = true);

    try {
      /// Firebase Auth – create user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = userCredential.user!.uid;

      /// Firestore – create business document with new professional model
      await _firestore.collection('users').doc(uid).set({
        "role": "business",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),

        /// İşletme bilgileri
        "businessInfo": {
          "name": _businessName.text.trim(),
          "location": _location.text.trim(),
          "email": _email.text.trim(),
        },

        /// Ayarlar (tek noktada)
        "settings": {
          "weekday": {
            "start": "08:00",
            "end": "22:00",
          },
          "weekend": {
            "start": "08:00",
            "end": "22:00",
          },
          "sessionDuration": 50,
          "breakDuration": 10,
        },

        /// Cihaz sayısı
        "reformerCount": 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İşletme hesabı başarıyla oluşturuldu!")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.message}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration customInput(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF6A4E4E)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9C6C6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBFA9A9), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8CFCF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "İşletme Hesabı Oluştur",
          style: TextStyle(
            color: Color(0xFF6A4E4E),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text(
                'İşletme Bilgileri',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A4E4E),
                ),
              ),
              const SizedBox(height: 25),

              TextField(
                controller: _businessName,
                decoration: customInput("İşletme Adı"),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _location,
                decoration: customInput("Konum"),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _email,
                decoration: customInput("E-posta"),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _password,
                obscureText: true,
                decoration: customInput("Şifre"),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : registerBusiness,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8CFCF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Hesabı Oluştur",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFBFA9A9), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Geri Dön",
                    style: TextStyle(
                      color: Color(0xFF6A4E4E),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
