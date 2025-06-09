import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../domain/settings_cubit.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/widgets/custom_app_bar.dart';
import 'package:moji_todo/features/tasks/data/models/task_model.dart';

class BackupSyncScreen extends StatelessWidget {
  final BackupService backupService;
  final String forceBackupUrl = 'https://us-central1-moji-todo.cloudfunctions.net/forceBackup';

  const BackupSyncScreen({super.key, required this.backupService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(),
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              const Text(
                'Backup & Sync',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<DateTime?>(
                future: backupService.getLastBackupTime(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Loading backup status...',
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Error loading backup status',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      'Last backup: ${snapshot.data!.toString()}',
                      style: const TextStyle(color: Colors.grey),
                    );
                  }
                  return const Text(
                    'No backup yet',
                    style: TextStyle(color: Colors.grey),
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<int>(
                future: _getPendingSyncCount(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Checking pending sync...',
                      style: TextStyle(color: Colors.grey),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Error checking pending sync',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  return Text(
                    'Pending Sync: ${snapshot.data ?? 0} users',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                icon: Icons.cloud_upload,
                title: 'Backup Now',
                onTap: () async {
                  try {
                    await backupService.backupToFirestore();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup completed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    (context as Element).markNeedsBuild();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Backup failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.cloud_download,
                title: 'Restore from Cloud',
                onTap: () async {
                  try {
                    await backupService.restoreFromFirestore();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Restore completed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restore failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.delete_forever,
                title: 'Delete Cloud Backup',
                titleColor: Colors.red,
                onTap: () async {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirm Delete'),
                        content: const Text('Are you sure you want to delete your cloud backup?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              try {
                                await backupService.deleteFirestoreBackup();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cloud backup deleted successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                (context as Element).markNeedsBuild();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to delete cloud backup: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Yes',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.file_download,
                title: 'Export to Local JSON',
                onTap: () async {
                  try {
                    final filePath = await backupService.exportToLocalJson();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Exported to $filePath'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Export failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
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
        Color titleColor = Colors.black,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: titleColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black54),
      onTap: onTap,
    );
  }

  // Hàm để lấy số lượng người dùng chưa được đồng bộ (chỉ kiểm tra người dùng hiện tại)
  Future<int> _getPendingSyncCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final box = await Hive.openBox<DateTime>('sync_info');
    final lastSync = box.get('lastSync');
    final now = DateTime.now();

    if (lastSync == null || now.difference(lastSync).inMinutes >= 15) {
      return 1; // Cần đồng bộ
    }

    return 0; // Không cần đồng bộ
  }
}