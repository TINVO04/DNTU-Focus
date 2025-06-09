import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import các model và cubit cần thiết của bạn
import '../../../tasks/data/models/project_model.dart';
import '../../../tasks/data/models/tag_model.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/domain/task_cubit.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onPlay; // Callback khi nhấn nút "Play" -> chọn task cho Pomodoro
  final VoidCallback onComplete; // Callback khi nhấn Checkbox -> hoàn thành task

  const TaskCard({
    super.key,
    required this.task,
    required this.onPlay,
    required this.onComplete,
  });

  // Hàm helper để lấy IconData cho dueDate (giữ lại từ code bạn cung cấp ban đầu)
  IconData _getDueDateIconData(BuildContext context, DateTime? dueDate) {
    if (dueDate == null) {
      return Icons.calendar_today_outlined;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateOnly.isAtSameMomentAs(today)) {
      return Icons.wb_sunny_outlined;
    } else if (dueDateOnly.isAtSameMomentAs(tomorrow)) {
      return Icons.wb_cloudy_outlined;
    }
    return Icons.event_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final taskCubitState = context.watch<TaskCubit>().state;
    final List<Project> allProjects = taskCubitState.allProjects;
    final List<Tag> allTags = taskCubitState.allTags;

    String? projectNameDisplay;
    IconData projectIconData = Icons.bookmark_border; // Icon mặc định
    Color projectAccentColor = Colors.transparent; // Màu mặc định cho viền

    if (task.projectId != null && task.projectId != 'no_project_id' && task.projectId!.isNotEmpty) {
      try {
        final project = allProjects.firstWhere((p) => p.id == task.projectId);
        projectNameDisplay = project.name;
        projectAccentColor = project.color; // Lấy màu từ project
        if (project.icon != null) {
          projectIconData = project.icon!;
        }
      } catch (e) {
        print('TaskCard: Không tìm thấy project với ID: ${task.projectId} cho task "${task.title}"');
        // projectNameDisplay = task.projectId; // Hoặc hiển thị ID nếu không tìm thấy
      }
    }

    final Color detailIconAndTextColor = Theme.of(context).iconTheme.color?.withOpacity(0.7) ?? Colors.grey.shade600;
    final bool isTaskCompleted = task.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight( // Đảm bảo dải màu có chiều cao bằng card
        child: Row(
          children: [
            // Dải màu của dự án
            Container(
              width: 5, // Độ rộng của dải màu
              decoration: BoxDecoration(
                color: projectAccentColor, // Sử dụng màu của dự án
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11), // Bo góc theo card (nhỏ hơn 1px so với border ngoài)
                  bottomLeft: Radius.circular(11),
                ),
              ),
            ),
            // Nội dung chính của card (như bạn đã thiết kế)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Checkbox
                    Transform.scale(
                      scale: 0.85,
                      child: Checkbox(
                        value: isTaskCompleted,
                        onChanged: (value) {
                          if (value != null) { // Checkbox có thể trả về null nếu tristate
                            onComplete();
                          }
                        },
                        shape: const CircleBorder(),
                        activeColor: Colors.green,
                        checkColor: Theme.of(context).colorScheme.onPrimary,
                        side: BorderSide(
                          color: isTaskCompleted ? Colors.green : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          width: 1.5,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chi tiết task
                    Expanded(
                      child: GestureDetector( // Để có thể nhấn vào vùng text để chọn task (onPlay)
                        onTap: isTaskCompleted ? null : onPlay, // Chỉ cho phép nhấn nếu task chưa hoàn thành
                        behavior: HitTestBehavior.opaque, // Đảm bảo toàn bộ vùng GestureDetector nhận sự kiện tap
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              task.title ?? 'Task không có tiêu đề',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration: isTaskCompleted ? TextDecoration.lineThrough : null,
                                color: isTaskCompleted
                                    ? Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)
                                    : Theme.of(context).textTheme.titleMedium?.color,
                                fontWeight: isTaskCompleted ? FontWeight.normal : FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Hiển thị tags (giữ nguyên logic của bạn)
                            if (task.tagIds != null && task.tagIds!.isNotEmpty)
                              Wrap(
                                spacing: 7,
                                runSpacing: 4,
                                children: task.tagIds!.map((tagId) {
                                  Tag? currentTag;
                                  try {
                                    currentTag = allTags.firstWhere((t) => t.id == tagId);
                                  } catch (e) { /* Tag không tìm thấy */ }
                                  if (currentTag == null) return const SizedBox.shrink();
                                  return Text(
                                    '#${currentTag.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: currentTag.textColor.withOpacity(0.9),
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (task.tagIds != null && task.tagIds!.isNotEmpty)
                              const SizedBox(height: 6),
                            // Các thông tin khác (pomodoro, due date, project - giữ nguyên logic của bạn)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (task.estimatedPomodoros != null && task.estimatedPomodoros! > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.timer_outlined, size: 15, color: detailIconAndTextColor),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: detailIconAndTextColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (task.dueDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Icon(_getDueDateIconData(context, task.dueDate), size: 15, color: detailIconAndTextColor),
                                  ),
                                if (task.priority != null && task.priority!.isNotEmpty && task.priority != 'None')
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Icon(Icons.flag_outlined, size: 15, color: detailIconAndTextColor),
                                  ),
                                if (projectNameDisplay != null)
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(projectIconData, size: 15, color: detailIconAndTextColor),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            projectNameDisplay,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontSize: 12,
                                              color: detailIconAndTextColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nút Play (chọn task)
                    if (!isTaskCompleted) // Chỉ hiển thị nếu task chưa hoàn thành
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_outline,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 27,
                        ),
                        onPressed: onPlay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 22,
                        tooltip: 'Select this task for Pomodoro',
                      ),
                    if (isTaskCompleted) // Giữ khoảng trống nếu task đã hoàn thành
                      const SizedBox(width: 48), // Chiều rộng tương đương IconButton
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}