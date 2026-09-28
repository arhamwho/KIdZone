import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';

class LocationModel {
  const LocationModel({
    required this.locationId,
    required this.childId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final String locationId;
  final String childId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  factory LocationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return LocationModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  factory LocationModel.fromMap(Map<String, dynamic> data, String id) {
    return LocationModel(
      locationId: data['locationId'] as String? ?? id,
      childId: data['childId'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0,
      timestamp: readDate(data['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap({required bool isCreate}) {
    return <String, dynamic>{
      'locationId': locationId,
      'childId': childId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': isCreate
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(timestamp),
    };
  }
}
