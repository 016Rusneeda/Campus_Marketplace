import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // ดึงค่า API Key จาก --dart-define ตอนรันแอป
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  Future<String> generateText(String prompt) async {
    final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 50)); // ตั้ง Timeout ที่ 50 วินาที

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ตรวจสอบว่ามีข้อมูลใน candidates หรือไม่
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw Exception('ไม่พบข้อความตอบกลับจาก Gemini');
        }
      } else {
        throw Exception('เกิดข้อผิดพลาดจาก API (สถานะ ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อ Gemini API หมดเวลา (20 วินาที)');
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }
}