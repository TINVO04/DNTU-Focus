import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:hive/hive.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/unified_notification_service.dart';
import '../../tasks/domain/task_cubit.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/data/models/project_model.dart';
import '../../tasks/data/models/tag_model.dart';
import '../../tasks/presentation/add_task/add_task_bottom_sheet.dart';
import '../../tasks/data/models/project_tag_repository.dart';
import '../../../core/widgets/custom_app_bar.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  final GeminiService _geminiService = GeminiService();
  bool _isProcessing = false;
  bool _awaitingConfirmation = false;
  Map<String, dynamic>? _pendingCommand;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSuggestions();
    _messages.add({
      'role': 'assistant',
      'content': 'Xin chào! Mình là trợ lý AI. Bạn có thể nói hoặc nhập câu lệnh như:\n- Làm bài tập toán 25 phút 5 phút nghỉ\n- Ngày mai đi chợ 6 sáng\n- Họp nhóm lúc 3h',
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {});
  }

  void _loadSuggestions() async {
    final suggestions = await _geminiService.getSmartSuggestions("đang học toán");
    setState(() {
      _suggestions = suggestions;
    });
  }

  Future<String> _processCommand(Map<String, dynamic> commandResult) async {
    final taskCubit = context.read<TaskCubit>();
    if (commandResult['type'] == 'task') {
      final task = Task(
        title: commandResult['title'],
        estimatedPomodoros: (commandResult['duration'] / 25).ceil(),
        dueDate: commandResult['due_date'] != null
            ? DateTime.parse(commandResult['due_date'])
            : null,
        priority: commandResult['priority'],
      );
      await taskCubit.addTask(task);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm task: ${task.title}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return 'Đã thêm task: ${task.title}';
    } else if (commandResult['type'] == 'schedule') {
      final task = Task(
        title: commandResult['title'],
        dueDate: DateTime.parse(commandResult['due_date']),
        priority: commandResult['priority'] ?? 'Medium',
      );
      await taskCubit.addTask(task);

      final reminderTime = DateTime.parse(commandResult['due_date'])
          .subtract(Duration(minutes: commandResult['reminder_before']));
      final notificationService = UnifiedNotificationService();
      await notificationService.scheduleNotification(
        title: 'Nhắc nhở: ${task.title}',
        body: 'Sắp đến giờ ${task.title} vào lúc ${commandResult['due_date']}',
        scheduledTime: reminderTime,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lên lịch: ${task.title} vào ${task.dueDate}'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return 'Đã lên lịch: ${task.title} vào ${task.dueDate}';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không hiểu câu lệnh. Vui lòng thử lại!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return 'Không hiểu câu lệnh. Vui lòng thử lại!';
    }
  }

  Future<void> _handleMessage(String userMessage) async {
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isProcessing = true;
    });

    if (_awaitingConfirmation) {
      final normalized = userMessage.toLowerCase();
      if (normalized.contains('ok') || normalized.contains('xác nhận')) {
        if (_pendingCommand != null) {
          final response = await _processCommand(_pendingCommand!);
          setState(() {
            _messages.add({'role': 'assistant', 'content': response});
            _isProcessing = false;
            _awaitingConfirmation = false;
            _pendingCommand = null;
            _suggestions = [];
          });
          _loadSuggestions();
          return;
        }
      } else if (normalized.contains('chỉnh') || normalized.contains('thay')) {
        final taskData = _pendingCommand;
        setState(() {
          _isProcessing = false;
          _awaitingConfirmation = false;
          _pendingCommand = null;
          _suggestions = [];
        });
        if (taskData != null) {
          final projectTagRepository = ProjectTagRepository(
            projectBox: Hive.box<Project>('projects'),
            tagBox: Hive.box<Tag>('tags'),
          );
          final addedTask = await showModalBottomSheet<Task>(
            context: context,
            isScrollControlled: true,
            builder: (context) => BlocProvider.value(
              value: context.read<TaskCubit>(),
              child: AddTaskBottomSheet(
                repository: projectTagRepository,
                initialTaskData: taskData,
              ),
            ),
          );
          if (addedTask != null) {
            setState(() {
              _messages.add({
                'role': 'assistant',
                'content': 'Đã thêm task: ${addedTask.title}'
              });
            });
          }
        }
        _loadSuggestions();
        return;
      } else {
        // Người dùng nhập câu khác khi đang chờ xác nhận
        _awaitingConfirmation = false;
        _pendingCommand = null;
      }
    }

    final commandResult = await _geminiService.parseUserCommand(userMessage);
    if (commandResult.containsKey('error')) {
      final response = commandResult['error'] as String;
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $response'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    _pendingCommand = commandResult;
    _awaitingConfirmation = true;

    final title = commandResult['title'] ?? '';
    final duration = commandResult['duration'];
    final breakDuration = commandResult['break_duration'];
    final due = commandResult['due_date'] ??
        DateTime.now().toIso8601String().split('T').first;
    final priority = commandResult['priority'];
    final summary =
        "Thêm task \"$title\"? Pomodoro: $duration phút nghỉ $breakDuration phút, "
        "thời gian: $due, độ ưu tiên: ${priority ?? 'không'}."
        "\nGõ \"OK\" để xác nhận hoặc \"Chỉnh sửa\" để thay đổi.";

    setState(() {
      _messages.add({'role': 'assistant', 'content': summary});
      _isProcessing = false;
      _suggestions = ['OK', 'Chỉnh sửa'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 40), // Ép thêm padding phía trên
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: const CustomAppBar(),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['content']!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isProcessing)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              if (_suggestions.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _awaitingConfirmation ? _suggestions.length : _suggestions.length + 1,
                    itemBuilder: (context, index) {
                      if (!_awaitingConfirmation && index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ActionChip(
                            label: Text(
                              'Làm mới gợi ý',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            labelStyle: Theme.of(context).textTheme.bodyMedium,
                            onPressed: () {
                              setState(() {
                                _suggestions = [];
                              });
                              _loadSuggestions();
                            },
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ActionChip(
                          label: Text(
                            _awaitingConfirmation ? _suggestions[index] : _suggestions[index - 1],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          labelStyle: Theme.of(context).textTheme.bodyMedium,
                          onPressed: () async {
                            await _handleMessage(
                              _awaitingConfirmation ? _suggestions[index] : _suggestions[index - 1],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Nhập câu lệnh...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () async {
                        if (_controller.text.isNotEmpty) {
                          final message = _controller.text;
                          _controller.clear();
                          await _handleMessage(message);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _speechEnabled ? Icons.mic : Icons.mic_off,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        if (_speechEnabled) {
                          _speechToText.listen(
                            onResult: (result) async {
                              if (result.finalResult) {
                                await _handleMessage(result.recognizedWords);
                              }
                            },
                            localeId: 'vi_VN',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}