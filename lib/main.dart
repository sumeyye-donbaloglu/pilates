import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Firebase yapılandırma dosyası
import 'welcome.dart'; // Welcome ekranı

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Firebase başlatmadan önce gerekli
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(), // Uygulama ilk açıldığında bu ekran gelir
    );
  }
}
