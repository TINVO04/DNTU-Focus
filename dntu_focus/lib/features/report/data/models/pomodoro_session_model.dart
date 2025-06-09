import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Thêm dòng này để build_runner có thể tạo file tương ứng
part 'pomodoro_session_model.g.dart';

// Class để chuyển đổi giữa Timestamp của Firestore và DateTime của Dart
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) {
    return timestamp.toDate();
  }

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}


@JsonSerializable()
class PomodoroSessionRecordModel extends Equatable {
  final String id;
  final String userId;

  @TimestampConverter()
  final DateTime startTime;

  @TimestampConverter()
  final DateTime endTime;

  final int duration; // Thời gian tập trung tính bằng giây
  final bool isWorkSession; // True nếu là phiên làm việc, false nếu là phiên nghỉ
  final String? taskId; // ID của task đang làm (nếu có)
  final String? projectId; // ID của project (nếu có)

  const PomodoroSessionRecordModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.isWorkSession,
    this.taskId,
    this.projectId,
  });

  @override
  List<Object?> get props => [
    id,
    userId,
    startTime,
    endTime,
    duration,
    isWorkSession,
    taskId,
    projectId,
  ];

  // Factory để tạo đối tượng từ JSON (dữ liệu từ Firestore)
  factory PomodoroSessionRecordModel.fromJson(Map<String, dynamic> json) =>
      _$PomodoroSessionRecordModelFromJson(json);

  // Hàm để chuyển đổi đối tượng thành JSON (để lưu vào Firestore)
  Map<String, dynamic> toJson() => _$PomodoroSessionRecordModelToJson(this);

  // Factory để dễ dàng tạo đối tượng từ DocumentSnapshot của Firestore
  factory PomodoroSessionRecordModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    // Lấy dữ liệu từ doc và thêm doc.id vào trường 'id' của model
    final data = doc.data()!..['id'] = doc.id;
    return PomodoroSessionRecordModel.fromJson(data);
  }

  // Hàm copyWith để dễ dàng tạo bản sao và thay đổi một vài thuộc tính
  PomodoroSessionRecordModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    bool? isWorkSession,
    String? taskId,
    String? projectId,
  }) {
    return PomodoroSessionRecordModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isWorkSession: isWorkSession ?? this.isWorkSession,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
    );
  }
}