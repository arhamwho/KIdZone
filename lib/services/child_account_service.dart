import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'auth_service.dart';

class ChildProvisionResult {
  const ChildProvisionResult({
    required this.uid,
    required this.profileCreated,
  });

  final String uid;
  final bool profileCreated;
}

/// Creates a child Auth account without replacing the parent session.
///
/// Prefers a trusted Cloud Function. If the function is not deployed yet,
/// falls back to a named secondary Firebase app so the parent stays signed in.
/// Never embeds a service-account private key in the client.
class ChildAccountService {
  ChildAccountService();

  static const String _secondaryAppName = 'kidzone-child-provisioning';

  Future<ChildProvisionResult> provisionChild({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'createChildAccount',
      );
      final HttpsCallableResult<dynamic> result = await callable.call(
        <String, dynamic>{
          'email': email.trim(),
          'password': password,
          'name': name.trim(),
        },
      );
      final Object? data = result.data;
      final Map<String, dynamic> map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final String? uid = map['uid'] as String?;
      if (uid == null || uid.isEmpty) {
        throw const AuthException('Something went wrong. Please try again.');
      }
      return ChildProvisionResult(uid: uid, profileCreated: true);
    } on FirebaseFunctionsException catch (error) {
      if (_canUseLocalFallback(error)) {
        final String uid = await createChildAuthAccount(
          email: email,
          password: password,
          name: name,
        );
        return ChildProvisionResult(uid: uid, profileCreated: false);
      }
      throw AuthException(_functionsMessage(error));
    } on AuthException {
      rethrow;
    } catch (_) {
      final String uid = await createChildAuthAccount(
        email: email,
        password: password,
        name: name,
      );
      return ChildProvisionResult(uid: uid, profileCreated: false);
    }
  }

  Future<String> createChildAuthAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    final FirebaseApp app = await _secondaryApp();
    final FirebaseAuth auth = FirebaseAuth.instanceFor(app: app);

    try {
      final UserCredential credential = await auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final User? user = credential.user;
      if (user == null) {
        throw const AuthException('Something went wrong. Please try again.');
      }
      try {
        await user.updateDisplayName(name.trim());
      } catch (_) {
        // Profile name is also stored in Firestore.
      }
      return user.uid;
    } on FirebaseAuthException catch (error) {
      throw AuthException(friendlyAuthMessage(error));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Something went wrong. Please try again.');
    } finally {
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }

  bool _canUseLocalFallback(FirebaseFunctionsException error) {
    const Set<String> fallbackCodes = <String>{
      'not-found',
      'unimplemented',
      'unavailable',
      'internal',
      'deadline-exceeded',
    };
    return fallbackCodes.contains(error.code);
  }

  String _functionsMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Please sign in again to add a child.';
      case 'permission-denied':
        return 'Only a parent in this family can add a child.';
      case 'already-exists':
        return 'That email is already in use.';
      case 'invalid-argument':
        return 'Please check the child’s details and try again.';
      default:
        return error.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<FirebaseApp> _secondaryApp() async {
    for (final FirebaseApp app in Firebase.apps) {
      if (app.name == _secondaryAppName) return app;
    }
    return Firebase.initializeApp(
      name: _secondaryAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
