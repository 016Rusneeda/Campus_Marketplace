import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'screens/main_scaffold.dart';
import 'repositories/item_repository_api.dart';
import 'database/app_database.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';

void main() {
  // สร้าง AppDatabase เพียง 1 อินสแตนซ์ เพื่อใช้งานร่วมกันทั้งแอป
  final db = AppDatabase(); 

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(db: db), // ส่ง db เข้าไปใน MyApp
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db; // รับ AppDatabase เข้ามา
  
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      home: MainScaffold(
        itemRepository: ItemRepositoryApi(), 
        favoritesRepository: FavoritesRepositoryDrift(db), 
        draftRepository: ListingDraftRepositoryDrift(db), 
      ),
    );
  }
}