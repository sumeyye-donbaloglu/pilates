import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/daily_slot_service.dart';
import 'firestore_paths.dart';

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

class _RandevuManagementScreenState extends State<RandevuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  DateTime selectedDate = DateTime.now();
  bool loading = false;
  List<Map<String, dynamic>> slots = [];

  final DailySlotService _service = DailySlotService();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
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
      if (!mounted) return;
      setState(() => slots = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Slotlar yüklenemedi: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  // ------------------------------------------------
  // SLOT OLUŞTUR
  // ------------------------------------------------
  Future<void> generateSlots() async {
    setState(() => loading = true);
    try {
      await _service.generateDailySlots(widget.businessId, formattedDate);
      await loadSlots();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
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
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "Seanslar"),
            Tab(text: "Demo Talepleri"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _seansTab(),
          _demoTab(), // şimdilik pasif
        ],
      ),
    );
  }

  // ------------------------------------------------
  // TAB 1 — SEANSLAR
  // ------------------------------------------------
  Widget _seansTab() {
    return Column(
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
    );
  }

  // ------------------------------------------------
  // TAB 2 — DEMO (GEÇİCİ KAPALI)
  // ------------------------------------------------
  Widget _demoTab() {
    return const Center(
      child: Text(
        "Demo talepleri henüz aktif değil.",
        style: TextStyle(fontSize: 16),
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
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
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
        final endTime = slot['endTime'] ?? '';
        final remaining = slot['remaining'] ?? 0;
        final capacity = slot['capacity'] ?? 0;

        final isFull = remaining == 0;

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
                endTime.isEmpty ? time : "$time - $endTime",
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
