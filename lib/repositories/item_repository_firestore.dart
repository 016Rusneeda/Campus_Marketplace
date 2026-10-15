import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart'; // import Interface เดิม

class ItemRepositoryFirestore implements ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Item>> getItems() async {
    try {
      // อ่านข้อมูลครั้งเดียวด้วย .get() จาก collection 'items'
      final snapshot = await _firestore.collection('items').get();
      // แปลงข้อมูลจาก Firestore Document ให้เป็น List<Item>
      return snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('ไม่สามารถดึงข้อมูลจาก Firestore ได้: $e');
    }
  }

  // เมธอดนี้จะใช้ในส่วนที่ 6 (โพสต์ขายจริง)
  Future<void> postItem(Item item) async {
    try {
      await _firestore.collection('items').add(item.toFirestore());
    } catch (e) {
       throw Exception('ไม่สามารถเพิ่มสินค้าได้: $e');
    }
  }

  // เมธอดนี้อาจใช้ในหน้าประกาศของฉัน (ถ้ามี)
  Stream<List<Item>> watchMyListings(String sellerId) {
    return _firestore
        .collection('items')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Item.fromFirestore(doc)).toList());
  }
}