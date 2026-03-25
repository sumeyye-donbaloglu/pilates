import '../theme/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.deepIndigo),
        title: const Text(
          "Salon Detayı",
          style: TextStyle(
            color: AppColors.deepIndigo,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧘‍♀️ SALON KARTI
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8CFCF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepIndigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 📅 TARİH BAŞLIK
            const Text(
              "Tarih Seç",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.deepIndigo,
              ),
            ),
            const SizedBox(height: 10),

            // 📆 TARİH SEÇİCİ
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.textMuted,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8CFCF)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepIndigo,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // ✅ SLOT BUTONU – SADE, GÜÇLÜ CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SlotListScreen(
                        businessId: widget.businessId,
                        businessName: widget.name,
                        date: formattedDate,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Slotları Gör",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
