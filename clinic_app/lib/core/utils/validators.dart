class Validators {
  Validators._();

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    // Allow subdomains (e.g., admin@clinic.nalexustechnologies.com)
    final re = RegExp(r'^[\w.+-]+@([\w-]+\.)+[a-z]{2,}$', caseSensitive: false);
    if (!re.hasMatch(value.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final re = RegExp(r'^\+?[\d\s\-()]{7,15}$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid phone number.';
    return null;
  }

  static String? minLength(String? value, int min, [String field = 'This field']) {
    if (value == null || value.isEmpty) return '$field is required.';
    if (value.length < min) return '$field must be at least $min characters.';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? requiredPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required.';
    final re = RegExp(r'^\+?[\d\s\-()]{7,15}$');
    if (!re.hasMatch(value.trim())) return 'Enter a valid phone number.';
    return null;
  }

  static String? time(String? value) {
    if (value == null || value.trim().isEmpty) return 'Time is required.';
    final re = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    if (!re.hasMatch(value.trim())) return 'Enter time as HH:MM (24-hour).';
    return null;
  }

  static String? positiveInt(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) return '$field must be a positive whole number.';
    return null;
  }

  static String? positiveDecimal(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    final n = double.tryParse(value.trim());
    if (n == null || n < 0) return '$field must be 0 or greater.';
    return null;
  }

  /// Returns true when [later] is strictly after [earlier] in HH:MM format.
  static bool isTimeLater(String earlier, String later) {
    int _toMins(String t) {
      final p = t.split(':');
      return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0);
    }
    return _toMins(later) > _toMins(earlier);
  }
}
