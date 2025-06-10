enum ReportTimeRange { today, thisWeek, lastTwoWeeks, thisMonth }

import '../../core/utils/date_utils.dart';
import '../../core/utils/my_date_range.dart';

extension ReportTimeRangeX on ReportTimeRange {
  MyDateRange get range {
    switch (this) {
      case ReportTimeRange.today:
        return AppDateUtils.getTodayRange();
      case ReportTimeRange.thisWeek:
        return AppDateUtils.getCurrentWeekRange();
      case ReportTimeRange.lastTwoWeeks:
        return AppDateUtils.getLastTwoWeeksRange();
      case ReportTimeRange.thisMonth:
        return AppDateUtils.getCurrentMonthRange();
    }
  }
}
