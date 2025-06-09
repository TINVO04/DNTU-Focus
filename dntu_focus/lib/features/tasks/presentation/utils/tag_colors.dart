import 'package:flutter/material.dart';

class TagColors {
  static final Map<String, Map<String, Color>> tagColorMap = {
    'Design': {
      'background': Colors.lightGreen[50]!,
      'text': Colors.lightGreen,
    },
    'Work': {
      'background': Colors.blue[50]!,
      'text': Colors.blue,
    },
    'Productive': {
      'background': Colors.purple[50]!,
      'text': Colors.purple,
    },
    'Personal': {
      'background': Colors.green[50]!,
      'text': Colors.green,
    },
    'Study': {
      'background': Colors.purple[50]!,
      'text': Colors.purple,
    },
    'Urgent': {
      'background': Colors.red[50]!,
      'text': Colors.red,
    },
    'Home': {
      'background': Colors.cyan[50]!,
      'text': Colors.cyan,
    },
    'Important': {
      'background': Colors.orange[50]!,
      'text': Colors.orange,
    },
    'Research': {
      'background': Colors.brown[50]!,
      'text': Colors.brown,
    },
  };

  static Map<String, Color> getTagColors(String tag) {
    return tagColorMap[tag] ?? {
      'background': Colors.grey[200]!,
      'text': Colors.grey,
    };
  }
}