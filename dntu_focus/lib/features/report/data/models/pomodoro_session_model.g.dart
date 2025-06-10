// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pomodoro_session_model.dart';

PomodoroSessionRecordModel _$PomodoroSessionRecordModelFromJson(Map<String, dynamic> json) {
  return PomodoroSessionRecordModel(
    id: json['id'] as String,
    userId: json['userId'] as String?,
    startTime: const TimestampConverter().fromJson(json['startTime'] as Timestamp),
    endTime: const TimestampConverter().fromJson(json['endTime'] as Timestamp),
    duration: json['duration'] as int,
    isWorkSession: json['isWorkSession'] as bool,
    taskId: json['taskId'] as String?,
    projectId: json['projectId'] as String?,
  );
}

Map<String, dynamic> _$PomodoroSessionRecordModelToJson(PomodoroSessionRecordModel instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'startTime': const TimestampConverter().toJson(instance.startTime),
  'endTime': const TimestampConverter().toJson(instance.endTime),
  'duration': instance.duration,
  'isWorkSession': instance.isWorkSession,
  'taskId': instance.taskId,
  'projectId': instance.projectId,
};
