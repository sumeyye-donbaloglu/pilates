import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:cloud_firestore/cloud_firestore.dart";
class CustomerAccount extends StatefulWidget {
  const CustomerAccount({super.key});

  @override
  State<CustomerAccount> createState() => _CustomerAccountState();
}

class _CustomerAccountState extends State<CustomerAccount> {
  // 🔹 TextField controller'ları
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🔹 FirebaseAuth örneği
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _data = FirebaseFirestore.instance;
  bool _loading = false;
   bool ok =true;

  // 🔹 Kullanıcı oluşturma fonksiyonu
  Future<void> _registerCustomer() async {
    setState(() => _loading = true);

    try {
      setState(() {
        ok=false;
      });
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
       setState(() {
         if(userCredential.user?.email== null){
           ok =false;
         }else{
           ok = true;
         }
       });



       // başarıyla oluşturulduysa mesaj göster

      if(ok ==true){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri hesabı başarıyla oluşturuldu!')),
        );
      }


      print("Kayıtlı kullanıcı UID: ${userCredential.user?.uid}");
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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteri Hesabı Oluştur'),
        backgroundColor: const Color(0xFFB07C7C),
        centerTitle: true,
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
                'Üye Bilgileri',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7A4F4F)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Ad Soyad
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
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

              // Telefon
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
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
                onPressed: _loading ? null : _registerCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDBB5B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Hesabı Oluştur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                ),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(
                    color: Color(0xFF987070),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
