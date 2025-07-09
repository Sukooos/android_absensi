import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/user_model.dart';

class ProfileCard extends StatelessWidget {
  final User? user;
  final String? fallbackName;
  final String? fallbackPosition;
  final String? fallbackEmployeeId;

  const ProfileCard({
    super.key,
    this.user,
    this.fallbackName,
    this.fallbackPosition,
    this.fallbackEmployeeId,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? fallbackName ?? 'Nama Pengguna';
    final position = user?.position ?? fallbackPosition ?? 'Posisi';
    final employeeId = user?.employeeId ?? fallbackEmployeeId ?? '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              user?.profilePicture != null
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(user!.profilePicture!),
                    )
                  : const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 36),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'ID: $employeeId',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
