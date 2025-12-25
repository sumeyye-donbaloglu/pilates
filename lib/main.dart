import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'firestore_paths.dart';

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
    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1️⃣ Giriş yok
      if (user == null) {
        return const WelcomeScreen();
      }

      // 2️⃣ USERS → rol kontrolü
      final userDoc = await FirestorePaths.userDoc(user.uid).get();

      if (!userDoc.exists) {
        return const WelcomeScreen();
      }

      final data = userDoc.data()!;
      final role = data['role'];

      // 3️⃣ BUSINESS AKIŞI
      if (role == "business") {
        final businessDoc =
            await FirestorePaths.businessDoc(user.uid).get();

        // Business doc yoksa → onboarding'e düşür
        if (!businessDoc.exists) {
          return const WelcomeScreen();
        }

        return const BusinessHomeScreen();
      }

      // 4️⃣ CUSTOMER AKIŞI
      final completed = data['bodyInfoCompleted'] == true;

      if (!completed) {
        return const BodyInfoOnboardingScreen();
      }

      return const CustomerHomeScreen();
    } catch (e, s) {
      debugPrint("HANDLE USER ERROR: $e");
      debugPrintStack(stackTrace: s);
      return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
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
