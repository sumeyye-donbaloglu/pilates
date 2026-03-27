import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

// ── Firestore path sabiti
String _measurementsPath(String uid) => 'users/$uid/bodyMeasurements';

class BodyProgressScreen extends StatefulWidget {
  const BodyProgressScreen({super.key});

  @override
  State<BodyProgressScreen> createState() => _BodyProgressScreenState();
}

class _BodyProgressScreenState extends State<BodyProgressScreen> {
  // Seçili metrik: weight | waist | hip | fatPercent
  String _selectedMetric = 'weight';

  final _metrics = const [
    _Metric('weight',   'Kilo',       'kg',  Color(0xFF6366F1)),
    _Metric('waist',    'Bel',        'cm',  Color(0xFF7C3AED)),
    _Metric('hip',      'Basen',      'cm',  Color(0xFF0EA5E9)),
    _Metric('lowerAb',  'Alt Karın',  'cm',  Color(0xFFF472B6)),
    _Metric('neck',     'Boyun',      'cm',  Color(0xFF10B981)),
    _Metric('rightArm', 'Sağ Kol',   'cm',  Color(0xFFF59E0B)),
    _Metric('leftArm',  'Sol Kol',   'cm',  Color(0xFFEF4444)),
    _Metric('rightLeg', 'Sağ Bacak', 'cm',  Color(0xFF8B5CF6)),
    _Metric('leftLeg',  'Sol Bacak', 'cm',  Color(0xFFEC4899)),
  ];

