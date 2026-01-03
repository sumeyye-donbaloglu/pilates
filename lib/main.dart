import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ EKLENDİ

import 'firebase_options.dart';
import 'firestore_paths.dart';

import 'welcome.dart';
import 'business/business_home.dart';
import 'customer/customer_home.dart';
import 'customer/body_info.dart';

import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ TÜRKÇE TARİH FORMATLARI (EEEE, d MMMM y vs.)
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // --------------------------------------------------
  // 🔁 LOGIN + ROLE + ONBOARDING AKIŞI
  // --------------------------------------------------
  Future<Widget> _handleUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // 1️⃣ GİRİŞ YOK
      if (user == null) {
        return const WelcomeScreen();
      }

      // 2️⃣ USERS → ROL KONTROLÜ
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

        // Business doc yoksa → güvenli fallback
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

  // --------------------------------------------------
  // 🧱 APP ROOT
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 🎨 GLOBAL TEMA
      theme: AppTheme.lightTheme,

      home: FutureBuilder<Widget>(
        future: _handleUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
