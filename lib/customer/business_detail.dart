import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String businessId;
  final String name;
  final String location;

  const BusinessDetailScreen({
    super.key,
    required this.businessId,
    required this.name,
    required this.location,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  DateTime selectedDate = DateTime.now();
  bool loading = false;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // 14 günlük tarih listesi
  final List<DateTime> _dates = List.generate(
    14,
    (i) => DateTime.now().add(Duration(days: i)),
  );

  static const _weekdayShort = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
  static const _monthShort = [
    "", "Oca", "Şub", "Mar", "Nis", "May", "Haz",
    "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"
  ];

  String get formattedDate =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  // ── Randevu talebi ──────────────────────────────────────────────────

  Future<void> requestSlot({
    required String slotId,
    required String time,
    required String endTime,
  }) async {
    if (loading) return;

    String lessonType = 'normal';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestSheet(
        date: formattedDate,
        time: time,
        endTime: endTime,
        onConfirm: (type) {
          lessonType = type;
          Navigator.pop(context, true);
        },
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed != true) return;

    setState(() => loading = true);
    final firestore = FirebaseFirestore.instance;

    try {
      final existing = await firestore
          .collection('appointment_requests')
          .where('customerId', isEqualTo: uid)
          .where('slotId', isEqualTo: slotId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception("Bu seans için bekleyen talebin var.");
      }

      final userDoc = await firestore.collection('users').doc(uid).get();
      final customerName = userDoc.data()?['name'] ?? 'Müşteri';

      final requestRef = await firestore.collection('appointment_requests').add({
        'businessId': widget.businessId,
        'customerId': uid,
        'customerName': customerName,
        'slotId': slotId,
        'date': formattedDate,
        'time': time,
        'lessonType': lessonType,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await firestore.collection('notifications').add({
        'userId': widget.businessId,
        'title': 'Yeni Randevu Talebi',
        'message': '$customerName • $formattedDate $time için randevu talebi gönderdi',
        'type': 'appointment_request',
        'isRead': false,
        'relatedRequestId': requestRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Talep gönderildi ✓"),
            backgroundColor: AppColors.accentTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ── Yatay tarih strip ───────────────────────────────────────────────

  Widget _dateStrip() {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _dates.length,
        itemBuilder: (context, i) {
          final date = _dates[i];
          final isSelected = formattedDate ==
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final isToday = i == 0;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary.withOpacity(0.3)
                          : AppColors.border,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayShort[date.weekday - 1],
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${date.day}",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.deepIndigo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _monthShort[date.month],
                    style: GoogleFonts.nunito(
                      fontSize: 10,
                      color: isSelected ? Colors.white60 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Slot listesi ────────────────────────────────────────────────────

  Widget _slotList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('daily_slots')
          .where('date', isEqualTo: formattedDate)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final slots = snapshot.data!.docs;

        if (slots.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy_rounded, size: 40, color: AppColors.border),
                const SizedBox(height: 10),
                Text(
                  "Bu tarih için seans açılmamış",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        final sorted = [...slots]
          ..sort((a, b) {
            final aTime = (a.data() as Map)['time'] as String? ?? '';
            final bTime = (b.data() as Map)['time'] as String? ?? '';
            return aTime.compareTo(bTime);
          });

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sorted.length,
            itemBuilder: (context, i) {
              final slotDoc = sorted[i];
              final slot = slotDoc.data() as Map<String, dynamic>;
              final used = slot['usedCapacity'] ?? 0;
              final capacity = slot['capacity'] ?? 1;
              final slotType = slot['slotType'] as String?;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointment_requests')
                    .where('customerId', isEqualTo: uid)
                    .where('slotId', isEqualTo: slotDoc.id)
                    .where('status', isEqualTo: 'pending')
                    .limit(1)
                    .snapshots(),
                builder: (context, reqSnap) {
                  final hasPending =
                      reqSnap.hasData && reqSnap.data!.docs.isNotEmpty;
                  final isFull = used >= capacity;
                  final isDisabled = hasPending || isFull;

                  Color statusColor = AppColors.accentTeal;
                  String statusLabel = "Müsait";
                  if (hasPending) {
                    statusColor = AppColors.accentAmber;
                    statusLabel = "Talep Gönderildi";
                  } else if (isFull) {
                    statusColor = AppColors.accentPink;
                    statusLabel = "Dolu";
                  } else if (slotType == 'demo') {
                    statusColor = AppColors.purple;
                    statusLabel = "Demo";
                  } else if (slotType == 'normal') {
                    statusColor = AppColors.accentTeal;
                    statusLabel = "Normal";
                  }

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () => requestSlot(
                              slotId: slotDoc.id,
                              time: slot['time'],
                              endTime: slot['endTime'],
                            ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? AppColors.background
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDisabled
                              ? AppColors.border.withOpacity(0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Saat
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot['time'] as String,
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDisabled
                                      ? AppColors.textMuted
                                      : AppColors.deepIndigo,
                                ),
                              ),
                              Text(
                                slot['endTime'] as String,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Durum badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                          if (!isDisabled) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // ── Paket listesi ───────────────────────────────────────────────────

  Widget _packageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('packages')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final packages = snapshot.data!.docs
            .where((d) => (d.data() as Map)['isActive'] != false)
            .toList();

        if (packages.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                "Bu salon henüz paket tanımlamamış",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: packages.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _PackageCard(
                data: data,
                onBuy: () => _showBuyDialog(data),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showBuyDialog(Map<String, dynamic> packageData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              packageData['name'] ?? 'Paket',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "₺${(packageData['price'] as num?)?.toStringAsFixed(0) ?? '0'}  ·  "
              "${packageData['sessionCount']} seans  ·  "
              "${packageData['validityDays']} gün geçerli",
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ödeme sistemi yakında aktif olacak. Satın almak için salonla iletişime geçebilirsiniz.",
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.purple,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  "Salonla İletişime Geç",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section başlığı ─────────────────────────────────────────────────

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.deepIndigo,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                widget.location,
                                style: GoogleFonts.nunito(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── İçerik
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Tarih strip
                _sectionTitle("Tarih Seç"),
                const SizedBox(height: 12),
                _dateStrip(),

                const SizedBox(height: 24),

                // Seanslar
                _sectionTitle(
                  "Müsait Seanslar",
                  trailing: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                _slotList(),

                const SizedBox(height: 28),

                // Paketler
                _sectionTitle("Paketler"),
                const SizedBox(height: 12),
                _packageList(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paket Kartı ───────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onBuy;
  const _PackageCard({required this.data, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final sessionCount = data['sessionCount'] as int? ?? 0;
    final validityDays = data['validityDays'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepIndigo,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "$sessionCount seans  ·  $validityDays gün",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₺${price.toStringAsFixed(0)}",
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepIndigo,
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: onBuy,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Satın Al",
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Talep Bottom Sheet ────────────────────────────────────────────────

class _RequestSheet extends StatefulWidget {
  final String date;
  final String time;
  final String endTime;
  final Function(String) onConfirm;
  final VoidCallback onCancel;

  const _RequestSheet({
    required this.date,
    required this.time,
    required this.endTime,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  String _lessonType = 'normal';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            "Randevu Talebi",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.deepIndigo,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${widget.date}  ·  ${widget.time} – ${widget.endTime}",
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Text(
            "Ders Türü",
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          _option("normal", "Normal Ders", Icons.fitness_center_rounded),
          const SizedBox(height: 8),
          _option("demo", "Demo Ders", Icons.play_circle_outline_rounded),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        "Vazgeç",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => widget.onConfirm(_lessonType),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Talep Gönder",
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(String value, String label, IconData icon) {
    final selected = _lessonType == value;
    return GestureDetector(
      onTap: () => setState(() => _lessonType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceTint : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.deepIndigo,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
