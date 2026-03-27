import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../customer/customer_home.dart';

class BodyInfoOnboardingScreen extends StatefulWidget {
  const BodyInfoOnboardingScreen({super.key});

  @override
  State<BodyInfoOnboardingScreen> createState() =>
      _BodyInfoOnboardingScreenState();
}

class _BodyInfoOnboardingScreenState
    extends State<BodyInfoOnboardingScreen> {
  // ── Kontrolcüler
  final _height      = TextEditingController(); // Boy
  final _weight      = TextEditingController(); // Kilo
  final _neck        = TextEditingController(); // Boyun
  final _waist       = TextEditingController(); // Bel
  final _lowerAb     = TextEditingController(); // Alt Karın
  final _hip         = TextEditingController(); // Basen
  final _rightArm    = TextEditingController(); // Sağ Kol
  final _leftArm     = TextEditingController(); // Sol Kol
  final _rightLeg    = TextEditingController(); // Sağ Bacak
  final _leftLeg     = TextEditingController(); // Sol Bacak

  bool _saving = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _neck.dispose();
    _waist.dispose();
    _lowerAb.dispose();
    _hip.dispose();
    _rightArm.dispose();
    _leftArm.dispose();
    _rightLeg.dispose();
    _leftLeg.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("Kullanıcı oturumu hazır değil", Colors.red);
      return;
    }

    if (_height.text.trim().isEmpty || _weight.text.trim().isEmpty) {
      _snack("Boy ve kilo alanları zorunludur", Colors.orange);
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = user.uid;
      final now = Timestamp.now();

      final bodyInfo = {
        "height":   _parse(_height),
        "weight":   _parse(_weight),
        "neck":     _parse(_neck),
        "waist":    _parse(_waist),
        "lowerAb":  _parse(_lowerAb),
        "hip":      _parse(_hip),
        "rightArm": _parse(_rightArm),
        "leftArm":  _parse(_leftArm),
        "rightLeg": _parse(_rightLeg),
        "leftLeg":  _parse(_leftLeg),
        "createdAt": now,
      };

      // Ana kullanıcı dokümanı
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "bodyInfoCompleted": true,
        "bodyInfo": bodyInfo,
      });

      // İlk ölçümü subcollection'a kaydet (grafik için)
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("bodyMeasurements")
          .add({
        ...bodyInfo,
        "date":      now,
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      );
    } catch (e) {
      if (mounted) _snack(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── HEADER
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          "Vücut Ölçülerin",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Başlangıç ölçülerini gir, ilerlemeni grafik\nüzerinde takip et.",
                          style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                "Vücut Ölçüleri",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
            ),
          ),

          // ── FORM
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GENEL
                  _sectionTitle("Genel Bilgiler"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _Field(
                              ctrl: _height,
                              label: "Boy *",
                              unit: "cm",
                              icon: Icons.height_rounded)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _Field(
                              ctrl: _weight,
                              label: "Kilo *",
                              unit: "kg",
                              icon: Icons.monitor_weight_outlined)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Field(
                      ctrl: _neck,
                      label: "Boyun",
                      unit: "cm",
                      icon: Icons.accessibility_new_rounded),

                  const SizedBox(height: 28),

                  // GÖVDE
                  _sectionTitle("Gövde Ölçüleri"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _Field(
                              ctrl: _waist,
                              label: "Bel",
                              unit: "cm",
                              icon: Icons.straighten_rounded)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _Field(
                              ctrl: _lowerAb,
                              label: "Alt Karın",
                              unit: "cm",
                              icon: Icons.straighten_rounded)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Field(
                      ctrl: _hip,
                      label: "Basen",
                      unit: "cm",
                      icon: Icons.straighten_rounded),

                  const SizedBox(height: 28),

                  // KOL
                  _sectionTitle("Kol Ölçüleri"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _Field(
                              ctrl: _rightArm,
                              label: "Sağ Kol",
                              unit: "cm",
                              icon: Icons.fitness_center_rounded)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _Field(
                              ctrl: _leftArm,
                              label: "Sol Kol",
                              unit: "cm",
                              icon: Icons.fitness_center_rounded)),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // BACAK
                  _sectionTitle("Bacak Ölçüleri"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _Field(
                              ctrl: _rightLeg,
                              label: "Sağ Bacak",
                              unit: "cm",
                              icon: Icons.directions_walk_rounded)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: _Field(
                              ctrl: _leftLeg,
                              label: "Sol Bacak",
                              unit: "cm",
                              icon: Icons.directions_walk_rounded)),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // KAYDET
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _saving ? "Kaydediliyor..." : "Devam Et",
                        style: GoogleFonts.nunito(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "* ile işaretli alanlar zorunludur",
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.deepIndigo,
          ),
        ),
      ],
    );
  }
}

// ── Alan widget'ı
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String unit;
  final IconData icon;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.nunito(
          fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        prefixIcon: Icon(icon, color: AppColors.lavender, size: 20),
        labelStyle: GoogleFonts.nunito(
            color: AppColors.lavender, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
        isDense: true,
      ),
    );
  }
}
