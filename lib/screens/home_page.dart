import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart'; 
import 'checkout_page.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  final List<ItemRepository> repositories;
  final FavoritesRepository favoritesRepository; 

  // อัปเดต Constructor ให้รับ favoritesRepository
  const HomePage({
    super.key, 
    required this.repositories, 
    required this.favoritesRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems(); // แยกฟังก์ชันโหลดข้อมูลออกมา
  }

  void _loadItems() {
    // ดึงข้อมูลจากทุก Repository พร้อมกัน
    _itemsFuture = Future.wait(
      widget.repositories.map((repo) => repo.getItems())
    ).then((listOfLists) {
      // นำข้อมูลจากทุก List มารวมกันเป็น List เดียว
      return listOfLists.expand((list) => list).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [       
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout), // ไอคอนออกจากระบบ
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              // เรียกใช้คำสั่งให้ออกจากระบบ
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่พบสินค้า'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                
                // --- ส่วนที่แสดงชื่อสินค้าพร้อม Badge แยกแหล่งที่มา ---
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // ตัดข้อความยาวๆ เป็น ...
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        // เปลี่ยนสีพื้นหลังและขอบตาม sellerId
                        color: item.sellerId == null ? Colors.blue.shade50 : Colors.purple.shade50,
                        border: Border.all(
                          color: item.sellerId == null ? Colors.blue : Colors.purple,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            // เปลี่ยนไอคอนตาม sellerId
                            item.sellerId == null ? Icons.storefront : Icons.school,
                            size: 12,
                            color: item.sellerId == null ? Colors.blue : Colors.purple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            // เปลี่ยนข้อความตาม sellerId
                            item.sellerId == null ? 'API ร้านค้า' : 'นักศึกษา',
                            style: TextStyle(
                              fontSize: 10,
                              color: item.sellerId == null ? Colors.blue : Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // ----------------------------------------------------
                
                subtitle: Text('${item.price} บาท'),
                // เปลี่ยนจากปุ่มตะกร้าเดี่ยวๆ เป็น Row ที่มี 2 ปุ่ม (โปรด & ตะกร้า)
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () async {
                        try {
                          // เรียกใช้เมธอด addFavorite
                          await widget.favoritesRepository.addFavorite(
                            item.id, 
                            item.title, 
                            item.price.toDouble(), // ป้องกัน error type ให้แปลงเป็น double
                            item.imageUrl,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('เพิ่มลงรายการโปรดแล้ว')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่มรายการโปรด')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        context.read<CartModel>().add(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
      onPressed: () async {
        // แสดงข้อความบอกว่ากำลังโหลด
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กำลังคุยกับ Gemini...')),
        );

        try {
          // เรียกใช้งาน GeminiService
          final result = await GeminiService().generateText(
              'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง');

          // พิมพ์ลง Debug Console
          print('Gemini Response: $result');

          // แสดงผลลัพธ์ผ่าน SnackBar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gemini: $result')),
            );
          }
        } catch (e) {
          print('Error: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
      child: const Icon(Icons.chat),
    ),
    );
  }
}