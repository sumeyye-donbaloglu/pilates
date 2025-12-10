import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/daily_slot_service.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  bool loading = true;
  bool generating = false;

  // Settings fields
  String weekdayStart = "08:00";
  String weekdayEnd = "22:00";
  String weekendStart = "08:00";
  String weekendEnd = "22:00";
  int sessionDuration = 50;
  int breakDuration = 10;

  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  /// 🔥 Load NEW settings structure
  Future<void> loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _firestore.collection("users").doc(uid).get();

    if (!doc.exists || doc.data()!["settings"] == null) {
      setState(() => loading = false);
      return;
    }

    final settings = doc.data()!["settings"];

    setState(() {
      weekdayStart = settings["weekday"]["start"];
      weekdayEnd = settings["weekday"]["end"];
      weekendStart = settings["weekend"]["start"];
      weekendEnd = settings["weekend"]["end"];
      sessionDuration = settings["sessionDuration"];
      breakDuration = settings["breakDuration"];
      loading = false;
    });
  }

  /// 🔥 Save UPDATED nested settings object
  Future<void> saveSettings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _firestore.collection("users").doc(uid).update({
      "settings": {
        "weekday": { "start": weekdayStart, "end": weekdayEnd },
        "weekend": { "start": weekendStart, "end": weekendEnd },
        "sessionDuration": sessionDuration,
        "breakDuration": breakDuration,
      },
      "updatedAt": FieldValue.serverTimestamp()
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Ayarlar başarıyla kaydedildi!"),
        backgroundColor: Color(0xFFE48989),
      ),
    );
  }

  /// Weekly slot generator stays same
  Future<void> generateSlotsForWeek() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final service = DailySlotService();

    setState(() => generating = true);

    final now = DateTime.now();
    final startOfWeek =
        now.subtract(Duration(days: now.weekday - 1)); // Monday

    for (int i = 0; i < 7; i++) {
      final d = startOfWeek.add(Duration(days: i));
      final dateStr =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

      await service.generateDailySlots(uid, dateStr);
    }

    setState(() => generating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bu hafta için slotlar oluşturuldu."),
        backgroundColor: Color(0xFF6A4CC3),
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

  Widget buildTimeField(String label, String value, Function(String) onChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await pickTime(value);
        if (newTime != null) onChanged(newTime);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD9C6C6)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6A4E4E),
                    fontWeight: FontWeight.w500)),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6A4E4E),
                  fontWeight: FontWeight.bold),
            ),
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
                  const Text(
                    "Hafta İçi Çalışma Saatleri",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A4E4E)),
                  ),
                  const SizedBox(height: 10),
                  buildTimeField("Başlangıç", weekdayStart,
                      (v) => setState(() => weekdayStart = v)),
                  const SizedBox(height: 10),
                  buildTimeField("Bitiş", weekdayEnd,
                      (v) => setState(() => weekdayEnd = v)),

                  const SizedBox(height: 25),

                  const Text(
                    "Hafta Sonu Çalışma Saatleri",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A4E4E)),
                  ),
                  const SizedBox(height: 10),
                  buildTimeField("Başlangıç", weekendStart,
                      (v) => setState(() => weekendStart = v)),
                  const SizedBox(height: 10),
                  buildTimeField("Bitiş", weekendEnd,
                      (v) => setState(() => weekendEnd = v)),

                  const SizedBox(height: 25),

                  const Text(
                    "Seans Süresi",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A4E4E)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: sessionDuration,
                    decoration: _dropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text("30 dakika")),
                      DropdownMenuItem(value: 40, child: Text("40 dakika")),
                      DropdownMenuItem(value: 45, child: Text("45 dakika")),
                      DropdownMenuItem(value: 50, child: Text("50 dakika")),
                      DropdownMenuItem(value: 60, child: Text("60 dakika")),
                    ],
                    onChanged: (v) => setState(() => sessionDuration = v!),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Mola Süresi",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A4E4E)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: breakDuration,
                    decoration: _dropdownDecoration(),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text("5 dakika")),
                      DropdownMenuItem(value: 10, child: Text("10 dakika")),
                      DropdownMenuItem(value: 15, child: Text("15 dakika")),
                      DropdownMenuItem(value: 20, child: Text("20 dakika")),
                    ],
                    onChanged: (v) => setState(() => breakDuration = v!),
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE48989),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "Kaydet",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: generating ? null : generateSlotsForWeek,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A4CC3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: generating
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : const Text(
                              "Haftalık Slotları Oluştur",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD9C6C6)),
      ),
    );
  }
}
