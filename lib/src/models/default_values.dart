/// Defines default values and expressions for database columns.
///
/// This class provides a comprehensive set of default value types and
/// expressions commonly used in PostgreSQL/Supabase databases.
library;

import 'package:meta/meta.dart';

/// Represents a default value expression for a database column.
///
/// Default values can be literal values, SQL expressions, or function calls
/// that are evaluated when a new row is inserted without specifying a value
/// for the column.
@immutable
abstract class DefaultValue {
  /// Creates a default value with the specified SQL expression.
  const DefaultValue._(this.sqlExpression, this.description);

  /// The SQL expression used as the default value.
  final String sqlExpression;

  /// Human-readable description of what this default value does.
  final String description;

  // Common literal defaults

  /// No default value (explicit NULL).
  ///
  /// Use this when you want to explicitly specify that a column should
  /// default to NULL. This is different from not specifying a default.
  ///
  /// **Example:**
  /// ```sql
  /// ALTER TABLE users ALTER COLUMN middle_name SET DEFAULT NULL;
  /// ```
  static const none = _LiteralDefault('NULL', 'Explicit NULL value');

  /// String literal default value.
  ///
  /// **Parameters:**
  /// - [value]: The string value to use as default
  ///
  /// **Example:**
  /// ```dart
  /// DefaultValue.string('pending') // DEFAULT 'pending'
  /// DefaultValue.string('Unknown') // DEFAULT 'Unknown'
  /// ```
  static DefaultValue string(String value) =>
      _LiteralDefault("'$value'", 'String literal: $value');

  /// Numeric literal default value.
  ///
  /// **Parameters:**
  /// - [value]: The numeric value to use as default
  ///
  /// **Example:**
  /// ```dart
  /// DefaultValue.number(0)     // DEFAULT 0
  /// DefaultValue.number(42.5)  // DEFAULT 42.5
  /// DefaultValue.number(-1)    // DEFAULT -1
  /// ```
  static DefaultValue number(num value) =>
      _LiteralDefault('$value', 'Numeric literal: $value');

  /// Boolean literal default value.
  ///
  /// **Parameters:**
  /// - [value]: The boolean value to use as default
  ///
  /// **Example:**
  /// ```dart
  /// DefaultValue.boolean(value: true)  // DEFAULT true
  /// DefaultValue.boolean(value: false) // DEFAULT false
  /// ```
  static DefaultValue boolean({required bool value}) =>
      _LiteralDefault('$value', 'Boolean literal: $value');

  // Timestamp and date defaults

  /// Current timestamp (with timezone).
  ///
  /// Uses PostgreSQL's CURRENT_TIMESTAMP function which returns the
  /// current date and time with timezone at the time of insertion.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT CURRENT_TIMESTAMP
  /// ```
  static const currentTimestamp = _FunctionDefault(
    'CURRENT_TIMESTAMP',
    'Current timestamp with timezone',
  );

  /// Current timestamp (without timezone).
  ///
  /// Uses PostgreSQL's LOCALTIMESTAMP function which returns the
  /// current date and time without timezone information.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT LOCALTIMESTAMP
  /// ```
  static const localTimestamp = _FunctionDefault(
    'LOCALTIMESTAMP',
    'Current timestamp without timezone',
  );

  /// Current date only.
  ///
  /// Uses PostgreSQL's CURRENT_DATE function which returns only
  /// the current date (year-month-day).
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT CURRENT_DATE
  /// ```
  static const currentDate = _FunctionDefault(
    'CURRENT_DATE',
    'Current date (year-month-day only)',
  );

  /// Current time only.
  ///
  /// Uses PostgreSQL's CURRENT_TIME function which returns only
  /// the current time with timezone.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT CURRENT_TIME
  /// ```
  static const currentTime = _FunctionDefault(
    'CURRENT_TIME',
    'Current time with timezone',
  );

  /// NOW() function (equivalent to CURRENT_TIMESTAMP).
  ///
  /// Alternative syntax for current timestamp that some developers prefer.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT NOW()
  /// ```
  static const now = _FunctionDefault(
    'NOW()',
    'Current timestamp (NOW function)',
  );

  // UUID defaults

