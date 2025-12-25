import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_paths.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() =>
      _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  bool loading = true;

  String weekdayStart = "08:00";
  String weekdayEnd = "22:00";
  String weekendStart = "08:00";
  String weekendEnd = "22:00";
  int sessionDuration = 50;
  int breakDuration = 10;

  /// 🔴 İPTAL KURALI (İŞLETME BELİRLER)
  int cancelBeforeHours = 6;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirestorePaths.businessDoc(uid).get();

    if (!doc.exists) {
      setState(() => loading = false);
      return;
    }

    final settings = doc.data()!['settings'] ?? {};

    setState(() {
      weekdayStart = settings['weekday']?['start'] ?? weekdayStart;
      weekdayEnd = settings['weekday']?['end'] ?? weekdayEnd;
      weekendStart = settings['weekend']?['start'] ?? weekendStart;
      weekendEnd = settings['weekend']?['end'] ?? weekendEnd;
      sessionDuration = settings['sessionDuration'] ?? sessionDuration;
      breakDuration = settings['breakDuration'] ?? breakDuration;

      /// 🔴 OKU
      cancelBeforeHours =
          settings['cancelBeforeHours'] ?? cancelBeforeHours;

      loading = false;
    });
  }

  Future<void> saveSettings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirestorePaths.businessDoc(uid).update({
      "settings": {
        "weekday": {"start": weekdayStart, "end": weekdayEnd},
        "weekend": {"start": weekendStart, "end": weekendEnd},
        "sessionDuration": sessionDuration,
        "breakDuration": breakDuration,

        /// 🔴 KAYDET
        "cancelBeforeHours": cancelBeforeHours,
      },
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ayarlar kaydedildi"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<String?> pickTime(String initial) async {
    final parts = initial.split(":");
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );

    if (picked == null) return null;

    return "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
  }

  Widget buildTimeField(
      String label, String value, Function(String) onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await pickTime(value);
        if (newTime != null) onChanged(newTime);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9C6C6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: const Color(0xFFE48989),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hafta İçi Çalışma Saatleri"),
                  const SizedBox(height: 8),
                  buildTimeField("Başlangıç", weekdayStart,
                      (v) => setState(() => weekdayStart = v)),
                  const SizedBox(height: 10),
                  buildTimeField("Bitiş", weekdayEnd,
                      (v) => setState(() => weekdayEnd = v)),

                  const SizedBox(height: 24),

                  const Text("Hafta Sonu Çalışma Saatleri"),
                  const SizedBox(height: 8),
                  buildTimeField("Başlangıç", weekendStart,
                      (v) => setState(() => weekendStart = v)),
                  const SizedBox(height: 10),
                  buildTimeField("Bitiş", weekendEnd,
                      (v) => setState(() => weekendEnd = v)),

                  const SizedBox(height: 24),

                  DropdownButtonFormField<int>(
                    value: sessionDuration,
                    decoration: const InputDecoration(
                      labelText: "Seans Süresi",
                    ),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text("30 dk")),
                      DropdownMenuItem(value: 40, child: Text("40 dk")),
                      DropdownMenuItem(value: 50, child: Text("50 dk")),
                      DropdownMenuItem(value: 60, child: Text("60 dk")),
                    ],
                    onChanged: (v) =>
                        setState(() => sessionDuration = v!),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: breakDuration,
                    decoration: const InputDecoration(
                      labelText: "Ara Süre",
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text("5 dk")),
                      DropdownMenuItem(value: 10, child: Text("10 dk")),
                      DropdownMenuItem(value: 15, child: Text("15 dk")),
                    ],
                    onChanged: (v) =>
                        setState(() => breakDuration = v!),
                  ),

                  const SizedBox(height: 32),

                  /// 🔴 İPTAL SÜRESİ AYARI (BURASI SENİN DEDİĞİN YER)
                  const Text(
                    "Randevu İptal Kuralı",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<int>(
                    value: cancelBeforeHours,
                    decoration: const InputDecoration(
                      labelText:
                          "Müşteri en geç kaç saat önce iptal edebilir?",
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("1 saat")),
                      DropdownMenuItem(value: 2, child: Text("2 saat")),
                      DropdownMenuItem(value: 4, child: Text("4 saat")),
                      DropdownMenuItem(value: 6, child: Text("6 saat")),
                      DropdownMenuItem(value: 12, child: Text("12 saat")),
                      DropdownMenuItem(value: 24, child: Text("24 saat")),
                    ],
                    onChanged: (v) =>
                        setState(() => cancelBeforeHours = v!),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton(
                    onPressed: saveSettings,
                    child: const Text("Kaydet"),
                  ),
                ],
              ),
            ),
    );
  }
}
