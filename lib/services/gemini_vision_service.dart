import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  // ใช้โมเดล gemini-1.5-flash สำหรับ Multimodal (ภาพ+ข้อความ)
  static const String _model = 'gemini-3.5-flash'; 

  Future<Map<String, dynamic>> analyzeProductImage(File imageFile,String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$_apiKey');

    // 1. อ่านไฟล์ภาพและแปลงเป็น Base64
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // 2. เตรียม Prompt ตามที่ใบงานกำหนด
    const prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inlineData": {
                    "mimeType": "image/jpeg", // ใช้ jpeg เป็นค่ากลางได้
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          // บังคับให้ AI ตอบกลับเป็น JSON (Structured Output)
          "generationConfig": {
            "responseMimeType": "application/json",
          }
        }),
      ).timeout(const Duration(seconds: 50)); // ให้เวลา AI ดูรูปนานหน่อย (50 วินาที)

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // เช็คว่า AI ปฏิเสธการตอบเพราะติดเรื่อง Safety หรือไม่
        if (data['promptFeedback'] != null && data['promptFeedback']['blockReason'] != null) {
          throw Exception('ภาพนี้ถูกบล็อกโดยระบบความปลอดภัยของ Gemini');
        }

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          if (candidate['finishReason'] == 'SAFETY') {
            throw Exception('เนื้อหาเข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini');
          }

          final textResponse = candidate['content']['parts'][0]['text'];
          
          // แปลง JSON String ที่ AI ตอบกลับมา ให้กลายเป็น Map ของ Dart
          return jsonDecode(textResponse) as Map<String, dynamic>;
        } else {
          throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้');
        }
      } else {
        throw Exception('เกิดข้อผิดพลาดจาก API (สถานะ ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา (30 วินาที) กรุณาลองใหม่');
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }
}