import 'package:flutter/material.dart';
import 'services/daily_slot_service.dart';

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
  DateTime selectedDate = DateTime.now();
  bool loading = false;
  List<Map<String, dynamic>> slots = [];

  final DailySlotService _service = DailySlotService();

  @override
  void initState() {
    super.initState();
    loadSlots();
  }

  // ------------------------------------------------
  // TÜRKÇE TARİH SABİTLERİ
  // ------------------------------------------------
  final List<String> _weekdays = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];

  final List<String> _months = [
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

  String get formattedDate =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  // ------------------------------------------------
  // SLOT YÜKLE
  // ------------------------------------------------
  Future<void> loadSlots() async {
    setState(() => loading = true);
    try {
      final result =
          await _service.getSlotsForDay(widget.businessId, formattedDate);
      setState(() => slots = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Slotlar yüklenemedi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ------------------------------------------------
  // SLOT OLUŞTUR
  // ------------------------------------------------
  Future<void> generateSlots() async {
    setState(() => loading = true);
    try {
      await _service.generateDailySlots(
        widget.businessId,
        formattedDate,
      );
      await loadSlots();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  // ------------------------------------------------
  // UI
  // ------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Randevu Yönetimi"),
        backgroundColor: const Color(0xFFE48989),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 14),
          _premiumDateHeader(),
          const SizedBox(height: 14),
          if (loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (slots.isEmpty)
            _emptySlotCard()
          else
            Expanded(child: _slotList()),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // 🌸 PREMIUM TARİH HEADER
  // ------------------------------------------------
  Widget _premiumDateHeader() {
    final weekday = _weekdays[selectedDate.weekday - 1];
    final monthYear =
        "${_months[selectedDate.month].toUpperCase()} ${selectedDate.year}";

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFE48989),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
          await loadSlots();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // GÜN NUMARASI
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE48989),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  selectedDate.day.toString(),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 18),

            // AY + YIL / GÜN
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthYear,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A4F4F),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weekday,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E6B6B),
                  ),
                ),
              ],
            ),

            const Spacer(),

            const Icon(Icons.calendar_month,
                color: Color(0xFFE48989)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------
  // SLOT YOKSA
  // ------------------------------------------------
  Widget _emptySlotCard() {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: loading ? null : generateSlots,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE48989),
                  Color(0xFFB07C7C),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE48989).withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              "Bu Gün İçin Slot Oluştur",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // SLOT LİSTESİ – AÇIKLAMALI
  // ------------------------------------------------
  Widget _slotList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];

        final time = slot['time'];
        final endTime = slot['endTime'];
        final capacity = slot['capacity'];
        final used = slot['usedCapacity'];

        final remaining = capacity - used;
        final isFull = remaining <= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isFull
                  ? const Color(0xFFFFC1C1)
                  : const Color(0xFFE8CFCF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$time – $endTime",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7A4F4F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFull
                    ? "Bu saat dilimi dolu"
                    : "$remaining reformer müsait • Toplam $capacity cihaz",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isFull
                      ? const Color(0xFFE57373)
                      : const Color(0xFF7BCFA1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
