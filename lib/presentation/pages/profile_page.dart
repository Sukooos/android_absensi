import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late SessionService _sessionService;
  late AuthService _authService;
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);

    _sessionService = await SessionService.init();
    _authService = await AuthService.init();

    // Try to load user from local storage first
    _user = await _authService.loadUserFromStorage();

    // If user is not in storage or we need fresh data, fetch from API
    if (_user == null) {
      final result = await _authService.getUserProfile();
      if (result['success']) {
        _user = result['data'] as User;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefreshProfile() async {
    setState(() => _isLoading = true);

    final result = await _authService.getUserProfile();
    if (result['success'] && mounted) {
      setState(() {
        _user = result['data'] as User;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal memperbarui profil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.logout();
      if (!mounted) return;

      // Navigate to login page and clear all routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildInfoTile({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.grey[800],
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: textColor ?? Colors.grey[400]),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _handleRefreshProfile,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _user?.profilePicture != null
                          ? CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: NetworkImage(
                                _user!.profilePicture!,
                              ),
                            )
                          : const CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                      const SizedBox(height: 16),
                      Text(
                        _user?.name ?? 'Nama Pengguna',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _user?.position ?? 'Posisi',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Information Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoTile(
                        label: 'ID Karyawan',
                        value: _user?.employeeId ?? '-',
                      ),
                      _buildInfoTile(
                        label: 'Email',
                        value: _user?.email ?? '-',
                      ),
                      _buildInfoTile(
                        label: 'No. Telepon',
                        value: _user?.phone ?? '-',
                      ),
                      _buildInfoTile(
                        label: 'Alamat',
                        value: _user?.address ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Ubah Password',
                        onTap: () {
                          // TODO: Implement change password
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifikasi',
                        onTap: () {
                          // TODO: Implement notifications settings
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingsTile(
                        icon: Icons.help_outline,
                        title: 'Bantuan',
                        onTap: () {
                          // TODO: Implement help
                        },
                      ),
                      const Divider(height: 1),
                      _buildSettingsTile(
                        icon: Icons.logout,
                        title: 'Keluar',
                        textColor: Colors.red,
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
