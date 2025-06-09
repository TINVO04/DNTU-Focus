import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/home_cubit.dart';
import '../domain/home_state.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/sizes.dart';
import '../../../../core/constants/strings.dart';

class WhiteNoiseMenu extends StatelessWidget {
  const WhiteNoiseMenu({super.key});

  void _showWhiteNoiseMenu(BuildContext context) {
    final homeCubit = context.read<HomeCubit>();
    final currentState = homeCubit.state;
    bool isWhiteNoiseEnabled = currentState.isWhiteNoiseEnabled;
    String selectedWhiteNoise = currentState.selectedWhiteNoise ?? 'none';
    double whiteNoiseVolume = currentState.whiteNoiseVolume;

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
                      'Cài đặt White Noise',
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
                                    'Tắt White Noise',
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.labelFontSize - 2,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Tắt âm thanh White Noise',
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.helperFontSize,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  value: !isWhiteNoiseEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      isWhiteNoiseEnabled = !(value ?? false);
                                      if (!isWhiteNoiseEnabled) {
                                        selectedWhiteNoise = 'none';
                                      }
                                    });
                                  },
                                  activeColor: Theme.of(context).colorScheme.secondary,
                                  checkColor: Theme.of(context).colorScheme.onSecondary,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              if (isWhiteNoiseEnabled) ...[
                                const SizedBox(height: AppSizes.spacing / 2),
                                _buildCard(
                                  context: context,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Âm lượng: ${(whiteNoiseVolume * 100).round()}%',
                                        style: GoogleFonts.inter(
                                          fontSize: AppSizes.labelFontSize - 2,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Theme.of(context).colorScheme.onSurface
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Slider(
                                          value: whiteNoiseVolume,
                                          min: 0.0,
                                          max: 1.0,
                                          divisions: 20,
                                          activeColor: Theme.of(context).colorScheme.secondary,
                                          inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          onChanged: (value) {
                                            setState(() {
                                              whiteNoiseVolume = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSizes.spacing / 2),
                                _buildCard(
                                  context: context,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      popupMenuTheme: PopupMenuThemeData(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                                        ),
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: selectedWhiteNoise,
                                      decoration: InputDecoration(
                                        labelText: 'Chọn âm thanh',
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
                                          value: 'none',
                                          child: Text('Không có'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'clock_ticking',
                                          child: Text('Tiếng đồng hồ'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'gentle-rain',
                                          child: Text('Mưa nhẹ'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'metronome',
                                          child: Text('Nhịp điệu'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'small-stream',
                                          child: Text('Suối nhỏ'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'water-stream',
                                          child: Text('Dòng nước'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'bonfire',
                                          child: Text('Lửa trại'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cafe',
                                          child: Text('Quán cà phê'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'library',
                                          child: Text('Thư viện'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          selectedWhiteNoise = value ?? 'none';
                                          isWhiteNoiseEnabled = value != 'none';
                                        });
                                      },
                                      menuMaxHeight: 216,
                                    ),
                                  ),
                                ),
                              ],
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
                            homeCubit.toggleWhiteNoise(isWhiteNoiseEnabled);
                            homeCubit.selectWhiteNoise(selectedWhiteNoise);
                            homeCubit.setWhiteNoiseVolume(whiteNoiseVolume);
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
      previous.isWhiteNoiseEnabled != current.isWhiteNoiseEnabled ||
          previous.selectedWhiteNoise != current.selectedWhiteNoise,
      builder: (context, state) {
        return GestureDetector(
          onTap: () => _showWhiteNoiseMenu(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Icon(
                  Icons.music_note_rounded,
                  color: state.isWhiteNoiseEnabled
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: AppSizes.iconSize,
                ),
                const SizedBox(height: 4),
                Text(
                  'White Noise',
                  style: GoogleFonts.inter(
                    color: state.isWhiteNoiseEnabled
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}