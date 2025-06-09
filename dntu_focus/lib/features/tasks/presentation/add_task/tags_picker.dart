import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moji_todo/features/tasks/data/models/tag_model.dart';
import 'package:moji_todo/features/tasks/presentation/add_project_and_tags/add_tag_screen.dart';
import '../../data/models/project_tag_repository.dart';

class TagsPicker extends StatefulWidget {
  // MODIFIED: Đổi tên và kiểu dữ liệu
  final List<String> initialTagIds;
  final ProjectTagRepository repository;
  // MODIFIED: Kiểu dữ liệu của callback
  final ValueChanged<List<String>> onTagsSelected;

  const TagsPicker({
    super.key,
    required this.initialTagIds, // MODIFIED
    required this.repository,
    required this.onTagsSelected,
  });

  @override
  State<TagsPicker> createState() => _TagsPickerState();
}

class _TagsPickerState extends State<TagsPicker> {
  // MODIFIED: Đổi tên biến state
  late List<String> selectedTagIds;

  @override
  void initState() {
    super.initState();
    // MODIFIED: Khởi tạo bằng initialTagIds
    selectedTagIds = List.from(widget.initialTagIds);
  }

  // MODIFIED: Hàm này giờ làm việc với tagId
  void _updateTags(String tagId) {
    setState(() {
      if (selectedTagIds.contains(tagId)) {
        selectedTagIds.remove(tagId);
      } else {
        selectedTagIds.add(tagId);
      }
    });
    widget.onTagsSelected(selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tags',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.red),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTagScreen(
                          repository: widget.repository,
                          onTagAdded: () {
                            // ValueListenableBuilder sẽ tự rebuild
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: widget.repository.tagBox.listenable(),
              builder: (context, Box<Tag> box, _) {
                final availableTags = box.values
                    .where((tag) => !tag.isArchived)
                    .toList();
                return SizedBox(
                  height: 252,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: availableTags.length,
                    itemBuilder: (context, index) {
                      final tag = availableTags[index];
                      // MODIFIED: So sánh bằng tag.id
                      final isSelected = selectedTagIds.contains(tag.id);
                      return ListTile(
                        leading: Icon(
                          Icons.local_offer,
                          color: tag.textColor,
                          size: 24,
                        ),
                        title: Text(tag.name),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                        onTap: () {
                          // MODIFIED: Truyền tag.id vào _updateTags
                          _updateTags(tag.id);
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Callback đã được gọi mỗi khi chọn, nên chỉ cần pop
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}