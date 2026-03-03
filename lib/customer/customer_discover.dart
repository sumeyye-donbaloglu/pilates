import 'package:flutter/material.dart';
import 'customer_explore.dart';
import 'business_list.dart';

class CustomerDiscoverScreen extends StatelessWidget {
  const CustomerDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF6F6),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: const Color(0xFFE48989),
          title: const Text(
            "Keşfet",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
        body: Column(
          children: [

            /// MODERN TAB BAR
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const TabBar( indicatorSize: TabBarIndicatorSize.tab,
  indicator: const BoxDecoration(
    color: Color(0xFFE48989),
    borderRadius: BorderRadius.all(Radius.circular(30)),
  ),
  labelColor: Colors.white,
  unselectedLabelColor: const Color(0xFFE48989),
  tabs: const [
    Tab(
      icon: Icon(Icons.dynamic_feed),
      text: "Akış",
    ),
    Tab(
      icon: Icon(Icons.store),
      text: "Salonlar",
    ),
  ],
                
              ),
            ),

            /// CONTENT
            const Expanded(
              child: TabBarView(
                children: [
                  CustomerExploreScreen(),
                  BusinessListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}