  /// Generate a random UUID using gen_random_uuid().
  ///
  /// Uses PostgreSQL's gen_random_uuid() function which generates
  /// a random UUID (version 4). Requires the pgcrypto extension.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT gen_random_uuid()
  /// ```
  static const generateUuid = _FunctionDefault(
    'gen_random_uuid()',
    'Generate random UUID (requires pgcrypto extension)',
  );

  /// Generate a UUID using uuid_generate_v1().
  ///
  /// Uses the uuid-ossp extension to generate a version 1 UUID
  /// based on MAC address and timestamp.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT uuid_generate_v1()
  /// ```
  static const generateUuidV1 = _FunctionDefault(
    'uuid_generate_v1()',
    'Generate UUID v1 (requires uuid-ossp extension)',
  );

  /// Generate a UUID using uuid_generate_v4().
  ///
  /// Uses the uuid-ossp extension to generate a version 4 UUID
  /// (random UUID).
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT uuid_generate_v4()
  /// ```
  static const generateUuidV4 = _FunctionDefault(
    'uuid_generate_v4()',
    'Generate UUID v4 (requires uuid-ossp extension)',
  );

  // Sequence defaults

  /// Next value from a sequence.
  ///
  /// **Parameters:**
  /// - [sequenceName]: The name of the sequence
  ///
  /// **Example:**
  /// ```dart
  /// DefaultValue.nextVal('user_id_seq') // DEFAULT nextval('user_id_seq')
  /// DefaultValue.nextVal('order_number_seq')
  /// ```
  static DefaultValue nextVal(String sequenceName) => _FunctionDefault(
        "nextval('$sequenceName')",
        'Next value from sequence: $sequenceName',
      );

  /// Auto-incrementing integer (SERIAL).
  ///
  /// Creates a sequence automatically and uses it for default values.
  /// This is a PostgreSQL-specific shorthand for creating sequences.
  ///
  /// **Example:**
  /// ```sql
  /// -- This creates a sequence automatically
  /// id SERIAL DEFAULT nextval('table_id_seq')
  /// ```
  static const autoIncrement = _FunctionDefault(
    'nextval(pg_get_serial_sequence(TG_TABLE_NAME, TG_ARGV[0]))',
    'Auto-incrementing value (SERIAL)',
  );

  // Array and JSON defaults

  /// Empty array default.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT '{}'::text[]
  /// DEFAULT ARRAY[]::integer[]
  /// ```
  static const emptyArray = _LiteralDefault('ARRAY[]', 'Empty array');

  /// Empty JSON object.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT '{}'::jsonb
  /// ```
  static const emptyJsonObject = _LiteralDefault(
    "'{}'::jsonb",
    'Empty JSON object',
  );

  /// Empty JSON array.
  ///
  /// **Example:**
  /// ```sql
  /// DEFAULT '[]'::jsonb
  /// ```
  static const emptyJsonArray = _LiteralDefault(
    "'[]'::jsonb",
    'Empty JSON array',
  );

  /// Custom JSON object default.
  ///
  /// **Parameters:**
  /// - [jsonString]: The JSON string to use as default
  ///
  /// **Example:**
  /// ```dart
  /// DefaultValue.jsonObject('{"active": true, "count": 0}')
  /// ```
  static DefaultValue jsonObject(String jsonString) => _LiteralDefault(
        "'$jsonString'::jsonb",
        'JSON object: $jsonString',
      );

  // Mathematical defaults

  /// Zero (0) as default.
  static const zero = _LiteralDefault('0', 'Zero');

  /// One (1) as default.
  static const one = _LiteralDefault('1', 'One');

  /// Negative one (-1) as default.
  static const negativeOne = _LiteralDefault('-1', 'Negative one');

  // String defaults

  /// Empty string as default.
  static const emptyString = _LiteralDefault("''", 'Empty string');

  // Custom expression

  /// Custom SQL expression as default.
  ///
  /// Use this for complex default values that aren't covered by the
  /// predefined options.
  ///
  /// **Parameters:**
  /// - [expression]: The SQL expression to use
  /// - [description]: Optional description of what the expression does
  ///
  /// **Example:**
  /// ```dart
  /// DefaultValue.expression('EXTRACT(YEAR FROM NOW())', 'Current year')
  /// DefaultValue.expression('RANDOM() * 100', 'Random number 0-100')
  /// DefaultValue.expression("CONCAT('user_', nextval('user_seq'))", 'Generated username')
  /// ```
  static DefaultValue expression(String expression, [String? description]) =>
      _CustomDefault(
        expression,
        description ?? 'Custom expression: $expression',
      );

