import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'services/daily_slot_service.dart';

class RandevuManagementScreen extends StatefulWidget {
  final String businessId;

  const RandevuManagementScreen({super.key, required this.businessId});

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

  final _service = DailySlotService();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadSlots();
  }

  String get formattedDate {
    return "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
  }

  Future<void> loadSlots() async {
    setState(() => loading = true);
    final result =
        await _service.getSlotsForDay(widget.businessId, formattedDate);
    setState(() {
      slots = result;
      loading = false;
    });
  }

  Future<void> generateSlots() async {
    setState(() => loading = true);
    await _service.generateDailySlots(widget.businessId, formattedDate);
    await loadSlots();
  }

  Future<void> deleteSlot(String time) async {
    await _service.deleteSlot(
      businessId: widget.businessId,
      date: formattedDate,
      time: time,
    );
    await loadSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Randevu Yönetimi"),
        backgroundColor: const Color(0xFFE48989),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Seanslar"),
            Tab(text: "Demo Talepleri"),
          ],
        ),
        actions: [
          if (tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _service.regenerateDay(
                    widget.businessId, formattedDate);
                await loadSlots();
              },
            ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _seansTab(),
          _demoTab(),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // 🔵 TAB 1 - NORMAL SEANSLAR
  // --------------------------------------------------------
  Widget _seansTab() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _calendarPicker(),
        const SizedBox(height: 10),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (slots.isEmpty)
          _emptySlotCard()
        else
          Expanded(child: _slotList()),
      ],
    );
  }

  // --------------------------------------------------------
  // 🟣 TAB 2 - DEMO TALEPLERİ
  // --------------------------------------------------------
  Widget _demoTab() {
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(widget.businessId)
        .collection("dailySlots")
        .doc(formattedDate)
        .collection("demoRequests")
        .where("status", isEqualTo: "pending");

    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text("Bu gün için bekleyen demo talebi yok."));
        }

        final docs = snap.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(14),
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final time = data['time'] as String? ?? doc.id;
            final name = data['name'] as String? ?? "Müşteri";

            return Card(
              color: const Color(0xFFE6D9FA),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(
                  "Saat: $time",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Müşteri: $name"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveDemo(
                        time: time,
                        customerId: data['customerId'] as String,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectDemo(
                        time: time,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --------------------------------------------------------
  // ✔ DEMO ONAY / REDDET
  // --------------------------------------------------------

  Future<void> _approveDemo({
    required String time,
    required String customerId,
  }) async {
    await _service.approveDemo(
      businessId: widget.businessId,
      date: formattedDate,
      time: time,
      customerId: customerId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Demo talebi onaylandı!")),
    );
  }

  Future<void> _rejectDemo({
    required String time,
  }) async {
    await _service.rejectDemo(
      businessId: widget.businessId,
      date: formattedDate,
      time: time,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Demo talebi reddedildi.")),
    );
  }

  // --------------------------------------------------------
  // TAKVİM ve SLOT LİSTESİ
  // --------------------------------------------------------

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
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF6A4E4E),
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.calendar_month,
                color: Color(0xFFE48989), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _emptySlotCard() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bu gün için slot oluşturulmadı.",
              style: TextStyle(fontSize: 17, color: Colors.black54),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE48989),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: generateSlots,
              child: const Text(
                "Bu Gün İçin Slot Oluştur",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final time = slot["time"] as String;
        final endTime = slot["endTime"] as String? ?? "";
        final remaining = slot["remaining"] ?? 0;
        final capacity = slot["capacity"] ?? 0;
        final isFull = remaining == 0;

        return GestureDetector(
          onLongPress: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Slotu Sil"),
                content: Text("$time saatindeki slotu silmek istiyor musun?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Vazgeç"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Sil",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await deleteSlot(time);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFull ? const Color(0xFFFFE2E2) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endTime.isEmpty ? time : "$time - $endTime",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A4E4E),
                      ),
                    ),
                    if (isFull)
                      const Text("Dolu",
                          style: TextStyle(fontSize: 14, color: Colors.red))
                    else
                      Text(
                        "$remaining / $capacity müsait",
                        style: const TextStyle(
                            fontSize: 14, color: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
