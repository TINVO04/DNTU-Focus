import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../routes/app_routes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../domain/settings_cubit.dart';
import '../../../core/services/backup_service.dart';
import 'backup_sync_screen.dart';
import 'package:moji_todo/main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy taskBox, syncInfoBox, projectBox và tagBox từ AppData
    final appData = AppData.of(context);
    final backupService = BackupService(
      appData.taskBox,
      appData.syncInfoBox,
      appData.projectBox,
      appData.tagBox,
    );

    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final photoUrl = user?.photoURL; // Placeholder nếu không có avatar

    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const CustomAppBar(showBackButton: true),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              // Khu vực avatar và tên tài khoản
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profileSettings);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: photoUrl == null
                            ? Icon(Icons.person, size: 30, color: Theme.of(context).colorScheme.onSurface)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            'Tap to edit profile',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildSettingItem(
                context,
                icon: Icons.brightness_6,
                title: 'App Appearance',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.appAppearance);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.timer,
                title: 'Pomodoro Preferences',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.pomodoroPreferences);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.cloud_sync,
                title: 'Backup & Sync',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BackupSyncScreen(backupService: backupService),
                    ),
                  );
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.date_range,
                title: 'Date & Time',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.dateTime);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: 'Notifications',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: 'Account & Security',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.accountSecurity);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.color_lens,
                title: 'App Appearance',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.appAppearance);
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.help,
                title: 'Help & Support',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.helpSupport);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        // Color titleColor = Colors.black,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).iconTheme.color),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
      onTap: onTap,
    );
  }
}