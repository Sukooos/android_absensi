import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/user_model.dart';
import '../../services/auth_middleware.dart';
import '../../services/auth_service.dart';
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
  AuthMiddleware? _authMiddleware;
  AuthService? _authService;
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuthMiddleware();
  }

  Future<void> _initializeAuthMiddleware() async {
    _authMiddleware = await AuthMiddleware.init();
    _authService = await AuthService.init();

    // Check authentication on page load
    if (mounted) {
      final isAuthenticated = await _authMiddleware!.checkAuth(context);
      // If authentication failed, navigation to login happens in middleware
      if (mounted && isAuthenticated) {
        // Get user data
        _user = _authService!.currentUser;

        // If not already loaded, try to load from storage
        if (_user == null) {
          _user = await _authService!.loadUserFromStorage();

          // If still null, fetch from API
          if (_user == null) {
            final result = await _authService!.getUserProfile();
            if (result['success'] && mounted) {
              _user = result['data'] as User;
            }
          }
        }

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  ProfileCard(user: _user),
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
