import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:moji_todo/features/tasks/data/models/project_model.dart';
import 'package:moji_todo/features/tasks/presentation/add_project_and_tags/add_project_screen.dart';
import '../../data/models/project_tag_repository.dart';

class ProjectPicker extends StatefulWidget {
  // MODIFIED: Đổi tên và kiểu dữ liệu
  final String? initialProjectId;
  final ProjectTagRepository repository;
  // MODIFIED: Kiểu dữ liệu của callback
  final ValueChanged<String?> onProjectSelected;

  const ProjectPicker({
    super.key,
    this.initialProjectId, // MODIFIED
    required this.repository,
    required this.onProjectSelected,
  });

  @override
  State<ProjectPicker> createState() => _ProjectPickerState();
}

class _ProjectPickerState extends State<ProjectPicker> {
  // MODIFIED: Đổi tên biến state
  late String? selectedProjectId;

  @override
  void initState() {
    super.initState();
    // MODIFIED: Khởi tạo bằng initialProjectId
    selectedProjectId = widget.initialProjectId;
  }

  // MODIFIED: Hàm này giờ làm việc với projectId
  void _updateProject(String? projectId) {
    setState(() {
      selectedProjectId = projectId;
    });
    widget.onProjectSelected(projectId);
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
                  'Project',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.red),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProjectScreen(
                          repository: widget.repository,
                          onProjectAdded: () {
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
              valueListenable: widget.repository.projectBox.listenable(),
              builder: (context, Box<Project> box, _) {
                final availableProjects = box.values
                    .where((project) => !project.isArchived)
                    .toList();
                return SizedBox(
                  height: 252,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: availableProjects.length,
                    itemBuilder: (context, index) {
                      final project = availableProjects[index];
                      // MODIFIED: So sánh bằng project.id
                      final isSelected = selectedProjectId == project.id;
                      return ListTile(
                        leading: Icon(
                          Icons.work,
                          color: project.color,
                          size: 24,
                        ),
                        title: Text(project.name),
                        trailing: isSelected ? const Icon(Icons.check, color: Colors.red) : null,
                        onTap: () {
                          // MODIFIED: Truyền project.id vào _updateProject
                          _updateProject(project.id);
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