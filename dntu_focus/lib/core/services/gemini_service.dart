import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

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
    final prompt = '''
    Phân tích câu lệnh sau và trả về thông tin dưới dạng JSON:
    - Nếu là yêu cầu tạo task: trả về title, duration (phút), break_duration (phút), priority (High/Medium/Low), due_date (nếu có, định dạng ISO 8601).
    - Nếu là yêu cầu lên lịch: trả về title, due_date (định dạng ISO 8601), nhắc nhở trước bao lâu (phút).
    - Nhận diện a.m/p.m tự động nếu có thời gian (mặc định a.m nếu không rõ).
    - Gợi ý priority dựa trên ngữ cảnh (ví dụ: "họp nhóm" -> High).
    Câu lệnh: "$command"
    Ví dụ: "làm bài tập toán 25 phút 5 phút nghỉ" -> {"type": "task", "title": "Làm bài tập toán", "duration": 25, "break_duration": 5, "priority": "Medium"}
    Ví dụ: "ngày mai đi chợ 6 sáng" -> {"type": "schedule", "title": "Đi chợ", "due_date": "2025-05-04T06:00:00Z", "reminder_before": 15}
    Ví dụ: "họp nhóm lúc 3h" -> {"type": "schedule", "title": "Họp nhóm", "due_date": "2025-05-03T15:00:00Z", "reminder_before": 15, "priority": "High"}
    Trả về chỉ JSON, không thêm ký tự Markdown như ```json hoặc các ký tự thừa.
    ''';

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

      return jsonDecode(jsonString) as Map<String, dynamic>;
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