import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';

class TimerModeMenu extends StatelessWidget {
  const TimerModeMenu({super.key});

  void _showTimerModeMenu(BuildContext context) {
    final homeState = context.read<HomeCubit>().state;

    bool isEditable = (!homeState.isTimerRunning && !homeState.isPaused) ||
        (!homeState.isCountingUp && homeState.timerSeconds <= 0);

    if (!isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode!'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    String timerMode = homeState.timerMode;
    int workDuration = homeState.workDuration;
    int breakDuration = homeState.breakDuration;
    bool soundEnabled = homeState.soundEnabled;
    bool autoSwitch = homeState.autoSwitch;
    String notificationSound = homeState.notificationSound;
    int totalSessions = homeState.totalSessions;

    TextEditingController workController = TextEditingController(text: workDuration.toString());
    TextEditingController breakController = TextEditingController(text: breakDuration.toString());
    TextEditingController sessionsController = TextEditingController(text: totalSessions.toString());

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
                      AppStrings.timerModeTitle,
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
                                child: DropdownButtonFormField<String>(
                                  value: timerMode,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.timerModeLabel,
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).cardTheme.color
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: '25:00 - 00:00',
                                      child: Text('25:00 - 00:00'),
                                    ),
                                    DropdownMenuItem(value: '00:00 - 0∞', child: Text('00:00 - 0∞')),
                                    DropdownMenuItem(value: 'Tùy chỉnh', child: Text('Tùy chỉnh')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      timerMode = value ?? '25:00 - 00:00';
                                      if (timerMode == '25:00 - 00:00') {
                                        workDuration = 25;
                                        breakDuration = 5;
                                        workController.text = '25';
                                        breakController.text = '5';
                                      } else if (timerMode == '00:00 - 0∞') {
                                        workDuration = 0;
                                        breakDuration = 0;
                                        workController.text = '0';
                                        breakController.text = '0';
                                      }
                                    });
                                  },
                                ),
                              ),
                              if (timerMode == 'Tùy chỉnh') ...[
                                const SizedBox(height: AppSizes.spacing / 2),
                                _buildCard(
                                  context: context,
                                  child: TextField(
                                    controller: workController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: AppStrings.workDurationLabel,
                                      labelStyle: GoogleFonts.inter(
                                        fontSize: AppSizes.labelFontSize - 2,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface
                                            : AppColors.textPrimary,
                                      ),
                                      hintText: AppStrings.workDurationHelper,
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: AppSizes.helperFontSize,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                            : AppColors.textDisabled,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.timer,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                            : AppColors.textDisabled,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).cardTheme.color
                                          : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      int? parsed = int.tryParse(value);
                                      if (parsed == null || parsed < 1 || parsed > 480) {
                                        workDuration = 25;
                                        workController.text = '25';
                                      } else {
                                        workDuration = parsed;
                                      }
                                      setState(() {});
                                    },
                                    onChanged: (value) {
                                      int? parsed = int.tryParse(value);
                                      if (parsed != null && parsed >= 1 && parsed <= 480) {
                                        workDuration = parsed;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: AppSizes.spacing / 2),
                                _buildCard(
                                  context: context,
                                  child: TextField(
                                    controller: breakController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    decoration: InputDecoration(
                                      labelText: AppStrings.breakDurationLabel,
                                      labelStyle: GoogleFonts.inter(
                                        fontSize: AppSizes.labelFontSize - 2,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface
                                            : AppColors.textPrimary,
                                      ),
                                      hintText: AppStrings.breakDurationHelper,
                                      hintStyle: GoogleFonts.inter(
                                        fontSize: AppSizes.helperFontSize,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                            : AppColors.textDisabled,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.timer,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                            : AppColors.textDisabled,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).cardTheme.color
                                          : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      int? parsed = int.tryParse(value);
                                      if (parsed == null || parsed < 1 || parsed > 60) {
                                        breakDuration = 5;
                                        breakController.text = '5';
                                      } else {
                                        breakDuration = parsed;
                                      }
                                      setState(() {});
                                    },
                                    onChanged: (value) {
                                      int? parsed = int.tryParse(value);
                                      if (parsed != null && parsed >= 1 && parsed <= 60) {
                                        breakDuration = parsed;
                                      }
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSizes.spacing / 2),
                              _buildCard(
                                context: context,
                                child: TextField(
                                  controller: sessionsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    labelText: AppStrings.sessionsLabel,
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                    hintText: AppStrings.sessionsHelper,
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textDisabled,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.repeat,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textDisabled,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark
                                        ? Theme.of(context).cardTheme.color
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    int? parsed = int.tryParse(value);
                                    if (parsed == null || parsed < 1 || parsed > 10) {
                                      totalSessions = 4;
                                      sessionsController.text = '4';
                                    } else {
                                      totalSessions = parsed;
                                    }
                                    setState(() {});
                                  },
                                  onChanged: (value) {
                                    int? parsed = int.tryParse(value);
                                    if (parsed != null && parsed >= 1 && parsed <= 10) {
                                      totalSessions = parsed;
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacing / 2),
                              _buildCard(
                                context: context,
                                child: CheckboxListTile(
                                  title: Text(
                                    AppStrings.soundLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppStrings.soundHelper,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  value: soundEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      soundEnabled = value ?? true;
                                    });
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                  checkColor: Theme.of(context).colorScheme.onSecondary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              if (soundEnabled) ...[
                                const SizedBox(height: AppSizes.spacing / 2),
                                _buildCard(
                                  context: context,
                                  child: DropdownButtonFormField<String>(
                                    value: notificationSound,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.notificationSoundLabel,
                                      labelStyle: GoogleFonts.inter(
                                        fontSize: AppSizes.labelFontSize - 2,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface
                                            : AppColors.textPrimary,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).cardTheme.color
                                          : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'bell', child: Text('Bell')),
                                      DropdownMenuItem(value: 'chime', child: Text('Chime')),
                                      DropdownMenuItem(value: 'alarm', child: Text('Alarm')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        notificationSound = value ?? 'bell';
                                        print('Selected notification sound: $notificationSound');
                                      });
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSizes.spacing / 2),
                              _buildCard(
                                context: context,
                                child: CheckboxListTile(
                                  title: Text(
                                    AppStrings.autoSwitchLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    AppStrings.autoSwitchHelper,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  value: autoSwitch,
                                  onChanged: (value) {
                                    setState(() {
                                      autoSwitch = value ?? false;
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
                            if (workController.text.isEmpty || workDuration < 1 || workDuration > 480) {
                              workDuration = 25;
                            }
                            if (breakController.text.isEmpty || breakDuration < 1 || breakDuration > 60) {
                              breakDuration = 5;
                            }
                            if (sessionsController.text.isEmpty || totalSessions < 1 || totalSessions > 10) {
                              totalSessions = 4;
                            }
                            print('Saving timer mode: timerMode=$timerMode, notificationSound=$notificationSound');
                            context.read<HomeCubit>().updateTimerMode(
                              timerMode: timerMode,
                              workDuration: workDuration,
                              breakDuration: breakDuration,
                              soundEnabled: soundEnabled,
                              autoSwitch: autoSwitch,
                              notificationSound: notificationSound,
                              totalSessions: totalSessions,
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
          previous.timerSeconds != current.timerSeconds ||
          previous.isCountingUp != current.isCountingUp,
      builder: (context, state) {
        final isEditable = (!state.isTimerRunning && !state.isPaused) ||
            (!state.isCountingUp && state.timerSeconds <= 0);

        return GestureDetector(
          onTap: () {
            if (isEditable) {
              _showTimerModeMenu(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Vui lòng dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode!'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: Tooltip(
            message: isEditable
                ? 'Chỉnh Timer Mode'
                : 'Dừng timer hoàn toàn hoặc chờ hết giờ để chỉnh Timer Mode',
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    color: isEditable
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: AppSizes.iconSize,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Timer Mode',
                    style: GoogleFonts.inter(
                      color: isEditable
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