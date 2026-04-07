import '../theme/app_colors.dart';
import '../services/iyzico_service.dart';
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

      if (existing.docs.isNotEmpty) throw Exception("Bu seans için bekleyen talebin var.");

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
          const SnackBar(content: Text("Talep gönderildi ✓"), backgroundColor: AppColors.accentTeal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildDateStrip(),
                  const SizedBox(height: 24),
                  _buildSectionLabel("Müsait Seanslar"),
                  const SizedBox(height: 10),
                  _buildSlotList(),
                  const SizedBox(height: 28),
                  _buildSectionLabel("Paketler"),
                  const SizedBox(height: 10),
                  _buildPackageList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B4FCF), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Dekoratif daireler
            Positioned(
              right: -20,
              top: -10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              top: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Geri butonu
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.location.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white54, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                widget.location,
                                style: GoogleFonts.nunito(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ],
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

  // ── TARİH STRIP ─────────────────────────────────────────────────────

  Widget _buildDateStrip() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _dates.length,
        itemBuilder: (context, i) {
          final date = _dates[i];
          final key =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final isSelected = formattedDate == key;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 10),
              width: 56,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7C3AED) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
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
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.deepIndigo,
                    ),
                  ),
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

  // ── SECTION LABEL ───────────────────────────────────────────────────

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.deepIndigo,
        ),
      ),
    );
  }

  // ── SLOT LİSTESİ ────────────────────────────────────────────────────

  Widget _buildSlotList() {
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.calendar_today_outlined,
                        size: 28, color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Bu tarih için seans açılmamış",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Başka bir gün seçmeyi deneyin",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textMuted.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sorted = [...slots]
          ..sort((a, b) {
            final aT = (a.data() as Map)['time'] as String? ?? '';
            final bT = (b.data() as Map)['time'] as String? ?? '';
            return aT.compareTo(bT);
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

                  Color badgeColor = const Color(0xFF10B981);
                  String badgeLabel = "Müsait";
                  IconData badgeIcon = Icons.check_circle_outline_rounded;

                  if (hasPending) {
                    badgeColor = const Color(0xFFF59E0B);
                    badgeLabel = "Talep Gönderildi";
                    badgeIcon = Icons.hourglass_top_rounded;
                  } else if (isFull) {
                    badgeColor = const Color(0xFFEF4444);
                    badgeLabel = "Dolu";
                    badgeIcon = Icons.block_rounded;
                  } else if (slotType == 'demo') {
                    badgeColor = const Color(0xFF8B5CF6);
                    badgeLabel = "Demo";
                    badgeIcon = Icons.play_circle_outline_rounded;
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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDisabled ? const Color(0xFFF9F9F9) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDisabled
                              ? Colors.grey.withOpacity(0.15)
                              : const Color(0xFFEDE9FE),
                          width: 1.5,
                        ),
                        boxShadow: isDisabled
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ],
                      ),
                      child: Row(
                        children: [
                          // Saat kutusu
                          Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? Colors.grey.withOpacity(0.08)
                                  : const Color(0xFFF3F0FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  slot['time'] as String,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isDisabled
                                        ? AppColors.textMuted
                                        : const Color(0xFF7C3AED),
                                  ),
                                ),
                                Text(
                                  slot['endTime'] as String,
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Badge
                          Row(
                            children: [
                              Icon(badgeIcon, size: 14, color: badgeColor),
                              const SizedBox(width: 5),
                              Text(
                                badgeLabel,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: badgeColor,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Randevu al butonu
                          if (!isDisabled)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF5B4FCF)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: Text(
                                "Talep",
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

  // ── PAKET LİSTESİ ───────────────────────────────────────────────────

  Widget _buildPackageList() {
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ],
              ),
              child: Text(
                "Bu salon henüz paket tanımlamamış",
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: packages.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _PackageCard(data: data, onBuy: () => _showBuySheet(data));
            }).toList(),
          ),
        );
      },
    );
  }

  void _showBuySheet(Map<String, dynamic> pkg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PaymentSheet(
        pkg: pkg,
        businessId: widget.businessId,
        businessName: widget.name,
        customerId: uid,
      ),
    );
  }
}

