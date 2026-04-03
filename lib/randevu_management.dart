import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme/app_colors.dart';

class RandevuManagementScreen extends StatefulWidget {
  final String businessId;

  const RandevuManagementScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<RandevuManagementScreen> createState() =>
      _RandevuManagementScreenState();
}

class _RandevuManagementScreenState extends State<RandevuManagementScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();

  // date string (yyyy-MM-dd) → list of appointments
  Map<String, List<Map<String, dynamic>>> _appointmentsByDate = {};
  // customerId → name cache
  final Map<String, String> _nameCache = {};
  bool _loadingMonth = false;

  final _db = FirebaseFirestore.instance;

  static const _weekdayLabels = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"];
  static const _monthNames = [
    "",
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];

  @override
  void initState() {
    super.initState();
    _loadMonth(_focusedMonth);
  }

  // ─── DATA ─────────────────────────────────────────────────────────

  String _dateStr(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _loadMonth(DateTime month) async {
    final start =
        "${month.year}-${month.month.toString().padLeft(2, '0')}-01";
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final end =
        "${month.year}-${month.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}";

    setState(() => _loadingMonth = true);

    final snap = await _db
        .collection('appointments')
        .where('businessId', isEqualTo: widget.businessId)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .get();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    final Set<String> customerIds = {};

    for (final doc in snap.docs) {
      final data = {...doc.data(), 'id': doc.id};
      final date = data['date'] as String? ?? '';
      grouped.putIfAbsent(date, () => []).add(data);
      if (data['customerId'] != null) {
        customerIds.add(data['customerId'] as String);
      }
    }

    // fetch missing names
    for (final cid in customerIds) {
      if (!_nameCache.containsKey(cid)) {
        final userDoc =
            await _db.collection('users').doc(cid).get();
        _nameCache[cid] =
            (userDoc.data()?['name'] as String?) ?? 'Müşteri';
      }
    }

    if (mounted) {
      setState(() {
        _appointmentsByDate = grouped;
        _loadingMonth = false;
      });
    }
  }

  List<Map<String, dynamic>> get _selectedDayAppointments {
    return _appointmentsByDate[_dateStr(_selectedDay)] ?? [];
  }

  // ─── CALENDAR ─────────────────────────────────────────────────────

  Widget _buildCalendar() {
    // First weekday of month (1=Mon…7=Sun → 0-indexed offset)
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final offset = (firstDay.weekday - 1); // 0=Mon
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final today = DateTime.now();

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              _monthNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () {
                  final prev = DateTime(
                      _focusedMonth.year, _focusedMonth.month - 1);
                  setState(() {
                    _focusedMonth = prev;
                    _selectedDay =
                        DateTime(prev.year, prev.month, 1);
                  });
                  _loadMonth(prev);
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "${_monthNames[_focusedMonth.month].toUpperCase()}  ${_focusedMonth.year}",
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepIndigo,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              _monthNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () {
                  final next = DateTime(
                      _focusedMonth.year, _focusedMonth.month + 1);
                  setState(() {
                    _focusedMonth = next;
                    _selectedDay =
                        DateTime(next.year, next.month, 1);
                  });
                  _loadMonth(next);
                },
              ),
            ],
          ),
        ),

        // Day-of-week header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _weekdayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _loadingMonth
              ? const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: offset + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < offset) return const SizedBox();
                    final day = index - offset + 1;
                    final date = DateTime(
                        _focusedMonth.year, _focusedMonth.month, day);
                    final dateKey = _dateStr(date);
                    final hasAppointments =
                        (_appointmentsByDate[dateKey]?.isNotEmpty ?? false);
                    final isSelected =
                        _dateStr(date) == _dateStr(_selectedDay);
                    final isToday = _dateStr(date) == _dateStr(today);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = date),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                                  ? AppColors.surfaceTint
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              "$day",
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                        ? AppColors.primary
                                        : AppColors.deepIndigo,
                              ),
                            ),
                            if (hasAppointments && !isSelected)
                              Positioned(
                                bottom: 3,
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white70
                                        : AppColors.accentPink,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _monthNavButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  // ─── DAY APPOINTMENTS ─────────────────────────────────────────────

  Widget _buildDaySection() {
    final appts = _selectedDayAppointments;
    final dayLabel =
        "${_selectedDay.day} ${_monthNames[_selectedDay.month]} ${_selectedDay.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepIndigo,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: appts.isEmpty
                      ? AppColors.border
                      : AppColors.accentTeal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  appts.isEmpty
                      ? "Randevu yok"
                      : "${appts.length} randevu",
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: appts.isEmpty
                        ? AppColors.textMuted
                        : AppColors.accentTeal,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (appts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 48, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    "Bu gün için randevu bulunmuyor",
                    style: GoogleFonts.nunito(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: appts.length,
            itemBuilder: (context, i) => _appointmentCard(appts[i]),
          ),
      ],
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appt) {
    final customerId = appt['customerId'] as String? ?? '';
    final customerName = _nameCache[customerId] ?? 'Müşteri';
    final time = appt['time'] as String? ?? '--:--';
    final lessonType = appt['lessonType'] as String? ?? '';
    final lessonLabel = _lessonLabel(lessonType);
    final lessonColor = _lessonColor(lessonType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          // Time bubble
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepIndigo,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      customerId.length > 8
                          ? customerId.substring(0, 8) + '...'
                          : customerId,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lesson badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: lessonColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              lessonLabel,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: lessonColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lessonLabel(String type) {
    switch (type) {
      case 'demo':
        return 'Demo';
      case 'normal':
        return 'Normal';
      default:
        return type.isNotEmpty ? type : 'Seans';
    }
  }

  Color _lessonColor(String type) {
    switch (type) {
      case 'demo':
        return AppColors.accentAmber;
      case 'normal':
        return AppColors.accentTeal;
      default:
        return AppColors.primary;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Randevular",
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar card
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentPink,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Randevu olan günler",
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Divider
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: 1,
              color: AppColors.border,
            ),

            // Day appointments
            _buildDaySection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
