import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';

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

  Future<void> registerBusiness() async {
    setState(() => _loading = true);

    try {
      // 1️⃣ AUTH
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;

      // 2️⃣ USERS → sadece kimlik & rol
      await FirestorePaths.userDoc(uid).set({
        "uid": uid,
        "email": _email.text.trim(),
        "role": "business",
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 3️⃣ BUSINESSES → işletmenin KALBİ
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İşletme hesabı oluşturuldu")),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Bir hata oluştu")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration input(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İşletme Hesabı Oluştur")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _businessName,
              decoration: input("İşletme Adı"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: input("Konum"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              decoration: input("E-posta"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: input("Şifre"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : registerBusiness,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Hesabı Oluştur"),
            ),
          ],
        ),
      ),
    );
  }
}
