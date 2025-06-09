import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../data/models/project_model.dart';
import '../data/models/project_tag_repository.dart';
import '../data/models/tag_model.dart';
import '../domain/task_cubit.dart';
import 'manage_project_and_tags/manage_projects_tags_screen.dart';
import 'widgets/task_category_card.dart';
import 'add_task/add_task_bottom_sheet.dart';
import 'task_list_screen.dart';
import 'trash_screen.dart';
import 'completed_tasks_screen.dart';
// import 'package:collection/collection.dart'; // Có thể cần cho firstWhereOrNull nếu dùng

class TaskManageScreen extends StatelessWidget {
  const TaskManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 40), // Ép thêm padding phía trên
        ),
        child: Scaffold(
          appBar: const CustomAppBar(),
          body: Center(
            child: Text(
              'Vui lòng đăng nhập để tiếp tục.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final projectTagRepository = ProjectTagRepository(
      projectBox: Hive.box<Project>('projects'),
      tagBox: Hive.box<Tag>('tags'),
    );

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        // Lấy allProjects từ state để tra cứu tên và thông tin khác của project
        final List<Project> allProjects = state.allProjects;

        final categorizedTasks = context.read<TaskCubit>().getCategorizedTasks();
        final tasksByProject = context.read<TaskCubit>().getTasksByProject();

        // Các map projectBorderColors và projectIcons của bạn có thể cần được điều chỉnh
        // để sử dụng project.id làm key, hoặc bạn sẽ tra cứu màu/icon trực tiếp từ ProjectModel
        // Hiện tại, tôi sẽ giữ nguyên cách bạn dùng tên project làm key cho map này,
        // và chúng ta sẽ lấy tên project từ allProjects để tra cứu trong các map này.
        final projectBorderColors = {
          'Pomodoro App': Colors.red,
          'Fashion App': Colors.green[200]!,
          'AI Chatbot App': Colors.cyan[200]!,
          'Dating App': Colors.pink[200]!,
          'Quiz App': Colors.blue[200]!,
          'News App': Colors.blue[200]!, // Có vẻ trùng màu với Quiz App
          'General': Colors.blue[200]!,  // Cũng trùng màu
          'no_project_id_display_name': Colors.grey, // Key cho project không có ID (nếu bạn đặt tên hiển thị riêng)
        };
        final projectIcons = {
          'Pomodoro App': Icons.local_pizza_outlined,
          'Fashion App': Icons.check_box_outlined,
          'AI Chatbot App': Icons.smart_toy_outlined,
          'Dating App': Icons.favorite_outline,
          'Quiz App': Icons.quiz_outlined,
          'News App': Icons.newspaper_outlined,
          'General': Icons.category_outlined,
          'no_project_id_display_name': Icons.folder_off_outlined,
        };

        final spacing = 12.0;

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 40), // Ép thêm padding phía trên
          ),
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'Manage Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              centerTitle: true,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
                  onSelected: (value) {
                    if (value == 'Manage Projects and Tags') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageProjectsTagsScreen(
                            repository: projectTagRepository,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'Manage Projects and Tags',
                      child: Text('Manage Projects and Tags'),
                    ),
                  ],
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2,
                    children: [
                      TaskCategoryCard(
                        title: 'Hôm nay',
                        totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Today'] ?? []),
                        taskCount: categorizedTasks['Today']?.length ?? 0,
                        borderColor: Colors.green,
                        icon: Icons.wb_sunny_outlined,
                        iconColor: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskListScreen(category: 'Today'),
                            ),
                          );
                        },
                      ),
                      TaskCategoryCard(
                        title: 'Ngày mai',
                        totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Tomorrow'] ?? []),
                        taskCount: categorizedTasks['Tomorrow']?.length ?? 0,
                        borderColor: Colors.blue,
                        icon: Icons.wb_cloudy_outlined,
                        iconColor: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskListScreen(category: 'Tomorrow'),
                            ),
                          );
                        },
                      ),
                      TaskCategoryCard(
                        title: 'Tuần này',
                        totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['This Week'] ?? []),
                        taskCount: categorizedTasks['This Week']?.length ?? 0,
                        borderColor: Colors.orange,
                        icon: Icons.calendar_today_outlined,
                        iconColor: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskListScreen(category: 'This Week'),
                            ),
                          );
                        },
                      ),
                      TaskCategoryCard(
                        title: 'Đã lên kế hoạch',
                        totalTime: context.read<TaskCubit>().calculateTotalTime(categorizedTasks['Planned'] ?? []),
                        taskCount: categorizedTasks['Planned']?.length ?? 0,
                        borderColor: Colors.purple,
                        icon: Icons.event_note_outlined,
                        iconColor: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TaskListScreen(category: 'Planned'),
                            ),
                          );
                        },
                      ),
                      TaskCategoryCard(
                        title: 'Đã hoàn thành',
                        totalTime: '',
                        taskCount: categorizedTasks['Completed']?.length ?? 0,
                        borderColor: Colors.green[200]!,
                        icon: Icons.check_circle_outline,
                        iconColor: Colors.green[200]!,
                        showDetails: false,
                        isCompact: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CompletedTasksScreen(),
                            ),
                          );
                        },
                      ),
                      TaskCategoryCard(
                        title: 'Thùng rác',
                        totalTime: '',
                        taskCount: categorizedTasks['Trash']?.length ?? 0,
                        borderColor: Colors.red,
                        icon: Icons.delete_outline,
                        iconColor: Colors.red,
                        showDetails: false,
                        isCompact: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrashScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Dự án',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2,
                    children: tasksByProject.keys.map((projectIdFromKey) { // Đổi tên biến để rõ ràng
                      String projectNameDisplay;
                      Color projectColorDisplay;
                      IconData? projectIconDisplay;
                      Project? projectModel; // Biến để lưu ProjectModel tìm được

                      if (projectIdFromKey == 'no_project_id') { // Key bạn dùng cho task không có project trong TaskCubit
                        projectNameDisplay = 'Không có dự án';
                        projectColorDisplay = projectBorderColors['no_project_id_display_name'] ?? Colors.grey;
                        projectIconDisplay = projectIcons['no_project_id_display_name'];
                      } else {
                        try {
                          // Tìm ProjectModel từ allProjects bằng projectIdFromKey
                          projectModel = allProjects.firstWhere((p) => p.id == projectIdFromKey);
                          projectNameDisplay = projectModel.name;
                          // Lấy màu và icon trực tiếp từ ProjectModel nếu có, hoặc từ map nếu bạn muốn giữ map
                          projectColorDisplay = projectModel.color; // Ưu tiên màu từ model
                          projectIconDisplay = projectModel.icon; // Lấy icon từ model (nếu đã thêm)

                          // Fallback nếu ProjectModel chưa có icon, hoặc bạn muốn dùng map projectIcons
                          projectIconDisplay ??= projectIcons[projectModel.name];
                          // Fallback cho màu nếu projectModel.color không hợp lệ hoặc bạn muốn dùng map
                          // projectColorDisplay = projectBorderColors[projectModel.name] ?? projectModel.color;

                        } catch (e) {
                          print('Lỗi TaskManageScreen: Không tìm thấy project với ID: $projectIdFromKey trong state.allProjects');
                          projectNameDisplay = 'Dự án ID: ${projectIdFromKey.substring(0, (projectIdFromKey.length > 8) ? 8 : projectIdFromKey.length)}...';
                          projectColorDisplay = Colors.grey;
                          projectIconDisplay = Icons.folder_off_outlined;
                        }
                      }

                      return TaskCategoryCard(
                        title: projectNameDisplay, // Hiển thị tên project đã tra cứu
                        totalTime: context.read<TaskCubit>().calculateTotalTime(tasksByProject[projectIdFromKey]!),
                        taskCount: tasksByProject[projectIdFromKey]!.length,
                        borderColor: projectColorDisplay,
                        icon: projectIconDisplay,
                        iconColor: projectColorDisplay,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Truyền projectId (là projectIdFromKey) vào TaskListScreen
                              builder: (context) => TaskListScreen(
                                category: 'project', // Để TaskListScreen biết là đang xem theo project
                                filterId: projectIdFromKey == 'no_project_id' ? null : projectIdFromKey, // Truyền projectId
                                // Có thể truyền cả project name nếu TaskListScreen cần hiển thị ngay
                                // initialScreenTitle: projectNameDisplay
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 72),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'tasks_fab_manage_screen', // Đổi heroTag nếu cần
              backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  builder: (_) => BlocProvider.value(
                    value: BlocProvider.of<TaskCubit>(context), // Cung cấp TaskCubit hiện tại
                    child: AddTaskBottomSheet(
                      repository: projectTagRepository,
                    ),
                  ),
                );
              },
              child: Icon(Icons.add, color: Theme.of(context).floatingActionButtonTheme.foregroundColor),
            ),
          ),
        );
      },
    );
  }
}