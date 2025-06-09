import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moji_todo/features/home/presentation/widgets/task_card.dart';
import '../../../routes/app_routes.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/domain/task_cubit.dart';

class TaskBottomSheet {
  static void show(
      BuildContext context,
      Function(String, int) onPlay,
      Function(Task) onComplete,
      ) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).cardTheme.color,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Task',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.secondary),
                            onPressed: () {
                              Navigator.pushNamed(context, AppRoutes.tasks);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search task...',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          setBottomSheetState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      BlocBuilder<TaskCubit, TaskState>(
                        builder: (context, state) {
                          final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
                          final todayTasks = categorizedTasks['Today'] ?? [];
                          final filteredTasks = searchQuery.isEmpty
                              ? todayTasks
                              : todayTasks
                              .where((task) => task.title?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today Tasks',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              if (filteredTasks.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: Center(
                                    child: Text(
                                      'No tasks found.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    itemCount: filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = filteredTasks[index];
                                      return TaskCard(
                                        task: task,
                                        onPlay: () {
                                          onPlay(
                                            task.title ?? 'Untitled Task',
                                            task.estimatedPomodoros ?? 4,
                                          );
                                          Navigator.pop(context);
                                        },
                                        onComplete: () {
                                          onComplete(task);
                                        },
                                      );
                                    },
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}