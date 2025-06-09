import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../tasks/data/models/project_tag_repository.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/domain/task_cubit.dart';
import '../../tasks/presentation/add_task/add_task_bottom_sheet.dart';
import '../../tasks/presentation/task_detail_screen.dart';
import '../../tasks/presentation/widgets/task_item_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    context.read<TaskCubit>().loadTasks();
    // Cố định màu status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Light theme
      statusBarBrightness: Brightness.light, // Dark theme
    ));
  }

  List<Task> _getTasksForDay(DateTime day, List<Task> tasks) {
    return tasks.where((task) {
      if (task.dueDate == null || task.category == 'Trash') return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final selectedDate = DateTime(day.year, day.month, day.day);
      final isSameDay = taskDate.isAtSameMomentAs(selectedDate);
      print('Task: ${task.title}, DueDate: ${task.dueDate}, Same Day: $isSameDay');
      return isSameDay;
    }).toList();
  }

  bool _hasTasksOnDay(DateTime day, List<Task> tasks) {
    return tasks.any((task) {
      if (task.dueDate == null || task.category == 'Trash') return false;
      final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final selectedDate = DateTime(day.year, day.month, day.day);
      return taskDate.isAtSameMomentAs(selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectTagRepository = ProjectTagRepository(
      projectBox: Hive.box('projects'),
      tagBox: Hive.box('tags'),
    );

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        print('Padding: ${MediaQuery.of(context).padding}');
        final tasks = state.tasks ?? [];
        print('Total tasks in state: ${tasks.length}');
        final tasksForSelectedDay = _selectedDay != null ? _getTasksForDay(_selectedDay!, tasks) : [];

        return SafeArea(
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              scrolledUnderElevation: 0.0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'Lịch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      builder: (context) => AddTaskBottomSheet(
                        repository: projectTagRepository,
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    print('Selected Day: $selectedDay, Focused Day: $focusedDay');
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                    weekendStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  calendarFormat: CalendarFormat.month,
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    print('Page changed to: $focusedDay');
                  },
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final hasTasks = _hasTasksOnDay(day, tasks);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              '${day.day}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: hasTasks
                                    ? Theme.of(context).textTheme.bodyMedium?.color
                                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                                fontWeight: hasTasks ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasTasks)
                            Positioned(
                              bottom: 5,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      final hasTasks = _hasTasksOnDay(day, tasks);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${day.day}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (hasTasks)
                            Positioned(
                              bottom: 5,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                    todayBuilder: (context, day, focusedDay) {
                      final hasTasks = _hasTasksOnDay(day, tasks);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${day.day}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (hasTasks)
                            Positioned(
                              bottom: 5,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasks cho ${(_selectedDay != null) ? "${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}" : "ngày được chọn"}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        state.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : tasksForSelectedDay.isEmpty
                            ? Center(
                          child: Text(
                            'Không có task nào cho ngày này.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
                          ),
                        )
                            : Expanded(
                          child: ListView.builder(
                            itemCount: tasksForSelectedDay.length,
                            itemBuilder: (context, index) {
                              final task = tasksForSelectedDay[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: TaskItemCard(
                                  task: task,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailScreen(task: task),
                                      ),
                                    );
                                    if (result == true) {
                                      context.read<TaskCubit>().loadTasks();
                                    }
                                  },
                                  onCheckboxChanged: (value) {
                                    if (value != null) {
                                      context.read<TaskCubit>().updateTask(task.copyWith(isCompleted: value));
                                    }
                                  },
                                  onPlayPressed: () {
                                    // Logic bắt đầu Pomodoro cho task
                                  },
                                  showDetails: true,
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'calendar_fab',
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  builder: (context) => AddTaskBottomSheet(
                    repository: projectTagRepository,
                  ),
                );
              },
              child: Icon(
                Icons.add,
                color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
              ),
            ),
          ),
        );
      },
    );
  }
}