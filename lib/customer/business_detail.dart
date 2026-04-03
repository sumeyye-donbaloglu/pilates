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

  String get formattedDate =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  static const _weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
  static const _months = [
    "", "Oca", "Şub", "Mar", "Nis", "May", "Haz",
    "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"
  ];

  // ── Randevu talebi ────────────────────────────────────────────────

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

      final requestRef =
          await firestore.collection('appointment_requests').add({
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
        'message':
            '$customerName • $formattedDate $time için randevu talebi gönderdi',
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

  // ── Tarih seçici ──────────────────────────────────────────────────

  Widget _dateSelector() {
    final weekday = _weekdays[selectedDate.weekday - 1];
    final month = _months[selectedDate.month];

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${selectedDate.day}",
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    month,
                    style: GoogleFonts.nunito(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekday,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepIndigo,
                  ),
                ),
                Text(
                  "${selectedDate.day} $month ${selectedDate.year}",
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_outlined,
                color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Slot listesi (real-time) ───────────────────────────────────────

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
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final slots = snapshot.data!.docs;

        if (slots.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded,
                      size: 52, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    "Bu tarih için henüz\nseans açılmamış",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sorted = [...slots];
        sorted.sort((a, b) {
          final aTime = (a.data() as Map)['time'] as String? ?? '';
          final bTime = (b.data() as Map)['time'] as String? ?? '';
          return aTime.compareTo(bTime);
        });

        return ListView.builder(
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

                return GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () => requestSlot(
                            slotId: slotDoc.id,
                            time: slot['time'],
                            endTime: slot['endTime'],
                          ),
                  child: AnimatedOpacity(
                    opacity: isDisabled ? 0.55 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasPending
                              ? AppColors.accentAmber.withOpacity(0.5)
                              : isFull
                                  ? AppColors.accentPink.withOpacity(0.4)
                                  : AppColors.border,
                        ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? AppColors.border
                                  : AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              slot['time'] as String,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDisabled
                                    ? AppColors.textMuted
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "– ${slot['endTime']}",
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          _badge(
                            hasPending: hasPending,
                            isFull: isFull,
                            slotType: slotType,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _badge({
    required bool hasPending,
    required bool isFull,
    required String? slotType,
  }) {
    if (hasPending) return _pill("Talep Gönderildi", AppColors.accentAmber);
    if (isFull) return _pill("Dolu", AppColors.accentPink);
    if (slotType == 'demo') return _pill("Demo", AppColors.purple);
    if (slotType == 'normal') return _pill("Normal", AppColors.accentTeal);
    return _pill("Müsait", AppColors.accentTeal);
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.name,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: GoogleFonts.nunito(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),

            _dateSelector(),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  "Müsait Seanslar",
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepIndigo,
                  ),
                ),
                if (loading) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            _slotList(),

            const SizedBox(height: 28),

            Text(
              "Paketler",
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 12),

            _packageList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Paket listesi ──────────────────────────────────────────────────

  Widget _packageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('packages')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // isActive filtresi client-side
        final packages = snapshot.data!.docs
            .where((d) => (d.data() as Map)['isActive'] != false)
            .toList();

        if (packages.isEmpty) {
          return Container(
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
          );
        }

        return Column(
          children: packages.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _PackageCard(
              data: data,
              onBuy: () => _showBuyDialog(data),
            );
          }).toList(),
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
            const SizedBox(height: 8),
            Text(
              "₺${(packageData['price'] as num?)?.toStringAsFixed(0) ?? '0'} · "
              "${packageData['sessionCount']} seans · "
              "${packageData['validityDays']} gün geçerli",
              style: GoogleFonts.nunito(
                  fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Ödeme sistemi yakında aktif olacak. Satın almak için salonla iletişime geçebilirsiniz.",
                      style: GoogleFonts.nunito(
                        fontSize: 13,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? '',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepIndigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$sessionCount seans · $validityDays gün",
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₺${price.toStringAsFixed(0)}",
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepIndigo,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onBuy,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.gradientStart,
                        AppColors.gradientEnd
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Satın Al",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
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
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd
                        ],
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
