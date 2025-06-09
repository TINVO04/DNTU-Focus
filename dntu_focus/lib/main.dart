import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moji_todo/features/auth/data/auth_repository.dart';
import 'package:moji_todo/features/auth/domain/auth_cubit.dart';
import 'package:moji_todo/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'core/services/backup_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/unified_notification_service.dart';
import 'core/themes/theme.dart';
import 'core/themes/theme_provider.dart';
import 'features/home/domain/home_cubit.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/tasks/data/models/project_model.dart';
import 'features/tasks/data/models/project_tag_repository.dart';
import 'features/tasks/data/models/tag_model.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/domain/task_cubit.dart';

class AppData extends InheritedWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final UnifiedNotificationService notificationService;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final Box<dynamic> appStatusBox;

  const AppData({
    super.key,
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    required this.projectBox,
    required this.tagBox,
    required this.appStatusBox,
    required super.child,
  });

  static AppData of(BuildContext context) {
    final AppData? result = context.dependOnInheritedWidgetOfExactType<AppData>();
    assert(result != null, 'No AppData found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppData oldWidget) {
    return taskBox != oldWidget.taskBox ||
        syncInfoBox != oldWidget.syncInfoBox ||
        projectBox != oldWidget.projectBox ||
        tagBox != oldWidget.tagBox ||
        appStatusBox != oldWidget.appStatusBox;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(TagAdapter());

  final taskBox = await Hive.openBox<Task>('tasks');
  final syncInfoBox = await Hive.openBox<DateTime>('sync_info');
  final projectBox = await Hive.openBox<Project>('projects');
  final tagBox = await Hive.openBox<Tag>('tags');
  final appStatusBox = await Hive.openBox<dynamic>('app_status');

  final notificationService = UnifiedNotificationService();
  await notificationService.init();

  final firebaseService = FirebaseService();
  final authRepository = AuthRepository(firebaseService);

  runApp(MyApp(
    taskBox: taskBox,
    syncInfoBox: syncInfoBox,
    notificationService: notificationService,
    projectBox: projectBox,
    tagBox: tagBox,
    appStatusBox: appStatusBox,
    authRepository: authRepository,
    backupService: BackupService(taskBox, syncInfoBox, projectBox, tagBox),
  ));
}

class MyApp extends StatefulWidget {
  final Box<Task> taskBox;
  final Box<DateTime> syncInfoBox;
  final UnifiedNotificationService notificationService;
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final Box<dynamic> appStatusBox;
  final AuthRepository authRepository;
  final BackupService backupService;

  const MyApp({
    required this.taskBox,
    required this.syncInfoBox,
    required this.notificationService,
    required this.projectBox,
    required this.tagBox,
    required this.appStatusBox,
    required this.authRepository,
    required this.backupService,
    super.key,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Timer? _syncTimer; // ĐÃ XÓA

  @override
  void initState() {
    super.initState();
    // _startSyncTimer(); // ĐÃ XÓA
  }

  @override
  void dispose() {
    // _syncTimer?.cancel(); // ĐÃ XÓA
    // Đóng các box Hive khi ứng dụng thoát (quan trọng)
    // Không nên đóng ở đây nếu các service/cubit khác vẫn cần truy cập
    // Việc đóng box nên được quản lý cẩn thận hơn, có thể ở main() sau khi runApp() kết thúc
    // hoặc đảm bảo tất cả các Cubit/Service sử dụng box đều được dispose đúng cách.
    // Hiện tại, để tránh lỗi tiềm ẩn, tạm thời comment out việc đóng box ở đây.
    // widget.taskBox.close();
    // widget.syncInfoBox.close();
    // widget.projectBox.close();
    // widget.tagBox.close();
    // widget.appStatusBox.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppData(
      taskBox: widget.taskBox,
      syncInfoBox: widget.syncInfoBox,
      notificationService: widget.notificationService,
      projectBox: widget.projectBox,
      tagBox: widget.tagBox,
      appStatusBox: widget.appStatusBox,
      child: MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: widget.authRepository),
          Provider<BackupService>.value(value: widget.backupService),
          Provider<ProjectTagRepository>(
            create: (_) => ProjectTagRepository(
              projectBox: widget.projectBox,
              tagBox: widget.tagBox,
            ),
          ),
          Provider<TaskRepository>(
            create: (_) => TaskRepository(
              taskBox: widget.taskBox,
              projectBox: widget.projectBox,
              tagBox: widget.tagBox,
            ),
          ),
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              context.read<AuthRepository>(),
              context.read<BackupService>(),
              context.read<ProjectTagRepository>(),
              context.read<TaskRepository>(),
              widget.projectBox,
              widget.tagBox,
              widget.taskBox,
              widget.syncInfoBox,
              widget.appStatusBox,
            ),
          ),
          BlocProvider<TaskCubit>(
            create: (context) => TaskCubit(
              taskRepository: context.read<TaskRepository>(),
              projectTagRepository: context.read<ProjectTagRepository>(),
            )..loadInitialData(),
          ),
          BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(),
          ),
          ChangeNotifierProvider<ThemeProvider>(
            create: (context) => ThemeProvider(),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Moji ToDo',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.getThemeMode(),
              home: const SplashScreen(),
              onGenerateRoute: AppRoutes.generateRoute,
            );
          },
        ),
      ),
    );
  }
}