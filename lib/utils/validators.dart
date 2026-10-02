/// Reusable `TextFormField` validators.
///
/// Each method returns `null` when the value is acceptable and an error
/// message otherwise, matching the signature expected by `FormFieldValidator`.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    final String? emptyError = required(value, field: 'Email');
    if (emptyError != null) return emptyError;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final String? emptyError = required(value, field: 'Password');
    if (emptyError != null) return emptyError;
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? name(String? value) {
    final String? emptyError = required(value, field: 'Name');
    if (emptyError != null) return emptyError;
    if (value!.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? age(String? value, {int min = 3, int max = 17}) {
    final String? emptyError = required(value, field: 'Age');
    if (emptyError != null) return emptyError;
    final int? parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Age must be a number';
    if (parsed < min || parsed > max) return 'Age must be between $min and $max';
    return null;
  }

  static String? pin(String? value, {int length = 4}) {
    final String? emptyError = required(value, field: 'PIN');
    if (emptyError != null) return emptyError;
    if (value!.trim().length != length ||
        int.tryParse(value.trim()) == null) {
      return 'PIN must be $length digits';
    }
    return null;
  }

  static String? money(String? value, {int min = 1, int max = 100000}) {
    final String? emptyError = required(value, field: 'Amount');
    if (emptyError != null) return emptyError;
    final int? parsed = int.tryParse(value!.trim());
    if (parsed == null) return 'Enter a whole rupee amount';
    if (parsed < min || parsed > max) {
      return 'Amount must be between ₹$min and ₹$max';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final String? emptyError = required(value, field: 'Confirm password');
    if (emptyError != null) return emptyError;
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
