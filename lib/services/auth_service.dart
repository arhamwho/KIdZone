import 'package:firebase_auth/firebase_auth.dart';

import '../models/family_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

/// User-facing auth failure. [message] is always a friendly sentence, never
/// the raw Firebase error string.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Email/password authentication against Firebase Auth.
///
/// Role and family membership come from Firestore `users/{uid}`, not from a
/// hard-coded list.
class AuthService {
  AuthService({FirebaseAuth? auth, FirestoreService? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirestoreService.instance;

  static final AuthService instance = AuthService();

  final FirebaseAuth _auth;
  final FirestoreService _firestore;

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Creates an email/password parent account, then the Firestore profile and
  /// family documents.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final User user = credential.user!;
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {}

      final String uid = user.uid;
      await _firestore.createUserProfile(
        UserModel(
          uid: uid,
          name: name.trim(),
          email: email.trim(),
          role: UserRole.parent,
        ),
      );
      final FamilyModel family = await _firestore.createFamily(
        parentId: uid,
        familyName: "${name.trim()}'s family",
      );
      await _firestore.updateUserProfile(uid, familyId: family.familyId);
      final UserModel? profile = await _firestore.getUserProfile(uid);
      return profile ??
          UserModel(
            uid: uid,
            name: name.trim(),
            email: email.trim(),
            role: UserRole.parent,
            familyId: family.familyId,
          );
    } on FirebaseAuthException catch (error) {
      throw AuthException(friendlyAuthMessage(error));
    } on AuthException {
      rethrow;
    } on FirestoreException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User user = credential.user!;
      final UserModel? profile = await _firestore.getUserProfile(user.uid);
      if (profile == null) {
        throw const AuthException(
          'We couldn’t find your profile. Please try again.',
        );
      }
      return profile;
    } on FirebaseAuthException catch (error) {
      throw AuthException(friendlyAuthMessage(error));
    } on AuthException {
      rethrow;
    } on FirestoreException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw const AuthException('Something went wrong. Please try again.');
    }
  }

  Future<UserModel?> loadSignedInProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    try {
      final UserModel? profile = await _firestore.getUserProfile(user.uid);
      if (profile == null) {
        await logout();
      }
      return profile;
    } on FirestoreException {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

/// Converts a Firebase auth code into a short, friendly sentence.
String friendlyAuthMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' => 'That email is already registered.',
    'weak-password' => 'Your password is too weak.',
    'invalid-email' => 'Please check your email and password.',
    'user-not-found' => 'Please check your email and password.',
    'wrong-password' => 'Please check your email and password.',
    'invalid-credential' => 'Please check your email and password.',
    'user-disabled' => 'Please check your email and password.',
    'network-request-failed' => 'Something went wrong. Please try again.',
    'too-many-requests' => 'Something went wrong. Please try again.',
    _ => 'Something went wrong. Please try again.',
  };
}