// ── Ödeme Bottom Sheet ────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final Map<String, dynamic> pkg;
  final String businessId;
  final String businessName;
  final String customerId;

  const _PaymentSheet({
    required this.pkg,
    required this.businessId,
    required this.businessName,
    required this.customerId,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    final digits = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    final digits = value.replaceAll('/', '');
    if (digits.length >= 3) {
      return '${digits.substring(0, 2)}/${digits.substring(2, digits.length > 4 ? 4 : digits.length)}';
    } else if (digits.length == 2) {
      return '$digits/';
    }
    return digits;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final pkg = widget.pkg;
      final expiry = _expiryCtrl.text.split('/');
      final email = FirebaseAuth.instance.currentUser?.email ?? '';

      final result = await IyzicoService.createPayment(
        cardHolderName: _cardNameCtrl.text.trim(),
        cardNumber: _cardNumberCtrl.text,
        expireMonth: expiry[0],
        expireYear: expiry.length > 1 ? expiry[1] : '',
        cvc: _cvvCtrl.text,
        price: (pkg['price'] as num?)?.toDouble() ?? 0,
        packageName: pkg['name'] ?? 'Paket',
        buyerId: widget.customerId,
        buyerEmail: email,
      );

      if (result['status'] != 'success') {
        throw Exception(result['errorMessage'] ?? 'Ödeme başarısız');
      }

      final sessionCount = pkg['sessionCount'] as int? ?? 0;
      final validityDays = pkg['validityDays'] as int? ?? 30;
      final expiresAt = DateTime.now().add(Duration(days: validityDays));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.customerId)
          .collection('activePackages')
          .add({
        'packageName': pkg['name'] ?? 'Paket',
        'businessName': widget.businessName,
        'businessId': widget.businessId,
        'totalSessions': sessionCount,
        'remainingSessions': sessionCount,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'purchasedAt': FieldValue.serverTimestamp(),
        'price': pkg['price'] ?? 0,
        'paymentId': result['paymentId']?.toString() ?? '',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ödeme onaylandı! $sessionCount seans hesabınıza eklendi."),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg = widget.pkg;
    final price = (pkg['price'] as num?)?.toStringAsFixed(0) ?? '0';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),

                // Paket özeti
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B4FCF), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pkg['name'] ?? 'Paket',
                                style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text(
                              "${pkg['sessionCount']} seans  ·  ${pkg['validityDays']} gün geçerli",
                              style: GoogleFonts.nunito(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text("₺$price",
                          style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text("Kart Bilgileri",
                    style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepIndigo)),
                const SizedBox(height: 14),

                // Kart üzerindeki isim
                _buildField(
                  controller: _cardNameCtrl,
                  label: "Kart Üzerindeki İsim",
                  hint: "AD SOYAD",
                  icon: Icons.person_outline_rounded,
                  inputType: TextInputType.name,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "İsim gerekli" : null,
                ),
                const SizedBox(height: 12),

                // Kart numarası
                TextFormField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  decoration: _inputDecoration(
                    label: "Kart Numarası",
                    hint: "0000 0000 0000 0000",
                    icon: Icons.credit_card_rounded,
                  ),
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5),
                  onChanged: (v) {
                    final formatted = _formatCardNumber(v);
                    if (formatted != v) {
                      _cardNumberCtrl.value = TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  },
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(' ', '');
                    if (digits.length < 16) return "Geçerli kart numarası girin";
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Son kullanma + CVV
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: _inputDecoration(
                          label: "Son Kullanma",
                          hint: "AA/YY",
                          icon: Icons.calendar_today_rounded,
                        ),
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        onChanged: (v) {
                          final formatted = _formatExpiry(v);
                          if (formatted != v) {
                            _expiryCtrl.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          }
                        },
                        validator: (v) {
                          if (v == null || v.length < 5) return "AA/YY giriniz";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        obscureText: true,
                        decoration: _inputDecoration(
                          label: "CVV",
                          hint: "•••",
                          icon: Icons.lock_outline_rounded,
                        ),
                        style: GoogleFonts.nunito(
                            fontSize: 15, fontWeight: FontWeight.w600),
                        validator: (v) {
                          if (v == null || v.length < 3) return "CVV giriniz";
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Test modu uyarısı
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Test modu — gerçek ödeme alınmaz",
                          style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ödeme butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF7C3AED).withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            "₺$price  Ödemeyi Tamamla",
                            style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
      counterText: '',
      labelStyle:
          GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted),
      hintStyle: GoogleFonts.nunito(fontSize: 14, color: AppColors.border),
      filled: true,
      fillColor: const Color(0xFFF9F8FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // İkon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            // Bilgi
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
                  Row(
                    children: [
                      _chip("$sessionCount seans", const Color(0xFF7C3AED)),
                      const SizedBox(width: 6),
                      _chip("$validityDays gün", const Color(0xFF0EA5E9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Fiyat + buton
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "₺${price.toStringAsFixed(0)}",
                  style: GoogleFonts.nunito(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepIndigo,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
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
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text("Randevu Talebi",
              style: GoogleFonts.playfairDisplay(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.deepIndigo)),
          const SizedBox(height: 6),
          Text("${widget.date}  ·  ${widget.time} – ${widget.endTime}",
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 24),
          Text("Ders Türü",
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 10),
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
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                      child: Text("Vazgeç",
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700, color: AppColors.textMuted)),
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
                          colors: [Color(0xFF7C3AED), Color(0xFF5B4FCF)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text("Talep Gönder",
                          style: GoogleFonts.nunito(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF7C3AED) : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20,
                color: selected ? const Color(0xFF7C3AED) : AppColors.textMuted),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xFF7C3AED) : AppColors.deepIndigo,
                )),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF7C3AED), size: 18),
          ],
        ),
      ),
    );
  }
}
