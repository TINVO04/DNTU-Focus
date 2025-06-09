import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/adapters.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart'; // THÊM IMPORT BLOC
import '../../data/models/project_tag_repository.dart';
import '../../data/models/tag_model.dart';
import '../../../../core/themes/theme.dart';
import '../../domain/task_cubit.dart'; // THÊM IMPORT TASK_CUBIT

class ArchivedTagsScreen extends StatefulWidget {
  final ProjectTagRepository repository;

  const ArchivedTagsScreen({super.key, required this.repository});

  @override
  State<ArchivedTagsScreen> createState() => _ArchivedTagsScreenState();
}

class _ArchivedTagsScreenState extends State<ArchivedTagsScreen> {
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
    final Color errorColorWithTheme = theme.colorScheme.error;

    return ValueListenableBuilder(
      valueListenable: widget.repository.tagBox.listenable(),
      builder: (context, Box<Tag> box, _) {
        final archivedTags = widget.repository.getArchivedTags();

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
              'Archived Tags',
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
            child: archivedTags.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_off_outlined, // Thay icon
                      size: 64, color: theme.iconTheme.color?.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thẻ nào được lưu trữ.',
                    style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                ],
              ),
            )
                : AnimationLimiter(
              child: ListView.builder(
                itemCount: archivedTags.length,
                itemBuilder: (context, index) {
                  final tag = archivedTags[index];
                  // SỬA: Lấy ID của tag, không phải key của Hive object
                  final String tagId = tag.id;

                  final bool isDarkTextColor = tag.textColor.computeLuminance() < 0.5;
                  final Color firstLetterColor = isDarkTextColor ? Colors.white : Colors.black;

                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: tag.textColor,
                                  child: Text(
                                    tag.name.isNotEmpty ? tag.name[0].toUpperCase() : 'T',
                                    style: TextStyle(color: firstLetterColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tag.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.restore_from_trash_outlined, color: successColorWithTheme, size: 24),
                                  tooltip: 'Khôi phục thẻ',
                                  onPressed: () {
                                    _debounceAction(() async {
                                      try {
                                        // Sử dụng tagId (String)
                                        await widget.repository.restoreTagByKey(tagId);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Thẻ "${tag.name}" đã được khôi phục!'),
                                            backgroundColor: successColorWithTheme,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi khi khôi phục: $e'),
                                            backgroundColor: errorColorWithTheme,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_forever_outlined, color: errorColorWithTheme, size: 24),
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
                                                      'Bạn có chắc muốn xóa vĩnh viễn thẻ "${tag.name}" không? Hành động này không thể hoàn tác và sẽ gỡ bỏ thẻ này khỏi tất cả các task liên quan.',
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
                                                    onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                                                    child: Text('Hủy', style: TextStyle(color: theme.colorScheme.primary)),
                                                  ),
                                                  TextButton(
                                                    onPressed: isLoading
                                                        ? null
                                                        : () async {
                                                      stfSetState(() => isLoading = true);
                                                      try {
                                                        // SỬA: Gọi hàm điều phối trong TaskCubit
                                                        await context.read<TaskCubit>().deleteTagAndUpdateTasks(tagId);
                                                        if (!mounted) return;
                                                        Navigator.pop(dialogContext);
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Thẻ "${tag.name}" đã được xóa vĩnh viễn!'), backgroundColor: errorColorWithTheme),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        stfSetState(() => isLoading = false);
                                                        if (!mounted) return;
                                                        Navigator.pop(dialogContext);
                                                        if (mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Lỗi khi xóa thẻ: $e'), backgroundColor: errorColorWithTheme),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: Text('Xóa vĩnh viễn', style: TextStyle(color: errorColorWithTheme)),
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