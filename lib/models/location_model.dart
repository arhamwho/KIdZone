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
    this.sharingEnabled = false,
    this.source = 'device',
  });

  final String locationId;
  final String childId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool sharingEnabled;
  final String source;

  bool get hasFix {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    return latitude.abs() > 0.0001 || longitude.abs() > 0.0001;
  }

  bool get hasTimestamp => timestamp.year >= 2000;

  bool get isDemo => source == 'demo';

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
      timestamp:
          readDate(data['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      sharingEnabled: data['sharingEnabled'] as bool? ?? false,
      source: data['source'] as String? ?? 'device',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'locationId': locationId,
      'childId': childId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'sharingEnabled': sharingEnabled,
      'source': source,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
