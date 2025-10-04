/// Validation system for database column values.
///
/// This library provides a comprehensive validation framework for database
/// columns, allowing type-safe validation rules that can be applied at
/// compile-time and runtime.
library;

/// Base class for all column validators.
///
/// Validators provide type-safe validation rules that can be applied to
/// database column values. They are used to generate CHECK constraints
/// and provide client-side validation.
abstract class Validator<T> {
  /// Creates a new validator.
  const Validator();

  /// Validates the given value.
  ///
  /// Returns `true` if the value is valid, `false` otherwise.
  bool validate(T value);

  /// Returns the SQL CHECK constraint expression for this validator.
  ///
  /// The expression should use the column name as the variable.
  String toSqlExpression(String columnName);

  /// Returns a human-readable description of the validation rule.
  String get description;

  /// Returns the error message when validation fails.
  String get errorMessage;
}

/// Validates that a numeric value is within a specified range.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     RangeValidator(min: 0, max: 150),
///   ],
/// )
/// int age;
/// ```
class RangeValidator extends Validator<num> {
  /// Creates a range validator.
  ///
  /// At least one of [min] or [max] must be specified.
  const RangeValidator({this.min, this.max})
      : assert(
            min != null || max != null,
            'At least one '
            'of min or max must be specified');

  /// The minimum allowed value (inclusive).
  final num? min;

  /// The maximum allowed value (inclusive).
  final num? max;

  @override
  bool validate(num value) {
    if (min != null && value < min!) {
      return false;
    }
    if (max != null && value > max!) {
      return false;
    }
    return true;
  }

  @override
  String toSqlExpression(String columnName) {
    final conditions = <String>[];
    if (min != null) conditions.add('$columnName >= $min');
    if (max != null) conditions.add('$columnName <= $max');
    return conditions.join(' AND ');
  }

  @override
  String get description {
    if (min != null && max != null) {
      return 'Value must be between $min and $max (inclusive)';
    } else if (min != null) {
      return 'Value must be at least $min';
    } else {
      return 'Value must be at most $max';
    }
  }

  @override
  String get errorMessage {
    if (min != null && max != null) {
      return 'Value must be between $min and $max';
    } else if (min != null) {
      return 'Value must be at least $min';
    } else {
      return 'Value must be at most $max';
    }
  }
}

/// Validates that a string has a length within a specified range.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     LengthValidator(min: 3, max: 50),
///   ],
/// )
/// String username;
/// ```
class LengthValidator extends Validator<String> {
  /// Creates a length validator.
  ///
  /// At least one of [min] or [max] must be specified.
  const LengthValidator({this.min, this.max})
      : assert(
          min != null || max != null,
          'At least one of min or max must be specified',
        );

  /// The minimum allowed length (inclusive).
  final int? min;

  /// The maximum allowed length (inclusive).
  final int? max;

  @override
  bool validate(String value) {
    final length = value.length;
    if (min != null && length < min!) {
      return false;
    }
    if (max != null && length > max!) {
      return false;
    }
    return true;
  }

  @override
  String toSqlExpression(String columnName) {
    final conditions = <String>[];
    if (min != null) conditions.add('length($columnName) >= $min');
    if (max != null) conditions.add('length($columnName) <= $max');
    return conditions.join(' AND ');
  }

  @override
  String get description {
    if (min != null && max != null) {
      return 'Length must be between $min and $max characters';
    } else if (min != null) {
      return 'Length must be at least $min characters';
    } else {
      return 'Length must be at most $max characters';
    }
  }

  @override
  String get errorMessage => description;
}

/// Validates that a string matches a regular expression pattern.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     PatternValidator(r'^[a-zA-Z0-9_]+$', 'Username can only
/// contain letters, numbers, and underscores'),
///   ],
/// )
/// String username;
/// ```
class PatternValidator extends Validator<String> {
  /// Creates a pattern validator.
  const PatternValidator(this.pattern, [this.customErrorMessage]);

  /// The regular expression pattern to match.
  final String pattern;

  /// Custom error message for validation failures.
  final String? customErrorMessage;

  @override
  bool validate(String value) {
    final regex = RegExp(pattern);
    return regex.hasMatch(value);
  }

  @override
  String toSqlExpression(String columnName) {
    // PostgreSQL regex operator
    return "$columnName ~ '$pattern'";
  }

  @override
  String get description =>
      customErrorMessage ?? 'Value must match pattern: $pattern';

  @override
  String get errorMessage =>
      customErrorMessage ?? 'Value does not match required pattern';
}

/// Validates that a value is one of a specified set of allowed values.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     EnumValidator(['draft', 'published', 'archived']),
///   ],
/// )
/// String status;
/// ```
class EnumValidator<T> extends Validator<T> {
  /// Creates an enum validator.
  const EnumValidator(this.allowedValues);

  /// The list of allowed values.
  final List<T> allowedValues;

  @override
  bool validate(T value) {
    // Runtime validation for empty list
    if (allowedValues.isEmpty) {
      throw ArgumentError('At least one allowed value must be specified');
    }

    return allowedValues.contains(value);
  }

  @override
  String toSqlExpression(String columnName) {
    final valueList = allowedValues.map((v) => "'$v'").join(', ');
    return '$columnName IN ($valueList)';
  }

  @override
  String get description => 'Value must be one of: ${allowedValues.join(', ')}';

  @override
  String get errorMessage =>
      'Value must be one of the allowed values: ${allowedValues.join(', ')}';
}

/// Validates that an email address is in a valid format.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     EmailValidator(),
///   ],
/// )
/// String email;
/// ```
class EmailValidator extends Validator<String> {
  /// Creates an email validator.
  const EmailValidator();

