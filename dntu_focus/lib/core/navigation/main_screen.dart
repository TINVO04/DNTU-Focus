import 'package:flutter/material.dart';
import 'package:moji_todo/features/home/presentation/home_screen.dart';
import 'package:moji_todo/features/tasks/presentation/task_manage_screen.dart';
import 'package:moji_todo/features/calendar/presentation/calendar_screen.dart';
import 'package:moji_todo/features/report/presentation/report_screen.dart';
import 'package:moji_todo/features/ai_chat/presentation/ai_chat_screen.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../navigation/navigation_manager.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: NavigationManager.currentIndex,
        builder: (context, index, child) {
          return IndexedStack(
            index: index,
            children: const [
              HomeScreen(),
              TaskManageScreen(),
              CalendarScreen(),
              ReportScreen(),
              AIChatScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: NavigationManager.currentIndex,
        builder: (context, index, child) {
          return CustomBottomNavBar(
            currentIndex: index,
            onTap: (index) {
              NavigationManager.navigate(index);
            },
          );
        },
      ),
    );
  }
}