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
  static const Duration _minWriteGap = Duration(seconds: 8);

  final FirestoreService _db;
  StreamSubscription<Position>? _sub;
  Timer? _pulse;
  String? _familyId;
  String? _childId;
  DateTime? _lastWriteAt;

  Stream<LocationModel?> watchLatestForChild({
    required String familyId,
    required String childId,
  }) {
    return _db
        .locations(familyId)
        .doc(childId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return null;
          return LocationModel.fromFirestore(doc);
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Stream<List<LocationModel>> watchFamilyLocations({
    required String familyId,
  }) {
    return _db
        .locations(familyId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snap) {
          return snap.docs.map(LocationModel.fromFirestore).toList();
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
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
    if (state != LocationShareState.ready) {
      await _setSharingFlag(
        familyId: familyId,
        childId: childId,
        enabled: false,
      );
      return state;
    }
    await stopSharing(clearIds: false);
    _familyId = familyId;
    _childId = childId;
    try {
      await _publishCurrent(familyId: familyId, childId: childId, enabled: true);
    } catch (_) {
      // First GPS fix can fail on an emulator; later stream events may succeed.
    }
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen(
      (Position position) {
        unawaited(
          _writePosition(
            familyId: familyId,
            childId: childId,
            position: position,
            enabled: true,
          ),
        );
      },
      onError: (_) {},
    );
    _pulse = Timer.periodic(const Duration(seconds: 25), (_) {
      unawaited(
        _publishCurrent(familyId: familyId, childId: childId, enabled: true),
      );
    });
    return LocationShareState.sharing;
  }

  Future<void> stopSharing({bool clearIds = true}) async {
    await _sub?.cancel();
    _sub = null;
    _pulse?.cancel();
    _pulse = null;
    final String? familyId = _familyId;
    final String? childId = _childId;
    if (clearIds) {
      _familyId = null;
      _childId = null;
      _lastWriteAt = null;
    }
    if (clearIds && familyId != null && childId != null) {
      await _setSharingFlag(
        familyId: familyId,
        childId: childId,
        enabled: false,
      );
    }
  }

  Future<void> markSharingOff({
    required String familyId,
    required String childId,
  }) {
    return _setSharingFlag(
      familyId: familyId,
      childId: childId,
      enabled: false,
    );
  }

  Future<void> _publishCurrent({
    required String familyId,
    required String childId,
    required bool enabled,
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
      enabled: enabled,
      force: true,
    );
  }

  Future<void> _writePosition({
    required String familyId,
    required String childId,
    required Position position,
    required bool enabled,
    bool force = false,
  }) async {
    if (!_isRealFix(position.latitude, position.longitude)) return;
    final DateTime now = DateTime.now();
    if (!force &&
        _lastWriteAt != null &&
        now.difference(_lastWriteAt!) < _minWriteGap) {
      return;
    }
    try {
      final LocationModel location = LocationModel(
        locationId: childId,
        childId: childId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy.isFinite ? position.accuracy : 0,
        timestamp: position.timestamp,
        sharingEnabled: enabled,
        source: 'device',
      );
      await _db.locations(familyId).doc(childId).set(location.toMap());
      _lastWriteAt = now;
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> _setSharingFlag({
    required String familyId,
    required String childId,
    required bool enabled,
  }) async {
    try {
      await _db.locations(familyId).doc(childId).set(
        <String, dynamic>{
          'locationId': childId,
          'childId': childId,
          'sharingEnabled': enabled,
          'source': 'device',
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  static bool _isRealFix(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude.abs() > 90 || longitude.abs() > 180) return false;
    return latitude.abs() > 0.0001 || longitude.abs() > 0.0001;
  }
}
