import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // THÊM IMPORT
import '../../../../../core/themes/theme.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/project_tag_repository.dart';
import '../../../domain/task_cubit.dart'; // THÊM IMPORT TASK_CUBIT

const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;
const double kIconPickerItemSize = 48.0;

class EditProjectScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  // SỬA: projectKey nên là String (ID của project)
  final String projectKey; // Hoặc project.id nếu bạn truyền cả object Project
  final VoidCallback? onProjectUpdated;

  const EditProjectScreen({
    super.key,
    required this.repository,
    required this.projectKey,
    this.onProjectUpdated,
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  late TextEditingController _nameController;
  Color? _selectedColor;
  IconData? _selectedIconData;
  Project? _projectToEdit;
  bool _isLoadingData = true; // Cờ cho việc load dữ liệu ban đầu
  bool _isUpdating = false; // Cờ cho việc cập nhật

  final List<Color> _selectableColors = [
    Colors.red.shade400, Colors.pink.shade300, Colors.purple.shade300, Colors.deepPurple.shade300,
    Colors.indigo.shade300, Colors.blue.shade400, Colors.lightBlue.shade300, Colors.cyan.shade400,
    Colors.teal.shade400, Colors.green.shade400, Colors.lightGreen.shade400, Colors.lime.shade400,
    Colors.yellow.shade600, Colors.amber.shade400, Colors.orange.shade400, Colors.deepOrange.shade400,
    Colors.brown.shade400, Colors.grey.shade500, Colors.blueGrey.shade400,
  ];

  final List<IconData> selectableIcons = [
    Icons.work_outline_rounded, Icons.school_outlined, Icons.home_outlined, Icons.lightbulb_outline_rounded,
    Icons.book_outlined, Icons.fitness_center_outlined, Icons.code_rounded, Icons.palette_outlined,
    Icons.shopping_bag_outlined, Icons.flight_takeoff_rounded, Icons.account_balance_wallet_outlined, Icons.music_note_outlined,
    Icons.movie_outlined, Icons.restaurant_outlined, Icons.spa_outlined, Icons.pets_rounded,
    Icons.build_outlined, Icons.brush_outlined, Icons.camera_alt_outlined, Icons.star_border_rounded,
    Icons.category_outlined, Icons.folder_outlined, Icons.attach_money_outlined, Icons.bar_chart_outlined,
    Icons.settings_outlined, Icons.group_outlined, Icons.public_outlined, Icons.eco_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProjectData();
  }

  Future<void> _loadProjectData() async { // Đổi thành Future<void>
    setState(() {
      _isLoadingData = true;
    });
    // Giả sử projectKey là ID của project (String)
    final project = widget.repository.projectBox.get(widget.projectKey);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (project != null) {
      if (currentUser != null && project.userId == currentUser.uid) {
        setState(() {
          _projectToEdit = project;
          _nameController.text = _projectToEdit!.name;
          _selectedColor = _projectToEdit!.color;
          _selectedIconData = _projectToEdit!.icon;
          _isLoadingData = false;
        });
      } else {
        _showErrorAndPop('Bạn không có quyền chỉnh sửa project này hoặc project không tồn tại.');
        setState(() => _isLoadingData = false); // Kết thúc loading dù lỗi
      }
    } else {
      _showErrorAndPop('Không tìm thấy project để chỉnh sửa.');
      setState(() => _isLoadingData = false); // Kết thúc loading dù lỗi
    }
  }

  void _showErrorAndPop(String message) {
    // Đảm bảo context vẫn còn hợp lệ
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
    // Không tự động pop nữa, để người dùng thấy lỗi và tự quyết định
    // Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProject() async {
    if (_isUpdating || _projectToEdit == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _projectToEdit!.userId != currentUser.uid) {
      _showErrorAndPop('Không thể cập nhật project. Vui lòng thử lại.');
      return;
    }

    final String newName = _nameController.text.trim();
    final Color? newColor = _selectedColor;
    final IconData? newIcon = _selectedIconData;

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng nhập tên project!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (newColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng chọn màu cho project!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (newIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vui lòng chọn một icon cho project!'), backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }

    setState(() {
      _isUpdating = true; // Bắt đầu trạng thái cập nhật
    });

    // Tạo project mới với các thông tin đã cập nhật
    final updatedProject = _projectToEdit!.copyWith(
      name: newName,
      color: newColor,
      iconCodePoint: newIcon.codePoint,
      iconFontFamily: newIcon.fontFamily,
      iconFontPackage: newIcon.fontPackage,
      // userId và isArchived sẽ được giữ nguyên từ _projectToEdit.copyWith
    );

    try {
      // Truyền thẳng object updatedProject vào hàm update của repository
      // Repository sẽ dùng updatedProject.id làm key
      await widget.repository.updateProject(updatedProject);

      if (mounted) {
        context.read<TaskCubit>().loadInitialData(); // Cập nhật TaskState
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Project đã được cập nhật thành công!'),
              backgroundColor: Theme.of(context).extension<SuccessColor>()?.success ?? Colors.green,
            )
        );
        widget.onProjectUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Lỗi khi cập nhật project: ${e.toString().replaceFirst("Exception: ", "")}'),
                backgroundColor: Theme.of(context).colorScheme.error
            )
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false; // Kết thúc trạng thái cập nhật
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color currentIconColorOnAppBar = theme.appBarTheme.iconTheme?.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey[700]!);
    final Color currentIconColor = theme.iconTheme.color ?? (theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey[600]!);
    final Color currentHintTextColor = theme.hintColor;
    final Color currentTextFieldFillColor = theme.inputDecorationTheme.fillColor ?? (theme.brightness == Brightness.light ? Color(0xFFEFEFEF) : Colors.grey[800]!);
    final Color currentBorderColor = theme.dividerColor;

    if (_isLoadingData) {
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Edit Project', style: theme.appBarTheme.titleTextStyle),
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: currentIconColorOnAppBar), onPressed: () => Navigator.of(context).pop()),
          ),
          body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
      );
    }
    if (_projectToEdit == null) { // Trường hợp project không load được
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Edit Project', style: theme.appBarTheme.titleTextStyle),
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
            leading: IconButton(icon: Icon(Icons.arrow_back, color: currentIconColorOnAppBar), onPressed: () => Navigator.of(context).pop()),
          ),
          body: const Center(child: Text('Không thể tải dữ liệu project.'))
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: currentIconColorOnAppBar),
            onPressed: _isUpdating ? null : () => Navigator.pop(context)
        ),
        title: Text('Edit Project', style: theme.appBarTheme.titleTextStyle),
        centerTitle: true,
        actions: [
          _isUpdating
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
          )
              : IconButton(
            icon: Icon(Icons.check, color: theme.colorScheme.primary),
            onPressed: _updateProject,
            tooltip: 'Lưu thay đổi',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                labelText: 'Tên Project',
                labelStyle: TextStyle(color: currentHintTextColor),
                filled: true,
                fillColor: currentTextFieldFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: currentBorderColor.withOpacity(0.5))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _updateProject(),
            ),
            const SizedBox(height: kDefaultPadding * 1.5),
            Text(
              'Màu sắc',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.titleLarge?.color?.withOpacity(0.85)),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: kDefaultPadding / 2.5, mainAxisSpacing: kDefaultPadding / 2.5, childAspectRatio: 1),
              itemCount: _selectableColors.length,
              itemBuilder: (context, index) {
                final color = _selectableColors[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: theme.colorScheme.onSurface.withOpacity(0.9), width: 3) : Border.all(color: color.withOpacity(0.5), width: 1),
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5, spreadRadius: 1)] : null,
                    ),
                    child: isSelected ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white, size: kCircleAvatarRadius * 0.8) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: kDefaultPadding * 1.5),
            Text(
              'Icon',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.titleLarge?.color?.withOpacity(0.85)),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, crossAxisSpacing: kDefaultPadding / 2.5, mainAxisSpacing: kDefaultPadding / 2.5, childAspectRatio: 1),
              itemCount: selectableIcons.length,
              itemBuilder: (context, index) {
                final iconData = selectableIcons[index];
                final isSelected = _selectedIconData == iconData;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIconData = iconData;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : currentTextFieldFillColor.withOpacity(0.5),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : currentBorderColor.withOpacity(0.3),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? theme.colorScheme.primary : currentIconColor.withOpacity(0.8),
                      size: 22,
                    ),
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