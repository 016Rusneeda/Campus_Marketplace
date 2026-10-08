import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'listing_draft_repository.dart';

class ListingDraftRepositoryDrift implements ListingDraftRepository {
  final AppDatabase _db;
  ListingDraftRepositoryDrift(this._db);

  @override
  Future<void> saveDraft(dynamic draft, String imagePath) {
    // นำค่าจาก draft และ imagePath มาประกอบกันเพื่อบันทึกลงฐานข้อมูล
    return _db.into(_db.listingDrafts).insert(
      ListingDraftsCompanion.insert(
        title: draft.title,
        category: draft.category,
        description: draft.description,
        imagePath: imagePath,
      ),
    );
  }

  @override
  Future<List<ListingDraftRow>> getAllDrafts() {
    // ดึงข้อมูลทั้งหมดและเรียงลำดับจากเวลาที่อัปเดตล่าสุด
    return (_db.select(_db.listingDrafts)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  @override
  Future<void> deleteDraft(int id) {
    // ลบข้อมูลตาม id
    return (_db.delete(_db.listingDrafts)
          ..where((t) => t.id.equals(id)))
        .go();
  }
}