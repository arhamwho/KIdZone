import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzone/services/auth_service.dart';

void main() {
  test('maps Firebase auth codes to friendly copy', () {
    String message(String code) =>
        friendlyAuthMessage(FirebaseAuthException(code: code));

    expect(message('email-already-in-use'), 'That email is already registered.');
    expect(message('weak-password'), 'Your password is too weak.');
    expect(
      message('wrong-password'),
      'Please check your email and password.',
    );
    expect(
      message('network-request-failed'),
      'Something went wrong. Please try again.',
    );
    expect(message('mystery-code'), 'Something went wrong. Please try again.');
  });
}
