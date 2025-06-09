import 'package:flutter/material.dart';

class TaskCategoryCard extends StatelessWidget {
  final String title;
  final String totalTime;
  final int taskCount;
  final Color borderColor;
  final IconData? icon;
  final Color? iconColor;
  final bool showDetails;
  final bool isCompact;
  final VoidCallback? onTap;

  const TaskCategoryCard({
    super.key,
    required this.title,
    required this.totalTime,
    required this.taskCount,
    required this.borderColor,
    this.icon,
    this.iconColor,
    this.showDetails = true,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Lấy theme
    final double titleFontSize = isCompact ? 13 : 14.5; // Tăng nhẹ titleFontSize một chút
    final double detailFontSize = isCompact ? 14 : 15; // Giảm nhẹ detailFontSize
    final double iconSize = isCompact ? 20 : 22;
    final double internalPadding = isCompact ? 9 : 12; // Tăng nhẹ padding
    final double iconTextSpacing = isCompact ? 6 : 8;

    // Xác định màu chữ cho tiêu đề
    // Lựa chọn 1: Dùng màu của bodyMedium (thường là màu chữ chính)
    // final Color titleTextColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    // Lựa chọn 2: Dùng màu của titleLarge nhưng có thể giảm opacity một chút để phân biệt
    final Color titleTextColor = theme.textTheme.titleLarge?.color?.withOpacity(0.9) ??
        (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87);
    // Màu cho phần chi tiết (thời gian, số lượng task)
    final Color detailTextColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.95) ??
        (theme.brightness == Brightness.dark ? Colors.white : Colors.black);


    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(internalPadding),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.5), // Giảm độ dày border một chút
          borderRadius: BorderRadius.circular(10), // Tăng bo góc
          color: theme.cardColor.withOpacity(0.7), // Thêm một chút màu nền từ cardTheme
        ),
        child: Row(
          // mainAxisAlignment: MainAxisAlignment.center, // Bỏ cái này để icon và text thẳng hàng từ trái
          crossAxisAlignment: CrossAxisAlignment.center, // Để icon và cụm text canh giữa theo chiều dọc
          children: [
            if (icon != null)
              Padding(
                padding: EdgeInsets.only(right: iconTextSpacing),
                child: Icon(
                  icon,
                  color: iconColor ?? borderColor,
                  size: iconSize,
                ),
              ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: titleFontSize,
                        color: titleTextColor, // SỬ DỤNG MÀU CHỮ ĐÃ XÁC ĐỊNH
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showDetails) ...[
                    const SizedBox(height: 3), // Điều chỉnh khoảng cách
                    Text(
                      '$totalTime (${taskCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.w500, // Giảm một chút độ đậm cho chi tiết
                        fontSize: detailFontSize,
                        color: detailTextColor, // SỬ DỤNG MÀU CHỮ ĐÃ XÁC ĐỊNH
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}