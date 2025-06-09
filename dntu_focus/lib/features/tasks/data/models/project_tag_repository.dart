import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/project_model.dart';
import '../models/tag_model.dart';

class ProjectTagRepository {
  final Box<Project> projectBox;
  final Box<Tag> tagBox;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProjectTagRepository({
    required this.projectBox,
    required this.tagBox,
  });

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> _trackModification(String boxName) async {
    try {
      if (!Hive.isBoxOpen('app_status')) {
        await Hive.openBox('app_status');
      }
      final appStatusBox = Hive.box('app_status');
      await appStatusBox.put('lastModified_$boxName', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error tracking modification for $boxName: $e');
    }
  }

  // --- PROJECT METHODS ---

  Future<void> addProject(Project project) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể thêm project.');
    }
    final projectToAdd = project.copyWith(userId: userId);

    final existingProjects = projectBox.values.where((p) => p.userId == userId && !p.isArchived).toList();
    if (existingProjects.any((p) => p.name.toLowerCase() == projectToAdd.name.toLowerCase())) {
      throw Exception('Tên project "${projectToAdd.name}" đã tồn tại.');
    }

    await projectBox.put(projectToAdd.id, projectToAdd);
    await _trackModification('projects');
    print('Project added to Hive: ${projectToAdd.name} (ID: ${projectToAdd.id}) for user $userId');
  }

  Future<void> updateProject(Project updatedProjectData) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');
    if (updatedProjectData.id.isEmpty) throw Exception('Project ID không được rỗng khi cập nhật.');

    final existingProject = projectBox.get(updatedProjectData.id);
    if (existingProject == null || existingProject.userId != userId) {
      throw Exception('Project không tồn tại hoặc bạn không có quyền sửa.');
    }

    if (existingProject.name.toLowerCase() != updatedProjectData.name.toLowerCase()) {
      final otherProjects = projectBox.values.where((p) =>
      p.userId == userId &&
          p.id != updatedProjectData.id &&
          !p.isArchived
      ).toList();
      if (otherProjects.any((p) => p.name.toLowerCase() == updatedProjectData.name.toLowerCase())) {
        throw Exception('Tên project "${updatedProjectData.name}" đã được sử dụng bởi một project khác.');
      }
    }
    final projectToPut = updatedProjectData.copyWith(userId: userId);
    await projectBox.put(projectToPut.id, projectToPut);
    await _trackModification('projects');
    print('Project updated in Hive: ${projectToPut.name} (ID: ${projectToPut.id}) for user $userId');
  }

  Future<void> archiveProjectByKey(String projectKey) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final project = projectBox.get(projectKey);
    if (project != null && project.userId == userId) {
      final archivedProject = project.copyWith(isArchived: true);
      await projectBox.put(projectKey, archivedProject);
      await _trackModification('projects');
      print('Project archived: ${archivedProject.name} for user $userId');
    } else {
      throw Exception('Project không tồn tại hoặc bạn không có quyền lưu trữ.');
    }
  }

  Future<void> restoreProjectByKey(String projectKey) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final project = projectBox.get(projectKey);
    if (project != null && project.userId == userId) {
      final restoredProject = project.copyWith(isArchived: false);
      await projectBox.put(projectKey, restoredProject);
      await _trackModification('projects');
      print('Project restored: ${restoredProject.name} for user $userId');
    } else {
      throw Exception('Project không tồn tại hoặc bạn không có quyền khôi phục.');
    }
  }

  Future<void> deleteProjectByKey(String projectKey) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final projectToDelete = projectBox.get(projectKey);
    if (projectToDelete != null && projectToDelete.userId == userId) {
      await projectBox.delete(projectKey);
      await _trackModification('projects');
      print('Project with key $projectKey deleted successfully from Hive for user $userId.');
    } else {
      print('Project with key $projectKey not found or does not belong to user $userId. Skipping deletion.');
    }
  }

  List<Project> getProjects() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return projectBox.values.where((project) => project.userId == userId && !project.isArchived).toList();
  }

  List<Project> getArchivedProjects() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return projectBox.values.where((project) => project.userId == userId && project.isArchived).toList();
  }

  Project? getProjectById(String projectId) {
    final userId = _currentUserId;
    if (userId == null) return null;
    try {
      return projectBox.values.firstWhere((project) => project.id == projectId && project.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // --- TAG METHODS ---

  Future<void> addTag(Tag tag) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập, không thể thêm tag.');
    }
    final tagToAdd = tag.copyWith(userId: userId);

    final existingTags = getTags();
    if (existingTags.any((t) => t.name.toLowerCase() == tagToAdd.name.toLowerCase())) {
      throw Exception('Tên tag "${tagToAdd.name}" đã tồn tại.');
    }

    await tagBox.put(tagToAdd.id, tagToAdd);
    await _trackModification('tags');
    print('Tag added to Hive: ${tagToAdd.name} (ID: ${tagToAdd.id}) for user $userId');
  }

  Future<void> updateTag(Tag updatedTagData) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');
    if (updatedTagData.id.isEmpty) throw Exception('Tag ID không được rỗng khi cập nhật.');

    final existingTag = tagBox.get(updatedTagData.id);
    if (existingTag == null || existingTag.userId != userId) {
      throw Exception('Tag không tồn tại hoặc bạn không có quyền sửa.');
    }

    if (existingTag.name.toLowerCase() != updatedTagData.name.toLowerCase()) {
      final otherTags = tagBox.values.where((t) =>
      t.userId == userId &&
          t.id != updatedTagData.id &&
          !t.isArchived
      ).toList();
      if (otherTags.any((t) => t.name.toLowerCase() == updatedTagData.name.toLowerCase())) {
        throw Exception('Tên tag "${updatedTagData.name}" đã được sử dụng bởi một tag khác.');
      }
    }
    final tagToPut = updatedTagData.copyWith(userId: userId);
    await tagBox.put(tagToPut.id, tagToPut);
    await _trackModification('tags');
    print('Tag updated in Hive: ${tagToPut.name} (ID: ${tagToPut.id}) for user $userId');
  }

  Future<void> archiveTagByKey(String tagKey) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final tag = tagBox.get(tagKey);
    if (tag != null && tag.userId == userId) {
      final archivedTag = tag.copyWith(isArchived: true);
      await tagBox.put(tagKey, archivedTag);
      await _trackModification('tags');
      print('Tag archived: ${archivedTag.name} for user $userId');
    } else {
      throw Exception('Tag không tồn tại hoặc bạn không có quyền lưu trữ.');
    }
  }

  Future<void> restoreTagByKey(String tagKey) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final tag = tagBox.get(tagKey);
    if (tag != null && tag.userId == userId) {
      final restoredTag = tag.copyWith(isArchived: false);
      await tagBox.put(tagKey, restoredTag);
      await _trackModification('tags');
      print('Tag restored: ${restoredTag.name} for user $userId');
    } else {
      throw Exception('Tag không tồn tại hoặc bạn không có quyền khôi phục.');
    }
  }

  Future<void> deleteTagByKey(String tagKey) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('Người dùng chưa đăng nhập.');

    final tagToDelete = tagBox.get(tagKey);
    if (tagToDelete != null && tagToDelete.userId == userId) {
      await tagBox.delete(tagKey);
      await _trackModification('tags');
      print('Tag with key $tagKey deleted successfully from Hive for user $userId.');
    } else {
      print('Tag with key $tagKey not found or does not belong to user $userId. Skipping deletion.');
    }
  }

  List<Tag> getTags() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return tagBox.values.where((tag) => tag.userId == userId && !tag.isArchived).toList();
  }

  List<Tag> getArchivedTags() {
    final userId = _currentUserId;
    if (userId == null) return [];
    return tagBox.values.where((tag) => tag.userId == userId && tag.isArchived).toList();
  }

  Tag? getTagById(String tagId) {
    final userId = _currentUserId;
    if (userId == null) return null;
    try {
      return tagBox.values.firstWhere((tag) => tag.id == tagId && tag.userId == userId);
    } catch (e) {
      return null;
    }
  }
}