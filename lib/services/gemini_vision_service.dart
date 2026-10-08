import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiVisionService {
  // 1. ใส่คีย์ AQ. ของคุณตรงนี้
  static const String _apiKey = 'YOUR_API_KEY_'; 
  
  static const String _model = 'gemini-3.8-flash'; 

  Future<Map<String, dynamic>> analyzeProductImage(File imageFile) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent');
    
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

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
        // 3. ส่ง API Key ผ่าน Header 'x-goog-api-key' แทน
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey, 
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inlineData": {
                    "mimeType": "image/jpeg", 
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "responseMimeType": "application/json",
          }
        }),
      ).timeout(const Duration(seconds: 50)); 

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['promptFeedback'] != null && data['promptFeedback']['blockReason'] != null) {
          throw Exception('ภาพนี้ถูกบล็อกโดยระบบความปลอดภัยของ Gemini');
        }

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          if (candidate['finishReason'] == 'SAFETY') {
            throw Exception('เนื้อหาเข้าข่ายไม่ปลอดภัย');
          }

          final textResponse = candidate['content']['parts'][0]['text'];
          return jsonDecode(textResponse) as Map<String, dynamic>;
        } else {
          throw Exception('AI ไม่สามารถวิเคราะห์ภาพนี้ได้');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown Error';
        throw Exception('Google บอกว่า: $errorMessage (สถานะ ${response.statusCode})');
      }
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่');
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }
}