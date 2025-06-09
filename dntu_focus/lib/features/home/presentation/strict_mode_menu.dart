import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';

class StrictModeMenu extends StatelessWidget {
  const StrictModeMenu({super.key});

  static const MethodChannel _permissionChannel = MethodChannel('com.example.moji_todo/permissions');
  static const MethodChannel _serviceChannel = MethodChannel('com.example.moji_todo/app_block_service');

  Future<bool> _checkAndRequestAccessibilityPermission(BuildContext context) async {
    try {
      final bool isPermissionEnabled = await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
      if (!isPermissionEnabled) {
        bool? granted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
            ),
            elevation: 10,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(dialogContext).brightness == Brightness.dark
                      ? [const Color(0xFF2A2A2A), const Color(0xFF3A3A3A)]
                      : [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      'Yêu cầu quyền Accessibility',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).textTheme.titleLarge!.color
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Ứng dụng cần quyền Accessibility để chặn ứng dụng khi Strict Mode được bật. Vui lòng cấp quyền trong cài đặt.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      alignment: WrapAlignment.end, // Canh các nút về phía cuối (phải)
                      children: [
                        TextButton( // Dùng TextButton cho "Hủy" để ít chiếm không gian hơn
                          onPressed: () => Navigator.pop(dialogContext, false),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(dialogContext).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text(AppStrings.cancel, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                        // Nút Cấp quyền
                        ElevatedButton( // Giữ ElevatedButton cho hành động chính
                          onPressed: () async {
                            await _permissionChannel.invokeMethod('requestAccessibilityPermission');
                            Navigator.pop(dialogContext, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(dialogContext).colorScheme.secondary,
                            foregroundColor: Theme.of(dialogContext).colorScheme.onSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Giảm padding của nút
                          ),
                          child: Text(
                            'Cấp quyền',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15, // Có thể giảm nhẹ fontSize ở đây nếu cần
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (granted != true) {
          SystemNavigator.pop();
          return false;
        }

        return await _permissionChannel.invokeMethod('isAccessibilityPermissionEnabled');
      }
      return true;
    } catch (e) {
      print('Error checking accessibility permission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi kiểm tra quyền Accessibility: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  void _showStrictModeMenu(BuildContext context) {
    final homeState = context.read<HomeCubit>().state;

    bool isEditable = homeState.isPaused ||
        (!homeState.isTimerRunning && !homeState.isPaused) ||
        (!homeState.isCountingUp && homeState.timerSeconds <= 0);

    if (!isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode!'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    bool isAppBlockingEnabled = homeState.isAppBlockingEnabled;
    bool isFlipPhoneEnabled = homeState.isFlipPhoneEnabled;
    bool isExitBlockingEnabled = homeState.isExitBlockingEnabled;
    List<String> blockedApps = List.from(homeState.blockedApps);

    final List<Map<String, String>> availableApps = [
      {'name': 'Facebook', 'package': 'com.facebook.katana'},
      {'name': 'YouTube', 'package': 'com.google.android.youtube'},
      {'name': 'Instagram', 'package': 'com.instagram.android'},
      {'name': 'TikTok', 'package': 'com.zhiliaoapp.musically'},
      {'name': 'Twitter', 'package': 'com.twitter.android'},
    ];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          body: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
            ),
            elevation: 10,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [const Color(0xFF2A2A2A), const Color(0xFF3A3A3A)]
                      : [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      AppStrings.strictModeTitle,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).textTheme.titleLarge!.color
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 350),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return Column(
                            children: [
                              _buildCard(
                                context: context,
                                child: CheckboxListTile(
                                  title: Text(
                                    AppStrings.strictModeOffLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppStrings.strictModeOffHelper,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  value: !isAppBlockingEnabled && !isFlipPhoneEnabled && !isExitBlockingEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        isAppBlockingEnabled = false;
                                        isFlipPhoneEnabled = false;
                                        isExitBlockingEnabled = false;
                                        blockedApps = [];
                                      }
                                    });
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                  checkColor: Theme.of(context).colorScheme.onSecondary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacing / 2),
                              _buildCard(
                                context: context,
                                child: CheckboxListTile(
                                  title: Text(
                                    AppStrings.appBlockingLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppStrings.appBlockingHelper,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  value: isAppBlockingEnabled,
                                  onChanged: (value) async {
                                    if (value == true) {
                                      bool permissionGranted = await _checkAndRequestAccessibilityPermission(context);
                                      if (!permissionGranted) {
                                        return;
                                      }
                                    }
                                    setState(() {
                                      isAppBlockingEnabled = value ?? false;
                                      if (!isAppBlockingEnabled) {
                                        blockedApps = [];
                                      }
                                    });
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                  checkColor: Theme.of(context).colorScheme.onSecondary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              if (isAppBlockingEnabled)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton(
                                    onPressed: () {
                                      showGeneralDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
                                        transitionDuration: const Duration(milliseconds: 300),
                                        pageBuilder: (context, _, __) {
                                          return Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                                            ),
                                            elevation: 10,
                                            backgroundColor: Colors.transparent,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: Theme.of(context).brightness == Brightness.dark
                                                      ? [const Color(0xFF2A2A2A), const Color(0xFF3A3A3A)]
                                                      : [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(AppSizes.dialogRadius),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                                    child: Text(
                                                      AppStrings.selectAppsTitle,
                                                      style: GoogleFonts.inter(
                                                        fontSize: AppSizes.titleFontSize,
                                                        fontWeight: FontWeight.w700,
                                                        color: Theme.of(context).brightness == Brightness.dark
                                                            ? Theme.of(context).textTheme.titleLarge!.color
                                                            : AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    constraints: const BoxConstraints(maxHeight: 200),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                    child: SingleChildScrollView(
                                                      child: Column(
                                                        children: availableApps.map((app) {
                                                          return _buildCard(
                                                            context: context,
                                                            child: CheckboxListTile(
                                                              title: Text(
                                                                app['name']!,
                                                                style: GoogleFonts.inter(
                                                                  fontSize: AppSizes.labelFontSize - 2,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: Theme.of(context).brightness == Brightness.dark
                                                                      ? Theme.of(context).colorScheme.onSurface
                                                                      : AppColors.textPrimary,
                                                                ),
                                                              ),
                                                              value: blockedApps.contains(app['package']),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  if (value == true) {
                                                                    blockedApps.add(app['package']!);
                                                                  } else {
                                                                    blockedApps.remove(app['package']);
                                                                  }
                                                                });
                                                              },
                                                              activeColor: Theme.of(context).colorScheme.secondary,
                                                              checkColor: Theme.of(context).colorScheme.onSecondary,
                                                              contentPadding: EdgeInsets.zero,
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: [
                                                        CustomButton(
                                                          label: AppStrings.cancel,
                                                          onPressed: () => Navigator.pop(context),
                                                          backgroundColor: AppColors.cancelButton,
                                                          textColor: AppColors.textPrimary,
                                                          borderRadius: 12,
                                                        ),
                                                        CustomButton(
                                                          label: AppStrings.ok,
                                                          onPressed: () {
                                                            context.read<HomeCubit>().updateBlockedApps(blockedApps);
                                                            _serviceChannel.invokeMethod('setBlockedApps', {'apps': blockedApps});
                                                            Navigator.pop(context);
                                                          },
                                                          backgroundColor: Theme.of(context).colorScheme.secondary,
                                                          textColor: Theme.of(context).colorScheme.onSecondary,
                                                          borderRadius: 12,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                        transitionBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOut,
                                            ),
                                            child: ScaleTransition(
                                              scale: CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              ),
                                              child: child,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Theme.of(context).colorScheme.secondary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    child: Text(
                                      AppStrings.selectApps,
                                      style: GoogleFonts.inter(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontSize: AppSizes.helperFontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSizes.spacing / 2),
                              _buildCard(
                                context: context,
                                child: CheckboxListTile(
                                  title: Text(
                                    AppStrings.flipPhoneLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppStrings.flipPhoneHelper,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  value: isFlipPhoneEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      isFlipPhoneEnabled = value ?? false;
                                    });
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                  checkColor: Theme.of(context).colorScheme.onSecondary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacing / 2),
                              _buildCard(
                                context: context,
                                child: CheckboxListTile(
                                  title: Text(
                                    AppStrings.exitBlockingLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppStrings.exitBlockingHelper,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  value: isExitBlockingEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      isExitBlockingEnabled = value ?? false;
                                    });
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                  checkColor: Theme.of(context).colorScheme.onSecondary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CustomButton(
                          label: AppStrings.cancel,
                          onPressed: () => Navigator.pop(context),
                          backgroundColor: AppColors.cancelButton,
                          textColor: AppColors.textPrimary,
                          borderRadius: 12,
                        ),
                        CustomButton(
                          label: AppStrings.ok,
                          onPressed: () {
                            context.read<HomeCubit>().updateStrictMode(
                              isAppBlockingEnabled: isAppBlockingEnabled,
                              isFlipPhoneEnabled: isFlipPhoneEnabled,
                              isExitBlockingEnabled: isExitBlockingEnabled,
                            );
                            Navigator.pop(context);
                          },
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          textColor: Theme.of(context).colorScheme.onSecondary,
                          borderRadius: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildCard({required BuildContext context, required Widget child}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardTheme.color
          : AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
      previous.isTimerRunning != current.isTimerRunning ||
          previous.isPaused != current.isPaused ||
          previous.isStrictModeEnabled != current.isStrictModeEnabled ||
          previous.timerSeconds != current.timerSeconds ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        final isEditable = state.isPaused ||
            (!state.isTimerRunning && !state.isPaused) ||
            (!state.isCountingUp && state.timerSeconds <= 0);

        return GestureDetector(
          onTap: () {
            if (isEditable) {
              _showStrictModeMenu(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vui lòng tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode!'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: Tooltip(
            message: isEditable
                ? 'Chỉnh Strict Mode'
                : 'Tạm dừng timer, dừng hoàn toàn, hoặc chờ hết giờ để chỉnh Strict Mode',
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: state.isStrictModeEnabled
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: AppSizes.iconSize,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Strict Mode',
                    style: GoogleFonts.inter(
                      color: state.isStrictModeEnabled
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}