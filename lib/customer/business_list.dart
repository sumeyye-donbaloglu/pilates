import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../business/business_profile_screen.dart';

class BusinessListScreen extends StatelessWidget {
  const BusinessListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF6F6),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Henüz kayıtlı salon yok.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF7A4F4F),
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final businessId = doc.id;
              final businessInfo =
                  Map<String, dynamic>.from(data['businessInfo'] ?? {});

              final name = businessInfo['name'] ?? 'Salon';
              final location = businessInfo['location'] ?? '';
              final reformerCount = data['reformerCount'] ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BusinessProfileScreen(
                        businessId: businessId,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      /// SOL İKON
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEFEF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.self_improvement,
                          color: Color(0xFFE48989),
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 16),

                      /// SALON BİLGİLERİ
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7A4F4F),
                              ),
                            ),
                            const SizedBox(height: 6),

                            if (location.toString().isNotEmpty)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Color(0xFF9E6B6B),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF9E6B6B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 8),

                            Text(
                              "Reformer sayısı: $reformerCount",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// SAĞ OK (DAHA SOFT)
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: Color(0xFFB07C7C),
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
  }
}