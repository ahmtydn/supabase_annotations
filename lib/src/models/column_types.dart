/// Defines PostgreSQL column types supported by the schema generator.
///
/// This class provides a comprehensive set of PostgreSQL/Supabase column types
/// with proper validation and type safety.
library;

import 'package:meta/meta.dart';

/// Represents a PostgreSQL column type with validation and metadata.
@immutable
abstract class ColumnType {
  /// Variable-length character string with length limit.
  /// Maps to Dart [String].
  const factory ColumnType.varchar([int? length]) = _VarcharType;

  /// Fixed-length character string.
  /// Maps to Dart [String].
  const factory ColumnType.char(int length) = _CharType;

  /// Exact numeric with precision and scale.
  /// Maps to Dart [num].
  const factory ColumnType.decimal([int? precision, int? scale]) = _DecimalType;

  /// Alias for decimal.
  /// Maps to Dart [num].
  const factory ColumnType.numeric([int? precision, int? scale]) = _NumericType;

  /// Array of the specified type.
  /// Maps to Dart [List].
  const factory ColumnType.array(ColumnType elementType) = _ArrayType;

  /// Custom enumeration type.
  /// Maps to Dart enum types.
  const factory ColumnType.enumType(String enumName) = _EnumType;

  /// Creates a custom column type with specified SQL type.
  const factory ColumnType.custom(String sqlType, {Type? dartType}) =
      _CustomType;

  /// Creates a new column type with the specified SQL type and constraints.
  const ColumnType._(
    this.sqlType, {
    this.dartType,
    this.isNumeric = false,
    this.supportsLength = false,
    this.supportsPrecision = false,
    this.defaultLength,
    this.maxLength,
    this.minLength,
    this.validationPattern,
  });

  /// The SQL type name as it appears in PostgreSQL.
  final String sqlType;

  /// The corresponding Dart type for type safety.
  final Type? dartType;

  /// Whether this is a numeric type that supports precision and scale.
  final bool isNumeric;

  /// Whether this type supports length constraints.
  final bool supportsLength;

  /// Whether this type supports precision/scale constraints.
  final bool supportsPrecision;

  /// Default length for variable-length types.
  final int? defaultLength;

  /// Maximum allowed length.
  final int? maxLength;

  /// Minimum allowed length.
  final int? minLength;

  /// Regular expression pattern for validation.
  final String? validationPattern;

  // Text Types

  /// Variable-length character string.
  /// Maps to Dart [String].
  static const text = _SimpleColumnType('TEXT', dartType: String);

  // Numeric Types

  /// 32-bit signed integer (-2^31 to 2^31-1).
  /// Maps to Dart [int].
  static const integer =
      _SimpleColumnType('INTEGER', dartType: int, isNumeric: true);

  /// 64-bit signed integer.
  /// Maps to Dart [int].
  static const bigint =
      _SimpleColumnType('BIGINT', dartType: int, isNumeric: true);

  /// 16-bit signed integer.
  /// Maps to Dart [int].
  static const smallint =
      _SimpleColumnType('SMALLINT', dartType: int, isNumeric: true);

  /// Auto-incrementing 32-bit integer.
  /// Maps to Dart [int].
  static const serial =
      _SimpleColumnType('SERIAL', dartType: int, isNumeric: true);

  /// Auto-incrementing 64-bit integer.
  /// Maps to Dart [int].
  static const bigserial =
      _SimpleColumnType('BIGSERIAL', dartType: int, isNumeric: true);

  /// Single precision floating-point.
  /// Maps to Dart [double].
  static const real =
      _SimpleColumnType('REAL', dartType: double, isNumeric: true);

  /// Double precision floating-point.
  /// Maps to Dart [double].
  static const doublePrecision = _SimpleColumnType(
    'DOUBLE PRECISION',
    dartType: double,
    isNumeric: true,
  );

  // Boolean Type

  /// Boolean value (true/false).
  /// Maps to Dart [bool].
  static const boolean = _SimpleColumnType('BOOLEAN', dartType: bool);

  // Date/Time Types

  /// Date (year, month, day).
  /// Maps to Dart [DateTime].
  static const date = _SimpleColumnType('DATE', dartType: DateTime);

  /// Time of day (no date).
  /// Maps to Dart [DateTime].
  static const time = _SimpleColumnType('TIME', dartType: DateTime);

  /// Date and time (no timezone).
  /// Maps to Dart [DateTime].
  static const timestamp = _SimpleColumnType('TIMESTAMP', dartType: DateTime);

  /// Date and time with timezone.
  /// Maps to Dart [DateTime].
  static const timestampWithTimeZone = _SimpleColumnType(
    'TIMESTAMP WITH TIME ZONE',
    dartType: DateTime,
  );

  /// Time interval.
  /// Maps to Dart [Duration].
  static const interval = _SimpleColumnType('INTERVAL', dartType: Duration);

  // UUID Type

  /// Universally unique identifier.
  /// Maps to Dart [String].
  static const uuid = _SimpleColumnType(
    'UUID',
    dartType: String,
    validationPattern: r'''
^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$''',
  );

  // JSON Types

