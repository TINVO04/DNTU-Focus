import '../../../core/utils/date_utils.dart';
import '../../../core/utils/my_date_range.dart';

enum ReportTimeRange { today, thisWeek, lastTwoWeeks, thisMonth, thisYear }

extension ReportTimeRangeX on ReportTimeRange {
  MyDateRange get range {
    switch (this) {
      case ReportTimeRange.today:
        return AppDateUtils.getTodayRange();
      case ReportTimeRange.thisWeek:
        return AppDateUtils.getCurrentWeekRange();
      case ReportTimeRange.lastTwoWeeks:
        return AppDateUtils.getBiweeklyRange(); // Đổi sang getBiweeklyRange
      case ReportTimeRange.thisMonth:
        return AppDateUtils.getCurrentMonthRange();
      case ReportTimeRange.thisYear:
        return AppDateUtils.getCurrentYearRange();
    }
  }
}