import 'package:flutter/material.dart';

class AppColors {
  // ── Ana tonlar (Indigo → Violet)
  static const deepIndigo   = Color(0xFF1E1B4B); // en koyu, başlıklar
  static const primary      = Color(0xFF4F46E5); // ana indigo
  static const purple       = Color(0xFF7C3AED); // violet
  static const lavender     = Color(0xFF8B5CF6); // açık violet
  static const softLavender = Color(0xFFA78BFA); // çok açık violet

  // ── Arka plan & yüzey
  static const background   = Color(0xFFF5F3FF); // çok açık lavender
  static const surface      = Color(0xFFFFFFFF); // kart yüzeyi
  static const surfaceTint  = Color(0xFFEDE9FE); // hafif mor tint

  // ── Kenarlık & ayırıcı
  static const border       = Color(0xFFDDD6FE); // açık mor kenarlık

  // ── Metin
  static const text         = Color(0xFF1E1B4B); // koyu indigo metin
  static const textMuted    = Color(0xFF6B7280); // gri metin
  static const textLight    = Color(0xFF9CA3AF); // çok açık gri

  // ── Vurgu renkleri
  static const accentPink   = Color(0xFFF472B6); // canlı pembe (badge/notif)
  static const accentTeal   = Color(0xFF14B8A6); // teal (onay/başarı)
  static const accentAmber  = Color(0xFFFBBF24); // altın sarısı

  // ── Gradient
  static const gradientStart = Color(0xFF4F46E5); // indigo
  static const gradientEnd   = Color(0xFF7C3AED); // violet
}
