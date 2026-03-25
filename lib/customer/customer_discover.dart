import '../theme/app_colors.dart';
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.primary,
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
    color: AppColors.primary,
    borderRadius: BorderRadius.all(Radius.circular(30)),
  ),
  labelColor: Colors.white,
  unselectedLabelColor: AppColors.primary,
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