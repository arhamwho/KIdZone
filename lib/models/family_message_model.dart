import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';

class FamilyMessageModel {
  const FamilyMessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.read,
    this.createdAt,
  });

  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final bool read;
  final DateTime? createdAt;

  bool isMine(String uid) => senderId == uid;

  bool get hasValidTimestamp =>
      createdAt != null && createdAt!.year >= 2000;

  FamilyMessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    String? text,
    bool? read,
    DateTime? createdAt,
  }) {
    return FamilyMessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory FamilyMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FamilyMessageModel(
      messageId: data['messageId'] as String? ?? doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: _readCreatedAt(data),
    );
  }
}

DateTime? _usableDate(Object? value) {
  final DateTime? date = readDate(value);
  if (date == null || date.year < 2000) return null;
  return date;
}

DateTime? _readCreatedAt(Map<String, dynamic> data) {
  return _usableDate(data['createdAt']) ?? _usableDate(data['clientCreatedAt']);
}
