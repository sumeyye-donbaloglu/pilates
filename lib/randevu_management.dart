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
          content:
              Text(e.toString().replaceAll("Exception: ", "")),
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
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _calendarPicker(),
          const SizedBox(height: 10),
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
  // TAKVİM
  // ------------------------------------------------
  Widget _calendarPicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
          await loadSlots();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
              style: const TextStyle(fontSize: 18),
            ),
            const Icon(Icons.calendar_month),
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
        child: ElevatedButton(
          onPressed: loading ? null : generateSlots,
          child: const Text("Bu Gün İçin Slot Oluştur"),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // SLOT LİSTESİ
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isFull ? const Color(0xFFFFE2E2) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$time - $endTime",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFull
                    ? "Dolu"
                    : "$remaining / $capacity müsait",
                style: TextStyle(
                  color: isFull ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
