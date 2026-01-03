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

  /// 🔴 İPTAL KURALI
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
        "cancelBeforeHours": cancelBeforeHours,
      },
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ayarlar kaydedildi"),
        backgroundColor: Color(0xFFE48989),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE48989),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return null;

    return "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
  }

  Widget _timeTile(String label, String value, Function(String) onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await pickTime(value);
        if (newTime != null) onChanged(newTime);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8CFCF)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Color(0xFF9E6B6B))),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF7A4F4F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE48989),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8CFCF)),
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
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Hafta İçi Çalışma Saatleri"),
                  _timeTile("Başlangıç", weekdayStart,
                      (v) => setState(() => weekdayStart = v)),
                  const SizedBox(height: 12),
                  _timeTile("Bitiş", weekdayEnd,
                      (v) => setState(() => weekdayEnd = v)),

                  const SizedBox(height: 26),

                  _sectionTitle("Hafta Sonu Çalışma Saatleri"),
                  _timeTile("Başlangıç", weekendStart,
                      (v) => setState(() => weekendStart = v)),
                  const SizedBox(height: 12),
                  _timeTile("Bitiş", weekendEnd,
                      (v) => setState(() => weekendEnd = v)),

                  const SizedBox(height: 26),

                  DropdownButtonFormField<int>(
                    value: sessionDuration,
                    decoration: _dropdownDecoration("Seans Süresi"),
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
                    decoration: _dropdownDecoration("Ara Süre"),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text("5 dk")),
                      DropdownMenuItem(value: 10, child: Text("10 dk")),
                      DropdownMenuItem(value: 15, child: Text("15 dk")),
                    ],
                    onChanged: (v) =>
                        setState(() => breakDuration = v!),
                  ),

                  const SizedBox(height: 28),

                  _sectionTitle("Randevu İptal Kuralı"),
                  DropdownButtonFormField<int>(
                    value: cancelBeforeHours,
                    decoration: _dropdownDecoration(
                        "Müşteri en geç kaç saat önce iptal edebilir?"),
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

                  const SizedBox(height: 36),

                  GestureDetector(
                    onTap: saveSettings,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE48989),
                            Color(0xFFB07C7C),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE48989)
                                .withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Kaydet",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
