import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/task_model.dart'; // Đảm bảo TaskModel đã được cập nhật
import '../../domain/task_cubit.dart';
import 'due_date_picker.dart';
import 'priority_picker.dart';
import 'tags_picker.dart';    // Cần cập nhật file này
import 'project_picker.dart'; // Cần cập nhật file này

class AddTaskBottomSheet extends StatefulWidget {
  final ProjectTagRepository repository; // repository này có thể dùng để ProjectPicker và TagsPicker lấy danh sách project/tag
  final Map<String, dynamic>? initialTaskData;

  const AddTaskBottomSheet({
    super.key,
    required this.repository,
    this.initialTaskData,
  });

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  int _estimatedPomodoros = 1;
  DateTime? _dueDate;
  String? _priority;
  // MODIFIED: Thay đổi để lưu trữ IDs
  List<String> _tagIds = [];
  String? _projectId;
  String? _titleError;

  @override
  void initState() {
    super.initState();
    final data = widget.initialTaskData;
    if (data != null) {
      _titleController.text = data['title'] ?? '';
      if (data['duration'] != null) {
        final int duration = data['duration'];
        _estimatedPomodoros = (duration / 25).ceil();
      }
      if (data['due_date'] != null) {
        try {
          _dueDate = DateTime.parse(data['due_date']);
        } catch (_) {}
      }
      if (data['priority'] != null) {
        _priority = data['priority'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Add a Task...',
                border: InputBorder.none,
                errorText: _titleError,
                errorStyle: const TextStyle(color: Colors.red),
              ),
              onChanged: (value) {
                if (_titleError != null && value.isNotEmpty) {
                  setState(() {
                    _titleError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Estimated Pomodoros',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(8, (index) {
                  final pomodoros = index + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text('$pomodoros'),
                      selected: _estimatedPomodoros == pomodoros,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _estimatedPomodoros = pomodoros;
                          });
                        }
                      },
                      selectedColor: Colors.red,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: _estimatedPomodoros == pomodoros ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.wb_sunny,
                        color: _dueDate != null ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => DueDatePicker(
                            initialDate: _dueDate,
                            onDateSelected: (date) {
                              setState(() {
                                _dueDate = date;
                              });
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.flag,
                        color: _priority != null ? Colors.orange : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => PriorityPicker(
                            initialPriority: _priority,
                            onPrioritySelected: (priority) {
                              setState(() {
                                _priority = priority;
                              });
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.local_offer,
                        // MODIFIED: Điều kiện màu dựa trên _tagIds
                        color: _tagIds.isNotEmpty ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          // MODIFIED: Truyền initialTagIds và nhận lại selectedTagIds
                          builder: (context) => TagsPicker(
                            initialTagIds: _tagIds, // Truyền ID
                            repository: widget.repository, // Repository để lấy danh sách tags với ID
                            onTagsSelected: (selectedTagIds) { // Nhận lại danh sách ID
                              setState(() {
                                _tagIds = selectedTagIds;
                              });
                            },
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.work,
                        // MODIFIED: Điều kiện màu dựa trên _projectId
                        color: _projectId != null ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          // MODIFIED: Truyền initialProjectId và nhận lại selectedProjectId
                          builder: (context) => ProjectPicker(
                            initialProjectId: _projectId, // Truyền ID
                            repository: widget.repository, // Repository để lấy danh sách projects với ID
                            onProjectSelected: (selectedProjectId) { // Nhận lại ID
                              setState(() {
                                _projectId = selectedProjectId;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_titleController.text.isEmpty) {
                      setState(() {
                        _titleError = 'Vui lòng nhập tên task!';
                      });
                      return;
                    }
                    final dueDate = _dueDate ?? DateTime.now();
                    final task = Task(
                      // id sẽ được gán trong TaskRepository hoặc TaskCubit
                      title: _titleController.text,
                      estimatedPomodoros: _estimatedPomodoros,
                      completedPomodoros: 0,
                      dueDate: dueDate,
                      priority: _priority,
                      // MODIFIED: Sử dụng IDs
                      tagIds: _tagIds.isNotEmpty ? _tagIds : null, // Gửi null nếu rỗng, hoặc [] tùy theo model
                      projectId: _projectId,
                      isCompleted: false,
                      createdAt: DateTime.now(),
                      // completionDate sẽ là null cho task mới
                    );
                    context.read<TaskCubit>().addTask(task);
                    Navigator.pop(context, task);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}