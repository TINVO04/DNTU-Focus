import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/adapters.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart'; // THÊM IMPORT BLOC
import '../../../../core/themes/theme.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_tag_repository.dart';
import '../../domain/task_cubit.dart'; // THÊM IMPORT TASK_CUBIT

class ArchivedProjectsScreen extends StatefulWidget {
  final ProjectTagRepository repository;

  const ArchivedProjectsScreen({super.key, required this.repository});

  @override
  State<ArchivedProjectsScreen> createState() => _ArchivedProjectsScreenState();
}

class _ArchivedProjectsScreenState extends State<ArchivedProjectsScreen> {
  Timer? _debounce;

  void _debounceAction(VoidCallback action) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), action);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color successColorWithTheme = theme.extension<SuccessColor>()?.success ?? Colors.green;

    return ValueListenableBuilder(
      valueListenable: widget.repository.projectBox.listenable(),
      builder: (context, Box<Project> box, _) {
        final archivedProjects = widget.repository.getArchivedProjects();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Archived Projects',
              style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 24) ??
                  TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color),
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: archivedProjects.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, // Thay icon cho phù hợp
                      size: 64, color: theme.iconTheme.color?.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Không có dự án nào được lưu trữ.',
                    style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                ],
              ),
            )
                : AnimationLimiter(
              child: ListView.builder(
                itemCount: archivedProjects.length,
                itemBuilder: (context, index) {
                  final project = archivedProjects[index];
                  final IconData projectIconData = project.icon ?? Icons.folder_zip_outlined;
                  // SỬA: Lấy ID của project, không phải key của Hive object
                  final String projectId = project.id; // Sử dụng project.id

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  projectIconData,
                                  color: project.color,
                                  size: 36,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    project.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.restore_from_trash_outlined, // Icon khôi phục
                                      color: successColorWithTheme, size: 24),
                                  tooltip: 'Khôi phục dự án',
                                  onPressed: () {
                                    _debounceAction(() async {
                                      try {
                                        // Sử dụng projectId (String)
                                        await widget.repository.restoreProjectByKey(projectId);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Dự án "${project.name}" đã được khôi phục!'),
                                            backgroundColor: successColorWithTheme,
                                          ),
                                        );
                                        // Gọi loadInitialData của TaskCubit để cập nhật danh sách project trong TaskState
                                        // và cũng để các màn hình khác (như TaskManageScreen) cập nhật
                                        context.read<TaskCubit>().loadInitialData();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi khi khôi phục: $e'),
                                            backgroundColor: theme.colorScheme.error,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_forever_outlined, // Icon xóa vĩnh viễn
                                      color: theme.colorScheme.error, size: 24),
                                  tooltip: 'Xóa vĩnh viễn',
                                  onPressed: () {
                                    _debounceAction(() {
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) {
                                          bool isLoading = false;
                                          return StatefulBuilder(
                                            builder: (stfContext, stfSetState) {
                                              return AlertDialog(
                                                backgroundColor: theme.cardTheme.color ?? theme.dialogBackgroundColor,
                                                title: Text('Xóa vĩnh viễn', style: theme.textTheme.titleLarge),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Bạn có chắc muốn xóa vĩnh viễn dự án "${project.name}" không? Hành động này không thể hoàn tác và sẽ gỡ bỏ dự án này khỏi tất cả các task liên quan.',
                                                      style: theme.textTheme.bodyMedium,
                                                    ),
                                                    if (isLoading) ...[
                                                      const SizedBox(height: 16),
                                                      CircularProgressIndicator(color: theme.colorScheme.primary),
                                                    ],
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : () {
                                                      Navigator.pop(dialogContext);
                                                    },
                                                    child: Text('Hủy', style: TextStyle(color: theme.colorScheme.primary)),
                                                  ),
                                                  TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : () async {
                                                      stfSetState(() {
                                                        isLoading = true;
                                                      });
                                                      try {
                                                        // SỬA: Gọi hàm điều phối trong TaskCubit
                                                        // Truyền projectId (String)
                                                        await context.read<TaskCubit>().deleteProjectAndUpdateTasks(projectId);

                                                        if (!mounted) return;
                                                        Navigator.pop(dialogContext); // Đóng dialog xác nhận

                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Dự án "${project.name}" đã được xóa vĩnh viễn!'),
                                                              backgroundColor: theme.colorScheme.error,
                                                            ),
                                                          );
                                                        }
                                                        // TaskCubit đã gọi loadInitialData, ValueListenableBuilder sẽ tự cập nhật
                                                      } catch (e) {
                                                        stfSetState(() {
                                                          isLoading = false;
                                                        });
                                                        if (!mounted) return;
                                                        Navigator.pop(dialogContext);
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Lỗi khi xóa dự án: $e'),
                                                              backgroundColor: theme.colorScheme.error,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      'Xóa vĩnh viễn',
                                                      style: TextStyle(color: theme.colorScheme.error),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}