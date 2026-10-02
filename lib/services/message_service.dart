import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/family_message_model.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

class MessageService {
  MessageService({FirestoreService? firestore})
    : _db = firestore ?? FirestoreService.instance;

  static final MessageService instance = MessageService();

  final FirestoreService _db;

  Stream<List<FamilyMessageModel>> watchConversation({
    required String familyId,
    required String parentId,
    required String childId,
  }) {
    return _db
        .messages(familyId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<FamilyMessageModel> items = snapshot.docs
              .map(FamilyMessageModel.fromFirestore)
              .where((FamilyMessageModel item) {
                final bool parentToChild =
                    item.senderId == parentId && item.receiverId == childId;
                final bool childToParent =
                    item.senderId == childId && item.receiverId == parentId;
                return parentToChild || childToParent;
              })
              .toList();
          items.sort((FamilyMessageModel a, FamilyMessageModel b) {
            final DateTime unresolved = DateTime.utc(9999);
            final DateTime left = a.createdAt ?? unresolved;
            final DateTime right = b.createdAt ?? unresolved;
            return left.compareTo(right);
          });
          return items;
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  String newMessageId(String familyId) => _db.messages(familyId).doc().id;

  Future<void> sendMessage({
    required String familyId,
    required String messageId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const FirestoreException('Type a message first.');
    }
    if (trimmed.length > 500) {
      throw const FirestoreException('Keep messages under 500 characters.');
    }
    if (senderId == receiverId) {
      throw const FirestoreException('Choose someone to message.');
    }
    try {
      final DateTime now = DateTime.now();
      await _db.messages(familyId).doc(messageId).set(<String, dynamic>{
        'messageId': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': trimmed,
        'createdAt': Timestamp.fromDate(now),
        'clientCreatedAt': Timestamp.fromDate(now),
        'read': false,
      });
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> markConversationRead({
    required String familyId,
    required String readerId,
    required List<FamilyMessageModel> messages,
  }) async {
    final List<FamilyMessageModel> unread = messages
        .where(
          (FamilyMessageModel item) =>
              item.receiverId == readerId && !item.read,
        )
        .toList();
    if (unread.isEmpty) return;
    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final FamilyMessageModel item in unread) {
        batch.update(_db.messages(familyId).doc(item.messageId), <String, dynamic>{
          'read': true,
        });
      }
      await batch.commit();
    } catch (_) {}
  }
}
