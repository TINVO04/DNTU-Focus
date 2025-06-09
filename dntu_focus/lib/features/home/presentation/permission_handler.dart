import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/unified_notification_service.dart';

class PermissionHandler {
  final BuildContext context;
  final MethodChannel notificationChannel;
  final UnifiedNotificationService notificationService;
  final Function({
  bool? hasNotificationPermission,
  bool? hasRequestedBackgroundPermission,
  bool? isIgnoringBatteryOptimizations,
  }) onPermissionStateChanged;

  static const MethodChannel _permissionChannel = MethodChannel('com.example.moji_todo/permissions');

  PermissionHandler({
    required this.context,
    required this.notificationChannel,
    required this.notificationService,
    required this.onPermissionStateChanged,
  });

  Future<void> checkNotificationPermission() async {
    await notificationService.init();
    try {
      final hasPermission = await notificationChannel.invokeMethod('checkNotificationPermission');
      print('Notification Permission: $hasPermission');
      onPermissionStateChanged(hasNotificationPermission: hasPermission);
      if (!hasPermission && context.mounted) {
        bool? granted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Yêu cầu quyền thông báo'),
            content: const Text('Ứng dụng cần quyền thông báo để hiển thị trạng thái timer. Vui lòng cấp quyền trong cài đặt.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('Từ chối'),
              ),
              TextButton(
                onPressed: () async {
                  await notificationChannel.invokeMethod('requestNotificationPermission');
                  Navigator.pop(context, true);
                },
                child: const Text('Cấp quyền'),
              ),
            ],
          ),
        );

        if (granted != true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission is required to display timer notifications.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking notification permission: $e');
      onPermissionStateChanged(hasNotificationPermission: false);
    }
  }

  Future<void> checkBackgroundPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasDeclinedPermission = prefs.getBool('hasDeclinedBackgroundPermission') ?? false;
    if (hasDeclinedPermission) {
      print('User has declined background permission, skipping check');
      onPermissionStateChanged(
        hasRequestedBackgroundPermission: true,
        isIgnoringBatteryOptimizations: false,
      );
      return;
    }

    final hasRequested = prefs.getBool('hasRequestedBackgroundPermission') ?? false;
    if (!hasRequested) {
      final isIgnoringBatteryOptimizations = await _permissionChannel.invokeMethod('checkIgnoreBatteryOptimizations');
      print('Battery Optimization Ignored: $isIgnoringBatteryOptimizations');
      onPermissionStateChanged(isIgnoringBatteryOptimizations: isIgnoringBatteryOptimizations);

      if (!isIgnoringBatteryOptimizations && context.mounted) {
        bool? confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Yêu cầu quyền chạy nền'),
            content: const Text(
              'Để timer hoạt động chính xác khi ứng dụng ở background, vui lòng cho phép ứng dụng chạy nền:\n'
                  '1. Bỏ qua tối ưu pin (sẽ mở cài đặt ngay).\n'
                  '2. Nếu thiết bị yêu cầu thêm, vào Settings > Apps > Moji Todo > Allow background activity.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, false);
                  await prefs.setBool('hasDeclinedBackgroundPermission', true);
                },
                child: const Text('Bỏ qua'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Mở cài đặt'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _permissionChannel.invokeMethod('requestIgnoreBatteryOptimizations');
          await prefs.setBool('hasRequestedBackgroundPermission', true);
        } else {
          await prefs.setBool('hasDeclinedBackgroundPermission', true);
        }
      }

      onPermissionStateChanged(hasRequestedBackgroundPermission: true);
    } else {
      onPermissionStateChanged(
        hasRequestedBackgroundPermission: true,
        isIgnoringBatteryOptimizations: prefs.getBool('isIgnoringBatteryOptimizations') ?? false,
      );
    }
  }
}