  _Metric get _current =>
      _metrics.firstWhere((m) => m.key == _selectedMetric);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Vücut İlerlemesi",
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: "Yeni Ölçüm",
            onPressed: () => _showAddSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(_measurementsPath(_uid))
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _EmptyState(onAdd: () => _showAddSheet(context));
          }

          // Ölçümleri parse et
          final measurements = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return _MeasurementEntry(
              id:       d.id,
              date:     (data['date'] as Timestamp).toDate(),
              weight:   _toDouble(data['weight']),
              neck:     _toDouble(data['neck']),
              waist:    _toDouble(data['waist']),
              lowerAb:  _toDouble(data['lowerAb']),
              hip:      _toDouble(data['hip']),
              rightArm: _toDouble(data['rightArm']),
              leftArm:  _toDouble(data['leftArm']),
              rightLeg: _toDouble(data['rightLeg']),
              leftLeg:  _toDouble(data['leftLeg']),
            );
          }).toList();

          return Column(
            children: [
              // ── METRİK SEÇİCİ
              _MetricSelector(
                metrics: _metrics,
                selected: _selectedMetric,
                onSelect: (key) => setState(() => _selectedMetric = key),
              ),

              // ── GRAFİK
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                child: _ProgressChart(
                  measurements: measurements,
                  metric: _current,
                ),
              ),

              // ── ÖZET SATIRI (ilk / son / fark)
              _SummaryRow(measurements: measurements, metric: _current),

              const Divider(height: 1),

              // ── GEÇMİŞ LİSTE
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: measurements.length,
                  itemBuilder: (ctx, i) {
                    // Yeniden eskiye göster
                    final entry =
                        measurements[measurements.length - 1 - i];
                    return _MeasurementTile(
                      entry: entry,
                      metric: _current,
                      onDelete: () => _delete(entry.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // ── EKLE BUTONU
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          "Ölçüm Ekle",
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Yeni ölçüm bottom sheet
  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMeasurementSheet(uid: _uid),
    );
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Sil", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text("Bu ölçümü silmek istiyor musun?",
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sil",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .doc('${_measurementsPath(_uid)}/$id')
          .delete();
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }
}

// ────────────────────────────────────────────────
// METRİK SEÇİCİ
// ────────────────────────────────────────────────
class _MetricSelector extends StatelessWidget {
  final List<_Metric> metrics;
  final String selected;
  final ValueChanged<String> onSelect;
  const _MetricSelector(
      {required this.metrics,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: metrics.map((m) {
          final active = m.key == selected;
          return GestureDetector(
            onTap: () => onSelect(m.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? m.color : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? m.color : AppColors.border),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: m.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                m.label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// GRAFİK
// ────────────────────────────────────────────────
class _ProgressChart extends StatelessWidget {
  final List<_MeasurementEntry> measurements;
  final _Metric metric;
  const _ProgressChart(
      {required this.measurements, required this.metric});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < measurements.length; i++) {
      final val = measurements[i].valueOf(metric.key);
      if (val > 0) spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "Bu metrik için veri yok",
            style: GoogleFonts.nunito(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final minY = (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 3)
        .clamp(0, double.infinity)
        .toDouble();
    final maxY =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 3;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(1, 999),
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (val, _) => Text(
                  val.toStringAsFixed(0),
                  style: GoogleFonts.nunito(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: (spots.length > 6
                    ? (spots.length / 5).ceilToDouble()
                    : 1),
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= measurements.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MMM yy', 'tr_TR')
                          .format(measurements[idx].date),
                      style: GoogleFonts.nunito(
                          fontSize: 10, color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: metric.color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: metric.color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    metric.color.withOpacity(0.25),
                    metric.color.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.deepIndigo,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        "${s.y.toStringAsFixed(1)} ${metric.unit}",
                        GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// ÖZET SATIRI
// ────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final List<_MeasurementEntry> measurements;
  final _Metric metric;
  const _SummaryRow(
      {required this.measurements, required this.metric});

  @override
  Widget build(BuildContext context) {
    final vals = measurements
        .map((m) => m.valueOf(metric.key))
        .where((v) => v > 0)
        .toList();
    if (vals.isEmpty) return const SizedBox.shrink();

    final first = vals.first;
    final last  = vals.last;
    final diff  = last - first;
    // Kilo ve çevre ölçülerinde azalma iyidir
    final isGood = diff <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryChip(
              label: "Başlangıç",
              value: "${first.toStringAsFixed(1)} ${metric.unit}",
              color: AppColors.lavender),
          const SizedBox(width: 10),
          _SummaryChip(
              label: "Güncel",
              value: "${last.toStringAsFixed(1)} ${metric.unit}",
              color: AppColors.primary),
          const SizedBox(width: 10),
          _SummaryChip(
            label: "Fark",
            value:
                "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} ${metric.unit}",
            color: isGood ? AppColors.accentTeal : AppColors.accentPink,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.nunito(
                  fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// GEÇMİŞ SATIRI
// ────────────────────────────────────────────────
class _MeasurementTile extends StatelessWidget {
  final _MeasurementEntry entry;
  final _Metric metric;
  final VoidCallback onDelete;
  const _MeasurementTile(
      {required this.entry,
      required this.metric,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.monitor_weight_rounded,
                color: metric.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM y', 'tr_TR').format(entry.date),
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepIndigo,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _allValues(),
                  style: GoogleFonts.nunito(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            "${entry.valueOf(metric.key).toStringAsFixed(1)} ${metric.unit}",
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: metric.color,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _allValues() {
    final parts = <String>[];
    if (entry.weight   > 0) parts.add("${entry.weight.toStringAsFixed(1)} kg");
    if (entry.waist    > 0) parts.add("Bel ${entry.waist.toStringAsFixed(1)}");
    if (entry.hip      > 0) parts.add("Basen ${entry.hip.toStringAsFixed(1)}");
    if (entry.lowerAb  > 0) parts.add("Alt K. ${entry.lowerAb.toStringAsFixed(1)}");
    if (entry.rightArm > 0) parts.add("S.Kol ${entry.rightArm.toStringAsFixed(1)}");
    if (entry.rightLeg > 0) parts.add("S.Bacak ${entry.rightLeg.toStringAsFixed(1)}");
    return parts.join("  ·  ");
  }
}

// ────────────────────────────────────────────────
// YENİ ÖLÇÜM BOTTOM SHEET
// ────────────────────────────────────────────────
class _AddMeasurementSheet extends StatefulWidget {
  final String uid;
  const _AddMeasurementSheet({required this.uid});

  @override
  State<_AddMeasurementSheet> createState() =>
      _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  final _weightCtrl   = TextEditingController();
  final _neckCtrl     = TextEditingController();
  final _waistCtrl    = TextEditingController();
  final _lowerAbCtrl  = TextEditingController();
  final _hipCtrl      = TextEditingController();
  final _rightArmCtrl = TextEditingController();
  final _leftArmCtrl  = TextEditingController();
  final _rightLegCtrl = TextEditingController();
  final _leftLegCtrl  = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _neckCtrl.dispose();
    _waistCtrl.dispose();
    _lowerAbCtrl.dispose();
    _hipCtrl.dispose();
    _rightArmCtrl.dispose();
    _leftArmCtrl.dispose();
    _rightLegCtrl.dispose();
    _leftLegCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kilo alanı zorunludur")),
      );
      return;
    }

    double _p(TextEditingController c) =>
        double.tryParse(c.text.trim()) ?? 0;

    setState(() => _saving = true);
    try {
      final data = {
        'weight':   weight,
        'neck':     _p(_neckCtrl),
        'waist':    _p(_waistCtrl),
        'lowerAb':  _p(_lowerAbCtrl),
        'hip':      _p(_hipCtrl),
        'rightArm': _p(_rightArmCtrl),
        'leftArm':  _p(_leftArmCtrl),
        'rightLeg': _p(_rightLegCtrl),
        'leftLeg':  _p(_leftLegCtrl),
        'date':      Timestamp.fromDate(_selectedDate),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Subcollection'a kaydet
      await FirebaseFirestore.instance
          .collection(_measurementsPath(widget.uid))
          .add(data);

      // Ana dokümanı güncelle
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'bodyInfo.weight': weight});

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ölçüm kaydedildi ✓"),
          backgroundColor: AppColors.accentTeal,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle çizgisi
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
            const SizedBox(height: 16),

            Text(
              "Yeni Ölçüm Ekle",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Düzenli kayıt tutmak ilerlemeyi görmeni sağlar.",
              style: GoogleFonts.nunito(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Tarih seçici
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMMM y', 'tr_TR')
                          .format(_selectedDate),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepIndigo,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Genel
            Row(children: [
              Expanded(child: _SheetField(ctrl: _weightCtrl, label: "Kilo *", unit: "kg")),
              const SizedBox(width: 12),
              Expanded(child: _SheetField(ctrl: _neckCtrl,   label: "Boyun",  unit: "cm")),
            ]),
            const SizedBox(height: 10),
            // Gövde
            Row(children: [
              Expanded(child: _SheetField(ctrl: _waistCtrl,   label: "Bel",      unit: "cm")),
              const SizedBox(width: 12),
              Expanded(child: _SheetField(ctrl: _lowerAbCtrl, label: "Alt Karın",unit: "cm")),
            ]),
            const SizedBox(height: 10),
            _SheetField(ctrl: _hipCtrl, label: "Basen", unit: "cm"),
            const SizedBox(height: 10),
            // Kollar
            Row(children: [
              Expanded(child: _SheetField(ctrl: _rightArmCtrl, label: "Sağ Kol", unit: "cm")),
              const SizedBox(width: 12),
              Expanded(child: _SheetField(ctrl: _leftArmCtrl,  label: "Sol Kol", unit: "cm")),
            ]),
            const SizedBox(height: 10),
            // Bacaklar
            Row(children: [
              Expanded(child: _SheetField(ctrl: _rightLegCtrl, label: "Sağ Bacak", unit: "cm")),
              const SizedBox(width: 12),
              Expanded(child: _SheetField(ctrl: _leftLegCtrl,  label: "Sol Bacak", unit: "cm")),
            ]),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? "Kaydediliyor..." : "Kaydet"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String unit;
  const _SheetField(
      {required this.ctrl, required this.label, required this.unit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        labelStyle: GoogleFonts.nunito(
            color: AppColors.lavender, fontSize: 13),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }
}

// ────────────────────────────────────────────────
// BOŞ DURUM
// ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.show_chart_rounded,
                  color: Colors.white, size: 46),
            ),
            const SizedBox(height: 20),
            Text(
              "Henüz ölçüm yok",
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "İlk ölçümünü ekle ve ilerlemeni\ngrafik üzerinde izle.",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text("İlk Ölçümü Ekle",
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// MODEL SINIFLAR
// ────────────────────────────────────────────────
class _Metric {
  final String key;
  final String label;
  final String unit;
  final Color color;
  const _Metric(this.key, this.label, this.unit, this.color);
}

class _MeasurementEntry {
  final String id;
  final DateTime date;
  final double weight;
  final double neck;
  final double waist;
  final double lowerAb;
  final double hip;
  final double rightArm;
  final double leftArm;
  final double rightLeg;
  final double leftLeg;

  const _MeasurementEntry({
    required this.id,
    required this.date,
    required this.weight,
    required this.neck,
    required this.waist,
    required this.lowerAb,
    required this.hip,
    required this.rightArm,
    required this.leftArm,
    required this.rightLeg,
    required this.leftLeg,
  });

  double valueOf(String key) {
    switch (key) {
      case 'weight':   return weight;
      case 'neck':     return neck;
      case 'waist':    return waist;
      case 'lowerAb':  return lowerAb;
      case 'hip':      return hip;
      case 'rightArm': return rightArm;
      case 'leftArm':  return leftArm;
      case 'rightLeg': return rightLeg;
      case 'leftLeg':  return leftLeg;
      default:         return 0;
    }
  }
}