  // Validation methods

  /// Validates if this default value is appropriate for the given column type.
  ///
  /// **Parameters:**
  /// - [columnType]: The SQL column type
  ///
  /// **Returns:** True if the default value is compatible
  ///
  /// **Example:**
  /// ```dart
  /// final uuidDefault = DefaultValue.generateUuid;
  /// final isValid = uuidDefault.isValidForColumnType('UUID'); // true
  /// ```
  bool isValidForColumnType(String columnType) {
    final normalizedType = columnType.toUpperCase();

    return switch (this) {
      // Timestamp defaults
      _
          when (this == currentTimestamp ||
              this == localTimestamp ||
              this == now) =>
        normalizedType.contains('TIMESTAMP'),
      _ when this == currentDate => normalizedType == 'DATE',
      _ when this == currentTime => normalizedType.contains('TIME'),

      // UUID defaults
      _
          when (this == generateUuid ||
              this == generateUuidV1 ||
              this == generateUuidV4) =>
        normalizedType == 'UUID',

      // JSON defaults
      _ when (this == emptyJsonObject || this == emptyJsonArray) =>
        normalizedType.contains('JSON'),

      // Array defaults
      _ when this == emptyArray => normalizedType.contains('[]'),

      // Numeric defaults
      _ when (this == zero || this == one || this == negativeOne) =>
        _isNumericType(normalizedType),

      // String defaults
      _ when (this == emptyString) => _isStringType(normalizedType),

      // Boolean defaults are handled by the boolean() factory

      // Custom defaults and literals - assume valid
      _ => true,
    };
  }

  /// Checks if a column type is numeric.
  static bool _isNumericType(String type) {
    return const [
      'INTEGER',
      'BIGINT',
      'SMALLINT',
      'SERIAL',
      'BIGSERIAL',
      'DECIMAL',
      'NUMERIC',
      'REAL',
      'DOUBLE PRECISION',
      'FLOAT',
    ].any(type.contains);
  }

  /// Checks if a column type is string-based.
  static bool _isStringType(String type) {
    return const [
      'TEXT',
      'VARCHAR',
      'CHAR',
      'CHARACTER',
    ].any(type.contains);
  }

  /// Gets the required database extensions for this default value.
  ///
  /// **Returns:** A list of PostgreSQL extensions required
  List<String> getRequiredExtensions() {
    return switch (this) {
      _ when (this == generateUuid) => ['pgcrypto'],
      _ when (this == generateUuidV1 || this == generateUuidV4) => [
          'uuid-ossp',
        ],
      _ => <String>[],
    };
  }

  /// Gets validation warnings for this default value.
  ///
  /// **Returns:** A list of potential issues or considerations
  List<String> getValidationWarnings() {
    return switch (this) {
      _ when this == autoIncrement => [
          'Auto-increment requires careful handling in distributed systems',
          'Consider UUIDs for better scalability',
        ],
      _ when (this == generateUuidV1) => [
          'UUID v1 may leak MAC address information',
          'Consider UUID v4 for privacy',
        ],
      _ when sqlExpression.contains('RANDOM()') => [
          'Random values are not deterministic',
          'May cause issues with replication',
        ],
      _ => <String>[],
    };
  }

  /// Returns the SQL expression for this default value.
  @override
  String toString() => sqlExpression;

  /// Compares two default values for equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DefaultValue &&
          runtimeType == other.runtimeType &&
          sqlExpression == other.sqlExpression;

  /// Hash code for this default value.
  @override
  int get hashCode => sqlExpression.hashCode;
}

/// Implementation for literal default values.
class _LiteralDefault extends DefaultValue {
  const _LiteralDefault(super.expression, super.description) : super._();
}

/// Implementation for function-based default values.
class _FunctionDefault extends DefaultValue {
  const _FunctionDefault(super.expression, super.description) : super._();
}

/// Implementation for custom expression default values.
class _CustomDefault extends DefaultValue {
  const _CustomDefault(super.expression, super.description) : super._();
}