  /// JSON data (stored as text).
  /// Maps to Dart [Map<String, dynamic>].
  static const json = _SimpleColumnType('JSON', dartType: Map);

  /// Binary JSON data (more efficient).
  /// Maps to Dart [Map<String, dynamic>].
  static const jsonb = _SimpleColumnType('JSONB', dartType: Map);

  // Array Types

  // Binary Types

  /// Binary data.
  /// Maps to Dart [List<int>].
  static const bytea = _SimpleColumnType('BYTEA', dartType: List);

  // Network Types

  /// IPv4 or IPv6 network address.
  /// Maps to Dart [String].
  static const inet = _SimpleColumnType(
    'INET',
    dartType: String,
    validationPattern: r'''
^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?:\/(?:[0-9]|[1-2][0-9]|3[0-2]))?$''',
  );

  /// Network address with subnet mask.
  /// Maps to Dart [String].
  static const cidr = _SimpleColumnType('CIDR', dartType: String);

  /// MAC address.
  /// Maps to Dart [String].
  static const macaddr = _SimpleColumnType(
    'MACADDR',
    dartType: String,
    validationPattern: r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
  );

  // Geometric Types

  /// Point on a plane (x,y).
  /// Maps to Dart [Map<String, double>].
  static const point = _SimpleColumnType('POINT', dartType: Map);

  /// Line segment.
  /// Maps to Dart [Map<String, dynamic>].
  static const line = _SimpleColumnType('LINE', dartType: Map);

  /// Rectangle.
  /// Maps to Dart [Map<String, dynamic>].
  static const box = _SimpleColumnType('BOX', dartType: Map);

  /// Circle.
  /// Maps to Dart [Map<String, dynamic>].
  static const circle = _SimpleColumnType('CIRCLE', dartType: Map);

  // Custom enum type

  /// Validates if a Dart value is compatible with this column type.
  bool isValidDartValue(dynamic value) {
    if (value == null) return true; // Null is always valid

    if (dartType != null) {
      return value.runtimeType == dartType;
    }

    // Custom validation for special types
    switch (sqlType) {
      case 'UUID':
        return value is String &&
            (validationPattern == null ||
                RegExp(validationPattern!, caseSensitive: false)
                    .hasMatch(value));
      case 'INET':
      case 'CIDR':
      case 'MACADDR':
        return value is String &&
            (validationPattern == null ||
                RegExp(validationPattern!).hasMatch(value));
      default:
        return true; // Allow custom types
    }
  }

  /// Gets the default Dart type for this column type.
  Type? get defaultDartType => dartType;

  /// Returns a string representation suitable for debugging.
  @override
  String toString() => 'ColumnType($sqlType)';

  /// Compares two column types for equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnType &&
          runtimeType == other.runtimeType &&
          sqlType == other.sqlType;

  /// Hash code for this column type.
  @override
  int get hashCode => sqlType.hashCode;
}

// Implementation classes for factory constructors

/// Implementation for VARCHAR column type.
class _VarcharType extends ColumnType {
  const _VarcharType([int? length])
      : super._(
          length != null ? 'VARCHAR($length)' : 'VARCHAR',
          dartType: String,
          supportsLength: true,
          maxLength: 65535,
          minLength: 1,
        );
}

/// Implementation for CHAR column type.
class _CharType extends ColumnType {
  const _CharType(int length)
      : super._(
          'CHAR($length)',
          dartType: String,
          supportsLength: true,
          defaultLength: length,
          maxLength: 255,
          minLength: 1,
        );
}

/// Implementation for DECIMAL column type.
class _DecimalType extends ColumnType {
  const _DecimalType([int? precision, int? scale])
      : super._(
          precision != null && scale != null
              ? 'DECIMAL($precision,$scale)'
              : precision != null
                  ? 'DECIMAL($precision)'
                  : 'DECIMAL',
          dartType: num,
          isNumeric: true,
          supportsPrecision: true,
        );
}

/// Implementation for NUMERIC column type.
class _NumericType extends ColumnType {
  const _NumericType([int? precision, int? scale])
      : super._(
          precision != null && scale != null
              ? 'NUMERIC($precision,$scale)'
              : precision != null
                  ? 'NUMERIC($precision)'
                  : 'NUMERIC',
          dartType: num,
          isNumeric: true,
          supportsPrecision: true,
        );
}

/// Implementation for array column type.
class _ArrayType extends ColumnType {
  const _ArrayType(this.elementType)
      : super._(
          'ARRAY',
          dartType: List,
        );

  final ColumnType elementType;

  @override
  String get sqlType => '${elementType.sqlType}[]';
}

/// Implementation for enum column type.
class _EnumType extends ColumnType {
  const _EnumType(super.enumName) : super._();
}

/// Implementation for custom column type.
class _CustomType extends ColumnType {
  const _CustomType(super.sqlType, {super.dartType}) : super._();
}

/// Implementation for simple column types (const types without parameters).
class _SimpleColumnType extends ColumnType {
  const _SimpleColumnType(
    super.sqlType, {
    super.dartType,
    super.isNumeric,
    super.validationPattern,
  }) : super._();
}
