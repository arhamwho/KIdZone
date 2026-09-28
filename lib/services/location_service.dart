import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

enum LocationShareState {
  ready,
  sharing,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
  unavailable,
}

class LocationService {
  LocationService({FirestoreService? firestore})
    : _db = firestore ?? FirestoreService.instance;

  static final LocationService instance = LocationService();
  static const int _keepLast = 20;

  final FirestoreService _db;
  StreamSubscription<Position>? _sub;

  Stream<List<LocationModel>> watchLocations(String familyId) {
    return _db
        .locations(familyId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<LocationModel> items = snapshot.docs
              .map(LocationModel.fromFirestore)
              .toList();
          items.sort(
            (LocationModel a, LocationModel b) =>
                b.timestamp.compareTo(a.timestamp),
          );
          return items;
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Stream<LocationModel?> watchLatestForChild({
    required String familyId,
    required String childId,
  }) {
    return watchLocations(familyId).map((List<LocationModel> items) {
      for (final LocationModel item in items) {
        if (item.childId == childId) return item;
      }
      return null;
    });
  }

  Future<LocationShareState> currentState() async {
    final bool service = await Geolocator.isLocationServiceEnabled();
    if (!service) return LocationShareState.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return LocationShareState.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationShareState.permissionPermanentlyDenied;
    }
    return LocationShareState.ready;
  }

  Future<LocationShareState> startSharing({
    required String familyId,
    required String childId,
  }) async {
    final LocationShareState state = await currentState();
    if (state != LocationShareState.ready) return state;
    await stopSharing();
    try {
      await _publishCurrent(familyId: familyId, childId: childId);
    } catch (_) {
      // First fix can fail on emulator; the stream may still deliver later.
    }
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((Position position) {
      unawaited(
        _writePosition(
          familyId: familyId,
          childId: childId,
          position: position,
        ),
      );
    });
    return LocationShareState.sharing;
  }

  Future<void> stopSharing() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _publishCurrent({
    required String familyId,
    required String childId,
  }) async {
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    await _writePosition(
      familyId: familyId,
      childId: childId,
      position: position,
    );
  }

  Future<void> _writePosition({
    required String familyId,
    required String childId,
    required Position position,
  }) async {
    try {
      final CollectionReference<Map<String, dynamic>> col = _db.locations(
        familyId,
      );
      final DocumentReference<Map<String, dynamic>> doc = col.doc();
      final LocationModel location = LocationModel(
        locationId: doc.id,
        childId: childId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      await doc.set(location.toMap(isCreate: true));
      await _prune(col, childId);
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> _prune(
    CollectionReference<Map<String, dynamic>> col,
    String childId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await col
        .where('childId', isEqualTo: childId)
        .get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(snapshot.docs);
    docs.sort((QueryDocumentSnapshot<Map<String, dynamic>> a, QueryDocumentSnapshot<Map<String, dynamic>> b) {
      final DateTime aTime =
          readSafe(a.data()['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          readSafe(b.data()['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    if (docs.length <= _keepLast) return;
    final WriteBatch batch = FirebaseFirestore.instance.batch();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> extra
        in docs.skip(_keepLast)) {
      batch.delete(extra.reference);
    }
    await batch.commit();
  }
}

DateTime? readSafe(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
