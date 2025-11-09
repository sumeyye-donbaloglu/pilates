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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'businessName': _businessName.text.trim(),
        'location': _location.text.trim(),
        'email': _email.text.trim(),
        'role': 'business',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşletme hesabı başarıyla oluşturuldu!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.message}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İşletme Hesabı Oluştur'), backgroundColor: const Color(0xFFB07C7C)),
      backgroundColor: const Color(0xFFFFF6F6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('İşletme Bilgileri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7A4F4F))),
              const SizedBox(height: 30),
              TextField(controller: _businessName, decoration: const InputDecoration(labelText: 'İşletme Adı', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _location, decoration: const InputDecoration(labelText: 'Konum', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : registerBusiness,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDBB5B5), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Hesabı Oluştur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Geri Dön')),
            ],
          ),
        ),
      ),
    );
  }
}
