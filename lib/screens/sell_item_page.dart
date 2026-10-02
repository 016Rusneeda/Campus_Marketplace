import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_vision_service.dart';
import '../models/listing_draft.dart';

class SellItemPage extends StatefulWidget {
  const SellItemPage({super.key});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  File? _imageFile;
  bool _isLoading = false;
  
  // เพิ่มตัวแปรสำหรับควบคุม TextField ทั้ง 3 ช่อง
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ตัวแปรเช็คว่าจะแสดงฟอร์มแก้ไขหรือไม่
  bool _showForm = false;

  static const String _prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';

  @override
  void dispose() {
    // ต้องทำลาย Controller เมื่อปิดหน้าจอเพื่อคืนหน่วยความจำให้ระบบ
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // ซ่อนฟอร์มไปก่อนเมื่อเลือกรูปใหม่
        _showForm = false; 
      });
    }
  }

  // ฟังก์ชันล้างข้อมูลหน้าจอ (เมื่อกดยืนยัน)
  void _clearForm() {
    setState(() {
      _imageFile = null;
      _showForm = false;
      _titleController.clear();
      _categoryController.clear();
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงประกาศขาย')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile != null)
              Image.file(_imageFile!, height: 300, fit: BoxFit.cover)
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: (_imageFile == null || _isLoading)
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                        _showForm = false; // ซ่อนฟอร์มเก่าขณะโหลด
                      });

                      try {
                        // ส่งภาพไปให้ Gemini วิเคราะห์
                        final resultMap = await GeminiVisionService()
                            .analyzeProductImage(_imageFile!, _prompt);
                        
                        final draft = ListingDraft.fromJson(resultMap);

                        // นำข้อมูลที่ได้มาใส่ในช่อง TextField
                        if (context.mounted) {
                          setState(() {
                            _titleController.text = draft.title;
                            _categoryController.text = draft.category;
                            _descriptionController.text = draft.description;
                            _showForm = true; // เปิดให้แสดงฟอร์มบนหน้าจอ
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('ให้ AI ช่วยแนะนำ'),
            ),
            
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Column(
                children: [
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 16),
                  Center(child: Text('AI กำลังวิเคราะห์ภาพสินค้า...', style: TextStyle(color: Colors.grey))),
                ],
              ),

            // ส่วนของฟอร์มแก้ไขข้อมูลที่จะโผล่มาเมื่อ AI ทำงานเสร็จ
            if (_showForm) ...[
              const Divider(),
              const Text('ตรวจสอบและแก้ไขข้อมูล (AI แนะนำ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              const SizedBox(height: 16),
              
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อประกาศ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'หมวดหมู่',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดสินค้า',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  // แสดงแจ้งเตือนว่าสำเร็จ แล้วล้างค่าในฟอร์มกลับไปจุดเริ่มต้น
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว (จำลอง)')),
                  );
                  _clearForm();
                },
                child: const Text('ยืนยันร่างประกาศ', style: TextStyle(fontSize: 16)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}