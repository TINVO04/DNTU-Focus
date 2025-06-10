import 'my_date_range.dart';

class AppDateUtils {
  static MyDateRange getTodayRange() {
    final now = DateTime.now();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
    return MyDateRange(start: todayStart, end: todayEnd);
  }

  static MyDateRange getCurrentWeekRange({int startOfWeek = DateTime.monday}) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final daysToSubtract = (today.weekday - startOfWeek + 7) % 7;
    final weekStart = today.subtract(Duration(days: daysToSubtract));
    final weekEnd = weekStart.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
    return MyDateRange(start: weekStart, end: weekEnd);
  }

  static MyDateRange getLastTwoWeeksRange({int startOfWeek = DateTime.monday}) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(Duration(days: (today.weekday - startOfWeek + 7) % 7));
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    return MyDateRange(start: previousWeekStart, end: currentWeekEnd);
  }

  static MyDateRange getBiweeklyRange({int startOfWeek = DateTime.monday}) {
    final now = DateTime.now();
    final todayEnd = DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999, 999);
    final fourteenDaysAgoStart = DateTime.utc(now.year, now.month, now.day).subtract(const Duration(days: 13));
    return MyDateRange(start: fourteenDaysAgoStart, end: todayEnd);
  }

  static MyDateRange getCurrentMonthRange() {
    final now = DateTime.now();
    final monthStart = DateTime.utc(now.year, now.month, 1);
    final nextMonthStart = (now.month == 12)
        ? DateTime.utc(now.year + 1, 1, 1)
        : DateTime.utc(now.year, now.month + 1, 1);
    final monthEnd = nextMonthStart.subtract(const Duration(microseconds: 1));
    return MyDateRange(start: monthStart, end: monthEnd);
  }

  static MyDateRange getCurrentYearRange() {
    final now = DateTime.now();
    final yearStart = DateTime.utc(now.year, 1, 1);
    final yearEnd = DateTime.utc(now.year, 12, 31, 23, 59, 59, 999, 999);
    return MyDateRange(start: yearStart, end: yearEnd);
  }

  // Hàm tiện ích để cắt bỏ giờ, phút, giây
  static DateTime dateOnly(DateTime dateTime) {
    return DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
  }
}