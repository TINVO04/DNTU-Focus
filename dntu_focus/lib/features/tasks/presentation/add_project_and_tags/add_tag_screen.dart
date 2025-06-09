import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // THÊM IMPORT NÀY
import '../../../../core/themes/theme.dart';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/tag_model.dart';
import '../../domain/task_cubit.dart'; // THÊM IMPORT TASK_CUBIT

const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;
const double kButtonHeight = 48.0;

class AddTagScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final VoidCallback? onTagAdded;

  const AddTagScreen({super.key, required this.repository, this.onTagAdded});

  @override
  State<AddTagScreen> createState() => _AddTagScreenState();
}

class _AddTagScreenState extends State<AddTagScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedTextColor;
  bool _isAdding = false; // Thêm cờ để quản lý trạng thái loading

  final List<Color> textColorOptions = [
    Colors.blue.shade700, Colors.pink.shade700, Colors.green.shade700, Colors.orange.shade700,
    Colors.purple.shade700, Colors.yellow.shade900, Colors.cyan.shade700, Colors.red.shade700,
    Colors.teal.shade700, Colors.lime.shade900, Colors.brown.shade700, Colors.grey.shade800,
    Colors.black,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addTag() async {
    if (_isAdding) return; // Ngăn chặn double tap

    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập tên tag!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_selectedTextColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn màu chữ cho tag!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) { // Kiểm tra mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Bạn cần đăng nhập để thêm tag!'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      return;
    }
    final String userId = currentUser.uid;

    setState(() {
      _isAdding = true; // Bắt đầu loading
    });

    try {
      await widget.repository.addTag(
        Tag(
          name: name,
          textColor: _selectedTextColor!,
          userId: userId, // userId đã được gán ở đây
        ),
      );

      if (mounted) { // Kiểm tra mounted trước khi dùng context
        context.read<TaskCubit>().loadInitialData(); // CẬP NHẬT STATE TRUNG TÂM
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tag đã được thêm thành công!'),
            backgroundColor: Theme.of(context).extension<SuccessColor>()?.success ?? Colors.green,
          ),
        );
        widget.onTagAdded?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) { // Kiểm tra mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm tag: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) { // Kiểm tra mounted
        setState(() {
          _isAdding = false; // Kết thúc loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color currentElevatedButtonColor = theme.colorScheme.primary;
    final Color currentHintTextColor = theme.hintColor;
    final Color currentTextFieldFillColor = theme.inputDecorationTheme.fillColor ?? (theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade800);
    final Color currentBorderColor = theme.dividerColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color),
          onPressed: _isAdding ? null : () => Navigator.pop(context), // Vô hiệu hóa khi đang thêm
        ),
        title: Text(
          'Add New Tag',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        actions: [
          _isAdding
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 3)
            ),
          )
              : IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.primary),
            onPressed: _addTag,
            tooltip: 'Lưu Tag',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                labelText: 'Tên Tag',
                labelStyle: TextStyle(color: currentHintTextColor),
                hintText: 'Ví dụ: Quan trọng, Việc nhà',
                hintStyle: TextStyle(color: currentHintTextColor.withOpacity(0.7)),
                filled: true,
                fillColor: currentTextFieldFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: currentBorderColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.done, // Thay đổi action
              onSubmitted: (_) => _addTag(), // Gọi _addTag khi nhấn done trên bàn phím
            ),
            const SizedBox(height: kDefaultPadding * 1.5),
            Text(
              'Màu sắc Tag',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color?.withOpacity(0.85)
              ),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: kDefaultPadding / 2.5,
                mainAxisSpacing: kDefaultPadding / 2.5,
                childAspectRatio: 1,
              ),
              itemCount: textColorOptions.length,
              itemBuilder: (context, index) {
                final color = textColorOptions[index];
                final isSelected = _selectedTextColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTextColor = color;
                    });
                  },
                  child: Container(
                    width: kCircleAvatarRadius * 1.8,
                    height: kCircleAvatarRadius * 1.8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface.withOpacity(0.9), width: 3)
                          : Border.all(color: color.withOpacity(0.5), width: 1),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        )
                      ] : null,
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white, size: kCircleAvatarRadius * 0.9)
                        : null,
                  ),
                );
              },
            ),
            const Spacer(), // Đẩy nút xuống dưới
            ElevatedButton(
              onPressed: _isAdding ? null : _addTag, // Vô hiệu hóa khi đang thêm
              style: ElevatedButton.styleFrom(
                backgroundColor: currentElevatedButtonColor,
                minimumSize: const Size(double.infinity, kButtonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Bo tròn hơn
                ),
                padding: const EdgeInsets.symmetric(vertical: 14), // Tăng padding
              ),
              child: _isAdding
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Thêm Tag',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Đảm bảo màu chữ là trắng
                ),
              ),
            ),
            const SizedBox(height: 20,)
          ],
        ),
      ),
    );
  }
}