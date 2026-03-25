import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../firestore_paths.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_colors.dart';

class BusinessEditProfileScreen extends StatefulWidget {
  final String businessId;

  const BusinessEditProfileScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessEditProfileScreen> createState() =>
      _BusinessEditProfileScreenState();
}

class _BusinessEditProfileScreenState
    extends State<BusinessEditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _currentPhotoUrl; // Firestore'daki mevcut fotoğraf URL'si
  File? _pickedImage;       // Kullanıcının seçtiği yeni fotoğraf (henüz yüklenmedi)
  bool _loading = true;     // İlk veri yükleme
  bool _saving = false;     // Kaydetme işlemi

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  /// Firestore'dan mevcut profil bilgilerini çekip TextFieldları doldurur.
  Future<void> _loadCurrentData() async {
    final doc = await FirestorePaths.businessDoc(widget.businessId).get();
    if (!doc.exists) {
      setState(() => _loading = false);
      return;
    }
    final info = Map<String, dynamic>.from(doc.data()?['businessInfo'] ?? {});
    _nameCtrl.text     = info['name']     ?? '';
    _locationCtrl.text = info['location'] ?? '';
    _bioCtrl.text      = info['bio']      ?? '';
    _currentPhotoUrl   = info['photoUrl'] as String?;
    setState(() => _loading = false);
  }

  /// Galeriden fotoğraf seçer ve önizleme için `_pickedImage`'a atar.
  /// Henüz Cloudinary'e yüklemez — kaydet butonuna basıldığında yüklenecek.
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  /// Kaydet:
  /// 1. Yeni fotoğraf seçildiyse Cloudinary'e yükle, URL al
  /// 2. Firestore'daki businessInfo alanını güncelle
  Future<void> _save() async {
    final name     = _nameCtrl.text.trim();
    final location = _locationCtrl.text.trim();
    final bio      = _bioCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İşletme adı boş bırakılamaz")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Yeni fotoğraf varsa yükle
      String? photoUrl = _currentPhotoUrl;
      if (_pickedImage != null) {
        final uploaded = await CloudinaryService.uploadImage(_pickedImage!);
        if (uploaded != null) photoUrl = uploaded;
      }

      // Firestore güncelle
      await FirestorePaths.businessDoc(widget.businessId).update({
        'businessInfo.name':     name,
        'businessInfo.location': location,
        'businessInfo.bio':      bio,
        if (photoUrl != null) 'businessInfo.photoUrl': photoUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil güncellendi ✓"),
          backgroundColor: AppColors.accentTeal,
        ),
      );
      Navigator.pop(context, true); // true -> profil ekranı yenilesin
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Profili Düzenle",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_saving)
            TextButton(
              onPressed: _save,
              child: Text(
                "Kaydet",
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── PROFİL FOTOĞRAFI
                  Center(
                    child: Stack(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _pickedImage != null
                                  // Yeni seçilen fotoğraf (önizleme)
                                  ? Image.file(_pickedImage!,
                                      fit: BoxFit.cover)
                                  : _currentPhotoUrl != null
                                      // Mevcut Cloudinary fotoğrafı
                                      ? Image.network(_currentPhotoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _defaultIcon())
                                      // Henüz fotoğraf yok
                                      : _defaultIcon(),
                            ),
                          ),
                        ),
                        // Düzenleme ikonu
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.purple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.background, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Fotoğrafı değiştirmek için dokun",
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── FORM ALANLARI
                  _SectionLabel("İşletme Adı"),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _nameCtrl,
                    hint: "örn. NTYA Pilates Studio",
                    icon: Icons.store_rounded,
                  ),

                  const SizedBox(height: 20),

                  _SectionLabel("Konum"),
                  const SizedBox(height: 8),
                  _Field(
                    controller: _locationCtrl,
                    hint: "örn. Konya / Selçuklu",
                    icon: Icons.location_on_rounded,
                  ),

                  const SizedBox(height: 20),

                  _SectionLabel("İşletme Hakkında"),
                  const SizedBox(height: 4),
                  Text(
                    "Müşterilerinizin sizi tanıyabilmesi için kısa bir tanıtım yazın.",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 5,
                    maxLength: 400,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.text,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "Reformer pilates salonumuzda deneyimli eğitmenlerimizle...",
                      hintStyle: GoogleFonts.nunito(
                        color: AppColors.textLight,
                        fontSize: 14,
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
                            color: AppColors.primary, width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── KAYDET BUTONU
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
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? "Kaydediliyor..." : "Kaydet"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _defaultIcon() {
    return const Icon(Icons.store_rounded, color: Colors.white, size: 48);
  }
}

// ── Küçük yardımcı widget'lar
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.deepIndigo,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.lavender, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
