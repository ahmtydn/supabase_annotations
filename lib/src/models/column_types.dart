/// Defines PostgreSQL column types supported by the schema generator.
///
/// This class provides a comprehensive set of PostgreSQL/Supabase column types
/// with proper validation and type safety.
library;

import 'package:meta/meta.dart';

/// Represents a PostgreSQL column type with validation and metadata.
@immutable
class ColumnType {
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
  static const text = ColumnType._('TEXT', dartType: String);

  /// Variable-length character string with length limit.
  /// Maps to Dart [String].
  static ColumnType varchar([int? length]) => ColumnType._(
        length != null ? 'VARCHAR($length)' : 'VARCHAR',
        dartType: String,
        supportsLength: true,
        maxLength: 65535,
        minLength: 1,
      );

  /// Fixed-length character string.
  /// Maps to Dart [String].
  static ColumnType char(int length) => ColumnType._(
        'CHAR($length)',
        dartType: String,
        supportsLength: true,
        defaultLength: length,
        maxLength: 255,
        minLength: 1,
      );

  // Numeric Types

  /// 32-bit signed integer (-2^31 to 2^31-1).
  /// Maps to Dart [int].
  static const integer =
      ColumnType._('INTEGER', dartType: int, isNumeric: true);

  /// 64-bit signed integer.
  /// Maps to Dart [int].
  static const bigint = ColumnType._('BIGINT', dartType: int, isNumeric: true);

  /// 16-bit signed integer.
  /// Maps to Dart [int].
  static const smallint =
      ColumnType._('SMALLINT', dartType: int, isNumeric: true);

  /// Auto-incrementing 32-bit integer.
  /// Maps to Dart [int].
  static const serial = ColumnType._('SERIAL', dartType: int, isNumeric: true);

  /// Auto-incrementing 64-bit integer.
  /// Maps to Dart [int].
  static const bigserial =
      ColumnType._('BIGSERIAL', dartType: int, isNumeric: true);

  /// Exact numeric with precision and scale.
  /// Maps to Dart [num].
  static ColumnType decimal([int? precision, int? scale]) => ColumnType._(
        precision != null && scale != null
            ? 'DECIMAL($precision,$scale)'
            : precision != null
                ? 'DECIMAL($precision)'
                : 'DECIMAL',
        dartType: num,
        isNumeric: true,
        supportsPrecision: true,
      );

  /// Alias for decimal.
  /// Maps to Dart [num].
  static ColumnType numeric([int? precision, int? scale]) => ColumnType._(
        precision != null && scale != null
            ? 'NUMERIC($precision,$scale)'
            : precision != null
                ? 'NUMERIC($precision)'
                : 'NUMERIC',
        dartType: num,
        isNumeric: true,
        supportsPrecision: true,
      );

  /// Single precision floating-point.
  /// Maps to Dart [double].
  static const real = ColumnType._('REAL', dartType: double, isNumeric: true);

  /// Double precision floating-point.
  /// Maps to Dart [double].
  static const doublePrecision = ColumnType._(
    'DOUBLE PRECISION',
    dartType: double,
    isNumeric: true,
  );

  // Boolean Type

  /// Boolean value (true/false).
  /// Maps to Dart [bool].
  static const boolean = ColumnType._('BOOLEAN', dartType: bool);

  // Date/Time Types

  /// Date (year, month, day).
  /// Maps to Dart [DateTime].
  static const date = ColumnType._('DATE', dartType: DateTime);

  /// Time of day (no date).
  /// Maps to Dart [DateTime].
  static const time = ColumnType._('TIME', dartType: DateTime);

  /// Date and time (no timezone).
  /// Maps to Dart [DateTime].
  static const timestamp = ColumnType._('TIMESTAMP', dartType: DateTime);

  /// Date and time with timezone.
  /// Maps to Dart [DateTime].
  static const timestampWithTimeZone = ColumnType._(
    'TIMESTAMP WITH TIME ZONE',
    dartType: DateTime,
  );

  /// Time interval.
  /// Maps to Dart [Duration].
  static const interval = ColumnType._('INTERVAL', dartType: Duration);

  // UUID Type

  /// Universally unique identifier.
  /// Maps to Dart [String].
  static const uuid = ColumnType._(
    'UUID',
    dartType: String,
    validationPattern: r'''
^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$''',
  );

  // JSON Types

  /// JSON data (stored as text).
  /// Maps to Dart [Map<String, dynamic>].
  static const json = ColumnType._('JSON', dartType: Map);

  /// Binary JSON data (more efficient).
  /// Maps to Dart [Map<String, dynamic>].
  static const jsonb = ColumnType._('JSONB', dartType: Map);

  // Array Types

  /// Array of the specified type.
  /// Maps to Dart [List].
  static ColumnType array(ColumnType elementType) => ColumnType._(
        '${elementType.sqlType}[]',
        dartType: List,
      );

  // Binary Types

  /// Binary data.
  /// Maps to Dart [List<int>].
  static const bytea = ColumnType._('BYTEA', dartType: List);

  // Network Types

  /// IPv4 or IPv6 network address.
  /// Maps to Dart [String].
  static const inet = ColumnType._(
    'INET',
    dartType: String,
    validationPattern: r'''
^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?:\/(?:[0-9]|[1-2][0-9]|3[0-2]))?$''',
  );

  /// Network address with subnet mask.
  /// Maps to Dart [String].
  static const cidr = ColumnType._('CIDR', dartType: String);

  /// MAC address.
  /// Maps to Dart [String].
  static const macaddr = ColumnType._(
    'MACADDR',
    dartType: String,
    validationPattern: r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
  );

  // Geometric Types

  /// Point on a plane (x,y).
  /// Maps to Dart [Map<String, double>].
  static const point = ColumnType._('POINT', dartType: Map);

  /// Line segment.
  /// Maps to Dart [Map<String, dynamic>].
  static const line = ColumnType._('LINE', dartType: Map);

  /// Rectangle.
  /// Maps to Dart [Map<String, dynamic>].
  static const box = ColumnType._('BOX', dartType: Map);

  /// Circle.
  /// Maps to Dart [Map<String, dynamic>].
  static const circle = ColumnType._('CIRCLE', dartType: Map);

  // Custom enum type

  /// Custom enumeration type.
  /// Maps to Dart enum types.
  static ColumnType enumType(String enumName) => ColumnType._(enumName);

  /// Creates a custom column type with specified SQL type.
  static ColumnType custom(String sqlType, {Type? dartType}) => ColumnType._(
        sqlType,
        dartType: dartType,
      );

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
