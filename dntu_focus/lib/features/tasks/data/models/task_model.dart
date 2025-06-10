import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // THÊM IMPORT NÀY

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  String? id; // ĐỔI THÀNH String?

  @HiveField(1)
  String? title;

  @HiveField(2)
  String? note;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  String? priority;

  @HiveField(5)
  String? projectId;

  @HiveField(6)
  List<String>? tagIds;

  @HiveField(7)
  int? estimatedPomodoros;

  @HiveField(8)
  int? completedPomodoros;

  @HiveField(9)
  String? category;

  @HiveField(10)
  bool? isPomodoroActive;

  @HiveField(11)
  int? remainingPomodoroSeconds;

  @HiveField(12)
  bool? isCompleted;

  @HiveField(13)
  List<Map<String, dynamic>>? subtasks;

  @HiveField(14)
  String? userId;

  @HiveField(15)
  DateTime? createdAt;

  @HiveField(16)
  String? originalCategory;

  @HiveField(17)
  DateTime? completionDate;

  Task({
    String? id, // ĐỔI THÀNH String?
    this.title,
    this.note,
    this.dueDate,
    this.priority,
    this.projectId,
    this.tagIds,
    this.estimatedPomodoros,
    this.completedPomodoros,
    this.category,
    this.isPomodoroActive = false,
    this.remainingPomodoroSeconds,
    this.isCompleted = false,
    this.subtasks,
    this.userId,
    this.createdAt,
    this.originalCategory,
    this.completionDate,
  }) : id = id ?? const Uuid().v4(); // TỰ ĐỘNG TẠO UUID NẾU ID LÀ NULL

  factory Task.fromJson(Map<String, dynamic> json, {String? docId}) { // Thêm docId tùy chọn
    return Task(
      id: docId ?? json['id'] as String?, // Ưu tiên docId từ Firestore nếu có, sau đó mới đến trường 'id' trong data
      title: json['title'] as String?,
      note: json['note'] as String?,
      dueDate: json['dueDate'] != null ? (json['dueDate'] as Timestamp).toDate() : null,
      priority: json['priority'] as String?,
      projectId: json['projectId'] as String?,
      tagIds: (json['tagIds'] as List<dynamic>?)?.cast<String>(),
      estimatedPomodoros: json['estimatedPomodoros'] as int?,
      completedPomodoros: json['completedPomodoros'] as int?,
      category: json['category'] as String?,
      isPomodoroActive: json['isPomodoroActive'] as bool? ?? false,
      remainingPomodoroSeconds: json['remainingPomodoroSeconds'] as int?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      subtasks: (json['subtasks'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      userId: json['userId'] as String?,
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : null,
      originalCategory: json['originalCategory'] as String?,
      completionDate: json['completionDate'] != null ? (json['completionDate'] as Timestamp).toDate() : null,
    );
  }

  static Task fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document does not exist');
    }
    return Task.fromJson(data, docId: doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      // Không gửi 'id' ở đây nếu bạn dùng ID của document làm ID task trên Firestore
      // Nếu bạn muốn lưu 'id' (UUID) vào trong data của document thì thêm dòng sau:
      'id': id, // GIỮ LẠI ĐỂ NHẤT QUÁN VỚI PROJECT VÀ TAG
      'title': title,
      'note': note,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': priority,
      'projectId': projectId,
      'tagIds': tagIds,
      'estimatedPomodoros': estimatedPomodoros,
      'completedPomodoros': completedPomodoros,
      'category': category,
      'isPomodoroActive': isPomodoroActive,
      'remainingPomodoroSeconds': remainingPomodoroSeconds,
      'isCompleted': isCompleted,
      'subtasks': subtasks,
      'userId': userId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'originalCategory': originalCategory,
      'completionDate': completionDate != null ? Timestamp.fromDate(completionDate!) : null,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? dueDate,
    String? priority,
    // Sử dụng Object? cho các trường bạn muốn có khả năng set về null,
    // và gán giá trị mặc định là sentinel.
    Object? projectId = _copyWithSentinel,
    Object? tagIds = _copyWithSentinel, // Làm tương tự cho các trường List?, int?, bool? khác nếu cần
    Object? estimatedPomodoros = _copyWithSentinel,
    Object? completedPomodoros = _copyWithSentinel,
    Object? category = _copyWithSentinel,
    Object? isPomodoroActive = _copyWithSentinel,
    Object? remainingPomodoroSeconds = _copyWithSentinel,
    Object? isCompleted = _copyWithSentinel,
    Object? subtasks = _copyWithSentinel,
    // userId và createdAt thường không nên set về null tùy tiện nếu đã có giá trị,
    // nhưng nếu cần thì làm tương tự.
    String? userId, // Giữ nguyên nếu bạn không muốn set userId về null qua copyWith
    DateTime? createdAt, // Giữ nguyên
    Object? originalCategory = _copyWithSentinel,
    Object? completionDate = _copyWithSentinel,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note, // Giữ nguyên cho các trường String? nếu logic ?? phù hợp
      dueDate: dueDate ?? this.dueDate, // Giữ nguyên cho DateTime? nếu logic ?? phù hợp
      priority: priority ?? this.priority,

      // Logic mới cho projectId
      projectId: projectId == _copyWithSentinel
          ? this.projectId // Nếu là sentinel, nghĩa là không có giá trị mới được truyền -> giữ giá trị cũ
          : projectId as String?, // Nếu không phải sentinel -> dùng giá trị mới (có thể là null hoặc một String)

      // Áp dụng tương tự cho các trường khác mà bạn muốn có thể set về null
      tagIds: tagIds == _copyWithSentinel
          ? this.tagIds
          : tagIds as List<String>?,

      estimatedPomodoros: estimatedPomodoros == _copyWithSentinel
          ? this.estimatedPomodoros
          : estimatedPomodoros as int?,

      completedPomodoros: completedPomodoros == _copyWithSentinel
          ? this.completedPomodoros
          : completedPomodoros as int?,

      category: category == _copyWithSentinel
          ? this.category
          : category as String?,

      isPomodoroActive: isPomodoroActive == _copyWithSentinel
          ? this.isPomodoroActive
          : isPomodoroActive as bool?,

      remainingPomodoroSeconds: remainingPomodoroSeconds == _copyWithSentinel
          ? this.remainingPomodoroSeconds
          : remainingPomodoroSeconds as int?,

      isCompleted: isCompleted == _copyWithSentinel
          ? this.isCompleted
          : isCompleted as bool?,

      subtasks: subtasks == _copyWithSentinel
          ? this.subtasks
          : subtasks as List<Map<String, dynamic>>?,

      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,

      originalCategory: originalCategory == _copyWithSentinel
          ? this.originalCategory
          : originalCategory as String?,

      completionDate: completionDate == _copyWithSentinel
          ? this.completionDate
          : completionDate as DateTime?,
    );
  }
}
const Object _copyWithSentinel = Object();