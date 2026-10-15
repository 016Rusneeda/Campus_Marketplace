import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/app_database.dart';
import '../models/item.dart';
import '../repositories/listing_draft_repository.dart';
import '../repositories/item_repository_firestore.dart';
import '../services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;
  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    setState(() {
      _draftsFuture = widget.repository.getAllDrafts();
    });
  }

  // --- เพิ่มฟังก์ชันจัดการการโพสต์ขายจริง ---
  Future<void> _publishDraft(ListingDraftRow draft) async {
    final priceController = TextEditingController();
    
    // 1. แสดง Dialog ถามราคา
    final price = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตั้งราคาสินค้า'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'ราคา (บาท)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              final parsedPrice = double.tryParse(priceController.text);
              if (parsedPrice != null && parsedPrice > 0) {
                Navigator.pop(context, parsedPrice);
              }
            },
            child: const Text('โพสต์ขาย'),
          ),
        ],
      ),
    );

    // ถ้ายกเลิก หรือกรอกราคาไม่ถูกต้อง
    if (price == null) return;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('กำลังอัปโหลดรูปภาพและโพสต์ขาย...')),
    );

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // 2. อัปโหลดรูปภาพขึ้น Storage
      final imageUrl = await StorageService().uploadListingImage(
        File(draft.imagePath),
        user.uid,
      );

      // 3. สร้าง Item Object ใหม่
      final newItem = Item(
        id: '', // ปล่อยว่างไว้ Firestore จะสร้าง Document ID ให้เอง
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: user.uid,
      );

      // 4. บันทึกลง Firestore
      await ItemRepositoryFirestore().postItem(newItem);

      // 5. ลบร่างนี้ออกจาก Local Database
      await widget.repository.deleteDraft(draft.id);

      // 6. โหลดข้อมูลร่างใหม่เพื่ออัปเดตหน้าจอ
      _loadDrafts();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('โพสต์ขายสำเร็จแล้ว!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }

          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(child: Text('ไม่มีร่างประกาศ'));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return ListTile(
                // แสดงรูปภาพตัวอย่างเล็กๆ ด้านหน้า (ถ้ามี)
                leading: Image.file(
                  File(draft.imagePath),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
                title: Text(draft.title),
                subtitle: Text('หมวดหมู่: ${draft.category}'),
                // --- เปลี่ยนเป็น Row เพื่อให้มี 2 ปุ่ม (โพสต์ และ ลบ) ---
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.upload, color: Colors.blue),
                      tooltip: 'โพสต์ขายจริง',
                      onPressed: () => _publishDraft(draft),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'ลบร่าง',
                      onPressed: () async {
                        await widget.repository.deleteDraft(draft.id);
                        _loadDrafts(); // รีเฟรชรายการ
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}