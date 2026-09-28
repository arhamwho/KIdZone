import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'auth_service.dart';

/// Creates a child Firebase Auth account without replacing the parent session.
///
/// Default `FirebaseAuth.instance.createUserWithEmailAndPassword` signs in as
/// the new user. This service uses a **named secondary Firebase app** so only
/// that extra app is signed in, then signs it out.
///
/// Move this to a Cloud Function / Admin SDK for production. Do not put a
/// service-account private key in the Flutter app.
class ChildAccountService {
  ChildAccountService();

  static const String _secondaryAppName = 'kidzone-child-provisioning';

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
