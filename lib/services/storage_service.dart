import 'dart:io';

class StorageService {
  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    try {
      // จำลองการใช้เวลาอัปโหลด 2 วินาที
      await Future.delayed(const Duration(seconds: 2));
      
      // ส่งคืน URL ของรูปภาพจำลองกลับไปแทนการอัปโหลดขึ้น Firebase จริงๆ
      // เพื่อแก้ปัญหา Firebase Storage บังคับผูกบัตรเครดิต
      return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=800&auto=format&fit=crop';
    } catch (e) {
      throw Exception('ไม่สามารถอัปโหลดรูปภาพได้: $e');
    }
  }
}