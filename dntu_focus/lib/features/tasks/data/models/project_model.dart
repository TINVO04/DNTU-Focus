import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'project_model.g.dart'; // Đảm bảo file này được tạo/cập nhật bởi build_runner

@HiveType(typeId: 1) // typeId phải là duy nhất cho mỗi model Hive
class Project extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int colorValue; // Lưu trữ giá trị integer của màu

  @HiveField(3)
  final bool isArchived;

  @HiveField(4)
  final int? iconCodePoint;

  @HiveField(5)
  final String? iconFontFamily;

  @HiveField(6)
  final String? iconFontPackage; // Trường mới cho icon package

  @HiveField(7) // SỐ FIELD MỚI CHO userId
  final String? userId; // THÊM TRƯỜNG userId

  Project({
    String? id,
    required this.name,
    required Color color,
    this.isArchived = false,
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.userId, // THÊM userId VÀO CONSTRUCTOR
  })  : id = id ?? const Uuid().v4(),
        colorValue = color.value;

  Color get color => Color(colorValue);

  IconData? get icon {
    if (iconCodePoint == null) return null;
    return IconData(
      iconCodePoint!,
      fontFamily: iconFontFamily,
      fontPackage: iconFontPackage,
    );
  }

  Project copyWith({
    String? id,
    String? name,
    Color? color,
    bool? isArchived,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    bool clearIcon = false,
    String? userId, // THÊM userId VÀO copyWith
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      iconCodePoint: clearIcon ? null : iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: clearIcon ? null : iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: clearIcon ? null : iconFontPackage ?? this.iconFontPackage,
      userId: userId ?? this.userId, // GÁN userId
    );
  }
}