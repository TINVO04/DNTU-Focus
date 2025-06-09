import 'package:flutter/foundation.dart';

class NavigationManager {
  static final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  static void navigate(int index) {
    if (currentIndex.value == index) return;
    currentIndex.value = index; // Chỉ cập nhật index
  }
}