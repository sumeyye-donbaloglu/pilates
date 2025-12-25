import 'package:flutter/material.dart';
import 'slot_list.dart';

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

  String get formattedDate =>
      "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F6),
      appBar: AppBar(
        title: const Text("Salon Detayı"),
        backgroundColor: const Color(0xFF7A4F4F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7A4F4F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.location,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9E6B6B),
              ),
            ),
            const SizedBox(height: 30),

            /// 📅 Tarih Seç
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formattedDate),
                    const Icon(Icons.calendar_month),
                  ],
                ),
              ),
            ),

            const Spacer(),

            /// 👉 SLOT LİSTESİNE GEÇİŞ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SlotListScreen(
                        businessId: widget.businessId,
                        businessName: widget.name, // ✅ EKLENDİ
                        date: formattedDate,
                      ),
                    ),
                  );
                },
                child: const Text("Slotları Gör"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
