import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/theme_provider.dart';
import '../../../core/widgets/custom_app_bar.dart';

class AppAppearanceScreen extends StatelessWidget {
  const AppAppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chế độ giao diện',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  children: [
                    _buildThemeOption(
                      context,
                      title: 'Light Mode',
                      value: ThemeModeOption.light,
                      currentValue: themeProvider.themeMode,
                      onTap: () => themeProvider.setThemeMode(ThemeModeOption.light),
                    ),
                    _buildThemeOption(
                      context,
                      title: 'Dark Mode',
                      value: ThemeModeOption.dark,
                      currentValue: themeProvider.themeMode,
                      onTap: () => themeProvider.setThemeMode(ThemeModeOption.dark),
                    ),
                    _buildThemeOption(
                      context,
                      title: 'Tự động (theo hệ thống)',
                      value: ThemeModeOption.auto,
                      currentValue: themeProvider.themeMode,
                      onTap: () => themeProvider.setThemeMode(ThemeModeOption.auto),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, {
        required String title,
        required ThemeModeOption value,
        required ThemeModeOption currentValue,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: value == currentValue
            ? Icon(Icons.check, color: Theme.of(context).colorScheme.secondary)
            : null,
        onTap: onTap,
      ),
    );
  }
}