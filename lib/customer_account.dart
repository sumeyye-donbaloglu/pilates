import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAccount extends StatefulWidget {
  const CustomerAccount({super.key});

  @override
  State<CustomerAccount> createState() => _CustomerAccountState();
}

class _CustomerAccountState extends State<CustomerAccount> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _loading = false;

  Future<void> registerCustomer() async {
    setState(() => _loading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müşteri hesabı başarıyla oluşturuldu!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${e.message}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Hesabı Oluştur'), backgroundColor: const Color(0xFFB07C7C)),
      backgroundColor: const Color(0xFFFFF6F6),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('Üye Bilgileri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7A4F4F))),
              const SizedBox(height: 30),
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Ad Soyad', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'E-posta', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Telefon Numarası', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Şifre', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : registerCustomer,
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
