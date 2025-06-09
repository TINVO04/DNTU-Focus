import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/task_cubit.dart';
import '../data/models/task_model.dart';
import '../data/models/project_model.dart';
import '../data/models/tag_model.dart'; // Model đã được cập nhật
import 'task_detail_screen.dart';

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        if (state.isLoading && state.tasks.where((task) => task.isCompleted == true).isEmpty) {
          return SafeArea(
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
                title: Text(
                  'Đã hoàn thành',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                centerTitle: true,
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final List<Project> allProjects = state.allProjects;
        final List<Tag> allTags = state.allTags; // allTags giờ sẽ là các Tag không có backgroundColor
        final completedTasks = state.tasks.where((task) => task.isCompleted == true).toList();

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 40),
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                'Đã hoàn thành',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        final TextEditingController controller = TextEditingController();
                        return AlertDialog(
                          title: Text(
                            'Tìm kiếm task đã hoàn thành',
                            style: Theme.of(dialogContext).textTheme.titleLarge,
                          ),
                          content: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên task...',
                              hintStyle: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              filled: true,
                              fillColor: Theme.of(dialogContext).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('Hủy', style: Theme.of(dialogContext).textTheme.bodyMedium),
                            ),
                            TextButton(
                              onPressed: () async {
                                await context.read<TaskCubit>().searchTasks(controller.text);
                                Navigator.pop(dialogContext);
                              },
                              child: Text('Tìm kiếm', style: Theme.of(dialogContext).textTheme.bodyMedium),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'Sort by Due Date') {
                      context.read<TaskCubit>().sortTasks('dueDate');
                    } else if (value == 'Sort by Priority') {
                      context.read<TaskCubit>().sortTasks('priority');
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Sort by Due Date', child: Text('Sắp xếp theo ngày đến hạn')),
                    const PopupMenuItem(value: 'Sort by Priority', child: Text('Sắp xếp theo độ ưu tiên')),
                  ],
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row( // Row for summary cards
                    // ... (Phần này giữ nguyên)
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.read<TaskCubit>().calculateTotalTime(completedTasks).toString(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tổng thời gian dự kiến',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.read<TaskCubit>().calculateElapsedTime(completedTasks).toString(),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thời gian đã hoàn thành',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: completedTasks.isEmpty
                        ? Center(
                      child: Text('Không có task nào đã hoàn thành.', style: Theme.of(context).textTheme.bodyMedium),
                    )
                        : ListView.builder(
                      itemCount: completedTasks.length,
                      itemBuilder: (context, index) {
                        final task = completedTasks[index];
                        String projectNameDisplay = task.projectId ?? 'Không có Project';
                        Color projectColorDisplay = Colors.grey;
                        if (task.projectId != null) {
                          try {
                            final project = allProjects.firstWhere((p) => p.id == task.projectId);
                            projectNameDisplay = project.name;
                            projectColorDisplay = project.color;
                          } catch (e) {
                            projectNameDisplay = 'Project ID: ${task.projectId}';
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
                                ).then((value) {
                                  if (value == true) {
                                    context.read<TaskCubit>().loadTasks();
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 4.0),
                                      child: Checkbox(
                                        value: task.isCompleted ?? false,
                                        onChanged: (value) {
                                          if (value != null) {
                                            context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                                          }
                                        },
                                        shape: const CircleBorder(),
                                        activeColor: Colors.green,
                                        checkColor: Theme.of(context).checkboxTheme.checkColor?.resolve({MaterialState.selected}),
                                        side: MaterialStateBorderSide.resolveWith(
                                              (states) => BorderSide(color: states.contains(MaterialState.selected) ? Colors.green : Colors.red),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title ?? 'Task không có tiêu đề',
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                decoration: TextDecoration.lineThrough,
                                                color: Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.6)),
                                          ),
                                          if (task.tagIds != null && task.tagIds!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: task.tagIds!.map((tagId) {
                                                  Tag? currentTag;
                                                  try {
                                                    currentTag = allTags.firstWhere((t) => t.id == tagId);
                                                  } catch (e) {
                                                    // print('Không tìm thấy tag với ID: $tagId cho task "${task.title}"');
                                                  }
                                                  if (currentTag == null) return const SizedBox.shrink();

                                                  // SỬA HIỂN THỊ CHIP CHO TAG
                                                  final bool isDarkTagColor = currentTag.textColor.computeLuminance() < 0.5;
                                                  final Color chipLabelColor = isDarkTagColor ? Colors.white : Colors.black;

                                                  return Chip(
                                                    label: Text(
                                                      currentTag.name,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: chipLabelColor, // Màu chữ trên chip
                                                      ),
                                                    ),
                                                    backgroundColor: currentTag.textColor, // Dùng textColor làm màu nền chip
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                    labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                    visualDensity: VisualDensity.compact,
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          Padding( // Phần hiển thị Pomodoro và Project
                                            // ... (Phần này giữ nguyên)
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.timer_outlined, size: 14, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${task.completedPomodoros ?? 0}/${task.estimatedPomodoros ?? 0}',
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                                    ),
                                                  ],
                                                ),
                                                if (task.projectId != null)
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.bookmark_border, size: 14, color: projectColorDisplay.withOpacity(0.7)),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        projectNameDisplay,
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: projectColorDisplay.withOpacity(0.9)),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}