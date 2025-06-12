import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DueDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateSelected;

  const DueDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<DueDatePicker> createState() => _DueDatePickerState();
}

class _DueDatePickerState extends State<DueDatePicker> {
  late DateTime _selectedDate;
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? _now;
  }

  void _updateSelectedDateAndClose(DateTime? date, String? quickOptionName) {
    setState(() {
      if (date != null) {
        _selectedDate = date;
      }
    });
    widget.onDateSelected(date);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final ThemeData theme = Theme.of(context);

    final double quickOptionHorizontalPadding = screenWidth < 360 ? 4.0 : 8.0;
    final double quickOptionIconSize = screenWidth < 360 ? 26.0 : 30.0;
    final double circularOptionContainerHeight = screenWidth < 360 ? 60 : 65;
    final double quickOptionMinWidth = screenWidth / 4.9;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Ngày đến hạn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: quickOptionHorizontalPadding,
              runSpacing: 8.0,
              children: [
                _buildCircularDateOption(theme, 'Hôm nay', Colors.green, Icons.wb_sunny_outlined, _now, circularOptionContainerHeight, quickOptionIconSize, quickOptionMinWidth),
                _buildCircularDateOption(theme, 'Ngày mai', Colors.blue, Icons.wb_cloudy_outlined, _now.add(const Duration(days: 1)), circularOptionContainerHeight, quickOptionIconSize, quickOptionMinWidth),
                _buildCircularDateOption(theme, 'Tuần này', Colors.purple, Icons.calendar_view_week_outlined, _now.add(Duration(days: DateTime.daysPerWeek - _now.weekday)), circularOptionContainerHeight, quickOptionIconSize, quickOptionMinWidth),
                _buildCircularDateOption(theme, 'Lên kế hoạch', Colors.red, Icons.check_circle_outline, null, circularOptionContainerHeight, quickOptionIconSize, quickOptionMinWidth),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (screenHeight * 0.43).clamp(270.0, 340.0),
              ),
              child: TableCalendar(
                firstDay: _now.subtract(const Duration(days: 30)),
                lastDay: _now.add(const Duration(days: 365 * 2)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black, size: 20),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black, size: 20),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: theme.colorScheme.onPrimary),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(color: theme.colorScheme.onSecondary),
                  outsideDaysVisible: false,
                  disabledTextStyle: TextStyle(color: Colors.grey.shade400),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  weekendStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                daysOfWeekHeight: 20,
                rowHeight: 36,
                calendarFormat: CalendarFormat.month,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: theme.dividerColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Hủy',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDateSelected(_selectedDate);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Đồng ý'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularDateOption(
      ThemeData theme,
      String label,
      Color baseColor,
      IconData icon,
      DateTime? date,
      double containerHeight,
      double iconSize,
      double minWidth,
      ) {
    bool isSelected = false;
    if (date != null && isSameDay(_selectedDate, date)) {
      isSelected = true;
    }

    Color currentButtonColor = isSelected ? baseColor : baseColor.withOpacity(0.65);
    Color? currentBorderColor;
    double currentBorderWidth = 0;
    List<BoxShadow>? currentBoxShadow;

    if (isSelected) {
      currentBorderColor = theme.brightness == Brightness.light
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface.withOpacity(0.9);
      currentBorderWidth = 2.5;
      currentBoxShadow = [
        BoxShadow(
            color: baseColor.withOpacity(0.5),
            blurRadius: 5,
            spreadRadius: 1)
      ];
    }

    return GestureDetector(
      onTap: () {
        _updateSelectedDateAndClose(date, label);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: containerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: BoxConstraints(minWidth: minWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentButtonColor,
              border: currentBorderColor != null
                  ? Border.all(color: currentBorderColor, width: currentBorderWidth)
                  : null,
              boxShadow: currentBoxShadow,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}