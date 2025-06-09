import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Để định dạng ngày nếu cần
import '../../data/models/project_model.dart';
import '../../data/models/tag_model.dart';
import '../../domain/task_cubit.dart';
import '../../data/models/task_model.dart';

class TaskItemCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback onPlayPressed;
  final bool showDetails;
  final EdgeInsets padding;
  final Widget? actionButton;
  final VoidCallback? onLongPress;
  final bool isSelected;

  const TaskItemCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onCheckboxChanged,
    required this.onPlayPressed,
    this.showDetails = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
    this.actionButton,
    this.onLongPress, // Thêm vào constructor
    this.isSelected = false, // Thêm vào constructor, mặc định là false
  });

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
    IconData projectIconData = Icons.bookmark_border;
    Color projectAccentColor = Colors.transparent; // Màu mặc định cho dải màu

    if (task.projectId != null && task.projectId != 'no_project_id' && task.projectId!.isNotEmpty) {
      try {
        final project = allProjects.firstWhere((p) => p.id == task.projectId);
        projectNameDisplay = project.name;
        projectAccentColor = project.color; // Lấy màu từ project cho dải màu
        if (project.icon != null) {
          projectIconData = project.icon!;
        }
      } catch (e) {
        print('TaskItemCard: Không tìm thấy project với ID: ${task.projectId} cho task "${task.title}"');
        // projectNameDisplay = task.projectId; // Gỡ comment nếu muốn hiển thị ID khi lỗi
      }
    }

    final Color detailIconAndTextColor = Theme.of(context).iconTheme.color?.withOpacity(0.7) ?? Colors.grey.shade600;
    final bool isTaskCompleted = task.isCompleted ?? false;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : Theme.of(context).cardTheme.color,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Bo góc ngoài của Card
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        clipBehavior: Clip.antiAlias, // Đảm bảo dải màu không bị tràn ra ngoài nếu Card có bo góc
        child: IntrinsicHeight( // Đảm bảo Row bên trong có cùng chiều cao
          child: Row(
            children: [
              // Dải màu của dự án
              Container(
                width: 6, // Độ rộng của dải màu
                decoration: BoxDecoration(
                  color: projectAccentColor,
                  // Không cần borderRadius ở đây nữa vì Card đã clip
                ),
              ),
              // Nội dung chính của card
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: padding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (onCheckboxChanged != null)
                          Transform.scale(
                            scale: 0.85,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: onCheckboxChanged,
                              shape: const CircleBorder(),
                              activeColor: Colors.green,
                              checkColor: Theme.of(context).colorScheme.onPrimary,
                              side: MaterialStateBorderSide.resolveWith(
                                    (states) => BorderSide(color: states.contains(MaterialState.selected) ? Colors.green : Colors.red, width: 1.5),
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        if (onCheckboxChanged != null) const SizedBox(width: 8),
      
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung trong Column
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
                              const SizedBox(height: 5),
                              if (task.tagIds != null && task.tagIds!.isNotEmpty)
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 4,
                                  children: task.tagIds!.map((tagId) {
                                    Tag? currentTag;
                                    try {
                                      currentTag = allTags.firstWhere((t) => t.id == tagId);
                                    } catch (e) { /* Lỗi đã được log */ }
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
                              if (task.tagIds != null && task.tagIds!.isNotEmpty && showDetails)
                                const SizedBox(height: 7),
                              if (showDetails)
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
                                        child: Icon(
                                          Icons.flag_outlined,
                                          size: 15,
                                          color: detailIconAndTextColor,
                                        ),
                                      ),
                                    if (projectNameDisplay != null)
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                projectIconData,
                                                size: 15,
                                                color: detailIconAndTextColor,
                                              ),
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
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        if (actionButton != null)
                          actionButton!
                        else if (!isTaskCompleted)
                          IconButton(
                            icon: Icon(
                              Icons.play_circle, // Icon này có vẻ phù hợp hơn cho "play"
                              color: Theme.of(context).colorScheme.secondary,
                              size: 27,
                            ),
                            onPressed: onPlayPressed,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 22,
                            tooltip: 'Start Pomodoro for this task', // Thêm tooltip
                          ),
                        if (isTaskCompleted && actionButton == null) // Giữ khoảng trống nếu đã hoàn thành và không có actionButton
                          const SizedBox(width: 48), // Bằng kích thước IconButton
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}