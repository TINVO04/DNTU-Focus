import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/data/models/tag_model.dart'; // Model đã được cập nhật
import '../../../core/themes/theme.dart';
import '../domain/task_cubit.dart';
import '../data/models/task_model.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task? task;

  const TaskDetailScreen({super.key, required this.task});

  String _formatDueDate(DateTime? dueDate) {
    if (dueDate == null) return 'Hôm nay'; // Hoặc 'Không có' nếu bạn muốn

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateOnly.isAtSameMomentAs(today)) {
      return 'Hôm nay';
    } else if (dueDateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Ngày mai';
    } else {
      return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 40),
        ),
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            body: Center(
              child: Text(
                'Không tìm thấy task.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    final isInTrash = task!.category == 'Trash';
    final scaffoldContext = context; // Giữ lại context của Scaffold

    // Sử dụng context.watch để tự động rebuild khi TaskCubit state thay đổi
    final taskCubitState = context.watch<TaskCubit>().state;
    final List<Project> allProjects = taskCubitState.allProjects;
    final List<Tag> allTags = taskCubitState.allTags; // allTags giờ đã được cập nhật

    String projectNameDisplay = 'Không có dự án';
    Color projectColorDisplay = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    Project? currentProjectInstance;

    if (task!.projectId != null && task!.projectId != 'no_project_id') {
      try {
        currentProjectInstance = allProjects.firstWhere((p) => p.id == task!.projectId);
        projectNameDisplay = currentProjectInstance.name;
        projectColorDisplay = currentProjectInstance.color;
      } catch (e) {
        // print('Lỗi TaskDetailScreen: Không tìm thấy project với ID: ${task!.projectId} cho task "${task!.title}"');
        projectNameDisplay = 'ID Dự án: ${task!.projectId}';
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        title: Text(
          task!.title ?? 'Task không có tiêu đề',
          style: Theme.of(context).textTheme.titleLarge,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
            onSelected: (value) async {
              if (value == 'Delete') {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    bool isLoading = false;
                    return StatefulBuilder( //Sử dụng StatefulBuilder cho dialog
                      builder: (alertContext, setStateDialog) { // Đổi tên setState
                        return AlertDialog(
                          title: Text(
                            isInTrash ? 'Xóa vĩnh viễn' : 'Xóa Task',
                            style: Theme.of(alertContext).textTheme.titleLarge,
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isInTrash
                                    ? 'Bạn có chắc muốn xóa vĩnh viễn task "${task!.title}" không?'
                                    : 'Task "${task!.title}" sẽ được chuyển vào Thùng rác. Bạn có muốn tiếp tục?',
                                style: Theme.of(alertContext).textTheme.bodyMedium,
                              ),
                              if (isLoading) ...[
                                const SizedBox(height: 16),
                                const CircularProgressIndicator(),
                              ],
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                              child: Text('Hủy', style: Theme.of(alertContext).textTheme.bodyMedium),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                setStateDialog(() => isLoading = true); // Sử dụng setStateDialog
                                try {
                                  if (isInTrash) {
                                    await BlocProvider.of<TaskCubit>(scaffoldContext).deleteTask(task!);
                                  } else {
                                    await BlocProvider.of<TaskCubit>(scaffoldContext).updateTask(
                                      task!.copyWith(
                                        category: 'Trash',
                                        originalCategory: task!.category ?? 'Planned',
                                      ),
                                    );
                                  }
                                  if (!scaffoldContext.mounted) return;
                                  Navigator.pop(dialogContext);
                                  Navigator.pop(scaffoldContext, true);
                                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                    SnackBar(
                                      content: Text(isInTrash ? 'Task đã được xóa vĩnh viễn!' : 'Task đã được chuyển vào Thùng rác!'),
                                      backgroundColor: isInTrash
                                          ? Theme.of(scaffoldContext).colorScheme.error
                                          : Theme.of(scaffoldContext).extension<SuccessColor>()?.success ?? Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  setStateDialog(() => isLoading = false); // Sử dụng setStateDialog
                                  if (!scaffoldContext.mounted) return;
                                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Theme.of(scaffoldContext).colorScheme.error),
                                  );
                                }
                              },
                              child: Text(
                                isInTrash ? 'Xóa vĩnh viễn' : 'Xóa',
                                style: Theme.of(alertContext).textTheme.bodyMedium?.copyWith(color: Theme.of(alertContext).colorScheme.error),
                              ),
                            ),
                            if (isInTrash) // Nút khôi phục
                              TextButton(
                                onPressed: isLoading ? null : () async {
                                  setStateDialog(() => isLoading = true);
                                  try {
                                    await BlocProvider.of<TaskCubit>(scaffoldContext).updateTask(
                                        task!.copyWith(category: task!.originalCategory ?? 'Planned', originalCategory: null)
                                    );
                                    if(!scaffoldContext.mounted) return;
                                    Navigator.pop(dialogContext);
                                    Navigator.pop(scaffoldContext, true);
                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                      SnackBar(
                                        content: const Text('Task đã được khôi phục!'),
                                        backgroundColor: Theme.of(scaffoldContext).extension<SuccessColor>()?.success ?? Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    setStateDialog(() => isLoading = false);
                                    if(!scaffoldContext.mounted) return;
                                    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                                      SnackBar(content: Text('Lỗi khi khôi phục: $e'), backgroundColor: Theme.of(scaffoldContext).colorScheme.error),
                                    );
                                  }
                                },
                                child: Text(
                                  'Khôi phục',
                                  style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(dialogContext).extension<SuccessColor>()?.success ?? Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Delete', child: Text(isInTrash ? 'Thao tác khác...' : 'Xóa')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTaskDetailItem(
              context: context,
              icon: task!.isCompleted == true ? Icons.check_circle : Icons.radio_button_unchecked,
              title: 'Trạng thái',
              value: task!.isCompleted == true ? 'Đã hoàn thành' : 'Chưa hoàn thành',
              valueColor: task!.isCompleted == true ? Theme.of(context).extension<SuccessColor>()?.success : null,
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
            _buildTaskDetailItem(
              context: context,
              icon: Icons.timer_outlined,
              title: 'Pomodoro',
              value: '${task!.completedPomodoros ?? 0}/${task!.estimatedPomodoros ?? 0}',
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
            _buildTaskDetailItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              title: 'Ngày đến hạn',
              value: _formatDueDate(task!.dueDate),
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
            _buildTaskDetailItem(
              context: context,
              icon: Icons.flag_outlined,
              title: 'Độ ưu tiên',
              value: task!.priority ?? 'Không đặt',
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
            _buildTaskDetailItem(
              context: context,
              icon: currentProjectInstance?.icon ?? Icons.bookmark_border,
              title: 'Dự án',
              value: projectNameDisplay,
              valueColor: projectColorDisplay,
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
            _buildTaskDetailItem(
              context: context,
              icon: Icons.alarm_outlined,
              title: 'Nhắc nhở',
              value: 'Chưa đặt',
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
            _buildTaskDetailItem(
              context: context,
              icon: Icons.repeat_outlined,
              title: 'Lặp lại',
              value: 'Không',
              backgroundColor: Theme.of(context).cardTheme.color,
            ),
            const SizedBox(height: 16),

            if (task!.subtasks != null && task!.subtasks!.isNotEmpty) ...[
              Text('Subtasks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              ...task!.subtasks!.map((subtask) => ListTile(
                leading: Checkbox(
                  value: subtask['completed'] ?? false,
                  onChanged: (value) {
                    // TODO: Cập nhật subtask
                  },
                  shape: const CircleBorder(),
                  activeColor: Theme.of(context).extension<SuccessColor>()?.success,
                ),
                title: Text(
                  subtask['title'] ?? 'Subtask không có tiêu đề',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: (subtask['completed'] ?? false) ? TextDecoration.lineThrough : TextDecoration.none,
                    color: (subtask['completed'] ?? false)
                        ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              )),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextButton.icon(
                icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                label: Text('Thêm subtask', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                onPressed: () {
                  // TODO: Logic thêm subtask
                },
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 0), alignment: Alignment.centerLeft),
              ),
            ),
            const SizedBox(height: 8),

            // --- SỬA HIỂN THỊ TAGS ---
            if (task!.tagIds != null && task!.tagIds!.isNotEmpty) ...[
              Text('Thẻ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, // Khoảng cách giữa các thẻ
                runSpacing: 4, // Khoảng cách giữa các dòng thẻ nếu wrap
                children: task!.tagIds!.map((tagId) {
                  Tag? currentTag;
                  try {
                    currentTag = allTags.firstWhere((t) => t.id == tagId);
                  } catch (e) {
                    // Lỗi không tìm thấy tag, bỏ qua hiển thị tag này
                  }
                  if (currentTag == null) return const SizedBox.shrink();

                  // Hiển thị Text thay vì Chip
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), // Thêm padding nhẹ cho mỗi Text
                    child: Text(
                      '#${currentTag.name}',
                      style: TextStyle(
                        fontSize: 16, // Kích thước chữ cho tag
                        color: currentTag.textColor, // Màu chữ của tag
                        // fontWeight: FontWeight.w500, // Có thể thêm độ đậm nếu muốn
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            // --- Hết phần Tags ---

            if (task!.note != null && task!.note!.isNotEmpty) ...[
              Text('Ghi chú', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3))),
                child: Text(task!.note!, style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 16),
            ],
            Text('Tệp đính kèm', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.attach_file, color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
              title: Text(
                'Chưa có tệp đính kèm',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Điều hướng đến màn hình edit task
          print('Edit button tapped for task: ${task!.title}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chức năng chỉnh sửa task chưa được triển khai.')),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildTaskDetailItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Color? backgroundColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultTextColor = isDark ? Theme.of(context).colorScheme.onSurface : Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;
    final Color mutedTextColor = isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.black54;
    final Color iconColor = isDark ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: defaultTextColor)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: valueColor ?? mutedTextColor, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}