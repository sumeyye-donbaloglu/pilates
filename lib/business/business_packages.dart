import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class BusinessPackagesScreen extends StatelessWidget {
  const BusinessPackagesScreen({super.key});

  String get _businessId => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _packagesRef =>
      FirebaseFirestore.instance
          .collection('businesses')
          .doc(_businessId)
          .collection('packages');

  Future<void> _deletePackage(BuildContext context, String packageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Paketi Sil"),
        content: const Text("Bu paketi silmek istediğinizden emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _packagesRef.doc(packageId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Paket Yönetimi",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          "Yeni Paket",
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _showPackageDialog(context, null, null),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _packagesRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard_rounded,
                      size: 64, color: AppColors.border),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz paket oluşturmadınız",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sağ alttaki butona basarak başlayın",
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              return _PackageCard(
                data: data,
                packageId: doc.id,
                onEdit: () => _showPackageDialog(context, doc.id, data),
                onDelete: () => _deletePackage(context, doc.id),
                onToggle: (val) =>
                    _packagesRef.doc(doc.id).update({'isActive': val}),
              );
            },
          );
        },
      ),
    );
  }

  void _showPackageDialog(
    BuildContext context,
    String? packageId,
    Map<String, dynamic>? existing,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageFormSheet(
        packageId: packageId,
        existing: existing,
        packagesRef: _packagesRef,
      ),
    );
  }
}

// ── Paket kartı ─────────────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String packageId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _PackageCard({
    required this.data,
    required this.packageId,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = data['isActive'] as bool? ?? true;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final sessionCount = data['sessionCount'] as int? ?? 0;
    final validityDays = data['validityDays'] as int? ?? 30;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.border : AppColors.border.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isActive ? 0.07 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isActive ? 1 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['name'] ?? '',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepIndigo,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: isActive,
                    activeColor: AppColors.accentTeal,
                    onChanged: onToggle,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bilgi satırı
              Row(
                children: [
                  _InfoBadge(
                    icon: Icons.fitness_center_rounded,
                    label: "$sessionCount Seans",
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _InfoBadge(
                    icon: Icons.calendar_today_rounded,
                    label: "$validityDays Gün",
                    color: AppColors.purple,
                  ),
                  const Spacer(),
                  Text(
                    "₺${price.toStringAsFixed(0)}",
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepIndigo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Aksiyon butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: Text(
                      "Düzenle",
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: Text(
                      "Sil",
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                    ),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paket form sheet ─────────────────────────────────────────────────────────

class _PackageFormSheet extends StatefulWidget {
  final String? packageId;
  final Map<String, dynamic>? existing;
  final CollectionReference<Map<String, dynamic>> packagesRef;

  const _PackageFormSheet({
    required this.packageId,
    required this.existing,
    required this.packagesRef,
  });

  @override
  State<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends State<_PackageFormSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int _sessionCount = 10;
  int _validityDays = 90;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!;
      _nameCtrl.text = d['name'] ?? '';
      _priceCtrl.text = (d['price'] as num?)?.toString() ?? '';
      _sessionCount = d['sessionCount'] as int? ?? 10;
      _validityDays = d['validityDays'] as int? ?? 90;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty) {
      _showError("Paket adı boş bırakılamaz");
      return;
    }
    if (price == null || price <= 0) {
      _showError("Geçerli bir fiyat girin");
      return;
    }

    setState(() => _saving = true);

    try {
      final data = {
        'name': name,
        'price': price,
        'sessionCount': _sessionCount,
        'validityDays': _validityDays,
        'isActive': widget.existing?['isActive'] ?? true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.packageId != null) {
        await widget.packagesRef.doc(widget.packageId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await widget.packagesRef.add(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.packageId != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? "Paketi Düzenle" : "Yeni Paket Oluştur",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 24),

            // Paket adı
            _formField(
              controller: _nameCtrl,
              label: "Paket Adı",
              hint: "örn: 10 Seans Reformer",
              icon: Icons.card_giftcard_rounded,
            ),
            const SizedBox(height: 14),

            // Fiyat
            _formField(
              controller: _priceCtrl,
              label: "Fiyat (₺)",
              hint: "örn: 2500",
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Seans sayısı
            _CounterRow(
              label: "Seans Sayısı",
              icon: Icons.fitness_center_rounded,
              value: _sessionCount,
              min: 1,
              max: 100,
              onDecrement: () => setState(() => _sessionCount--),
              onIncrement: () => setState(() => _sessionCount++),
            ),
            const SizedBox(height: 14),

            // Geçerlilik süresi
            _dropdownRow(
              label: "Geçerlilik Süresi",
              icon: Icons.calendar_today_rounded,
              value: _validityDays,
              items: const [
                DropdownMenuItem(value: 30, child: Text("30 gün")),
                DropdownMenuItem(value: 60, child: Text("60 gün")),
                DropdownMenuItem(value: 90, child: Text("90 gün")),
                DropdownMenuItem(value: 180, child: Text("6 ay")),
                DropdownMenuItem(value: 365, child: Text("1 yıl")),
              ],
              onChanged: (v) => setState(() => _validityDays = v!),
            ),
            const SizedBox(height: 28),

            // Kaydet butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isEdit ? "Güncelle" : "Paketi Oluştur",
                        style: GoogleFonts.nunito(
                          fontSize: 16,
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

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.nunito(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.deepIndigo,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.nunito(color: AppColors.textMuted),
          hintStyle:
              GoogleFonts.nunito(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _dropdownRow<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.nunito(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
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
}

class _CounterRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int min;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CounterRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          _btn(Icons.remove_rounded, value > min ? onDecrement : null),
          const SizedBox(width: 16),
          Text(
            "$value",
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.deepIndigo,
            ),
          ),
          const SizedBox(width: 16),
          _btn(Icons.add_rounded, value < max ? onIncrement : null),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
