// lib/core/utils/my_date_range.dart
class MyDateRange {
  final DateTime start;
  final DateTime end;

  MyDateRange({required this.start, required this.end});

  // Bạn có thể thêm các getter hoặc phương thức tiện ích khác nếu cần
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MyDateRange &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}