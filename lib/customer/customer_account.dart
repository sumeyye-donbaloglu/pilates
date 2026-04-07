import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import 'body_info.dart';

class CustomerAccount extends StatefulWidget {
  const CustomerAccount({super.key});

  @override
  State<CustomerAccount> createState() => _CustomerAccountState();
}

class _CustomerAccountState extends State<CustomerAccount> {
  final _name       = TextEditingController();
  final _email      = TextEditingController();
  final _phone      = TextEditingController();
  final _password   = TextEditingController();
  final _healthNote = TextEditingController();

  DateTime? _birthDate;
  String _gender = 'Kadın'; // varsayılan
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _healthNote.dispose();
    super.dispose();
  }

  // ── Tarih seçici
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      locale: const Locale('tr', 'TR'),
      helpText: 'Doğum Tarihi Seç',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  // ── Kayıt
  Future<void> _register() async {
    // Zorunlu alan kontrolü
    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _password.text.trim().isEmpty) {
      _snack("Lütfen tüm zorunlu alanları doldurun", Colors.orange);
      return;
    }
    if (_birthDate == null) {
      _snack("Lütfen doğum tarihinizi seçin", Colors.orange);
      return;
    }

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'uid':        uid,
        'name':       _name.text.trim(),
        'email':      _email.text.trim(),
        'phone':      _phone.text.trim(),
        'birthDate':  Timestamp.fromDate(_birthDate!),
        'gender':     _gender,
        'healthNote': _healthNote.text.trim(),
        'role':       'customer',
        'createdAt':  FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BodyInfoOnboardingScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _snack(_authError(e.code), Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Bu e-posta zaten kullanımda';
      case 'weak-password':        return 'Şifre en az 6 karakter olmalı';
      case 'invalid-email':        return 'Geçersiz e-posta adresi';
      default:                     return 'Bir hata oluştu, tekrar dene';
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.nunito()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Geri butonu
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Hesap Oluştur",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Pilates stüdyolarını keşfetmeye başla",
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ── FORM
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── KİŞİSEL BİLGİLER
                  _sectionTitle("Kişisel Bilgiler"),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _name,
                    label: "Ad Soyad *",
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _phone,
                    label: "Telefon Numarası *",
                    icon: Icons.phone_outlined,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // Doğum tarihi
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cake_outlined,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _birthDate == null
                                  ? "Doğum Tarihi *"
                                  : DateFormat('d MMMM y', 'tr_TR')
                                      .format(_birthDate!),
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: _birthDate == null
                                    ? AppColors.lavender
                                    : AppColors.text,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Cinsiyet seçici
                  _GenderSelector(
                    selected: _gender,
                    onSelect: (v) => setState(() => _gender = v),
                  ),

                  const SizedBox(height: 28),

                  // ── HESAP BİLGİLERİ
                  _sectionTitle("Hesap Bilgileri"),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _email,
                    label: "E-posta *",
                    icon: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Şifre
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: AppColors.text),
                    decoration: InputDecoration(
                      labelText: "Şifre *",
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                          color: AppColors.primary, size: 22),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      labelStyle: GoogleFonts.nunito(
                          color: AppColors.lavender, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── SAĞLIK NOTU
                  _sectionTitle("Sağlık Notu"),
                  const SizedBox(height: 6),
                  Text(
                    "Bel fıtığı, diz ameliyatı gibi bilgileri paylaşman,\neğitmeninin sana daha iyi yardımcı olmasını sağlar.",
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _healthNote,
                    maxLines: 3,
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: AppColors.text),
                    decoration: InputDecoration(
                      hintText:
                          "Örn: Sol dizimde ameliyat izim var, bel fıtığım mevcut...",
                      hintStyle: GoogleFonts.nunito(
                          color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 42),
                        child: Icon(Icons.health_and_safety_outlined,
                            color: AppColors.primary, size: 22),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── KAYDET BUTONU
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _register,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        _loading ? "Kaydediliyor..." : "Hesap Oluştur",
                        style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
          ],
        ),
      ),
    );
  }

  // ── Bölüm başlığı
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

  // ── Metin alanı
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style:
          GoogleFonts.nunito(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: AppColors.primary, size: 22),
        labelStyle: GoogleFonts.nunito(
            color: AppColors.lavender, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Cinsiyet seçici widget
class _GenderSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _GenderSelector(
      {required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              "Cinsiyet *",
              style: GoogleFonts.nunito(
                  color: AppColors.lavender, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Kadın', 'Erkek', 'Belirtmek istemiyorum']
              .map((g) {
            final active = selected == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    g == 'Belirtmek istemiyorum' ? 'Diğer' : g,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          active ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
