import 'package:cloud_firestore/cloud_firestore.dart';

/// User-facing Firestore failure with a short, friendly sentence.
class FirestoreException implements Exception {
  const FirestoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

String friendlyFirestoreMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You don’t have access to this family data.',
      'unavailable' => 'Something went wrong. Please try again.',
      'not-found' => 'We couldn’t find that family information.',
      'deadline-exceeded' => 'Something went wrong. Please try again.',
      'network-request-failed' => 'Something went wrong. Please try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}
