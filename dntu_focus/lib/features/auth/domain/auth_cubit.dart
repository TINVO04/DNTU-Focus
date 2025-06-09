// auth_cubit.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';

// Đảm bảo các đường dẫn import là chính xác với cấu trúc thư mục của bạn
import '../../../../core/services/backup_service.dart';
import '../../tasks/data/models/project_model.dart';
import '../../tasks/data/models/project_tag_repository.dart';
import '../../tasks/data/models/tag_model.dart';
import '../../tasks/data/models/task_model.dart';
import '../../tasks/data/task_repository.dart';
import '../data/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final BackupService _backupService;
  final ProjectTagRepository _projectTagRepository;
  final TaskRepository _taskRepository;
  final Box<Project> _projectBox;
  final Box<Tag> _tagBox;
  final Box<Task> _taskBox;
  final Box<DateTime> _syncInfoBox;
  final Box<dynamic> _appStatusBox;

  StreamSubscription<User?>? _authStateSubscription;
  Timer? _autoSyncTimer; // THÊM: Timer cho đồng bộ tự động
  bool _isSyncing = false; // THÊM: Cờ báo đang đồng bộ

  AuthCubit(
      this._authRepository,
      this._backupService,
      this._projectTagRepository,
      this._taskRepository,
      this._projectBox,
      this._tagBox,
      this._taskBox,
      this._syncInfoBox,
      this._appStatusBox,
      ) : super(AuthInitial()) {
    _authStateSubscription = _authRepository.authStateChanges.listen((user) async {
      if (user == null) {
        _stopAutoSyncTimer(); // Hủy timer khi user null
        if (state is! AuthUnauthenticated && state is! AuthInitial) {
          print('AuthCubit: User is null via authStateChanges. Clearing local data and emitting AuthUnauthenticated.');
          await _clearLocalUserData();
          emit(AuthUnauthenticated());
        } else if (state is AuthInitial) {
          emit(AuthUnauthenticated());
        }
      } else {
        if (state is AuthUnauthenticated || state is AuthInitial) {
          print('AuthCubit: User found via authStateChanges (${user.uid}). Processing authentication flow...');
          await _onUserAuthenticated(user);
        }
      }
    });
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    _stopAutoSyncTimer(); // Hủy timer khi cubit đóng
    return super.close();
  }

  void _startAutoSyncTimer() {
    _stopAutoSyncTimer(); // Đảm bảo hủy timer cũ trước khi tạo mới
    print("AuthCubit: Starting auto-sync timer (15 minutes).");
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      if (_isSyncing) {
        print("AuthCubit: Auto-sync skipped, another sync is in progress.");
        return;
      }
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        print("AuthCubit: Auto-sync triggered for user ${currentUser.uid}.");
        await _performBackup(isAutoSync: true);
      } else {
        print("AuthCubit: Auto-sync aborted, user is null.");
        _stopAutoSyncTimer();
      }
    });
  }

  void _stopAutoSyncTimer() {
    if (_autoSyncTimer?.isActive ?? false) {
      print("AuthCubit: Stopping auto-sync timer.");
      _autoSyncTimer!.cancel();
    }
    _autoSyncTimer = null;
  }

  Future<void> _performBackup({bool isAutoSync = false, bool calledFromSignOut = false}) async {
    if (_isSyncing && !calledFromSignOut) {
      print("AuthCubit: Backup skipped, another sync is in progress.");
      return;
    }

    _isSyncing = true;
    if (!isAutoSync && !calledFromSignOut && state is! AuthLoading) {
      emit(AuthLoading(message: "Đang đồng bộ dữ liệu..."));
    } else if (calledFromSignOut && state is! AuthLoading) {
      // Giữ nguyên state nếu đang trong quá trình signOut và state đó đã là loading
    }

    try {
      await _backupService.backupToFirestore();
      print("AuthCubit: Backup to Firestore successful.");
      if (!isAutoSync) {
        _startAutoSyncTimer(); // Reset timer nếu là backup thủ công thành công
      }
    } catch (e) {
      print("AuthCubit: Error during backup: ${e.toString()}");
      if (!isAutoSync && !calledFromSignOut) {
        emit(AuthError("Lỗi đồng bộ dữ liệu: ${e.toString().replaceFirst("Exception: ", "")}"));
      }
    } finally {
      _isSyncing = false;
      if (!isAutoSync && !calledFromSignOut && state is AuthLoading && (state as AuthLoading).message == "Đang đồng bộ dữ liệu...") {
        final currentUser = _authRepository.currentUser;
        if (currentUser != null) {
          emit(AuthAuthenticated(currentUser));
        } else {
          emit(AuthUnauthenticated());
        }
      }
    }
  }

  Future<void> manualBackup() async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(AuthError("Bạn cần đăng nhập để đồng bộ."));
      return;
    }
    if (state is AuthLoading && (state as AuthLoading).message != "Đang kiểm tra dữ liệu...") { // Cho phép nếu chỉ đang kiểm tra dữ liệu
      print("AuthCubit: Manual backup skipped, an operation (not data check) is in progress.");
      return;
    }
    await _performBackup(isAutoSync: false);
  }

  Future<void> _onUserAuthenticated(User user) async {
    if (state is AuthAuthenticated && (state as AuthAuthenticated).user.uid == user.uid) {
      _startAutoSyncTimerIfNeeded(); // Đảm bảo timer chạy nếu user đã auth
      return;
    }
    emit(AuthLoading(message: "Đang tải dữ liệu người dùng..."));
    try {
      await _backupService.restoreFromFirestore();
      await _createDefaultDataForCurrentUserIfEmpty(user.uid);
      emit(AuthAuthenticated(user));
      _startAutoSyncTimer();
    } catch (e) {
      print("Lỗi khi _onUserAuthenticated: ${e.toString()}");
      emit(AuthError("Lỗi khi tải dữ liệu người dùng: ${e.toString().replaceFirst("Exception: ", "")}"));
      _stopAutoSyncTimer();
    }
  }

  void _startAutoSyncTimerIfNeeded() {
    final user = _authRepository.currentUser;
    if (user != null && (_autoSyncTimer == null || !_autoSyncTimer!.isActive)) {
      _startAutoSyncTimer();
    }
  }


  Future<void> _createDefaultDataForCurrentUserIfEmpty(String userId) async {
    try {
      final userProjects = _projectTagRepository.getProjects();
      final userTags = _projectTagRepository.getTags();
      final userTasks = await _taskRepository.getTasks();

      bool needsDefaultProjects = userProjects.isEmpty;
      bool needsDefaultTags = userTags.isEmpty;
      bool needsDefaultTasks = userTasks.isEmpty;

      if (needsDefaultProjects) {
        print('AuthCubit: Tạo projects mẫu cho người dùng: $userId');
        final defaultProjects = [
          Project(name: 'Công việc', color: Colors.blue, userId: userId, iconCodePoint: Icons.work_outline_rounded.codePoint, iconFontFamily: Icons.work_outline_rounded.fontFamily),
          Project(name: 'Cá nhân', color: Colors.green, userId: userId, iconCodePoint: Icons.person_outline_rounded.codePoint, iconFontFamily: Icons.person_outline_rounded.fontFamily),
          Project(name: 'Học tập', color: Colors.orange, userId: userId, iconCodePoint: Icons.school_outlined.codePoint, iconFontFamily: Icons.school_outlined.fontFamily),
        ];
        for (var project in defaultProjects) {
          await _projectTagRepository.addProject(project);
        }
      }

      if (needsDefaultTags) {
        print('AuthCubit: Tạo tags mẫu cho người dùng: $userId');
        final defaultTags = [
          Tag(name: 'Quan trọng', textColor: Colors.red.shade700, userId: userId),
          Tag(name: 'Ưu tiên', textColor: Colors.amber.shade700, userId: userId),
          Tag(name: 'Ý tưởng', textColor: Colors.lightBlue.shade600, userId: userId),
        ];
        for (var tag in defaultTags) {
          await _projectTagRepository.addTag(tag);
        }
      }

      if (needsDefaultTasks) {
        print('AuthCubit: Tạo task mẫu cho người dùng: $userId');
        final List<Project> currentUserProjects = _projectTagRepository.getProjects();
        if (currentUserProjects.isNotEmpty) {
          final sampleTask = Task(
            // id sẽ được TaskRepository tự tạo bằng UUID
            title: 'Chào mừng! Hoàn thành task đầu tiên của bạn.',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            priority: 'Medium',
            userId: userId,
            projectId: currentUserProjects.first.id,
            createdAt: DateTime.now(),
            estimatedPomodoros: 1,
          );
          await _taskRepository.addTask(sampleTask);
        } else {
          print('AuthCubit: Không có project nào để tạo task mẫu.');
        }
      }
    } catch (e) {
      print("Lỗi khi tạo dữ liệu mẫu: $e");
    }
  }

  Future<void> signInWithGoogle() async {
    if (_isSyncing || (state is AuthLoading && (state as AuthLoading).message != "Đang kiểm tra dữ liệu...")) return;
    emit(AuthLoading(message: "Đang đăng nhập với Google..."));
    try {
      await _authRepository.signInWithGoogle();
      final user = _authRepository.currentUser;
      if (user != null) {
        await _onUserAuthenticated(user);
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError("Đăng nhập Google thất bại: ${e.toString().replaceFirst("Exception: ", "")}"));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (_isSyncing || (state is AuthLoading && (state as AuthLoading).message != "Đang kiểm tra dữ liệu...")) return;
    emit(AuthLoading(message: "Đang đăng nhập..."));
    try {
      await _authRepository.signInWithEmail(email, password);
      final user = _authRepository.currentUser;
      if (user != null) {
        await _onUserAuthenticated(user);
      } else {
        emit(AuthError("Không thể lấy thông tin người dùng sau khi đăng nhập."));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    if (_isSyncing || (state is AuthLoading && (state as AuthLoading).message != "Đang kiểm tra dữ liệu...")) return;
    emit(AuthLoading(message: "Đang đăng ký..."));
    try {
      await _authRepository.signUpWithEmail(email, password);
      final user = _authRepository.currentUser;
      if (user != null) {
        await _onUserAuthenticated(user);
      } else {
        emit(AuthError("Không thể lấy thông tin người dùng sau khi đăng ký."));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst("Exception: ", "")));
    }
  }

  Future<void> _clearLocalUserData() async {
    try {
      if (_taskBox.isOpen) await _taskBox.clear();
      if (_projectBox.isOpen) await _projectBox.clear();
      if (_tagBox.isOpen) await _tagBox.clear();
      if (_appStatusBox.isOpen) await _appStatusBox.clear();
      if (_syncInfoBox.isOpen) await _syncInfoBox.clear();
      print("AuthCubit: Đã clear tất cả dữ liệu người dùng cục bộ và thông tin sync/modification.");
    } catch (e) {
      print("AuthCubit: Lỗi khi clear local user data: $e");
    }
  }

  Future<void> signOut({bool forceSignOut = false}) async {
    if (_isSyncing && !forceSignOut) {
      emit(AuthError("Đang có tiến trình đồng bộ, vui lòng thử lại sau."));
      return;
    }
    if (state is AuthLoading && (state as AuthLoading).message!.contains("Đang đăng xuất...")) {
      return;
    }

    final user = _authRepository.currentUser;

    if (user == null && !forceSignOut) {
      if (state is! AuthUnauthenticated) {
        await _clearLocalUserData();
        emit(AuthUnauthenticated());
      }
      return;
    }

    emit(AuthLoading(message: "Đang kiểm tra dữ liệu..."));

    if (!forceSignOut && user != null) {
      bool needsSync = false;
      try {
        final DateTime? lastSyncTime = await _backupService.getLastBackupTime();
        final String? lastModifiedProjectsStr = _appStatusBox.isOpen ? _appStatusBox.get('lastModified_projects') : null;
        final String? lastModifiedTagsStr = _appStatusBox.isOpen ? _appStatusBox.get('lastModified_tags') : null;
        final String? lastModifiedTasksStr = _appStatusBox.isOpen ? _appStatusBox.get('lastModified_tasks') : null;

        print("AuthCubit - signOut - Check sync: lastSyncTime=$lastSyncTime, "
            "lastModProjects=$lastModifiedProjectsStr, "
            "lastModTags=$lastModifiedTagsStr, "
            "lastModTasks=$lastModifiedTasksStr");

        if (lastSyncTime == null) {
          if ((_taskBox.isOpen && _taskBox.values.any((t) => t.userId == user.uid)) ||
              (_projectBox.isOpen && _projectBox.values.any((p) => p.userId == user.uid)) ||
              (_tagBox.isOpen && _tagBox.values.any((t) => t.userId == user.uid))) {
            needsSync = true;
            print("AuthCubit - signOut - needsSync=true (lastSyncTime is null, local data exists)");
          }
        } else {
          if (lastModifiedTasksStr != null && DateTime.tryParse(lastModifiedTasksStr)?.isAfter(lastSyncTime) == true) {
            needsSync = true;
            print("AuthCubit - signOut - needsSync=true (tasks modified after last sync)");
          }
          if (!needsSync && lastModifiedProjectsStr != null && DateTime.tryParse(lastModifiedProjectsStr)?.isAfter(lastSyncTime) == true) {
            needsSync = true;
            print("AuthCubit - signOut - needsSync=true (projects modified after last sync)");
          }
          if (!needsSync && lastModifiedTagsStr != null && DateTime.tryParse(lastModifiedTagsStr)?.isAfter(lastSyncTime) == true) {
            needsSync = true;
            print("AuthCubit - signOut - needsSync=true (tags modified after last sync)");
          }
        }

        if (needsSync) {
          print("AuthCubit - signOut - Emitting AuthSyncRequiredBeforeLogout.");
          emit(AuthSyncRequiredBeforeLogout());
          return;
        }
      } catch (e) {
        print("Lỗi khi kiểm tra đồng bộ trước khi logout: $e");
      }
    }
    print("AuthCubit - signOut - Proceeding to _performActualSignOut (forceSignOut=$forceSignOut, userIsNull=${user==null}).");
    await _performActualSignOut(calledFromSignOutAnyway: forceSignOut);
  }

  Future<void> syncDataAndProceedWithSignOut() async {
    if (_isSyncing) {
      print("AuthCubit: syncDataAndProceedWithSignOut skipped, another sync is in progress.");
      return;
    }
    if (state is AuthLoading && (state as AuthLoading).message == "Đang đồng bộ và đăng xuất...") return;

    emit(AuthLoading(message: "Đang đồng bộ và đăng xuất..."));
    try {
      await _performBackup(calledFromSignOut: true);
      await _performActualSignOut(calledFromSignOutAnyway: true);
    } catch (e) {
      print("Lỗi khi syncDataAndProceedWithSignOut: ${e.toString()}");
      emit(AuthError("Lỗi đồng bộ: ${e.toString().replaceFirst("Exception: ", "")}."));
      // Không tự động chuyển về AuthAuthenticated nếu sync lỗi, để UI xử lý.
      // Nếu muốn, có thể thêm logic để emit lại AuthSyncRequiredBeforeLogout
      // hoặc cho phép người dùng chọn "Vẫn đăng xuất" một lần nữa.
      // Hiện tại, nếu sync lỗi, app sẽ ở trạng thái AuthError.
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) { // Nếu user đã bị logout do lỗi nào đó
        await _performActualSignOut(calledFromSignOutAnyway: true);
      }
    }
  }

  Future<void> signOutAnyway() async {
    await _performActualSignOut(calledFromSignOutAnyway: true);
  }

  Future<void> _performActualSignOut({bool calledFromSignOutAnyway = false}) async {
    if (_isSyncing && !calledFromSignOutAnyway) {
      print("AuthCubit: _performActualSignOut called while syncing, potential issue. Aborting actual sign out.");
      // Cân nhắc emit một state lỗi hoặc giữ nguyên state hiện tại để tránh xung đột
      // Ví dụ: emit(AuthError("Không thể đăng xuất khi đang đồng bộ."));
      return; // Quan trọng: return để không thực hiện đăng xuất khi đang sync
    }

    if (!(state is AuthLoading && (state as AuthLoading).message!.contains("Đang đăng xuất"))) {
      emit(AuthLoading(message: "Đang đăng xuất..."));
    }

    _stopAutoSyncTimer();
    try {
      await _authRepository.signOut();
      // Listener _authStateSubscription sẽ tự động xử lý việc clear data và emit AuthUnauthenticated
      // Tuy nhiên, để đảm bảo, chúng ta có thể kiểm tra và thực hiện nếu state chưa đúng
      if (state is! AuthUnauthenticated) {
        await _clearLocalUserData();
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print("Lỗi khi _performActualSignOut: ${e.toString()}");
      await _clearLocalUserData(); // Vẫn clear data khi có lỗi
      emit(AuthUnauthenticated()); // Luôn đưa về trạng thái chưa đăng nhập khi có lỗi nghiêm trọng
    }
  }
}