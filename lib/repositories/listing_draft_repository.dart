import '../database/app_database.dart';

abstract class ListingDraftRepository {
  Future<void> saveDraft(dynamic draft, String imagePath);
  Future<List<ListingDraftRow>> getAllDrafts();
  Future<void> deleteDraft(int id);
}