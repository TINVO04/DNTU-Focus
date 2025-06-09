import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // THÊM IMPORT NÀY
import '../../../../core/themes/theme.dart'; // Để sử dụng SuccessColor
import '../../data/models/project_model.dart';
import '../../data/models/project_tag_repository.dart';
import '../../domain/task_cubit.dart'; // THÊM IMPORT TASK_CUBIT

// Hằng số (giữ nguyên)
const double kDefaultPadding = 16.0;
const double kCircleAvatarRadius = 20.0;
const double kIconPickerItemSize = 48.0;
const double kButtonHeight = 48.0;
// Bỏ các hằng số màu kErrorColor, kSuccessColor vì sẽ dùng từ Theme

class AddProjectScreen extends StatefulWidget {
  final ProjectTagRepository repository;
  final VoidCallback? onProjectAdded; // Callback này có thể được gọi để TaskCubit load lại

  const AddProjectScreen({super.key, required this.repository, this.onProjectAdded});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final TextEditingController _nameController = TextEditingController();
  Color? _selectedColor;
  IconData? _selectedIcon;
  bool _isAdding = false; // Thêm cờ để quản lý trạng thái loading

  final List<Color> colors = [
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addProject() async {
    if (_isAdding) return; // Ngăn chặn double tap

    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập tên project!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn màu cho project!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_selectedIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn một icon cho project!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isAdding = true; // Bắt đầu loading
    });

    try {
      // userId sẽ được tự động gán trong ProjectTagRepository.addProject
      await widget.repository.addProject(
        Project(
          name: name,
          color: _selectedColor!,
          iconCodePoint: _selectedIcon!.codePoint,
          iconFontFamily: _selectedIcon!.fontFamily,
          iconFontPackage: _selectedIcon!.fontPackage,
          // userId sẽ được gán trong repository
        ),
      );

      // Gọi loadInitialData của TaskCubit để cập nhật danh sách projects trong state
      // Điều này sẽ giúp các màn hình khác (như TaskManageScreen) tự động cập nhật
      // mà không cần truyền callback phức tạp.
      if (mounted) {
        context.read<TaskCubit>().loadInitialData(); // CẬP NHẬT STATE TRUNG TÂM
      }

      if (mounted) { // Kiểm tra mounted trước khi dùng context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Project đã được thêm thành công!'),
            backgroundColor: Theme.of(context).extension<SuccessColor>()?.success ?? Colors.green,
          ),
        );
        widget.onProjectAdded?.call(); // Gọi callback cũ nếu vẫn cần (có thể bỏ)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) { // Kiểm tra mounted trước khi dùng context
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // Hiển thị lỗi cụ thể từ repository (ví dụ: lỗi trùng tên)
            content: Text('Lỗi khi thêm project: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false; // Kết thúc loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color currentBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final Color currentTitleColor = Theme.of(context).textTheme.titleLarge?.color ?? (isDarkMode ? Colors.white : Colors.black);
    final Color currentTextColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDarkMode ? Colors.white70 : Colors.black87);
    final Color currentHintTextColor = Theme.of(context).hintColor; // Lấy từ theme
    final Color currentTextFieldFillColor = Theme.of(context).inputDecorationTheme.fillColor ?? (isDarkMode ? Colors.grey[800]! : const Color(0xFFEFEFEF)); // Màu nền textfield sáng hơn chút
    final Color currentBorderColor = Theme.of(context).dividerColor;
    final Color currentIconColor = Theme.of(context).iconTheme.color ?? (isDarkMode ? Colors.white70 : Colors.grey[600]!);


    return Scaffold(
      backgroundColor: currentBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: currentIconColor),
          onPressed: _isAdding ? null : () => Navigator.pop(context), // Vô hiệu hóa khi đang thêm
        ),
        title: Text(
          'Add New Project',
          style: TextStyle( // Giữ lại style này nếu bạn muốn nó khác với appBarTheme
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: currentTitleColor,
          ),
        ),
        centerTitle: true,
        actions: [
          _isAdding
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(
                width: 24, height: 24, // Kích thước của CircularProgressIndicator
                child: CircularProgressIndicator(strokeWidth: 3)
            ),
          )
              : IconButton(
            icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
            onPressed: _addProject,
            tooltip: 'Lưu Project',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                style: TextStyle(color: currentTextColor),
                decoration: InputDecoration(
                  labelText: 'Tên Project', // Thêm labelText
                  labelStyle: TextStyle(color: currentHintTextColor), // Style cho label
                  hintText: 'Ví dụ: Bài tập lớn Flutter',
                  hintStyle: TextStyle(color: currentHintTextColor.withOpacity(0.7)),
                  filled: true,
                  fillColor: currentTextFieldFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Bo góc nhiều hơn
                    borderSide: BorderSide.none, // Bỏ viền mặc định khi không focus
                  ),
                  enabledBorder: OutlineInputBorder( // Viền khi không focus
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: currentBorderColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), // Viền đậm hơn khi focus
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Tăng padding
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: kDefaultPadding * 1.5), // Tăng khoảng cách
              Text(
                'Màu sắc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // Đậm hơn chút
                  color: currentTitleColor.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, // Tăng số màu trên 1 hàng
                  crossAxisSpacing: kDefaultPadding / 2.5,
                  mainAxisSpacing: kDefaultPadding / 2.5,
                  childAspectRatio: 1,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9), width: 3) // Viền dày hơn khi chọn
                            : Border.all(color: color.withOpacity(0.5), width: 1), // Viền nhẹ cho các màu chưa chọn
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 5,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white, size: kCircleAvatarRadius * 0.8)
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: kDefaultPadding * 1.5),
              Text(
                'Icon',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: currentTitleColor.withOpacity(0.85),
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
                itemCount: selectableIcons.length,
                itemBuilder: (context, index) {
                  final iconData = selectableIcons[index];
                  final isSelected = _selectedIcon == iconData;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIcon = iconData;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : currentTextFieldFillColor.withOpacity(0.5),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : currentBorderColor.withOpacity(0.3),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: isSelected ? Theme.of(context).colorScheme.primary : currentIconColor.withOpacity(0.8),
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: kDefaultPadding * 2), // Thêm khoảng trống ở cuối
            ],
          ),
        ),
      ),
      // Không cần FloatingActionButton ở đây nếu dùng IconButton trên AppBar
    );
  }
}