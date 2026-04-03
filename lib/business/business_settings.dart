import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../firestore_paths.dart';
import '../theme/app_colors.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _loading = true;
  bool _saving = false;

  // Step 1 – Hafta içi
  String weekdayStart = "08:00";
  String weekdayEnd = "22:00";

  // Step 2 – Hafta sonu
  String weekendStart = "08:00";
  String weekendEnd = "22:00";

  // Step 3 – Randevu ayarları
  int sessionDuration = 50;
  int breakDuration = 10;
  int cancelBeforeHours = 6;

  // Step 4 – Reformer sayısı
  int reformerCount = 2;

  static const _stepTitles = [
    "Hafta İçi\nÇalışma Saatleri",
    "Hafta Sonu\nÇalışma Saatleri",
    "Randevu\nAyarları",
    "Reformer\nCihaz Sayısı",
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirestorePaths.businessDoc(uid).get();

    if (!doc.exists) {
      setState(() => _loading = false);
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
      cancelBeforeHours = settings['cancelBeforeHours'] ?? cancelBeforeHours;
      reformerCount = settings['reformerCount'] ?? reformerCount;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirestorePaths.businessDoc(uid).update({
        "settings": {
          "weekday": {"start": weekdayStart, "end": weekdayEnd},
          "weekend": {"start": weekendStart, "end": weekendEnd},
          "sessionDuration": sessionDuration,
          "breakDuration": breakDuration,
          "cancelBeforeHours": cancelBeforeHours,
          "reformerCount": reformerCount,
        },
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ayarlar kaydedildi ✓"),
          backgroundColor: AppColors.accentTeal,
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<String?> _pickTime(String initial) async {
    final parts = initial.split(":");
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    return "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────────────

  Widget _timeCard(String label, String value, Function(String) onChanged) {
    return GestureDetector(
      onTap: () async {
        final t = await _pickTime(value);
        if (t != null) setState(() => onChanged(t));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(label,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownCard<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    IconData icon = Icons.tune_rounded,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.nunito(color: AppColors.textMuted),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: GoogleFonts.nunito(
          color: AppColors.deepIndigo,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _stepContainer({
    required int step,
    required Widget content,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // step badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Adım ${step + 1} / 4",
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            _stepTitles[step],
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.deepIndigo,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          content,
        ],
      ),
    );
  }

  // ─── PAGE 0: Hafta İçi ────────────────────────────────────────────

  Widget _weekdayPage() {
    return _stepContainer(
      step: 0,
      content: Column(
        children: [
          _timeCard("Açılış Saati", weekdayStart,
              (v) => weekdayStart = v),
          const SizedBox(height: 16),
          _timeCard("Kapanış Saati", weekdayEnd,
              (v) => weekdayEnd = v),
          const SizedBox(height: 24),
          _infoBox(
            icon: Icons.info_outline_rounded,
            text:
                "Pazartesi – Cuma arası çalışma saatlerinizi belirleyin. Bu saatler dışında randevu oluşturulamaz.",
          ),
        ],
      ),
    );
  }

  // ─── PAGE 1: Hafta Sonu ───────────────────────────────────────────

  Widget _weekendPage() {
    return _stepContainer(
      step: 1,
      content: Column(
        children: [
          _timeCard("Açılış Saati", weekendStart,
              (v) => weekendStart = v),
          const SizedBox(height: 16),
          _timeCard("Kapanış Saati", weekendEnd,
              (v) => weekendEnd = v),
          const SizedBox(height: 24),
          _infoBox(
            icon: Icons.info_outline_rounded,
            text:
                "Cumartesi – Pazar arası çalışma saatlerinizi belirleyin. Hafta sonu çalışmıyorsanız saatleri aynı bırakabilirsiniz.",
          ),
        ],
      ),
    );
  }

  // ─── PAGE 2: Randevu Ayarları ─────────────────────────────────────

  Widget _appointmentPage() {
    return _stepContainer(
      step: 2,
      content: Column(
        children: [
          _dropdownCard<int>(
            label: "Seans Süresi",
            value: sessionDuration,
            icon: Icons.timer_outlined,
            items: const [
              DropdownMenuItem(value: 30, child: Text("30 dakika")),
              DropdownMenuItem(value: 40, child: Text("40 dakika")),
              DropdownMenuItem(value: 50, child: Text("50 dakika")),
              DropdownMenuItem(value: 60, child: Text("60 dakika")),
            ],
            onChanged: (v) => setState(() => sessionDuration = v!),
          ),
          const SizedBox(height: 16),
          _dropdownCard<int>(
            label: "Seanslar Arası Mola",
            value: breakDuration,
            icon: Icons.pause_circle_outline_rounded,
            items: const [
              DropdownMenuItem(value: 5, child: Text("5 dakika")),
              DropdownMenuItem(value: 10, child: Text("10 dakika")),
              DropdownMenuItem(value: 15, child: Text("15 dakika")),
            ],
            onChanged: (v) => setState(() => breakDuration = v!),
          ),
          const SizedBox(height: 16),
          _dropdownCard<int>(
            label: "İptal Süresi Limiti",
            value: cancelBeforeHours,
            icon: Icons.cancel_outlined,
            items: const [
              DropdownMenuItem(value: 1, child: Text("Randevudan 1 saat önce")),
              DropdownMenuItem(value: 2, child: Text("Randevudan 2 saat önce")),
              DropdownMenuItem(value: 4, child: Text("Randevudan 4 saat önce")),
              DropdownMenuItem(value: 6, child: Text("Randevudan 6 saat önce")),
              DropdownMenuItem(
                  value: 12, child: Text("Randevudan 12 saat önce")),
              DropdownMenuItem(
                  value: 24, child: Text("Randevudan 24 saat önce")),
            ],
            onChanged: (v) => setState(() => cancelBeforeHours = v!),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 3: Reformer Sayısı ──────────────────────────────────────

  Widget _reformerPage() {
    return _stepContainer(
      step: 3,
      content: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.fitness_center_rounded,
                    color: AppColors.primary, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Aktif Reformer Sayısı",
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _counterButton(
                      icon: Icons.remove_rounded,
                      onTap: reformerCount > 1
                          ? () => setState(() => reformerCount--)
                          : null,
                    ),
                    const SizedBox(width: 32),
                    Text(
                      "$reformerCount",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepIndigo,
                      ),
                    ),
                    const SizedBox(width: 32),
                    _counterButton(
                      icon: Icons.add_rounded,
                      onTap: reformerCount < 20
                          ? () => setState(() => reformerCount++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "cihaz",
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _infoBox(
            icon: Icons.info_outline_rounded,
            text:
                "Aynı saate alınabilecek maksimum müşteri sayısını belirler. Bakımda olan cihazları çıkararak girin.",
          ),
        ],
      ),
    );
  }

  Widget _counterButton({required IconData icon, VoidCallback? onTap}) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }

  Widget _infoBox({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.purple,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────

  Widget _bottomNav() {
    final isLast = _currentPage == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            GestureDetector(
              onTap: _prevPage,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: GestureDetector(
              onTap: isLast ? _saveSettings : _nextPage,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          isLast ? "Kaydet" : "İleri",
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROGRESS DOTS ────────────────────────────────────────────────

  Widget _progressDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Salon Ayarları",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _progressDots(),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _weekdayPage(),
                      _weekendPage(),
                      _appointmentPage(),
                      _reformerPage(),
                    ],
                  ),
                ),
                _bottomNav(),
              ],
            ),
    );
  }
}
