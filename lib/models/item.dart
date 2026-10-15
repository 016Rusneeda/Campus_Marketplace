import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  // 1. เปลี่ยนจาก int เป็น dynamic เพื่อให้รองรับ id ได้ทั้ง 2 แบบ (API=int, Firestore=String)
  final dynamic id; 
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  
  // 2. เพิ่มตัวแปร sellerId แบบ nullable
  final String? sellerId; 

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId, // 3. เพิ่มเข้า Constructor
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'], // ไม่ต้องบังคับเป็น int แล้ว
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      imageUrl: json['image'] as String,
    );
  }

  // 4. เพิ่มฟังก์ชันแปลงข้อมูลเป็น Map เพื่อส่งขึ้น Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  // 5. เพิ่มฟังก์ชันแปลงข้อมูลจาก Firestore กลับมาเป็น Item (แก้ Type ให้ตรงเป๊ะแล้ว)
  factory Item.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    // ใส่เครื่องหมาย ! เพื่อยืนยันว่า data ไม่ใช่ null แน่นอน
    final data = doc.data()!; 
    return Item(
      id: doc.id, // ใช้รหัสเอกสารของ Firestore เป็น id ไปเลย
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      sellerId: data['sellerId'],
    );
  }
}