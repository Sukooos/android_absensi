import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/activity_list.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/profile_card.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<ActivityItem> _activities = List.generate(
    5,
    (index) => const ActivityItem(
      title: 'Check-in at 09:00 AM',
      location: 'Location: Office',
      time: 'Today',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Beranda Page
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileCard(
                    name: 'John Doe',
                    position: 'Software Engineer',
                    employeeId: 'EMP123',
                  ),
                  ActivityList(activities: _activities),
                  const SizedBox(height: 80), // Space for bottom navigation
                ],
              ),
            ),
          ),
          // Riwayat Page
          const Center(child: Text('Riwayat')),
          // Empty page for center button
          const SizedBox(),
          // Notifikasi Page
          const Center(child: Text('Notifikasi')),
          // Akun Saya Page
          const ProfilePage(),
        ],
      ),
      floatingActionButton: Container(
        height: 65,
        width: 65,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 2,
          shape: const CircleBorder(),
          onPressed: () {
            // TODO: Implement absen feature
          },
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, color: Colors.white, size: 24),
              Text(
                'Absen',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
