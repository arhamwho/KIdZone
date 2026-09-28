import '../models/child_model.dart';
import 'firestore_service.dart';

/// Family membership and child list access.
class FamilyService {
  FamilyService({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService.instance;

  static final FamilyService instance = FamilyService();

  final FirestoreService _firestore;

  Stream<List<ChildModel>> watchChildren(String familyId) =>
      _firestore.watchChildren(familyId);

  Future<List<ChildModel>> getChildren(String familyId) =>
      _firestore.getChildren(familyId);
}
