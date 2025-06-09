import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/tasks/presentation/widgets/task_item_card.dart';
import '../domain/task_cubit.dart';
import 'task_detail_screen.dart';
import '../../../core/themes/theme.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<TaskCubit>().loadTasks(); // Tải tasks khi khởi tạo
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final trashTasks = categorizedTasks['Trash'] ?? [];
        final filteredTasks = _searchQuery.isEmpty
            ? trashTasks
            : trashTasks
            .where((task) => task.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
            .toList();

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 40), // Ép thêm padding phía trên
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () {
                  if (state.isSelectionMode) {
                    context.read<TaskCubit>().toggleSelectionMode();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              title: state.isSelectionMode
                  ? Text(
                '${state.selectedTasks.length} đã chọn',
                style: Theme.of(context).textTheme.titleLarge,
              )
                  : Text(
                'Thùng rác',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: true,
              actions: state.isSelectionMode
                  ? [
                IconButton(
                  icon: Icon(Icons.restore, color: Theme.of(context).extension<SuccessColor>()!.success),
                  onPressed: () async {
                    try {
                      await context.read<TaskCubit>().restoreSelectedTasks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã khôi phục ${state.selectedTasks.length} task!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          backgroundColor: Theme.of(context).extension<SuccessColor>()!.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Lỗi khi khôi phục: $e',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                  onPressed: () => _showDeleteConfirmationDialog(context, state.selectedTasks.length),
                ),
              ]
                  : [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                  onSelected: (value) {
                    if (value == 'Sort by Title') {
                      context.read<TaskCubit>().sortTasksInTrash('title');
                    } else if (value == 'Sort by Deleted Date') {
                      context.read<TaskCubit>().sortTasksInTrash('deletedDate');
                    } else if (value == 'Select Multiple') {
                      context.read<TaskCubit>().toggleSelectionMode();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Sort by Title', child: Text('Sắp xếp theo tiêu đề')),
                    const PopupMenuItem(value: 'Sort by Deleted Date', child: Text('Sắp xếp theo ngày xóa')),
                  ],
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                await context.read<TaskCubit>().loadTasks();
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm trong thùng rác...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: state.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredTasks.isEmpty
                          ? Center(
                        child: Text(
                          'Thùng rác trống.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                        ),
                      )
                          : ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          // if (task == null) return const SizedBox.shrink();
                          // final isSelected = state.isSelectionMode && state.selectedTasks.contains(task);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TaskItemCard(
                              task: task,
                              isSelected: state.selectedTasks.contains(task), // << TRUYỀN TRẠNG THÁI CHỌN
                              onLongPress: () { // << THÊM HÀNH ĐỘNG NHẤN GIỮ
                                if (!state.isSelectionMode) {
                                  context.read<TaskCubit>().toggleSelectionMode(); // Kích hoạt chế độ chọn nếu chưa
                                }
                                context.read<TaskCubit>().toggleTaskSelection(task); // Chọn/bỏ chọn item được nhấn giữ
                              },
                              onTap: () async {
                                if (state.isSelectionMode) {
                                  // Nếu đang ở chế độ chọn, onTap cũng sẽ chọn/bỏ chọn task
                                  context.read<TaskCubit>().toggleTaskSelection(task);
                                } else {
                                  // Nếu không ở chế độ chọn, giữ nguyên hành động xem chi tiết task
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TaskDetailScreen(task: task),
                                    ),
                                  );
                                  if (result == true) {
                                    context.read<TaskCubit>().loadTasks();
                                  }
                                }
                              },
                              onCheckboxChanged: state.isSelectionMode
                                  ? (value) { // value từ Checkbox không thực sự dùng ở đây, cubit tự toggle
                                context.read<TaskCubit>().toggleTaskSelection(task);
                              }
                                  : null, // Checkbox sẽ không có hành động nếu không ở chế độ chọn
                              onPlayPressed: () {}, // Giữ nguyên
                              showDetails: true,   // Giữ nguyên hoặc thay đổi thành true nếu muốn
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Giữ nguyên
                              actionButton: state.isSelectionMode
                                  ? const SizedBox.shrink()
                                  : PopupMenuButton<String>( // Khi không ở chế độ chọn, hiển thị menu 3 chấm
                                icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                                onSelected: (value) async {
                                  if (value == 'Restore') {
                                    await _restoreTask(context, task);
                                  } else if (value == 'Delete Permanently') {
                                    await _showDeleteConfirmationDialog(context, 1, task: task);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'Restore', child: Text('Khôi phục')),
                                  const PopupMenuItem(
                                      value: 'Delete Permanently', child: Text('Xóa vĩnh viễn')),
                                ],
                              ),

                            ),
                          );
                        },
                      ),
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

  Future<void> _restoreTask(BuildContext context, dynamic task) async {
    try {
      await context.read<TaskCubit>().restoreTask(task);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task "${task.title}" đã được khôi phục!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: Theme.of(context).extension<SuccessColor>()!.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi khôi phục: $e',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, int taskCount, {dynamic task}) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Xóa vĩnh viễn',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task != null
                        ? 'Bạn có chắc muốn xóa vĩnh viễn task "${task.title}" không?'
                        : 'Bạn có chắc muốn xóa vĩnh viễn $taskCount task không?',
                    style: Theme.of(context).textTheme.bodyMedium,
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
                  child: Text(
                    'Hủy',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setState(() {
                      isLoading = true;
                    });
                    try {
                      if (task != null) {
                        await context.read<TaskCubit>().deleteTask(task);
                      } else {
                        await context.read<TaskCubit>().deleteSelectedTasks();
                      }
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            task != null
                                ? 'Task "${task.title}" đã được xóa vĩnh viễn!'
                                : 'Đã xóa vĩnh viễn $taskCount task!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Lỗi khi xóa: $e',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Xóa vĩnh viễn',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
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
}