import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'welcome.dart';
import 'business/business_home.dart';
import 'customer/customer_home.dart';
import 'customer/body_info.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _handleUser() async {
    final user = FirebaseAuth.instance.currentUser;

    // Eğer giriş yapılmamışsa
    if (user == null) return const WelcomeScreen();

    // Firestore’dan kullanıcı belgesini al
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return const WelcomeScreen();

    final data = doc.data()!;
    final role = data['role'];

    // 🔥 1) İşletmeyse direkt BusinessHome
    if (role == "business") {
      return const BusinessHomeScreen();
    }

    // 🔥 2) Müşteriyse → önce bodyInfoCompleted kontrolü
    final bool completed = data['bodyInfoCompleted'] ?? false;

    if (!completed) {
      return const BodyInfoOnboardingScreen(); // Vücut bilgisi ekranı
    }

    // 🔥 3) Tamamlanmışsa dashboard
    return const CustomerHomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: FutureBuilder(
        future: _handleUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data!;
        },
      ),
    );
  }
}