  /// Email validation pattern (basic RFC 5322 compliant).
  static const String _emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  @override
  bool validate(String value) {
    final regex = RegExp(_emailPattern);
    return regex.hasMatch(value);
  }

  @override
  String toSqlExpression(String columnName) {
    return "$columnName ~ '$_emailPattern'";
  }

  @override
  String get description => 'Value must be a valid email address';

  @override
  String get errorMessage => 'Invalid email address format';
}

/// Validates that a URL is in a valid format.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     UrlValidator(),
///   ],
/// )
/// String website;
/// ```
class UrlValidator extends Validator<String> {
  /// Creates a URL validator.
  const UrlValidator();

  /// URL validation pattern.
  static const String _urlPattern = r'^https?:\/\/[^\s]+$';

  @override
  bool validate(String value) {
    final regex = RegExp(_urlPattern);
    return regex.hasMatch(value);
  }

  @override
  String toSqlExpression(String columnName) {
    return "$columnName ~ '$_urlPattern'";
  }

  @override
  String get description => 'Value must be a valid URL';

  @override
  String get errorMessage => 'Invalid URL format';
}

/// Validates that a string contains only alphabetic characters.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     AlphaValidator(),
///   ],
/// )
/// String name;
/// ```
class AlphaValidator extends Validator<String> {
  /// Creates an alpha validator.
  const AlphaValidator({this.allowSpaces = false});

  /// Whether to allow spaces in the string.
  final bool allowSpaces;

  @override
  bool validate(String value) {
    final pattern = allowSpaces ? r'^[a-zA-Z\s]+$' : r'^[a-zA-Z]+$';
    final regex = RegExp(pattern);
    return regex.hasMatch(value);
  }

  @override
  String toSqlExpression(String columnName) {
    final pattern = allowSpaces ? r'^[a-zA-Z\s]+$' : r'^[a-zA-Z]+$';
    return "$columnName ~ '$pattern'";
  }

  @override
  String get description => allowSpaces
      ? 'Value must contain only letters and spaces'
      : 'Value must contain only letters';

  @override
  String get errorMessage => allowSpaces
      ? 'Value can only contain letters and spaces'
      : 'Value can only contain letters';
}

/// Validates that a string contains only alphanumeric characters.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     AlphanumericValidator(),
///   ],
/// )
/// String code;
/// ```
class AlphanumericValidator extends Validator<String> {
  /// Creates an alphanumeric validator.
  const AlphanumericValidator({
    this.allowSpaces = false,
    this.allowUnderscores = false,
  });

  /// Whether to allow spaces in the string.
  final bool allowSpaces;

  /// Whether to allow underscores in the string.
  final bool allowUnderscores;

  @override
  bool validate(String value) {
    var pattern = '^[a-zA-Z0-9';
    if (allowSpaces) pattern += r'\s';
    if (allowUnderscores) pattern += '_';
    pattern += r']+$';

    final regex = RegExp(pattern);
    return regex.hasMatch(value);
  }

  @override
  String toSqlExpression(String columnName) {
    var pattern = '^[a-zA-Z0-9';
    if (allowSpaces) pattern += r'\s';
    if (allowUnderscores) pattern += '_';
    pattern += r']+$';

    return "$columnName ~ '$pattern'";
  }

  @override
  String get description {
    var desc = 'Value must contain only letters and numbers';
    if (allowSpaces && allowUnderscores) {
      desc += ', spaces, and underscores';
    } else if (allowSpaces) {
      desc += ' and spaces';
    } else if (allowUnderscores) {
      desc += ' and underscores';
    }
    return desc;
  }

  @override
  String get errorMessage => description;
}

/// Composite validator that requires all child validators to pass.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     AndValidator([
///       LengthValidator(min: 8),
///       PatternValidator(r'[A-Z]', 'Must contain uppercase letter'),
///       PatternValidator(r'[0-9]', 'Must contain number'),
///     ]),
///   ],
/// )
/// String password;
/// ```
class AndValidator<T> extends Validator<T> {
  /// Creates an AND validator.
  const AndValidator(this.validators)
      : assert(
          validators.length > 0,
          'At least one validator must be specified',
        );

  /// The list of validators that must all pass.
  final List<Validator<T>> validators;

  @override
  bool validate(T value) {
    return validators.every((validator) => validator.validate(value));
  }

  @override
  String toSqlExpression(String columnName) {
    final expressions =
        validators.map((v) => '(${v.toSqlExpression(columnName)})');
    return expressions.join(' AND ');
  }

  @override
  String get description {
    return validators.map((v) => v.description).join(' AND ');
  }

  @override
  String get errorMessage {
    return 'All validation rules must pass: ${validators.map((v) => v.description).join('; ')}';
  }
}

/// Composite validator that requires at least one child validator to pass.
///
/// **Example:**
/// ```dart
/// @DatabaseColumn(
///   validators: [
///     OrValidator([
///       EmailValidator(),
///       PatternValidator(r'^\+\d+$', 'Must be phone number'),
///     ]),
///   ],
/// )
/// String contact;
/// ```
class OrValidator<T> extends Validator<T> {
  /// Creates an OR validator.
  const OrValidator(this.validators)
      : assert(
          validators.length > 0,
          'At least one validator must be specified',
        );

  /// The list of validators where at least one must pass.
  final List<Validator<T>> validators;

  @override
  bool validate(T value) {
    return validators.any((validator) => validator.validate(value));
  }

  @override
  String toSqlExpression(String columnName) {
    final expressions =
        validators.map((v) => '(${v.toSqlExpression(columnName)})');
    return expressions.join(' OR ');
  }

  @override
  String get description {
    return validators.map((v) => v.description).join(' OR ');
  }

  @override
  String get errorMessage {
    return 'Value must satisfy at least '
        'one of: ${validators.map((v) => v.description).join('; ')}';
  }
}
