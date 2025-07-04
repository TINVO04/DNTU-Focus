import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  static const String _commandParserSystemPrompt = '''
Bạn là một bộ phân tích câu lệnh cho ứng dụng quản lý nhiệm vụ. Kết quả phải ở định dạng JSON.
Các quy tắc:
- Nếu người dùng muốn tạo task, trả về: {"type":"task","title":"...","duration":<phút>,"break_duration":<phút>,"priority":"High|Medium|Low","due_date":"<ISO 8601>"}
- Nếu người dùng lên lịch, trả về: {"type":"schedule","title":"...","due_date":"<ISO 8601>","reminder_before":<phút>,"priority":"High|Medium|Low"}
- Tự suy luận a.m/p.m khi có giờ, mặc định a.m nếu không rõ.
- Gợi ý priority dựa trên ngữ cảnh (ví dụ: "họp nhóm" -> High).
- Nếu câu lệnh không chỉ rõ thời gian, dùng thời điểm hiện tại.
- Ngày tháng phải dựa trên thời gian hiện tại được cung cấp trong prompt. "Hôm nay" tương ứng thời điểm hiện tại (cả ngày và giờ), "ngày mai" cộng thêm một ngày.
Chỉ phản hồi chuỗi JSON duy nhất, không dùng Markdown hay văn bản thừa.
Ví dụ (giả sử hôm nay là 2025-05-03):
"làm bài tập toán 25 phút 5 phút nghỉ" -> {"type":"task","title":"Làm bài tập toán","duration":25,"break_duration":5,"priority":"Medium"}
"ngày mai đi chợ 6 sáng" -> {"type":"schedule","title":"Đi chợ","due_date":"2025-05-04T06:00:00Z","reminder_before":15}
"họp nhóm lúc 3h" -> {"type":"schedule","title":"Họp nhóm","due_date":"2025-05-03T15:00:00Z","reminder_before":15,"priority":"High"}
''';

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) throw Exception('Gemini API Key không tìm thấy');
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  Future<GenerateContentResponse> generateContent(List<Content> content) async {
    try {
      return await _model.generateContent(content);
    } catch (e) {
      throw Exception('Failed to generate content from Gemini API: $e');
    }
  }

  // Phân tích câu lệnh người dùng để tạo task hoặc lịch trình
  Future<Map<String, dynamic>> parseUserCommand(String command) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final prompt = '$_commandParserSystemPrompt\nThời gian hiện tại: $now\nCâu lệnh: "$command"';

    String? rawText;
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      rawText = response.text?.trim() ?? '{}';

      // Xử lý phản hồi để loại bỏ Markdown (nếu có)
      String jsonString = rawText;
      if (jsonString.startsWith('```json')) {
        jsonString = jsonString.replaceFirst('```json', '').trim();
      }
      if (jsonString.endsWith('```')) {
        jsonString = jsonString.substring(0, jsonString.length - 3).trim();
      }

      final Map<String, dynamic> result =
          jsonDecode(jsonString) as Map<String, dynamic>;

      // Thiếu thời gian hoặc chỉ đề cập "hôm nay" -> dùng thời điểm hiện tại
      final lower = command.toLowerCase();
      final now = DateTime.now().toUtc();
      DateTime dueDate;
      bool showOnlyDate = false;

      if (result['due_date'] == null) {
        // Không có thông tin ngày giờ
        dueDate = now;
        showOnlyDate = true;
      } else {
        try {
          final parsed = DateTime.parse(result['due_date']);
          final missingTime = parsed.hour == 0 &&
              parsed.minute == 0 &&
              parsed.second == 0 &&
              parsed.millisecond == 0 &&
              parsed.microsecond == 0;

          if (lower.contains('hôm nay') && missingTime) {
            dueDate = now;
            showOnlyDate = true;
          } else if (missingTime) {
            // Chỉ có ngày, không có giờ -> giữ nguyên ngày, lấy giờ hiện tại
            dueDate = DateTime.utc(
              parsed.year,
              parsed.month,
              parsed.day,
              now.hour,
              now.minute,
              now.second,
              now.millisecond,
              now.microsecond,
            );
            showOnlyDate = true;
          } else {
            dueDate = parsed;
          }
        } catch (_) {
          dueDate = now;
          showOnlyDate = true;
        }
      }

      result['due_date'] = dueDate.toIso8601String();
      result['show_only_date'] = showOnlyDate;
      return result;
    } catch (e) {
      print('Error parsing command from Gemini API: $e');
      print('Raw response: $rawText');
      return {'error': 'Không thể phân tích câu lệnh từ Gemini API'};
    }
  }

  Future<List<String>> getSmartSuggestions(String context) async {
    final prompt = '''
    Dựa trên ngữ cảnh sau, gợi ý 3 câu lệnh mà người dùng có thể sử dụng để tạo task hoặc lên lịch.
    Ngữ cảnh: "$context"
    Ví dụ: Ngữ cảnh "đang học toán" -> ["làm bài tập toán 25 phút 5 phút nghỉ", "ôn tập toán 30 phút", "xem video bài giảng toán 20 phút"]
    Trả về dưới dạng danh sách các chuỗi, không thêm ký tự Markdown.
    ''';

    String? rawText;
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      rawText = response.text?.trim() ?? '[]';
      rawText = rawText.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
      // Xử lý JSON an toàn
      final jsonString = rawText.startsWith('[') ? rawText : '[$rawText]';
      return List<String>.from(jsonDecode(jsonString));

    } catch (e) {
      print('Error getting suggestions from Gemini API: $e');
      print('Raw response: $rawText');
      return [];
    }
  }

  Future<String> classifyTask(String taskTitle) async {
    final prompt = '''
    Phân loại task sau thành danh mục (Today, Tomorrow, This Week, Planned, Completed, Trash):
    - Task: "$taskTitle"
    - Nếu không có thời gian cụ thể, mặc định là Planned.
    - Nếu có từ "hoàn thành" hoặc "xong", phân loại là Completed.
    Trả về tên danh mục, không thêm ký tự Markdown.
    ''';

    String? rawText;
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      rawText = response.text?.trim() ?? 'Planned';
      return rawText;
    } catch (e) {
      print('Error classifying task from Gemini API: $e');
      print('Raw response: $rawText');
      return 'Planned';
    }
  }
}