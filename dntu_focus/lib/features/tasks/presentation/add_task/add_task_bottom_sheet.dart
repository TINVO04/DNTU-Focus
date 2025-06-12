import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/task_model.dart';
import '../../domain/task_cubit.dart';
import 'due_date_picker.dart';
import 'priority_picker.dart';
import 'tags_picker.dart';
import 'project_picker.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final ProjectTagRepository repository;
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
                hintText: 'Thêm nhiệm vụ...',
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
              'Số Pomodoro dự kiến',
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
                        color: _tagIds.isNotEmpty ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => TagsPicker(
                            initialTagIds: _tagIds,
                            repository: widget.repository,
                            onTagsSelected: (selectedTagIds) {
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
                        color: _projectId != null ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => ProjectPicker(
                            initialProjectId: _projectId,
                            repository: widget.repository,
                            onProjectSelected: (selectedProjectId) {
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
                        _titleError = 'Vui lòng nhập tên nhiệm vụ!';
                      });
                      return;
                    }
                    final now = DateTime.now();
                    final dueDate = _dueDate ?? DateTime(now.year, now.month, now.day);
                    final task = Task(
                      title: _titleController.text,
                      estimatedPomodoros: _estimatedPomodoros,
                      completedPomodoros: 0,
                      dueDate: dueDate,
                      priority: _priority,
                      tagIds: _tagIds.isNotEmpty ? _tagIds : null,
                      projectId: _projectId,
                      isCompleted: false,
                      createdAt: DateTime.now(),
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
                  child: const Text('Thêm'),
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