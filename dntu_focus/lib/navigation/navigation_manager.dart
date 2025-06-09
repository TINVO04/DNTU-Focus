import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class NavigationManager {
  static int currentIndex = 0;

  static void navigate(BuildContext context, int index) {
    if (currentIndex == index) return;

    currentIndex = index;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.pomodoro);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.tasks);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.calendar);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.report);
        break;
      case 4:
      // Chat tab - cần route tương ứng
        break;
    }
  }
}