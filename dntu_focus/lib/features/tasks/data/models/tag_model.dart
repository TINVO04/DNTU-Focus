import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'tag_model.g.dart';

@HiveType(typeId: 2)
class Tag extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(3)
  final int textColorValue;

  @HiveField(4)
  final bool isArchived;

  @HiveField(5)
  final String? userId;

  Tag({
    String? id,
    required this.name,
    // Bỏ tham số backgroundColor
    required Color textColor,
    this.isArchived = false,
    this.userId,
  })  : id = id ?? const Uuid().v4(),

        textColorValue = textColor.value;

  Color get textColor => Color(textColorValue);

  Tag copyWith({
    String? id,
    String? name,
    Color? textColor,
    bool? isArchived,
    String? userId,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      textColor: textColor ?? this.textColor,
      isArchived: isArchived ?? this.isArchived,
      userId: userId ?? this.userId,
    );
  }
}