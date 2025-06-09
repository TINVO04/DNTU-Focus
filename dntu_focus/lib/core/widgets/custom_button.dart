import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final bool useGradient;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 20,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = Theme.of(context).colorScheme.primary;
    final defaultTextColor = Theme.of(context).colorScheme.onPrimary;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: useGradient ? null : (backgroundColor ?? defaultBackgroundColor),
        foregroundColor: textColor ?? defaultTextColor,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
        elevation: 8,
        surfaceTintColor: Colors.transparent,
      ),
      child: Container(
        decoration: useGradient
            ? BoxDecoration(
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? defaultBackgroundColor,
              (backgroundColor ?? defaultBackgroundColor).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor ?? defaultTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}