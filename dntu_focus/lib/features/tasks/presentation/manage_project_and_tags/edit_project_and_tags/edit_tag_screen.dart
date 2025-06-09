import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // THÊM IMPORT
import '../../../../../core/themes/theme.dart';
import '../../../data/models/project_tag_repository.dart';
import '../../../data/models/tag_model.dart';
import '../../../domain/task_cubit.dart'; // THÊM IMPORT TASK_CUBIT

const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;

class EditTagScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  // SỬA: tagKey nên là String (ID của tag)
  final String tagKey; // Hoặc tag.id nếu bạn truyền cả object Tag
  final VoidCallback? onTagUpdated;

  const EditTagScreen({
    super.key,
    required this.repository,
    required this.tagKey,
    this.onTagUpdated,
  });

  @override
  State<EditTagScreen> createState() => _EditTagScreenState();
}

class _EditTagScreenState extends State<EditTagScreen> {
  late TextEditingController _nameController;
  Color? _selectedTextColor;
  Tag? _tagToEdit;
  bool _isLoadingData = true; // Cờ cho việc load dữ liệu ban đầu
  bool _isUpdating = false; // Cờ cho việc cập nhật

  final List<Color> _selectableTextColors = [
    Colors.blue.shade700, Colors.pink.shade700, Colors.green.shade700, Colors.orange.shade700,
    Colors.purple.shade700, Colors.yellow.shade900, Colors.cyan.shade700, Colors.red.shade700,
    Colors.teal.shade700, Colors.lime.shade900, Colors.brown.shade700, Colors.grey.shade800,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadTagData();
  }

  Future<void> _loadTagData() async { // Đổi thành Future<void>
    setState(() {
      _isLoadingData = true;
    });
    final tag = widget.repository.tagBox.get(widget.tagKey);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (tag != null) {
      if (currentUser != null && tag.userId == currentUser.uid) {
        setState(() {
          _tagToEdit = tag;
          _nameController.text = _tagToEdit!.name;
          _selectedTextColor = _tagToEdit!.textColor;
          _isLoadingData = false;
        });
      } else {
        _showErrorAndPop('Bạn không có quyền chỉnh sửa tag này hoặc tag không tồn tại.');
        setState(() => _isLoadingData = false);
      }
    } else {
      _showErrorAndPop('Không tìm thấy tag để chỉnh sửa.');
      setState(() => _isLoadingData = false);
    }
  }

  void _showErrorAndPop(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateTag() async {
    if (_isUpdating || _tagToEdit == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _tagToEdit!.userId != currentUser.uid) {
      _showErrorAndPop('Không thể cập nhật tag. Vui lòng thử lại.');
      return;
    }

    final String newName = _nameController.text.trim();
    final Color? newTextColor = _selectedTextColor;

    if (newName.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng nhập tên tag!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (newTextColor == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng chọn màu chữ cho tag!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    final updatedTag = _tagToEdit!.copyWith(
      name: newName,
      textColor: newTextColor,
      // userId và isArchived sẽ được giữ nguyên từ _tagToEdit.copyWith
    );

    try {
      // Truyền object Tag đã cập nhật
      await widget.repository.updateTag(updatedTag);

      if (mounted) {
        context.read<TaskCubit>().loadInitialData(); // Cập nhật TaskState
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tag đã được cập nhật thành công!'),
              backgroundColor: Theme.of(context).extension<SuccessColor>()?.success ?? Colors.green,
            )
        );
        widget.onTagUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi khi cập nhật tag: ${e.toString().replaceFirst("Exception: ", "")}'),
                backgroundColor: Theme.of(context).colorScheme.error
            )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color currentIconColorOnAppBar = theme.appBarTheme.iconTheme?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey[700]!);
    final Color currentHintTextColor = theme.hintColor;
    final Color currentTextFieldFillColor = theme.inputDecorationTheme.fillColor ?? (theme.brightness == Brightness.light ? const Color(0xFFEFEFEF) : Colors.grey[800]!);
    final Color currentBorderColor = theme.dividerColor;


    if (_isLoadingData) {
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Edit Tag', style: theme.appBarTheme.titleTextStyle),
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: currentIconColorOnAppBar), onPressed: () => Navigator.of(context).pop()),
          ),
          body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));
    }
    if (_tagToEdit == null) {
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Edit Tag', style: theme.appBarTheme.titleTextStyle),
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: currentIconColorOnAppBar), onPressed: () => Navigator.of(context).pop()),
          ),
          body: const Center(child: Text('Không thể tải dữ liệu tag để chỉnh sửa.')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: currentIconColorOnAppBar),
            onPressed: _isUpdating ? null :() => Navigator.pop(context)
        ),
        title: Text('Edit Tag', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [
          _isUpdating
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
          )
              : IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.primary),
            onPressed: _updateTag,
            tooltip: 'Lưu thay đổi',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Chip(
                label: Text(
                  _nameController.text.isNotEmpty ? _nameController.text : "Tag Preview",
                  // Sử dụng _selectedTextColor nếu có, nếu không thì dùng màu gốc của tag
                  style: TextStyle(color: _selectedTextColor ?? _tagToEdit!.textColor),
                ),
                backgroundColor: theme.brightness == Brightness.light ? Colors.grey.shade200 : Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            TextField(
              controller: _nameController,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                labelText: 'Tên Tag',
                labelStyle: TextStyle(color: currentHintTextColor),
                filled: true,
                fillColor: currentTextFieldFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: currentBorderColor.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _updateTag(),
            ),
            const SizedBox(height: kDefaultPadding * 1.5),
            Text(
              'Màu sắc Tag',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.titleLarge?.color?.withOpacity(0.85)),
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
              itemCount: _selectableTextColors.length,
              itemBuilder: (context, index) {
                final color = _selectableTextColors[index];
                final isSelected = _selectedTextColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTextColor = color),
                  child: Container(
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
                    child: isSelected ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white, size: kCircleAvatarRadius * 0.8) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: kDefaultPadding * 2),
          ],
        ),
      ),
    );
  }
}