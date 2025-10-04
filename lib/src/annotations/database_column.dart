/// Annotation for configuring database column properties.
///
/// This annotation provides comprehensive configuration options for individual
/// table columns, including type mapping, constraints, and validation.
library;

import 'package:meta/meta.dart';
import 'package:supabase_annotations/src/models/column_types.dart';
import 'package:supabase_annotations/src/models/default_values.dart';
import 'package:supabase_annotations/src/models/validators.dart';
import 'package:supabase_annotations/supabase_annotations.dart'
    show DatabaseTable, ForeignKeyAction, IndexType;

/// Annotation for configuring database column properties.
///
/// This annotation is applied to fields in a class marked with [DatabaseTable]
/// to specify how the field should be mapped to a database column.
///
/// **Basic Usage:**
/// ```dart
/// @DatabaseTable()
/// class User {
///   @DatabaseColumn(type: ColumnType.uuid, isPrimaryKey: true)
///   String? id;
///
///   @DatabaseColumn(type: ColumnType.text, isUnique: true)
///   String email;
///
///   @DatabaseColumn(type: ColumnType.timestampWithTimeZone)
///   DateTime? createdAt;
/// }
/// ```
///
/// **Advanced Usage:**
/// ```dart
/// @DatabaseTable()
/// class Product {
///   @DatabaseColumn(
///     name: 'product_id',
///     type: ColumnType.uuid,
///     isPrimaryKey: true,
///     defaultValue: DefaultValue.generateUuid(),
///     comment: 'Primary key for products',
///   )
///   String? id;
///
///   @DatabaseColumn(
///     type: ColumnType.varchar(255),
///     isNullable: false,
///     isUnique: true,
///     validators: [
///       LengthValidator(min: 3, max: 255),
///       PatternValidator(r'^[a-zA-Z0-9\s\-_]+$'),
///     ],
///   )
///   String name;
///
///   @DatabaseColumn(
///     type: ColumnType.numeric(10, 2),
///     isNullable: false,
///     defaultValue: DefaultValue.number(0),
///     checkConstraints: ['price >= 0'],
///   )
///   double price;
/// }
/// ```
@immutable
class DatabaseColumn {
  /// Creates a database column annotation with the specified configuration.
  ///
  /// **Parameters:**
  /// - [name]: Custom column name. If null, uses the field name in snake_case
  /// - [type]: The PostgreSQL column type. If null, inferred from Dart type
  /// - [isNullable]: Whether the column allows NULL values (default: true)
  /// - [isPrimaryKey]: Whether this column is a primary key (default: false)
  /// - [isUnique]: Whether this column has a unique constraint (default: false)
  /// - [defaultValue]: Default value expression for the column
  /// - [comment]: Optional column comment for documentation
  /// - [validators]: List of validation rules for this column
  /// - [checkConstraints]: List of CHECK constraint expressions
  /// - [references]: Foreign key reference configuration
  /// - [autoIncrement]: Whether this is an auto-incrementing column
  /// - [length]: Maximum length for string types
  /// - [precision]: Precision for numeric types
  /// - [scale]: Scale for numeric types
  /// - [collation]: Collation for text types
  /// - [isIndexed]: Whether to create a basic index on this column
  /// - [indexType]: Type of index to create if isIndexed is true
  /// - [storageType]: Storage type for the
  ///     column (PLAIN, EXTENDED, EXTERNAL, MAIN)
  const DatabaseColumn({
    this.name,
    this.type,
    this.isNullable = true,
    this.isPrimaryKey = false,
    this.isUnique = false,
    this.defaultValue,
    this.comment,
    this.validators = const [],
    this.checkConstraints = const [],
    this.references,
    this.autoIncrement = false,
    this.length,
    this.precision,
    this.scale,
    this.collation,
    this.isIndexed = false,
    this.indexType,
    this.storageType,
  });

  /// The column name in the database.
  ///
  /// If null, the generator will use the field name converted to snake_case.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(name: 'user_email')
  /// String email; // Column name: user_email
  ///
  /// @DatabaseColumn() // name is null
  /// String firstName; // Column name: first_name
  /// ```
  final String? name;

  /// The PostgreSQL column type.
  ///
  /// If null, the generator will infer the type from the Dart field type.
  /// Use [ColumnType] constants for type safety and validation.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(type: ColumnType.text)
  /// String description;
  ///
  /// @DatabaseColumn(type: ColumnType.varchar(100))
  /// String shortDescription;
  ///
  /// @DatabaseColumn(type: ColumnType.decimal(10, 2))
  /// double price;
  /// ```
  final ColumnType? type;

  /// Whether the column allows NULL values.
  ///
  /// **Default:** true (allows NULL)
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(isNullable: false)
  /// String email; // NOT NULL constraint
  ///
  /// @DatabaseColumn(isNullable: true)
  /// String? middleName; // Allows NULL
  /// ```
  final bool isNullable;

  /// Whether this column is a primary key.
  ///
  /// Primary key columns are automatically
  /// NOT NULL and have a unique constraint.
  /// A table can have only one primary key (which may span multiple columns).
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(isPrimaryKey: true)
  /// String id; // PRIMARY KEY constraint
  ///
  /// // Composite primary key (use on multiple columns)
  /// @DatabaseColumn(isPrimaryKey: true)
  /// String userId;
  /// @DatabaseColumn(isPrimaryKey: true)
  /// String roleId;
  /// ```
  final bool isPrimaryKey;

  /// Whether this column has a unique constraint.
  ///
  /// Unique constraints ensure that no two rows have the same value
  /// in this column (NULL values are allowed
  /// unless the column is also NOT NULL).
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(isUnique: true)
  /// String email; // UNIQUE constraint
  ///
  /// @DatabaseColumn(isUnique: true, isNullable: false)
  /// String username; // UNIQUE NOT NULL
  /// ```
  final bool isUnique;

  /// Default value expression for the column.
  ///
  /// The default value is used when inserting rows without specifying
  /// a value for this column. Use [DefaultValue] for type-safe defaults.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(defaultValue: DefaultValue.currentTimestamp)
  /// DateTime createdAt;
  ///
  /// @DatabaseColumn(defaultValue: DefaultValue.string('pending'))
  /// String status;
  ///
  /// @DatabaseColumn(defaultValue: DefaultValue.generateUuid())
  /// String id;
  /// ```
  final DefaultValue? defaultValue;

  /// Optional comment for the column.
  ///
  /// Comments are stored in the database metadata and can be useful for
  /// documentation and database administration tools.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(comment: 'User email address for authentication')
  /// String email;
  ///
  /// @DatabaseColumn(comment: 'Timestamp when the record was created')
  /// DateTime createdAt;
  /// ```
  final String? comment;

  /// List of validation rules for this column.
  ///
  /// Validators are used during code generation to validate the column
  /// configuration and can generate additional constraints or checks.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(
  ///   validators: [
  ///     EmailValidator(),
  ///     LengthValidator(min: 5, max: 255),
  ///   ],
  /// )
  /// String email;
  ///
  /// @DatabaseColumn(
  ///   validators: [
  ///     RangeValidator(min: 0, max: 150),
  ///   ],
  /// )
  /// int age;
  /// ```
  final List<Validator<dynamic>> validators;

  /// List of CHECK constraint expressions.
  ///
  /// CHECK constraints ensure that values in the column satisfy a boolean
  /// expression. They are evaluated for every INSERT and UPDATE.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(
  ///   checkConstraints: [
  ///     'price > 0',
  ///     'price <= 999999.99',
  ///   ],
  /// )
  /// double price;
  ///
  /// @DatabaseColumn(
  ///   checkConstraints: [
  ///     "status IN ('active', 'inactive', 'pending')",
  ///   ],
  /// )
  /// String status;
  /// ```
  final List<String> checkConstraints;

  /// Foreign key reference configuration.
  ///
  /// Defines a foreign key relationship to another table. This ensures
  /// referential integrity between tables.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(
  ///   references: ForeignKeyReference(
  ///     table: 'users',
  ///     column: 'id',
  ///     onDelete: ForeignKeyAction.cascade,
  ///   ),
  /// )
  /// String userId;
  /// ```
  final ForeignKeyAction? references;

  /// Whether this is an auto-incrementing column.
  ///
  /// Auto-incrementing columns automatically generate unique sequential
  /// values. In PostgreSQL, this is typically implemented using SERIAL types.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(autoIncrement: true)
  /// int id; // Becomes SERIAL or BIGSERIAL
  ///
  /// @DatabaseColumn(autoIncrement: true, type: ColumnType.bigserial)
  /// int sequenceNumber;
  /// ```
  final bool autoIncrement;

  /// Maximum length for string types.
  ///
  /// This is used for VARCHAR and CHAR types to specify the maximum
  /// number of characters allowed.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(length: 255)
  /// String email; // VARCHAR(255)
  ///
  /// @DatabaseColumn(type: ColumnType.varchar(), length: 50)
  /// String shortCode;
  /// ```
  final int? length;

  /// Precision for numeric types.
  ///
  /// For DECIMAL and NUMERIC types, precision is the total number of digits.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(precision: 10, scale: 2)
  /// double price; // DECIMAL(10,2) - up to 99999999.99
  ///
  /// @DatabaseColumn(precision: 5)
  /// int quantity; // DECIMAL(5) - up to 99999
  /// ```
  final int? precision;

  /// Scale for numeric types.
  ///
  /// For DECIMAL and NUMERIC types, scale is the number of digits after
  /// the decimal point.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(precision: 10, scale: 2)
  /// double price; // DECIMAL(10,2) - 2 digits after decimal
  ///
  /// @DatabaseColumn(precision: 8, scale: 4)
  /// double coordinates; // DECIMAL(8,4) - 4 digits after decimal
  /// ```
  final int? scale;

  /// Collation for text types.
  ///
  /// Collation determines how text values are sorted and compared.
  /// This affects ORDER BY, comparison operators, and indexes.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(collation: 'C')
  /// String code; // Case-sensitive, byte order
  ///
  /// @DatabaseColumn(collation: 'en_US.utf8')
  /// String name; // English locale, UTF-8
  /// ```
  final String? collation;

  /// Whether to create a basic index on this column.
  ///
  /// Indexes improve query performance for frequently searched columns
  /// but add overhead for write operations.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(isIndexed: true)
  /// String email; // Creates index on email column
  ///
  /// @DatabaseColumn(isIndexed: true, indexType: IndexType.hash)
  /// String status; // Creates hash index for equality lookups
  /// ```
  final bool isIndexed;

  /// Type of index to create if isIndexed is true.
  ///
  /// Different index types are optimized for different query patterns.
  /// If not specified, B-tree is used as the default.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(isIndexed: true, indexType: IndexType.gin)
  /// Map<String, dynamic> metadata; // GIN index for JSON queries
  ///
  /// @DatabaseColumn(isIndexed: true, indexType: IndexType.gist)
  /// String location; // GiST index for geometric queries
  /// ```
  final IndexType? indexType;

  /// Storage type for the column.
  ///
  /// PostgreSQL supports different storage strategies for columns:
  /// - PLAIN: Inline storage, no compression
  /// - EXTENDED: Inline storage with compression, then external
  /// - EXTERNAL: External storage without compression
  /// - MAIN: Inline storage with compression
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseColumn(storageType: 'EXTERNAL')
  /// String largeText; // Store large text externally
  ///
  /// @DatabaseColumn(storageType: 'MAIN')
  /// String compressedData; // Compress but keep inline
  /// ```
  final String? storageType;

  /// Validates the column configuration.
  ///
  /// This method checks for common configuration errors and returns a list
  /// of validation messages. It's called during code generation to ensure
  /// the column definition is valid.
  ///
  /// **Parameters:**
  /// - [fieldName]: The Dart field name for context in error messages
  /// - [fieldType]: The Dart field type for compatibility checking
  ///
  /// **Returns:** A list of validation error messages (empty if valid)
  List<String> validate(String fieldName, Type fieldType) {
    final errors = <String>[];

    // Column name validation (if provided)
    if (name != null) {
      if (name!.isEmpty) {
        errors.add('Column name cannot be empty for field $fieldName');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name!)) {
        errors.add(
          'Column name must be a valid '
          'PostgreSQL identifier for field $fieldName',
        );
      }

      // Check for PostgreSQL reserved words
      if (_isReservedWord(name!)) {
        errors.add(
          'Column name "${name!}" is a PostgreSQL '
          'reserved word for field $fieldName',
        );
      }
    }

    // Primary key validation
    if (isPrimaryKey && isNullable) {
      errors.add('Primary key column $fieldName cannot be nullable');
    }

    // Type compatibility validation
    if (type != null &&
        !type!.isValidDartValue(_getDefaultValueForType(fieldType))) {
      errors.add(
        'Column type ${type!.sqlType} is not compatible '
        'with Dart type $fieldType for field $fieldName',
      );
    }

    // Default value validation
    if (defaultValue != null && type != null) {
      if (!defaultValue!.isValidForColumnType(type!.sqlType)) {
        errors.add(
          'Default value is not compatible with '
          'column type ${type!.sqlType} for field $fieldName',
        );
      }
    }

    // Auto increment validation
    if (autoIncrement) {
      if (type != null && !_isNumericType(type!.sqlType)) {
        errors.add(
          'Auto increment can only be used with '
          'numeric types for field $fieldName',
        );
      }

      if (defaultValue != null) {
        errors.add(
          'Auto increment columns should not have '
          'explicit default values for field $fieldName',
        );
      }
    }

    // Precision and scale validation
    if (scale != null && precision == null) {
      errors.add('Scale specified without precision for field $fieldName');
    }

    if (precision != null && precision! <= 0) {
      errors.add('Precision must be positive for field $fieldName');
    }

    if (scale != null && scale! < 0) {
      errors.add('Scale cannot be negative for field $fieldName');
    }

    if (precision != null && scale != null && scale! > precision!) {
      errors.add('Scale cannot be greater than precision for field $fieldName');
    }

    // Length validation
    if (length != null && length! <= 0) {
      errors.add('Length must be positive for field $fieldName');
    }

    // Storage type validation
    if (storageType != null) {
      const validStorageTypes = {'PLAIN', 'EXTENDED', 'EXTERNAL', 'MAIN'};
      if (!validStorageTypes.contains(storageType!.toUpperCase())) {
        errors.add(
          'Invalid storage type "$storageType" for field $fieldName. '
          'Valid values: ${validStorageTypes.join(', ')}',
        );
      }
    }

    // Check constraint validation
    for (var i = 0; i < checkConstraints.length; i++) {
      if (checkConstraints[i].trim().isEmpty) {
        errors.add(
          'Check constraint ${i + 1} cannot be empty for field $fieldName',
        );
      }
    }

    // Comment validation
    if (comment != null && comment!.length > 1024) {
      errors.add(
        'Column comment should not exceed 1024 characters for field $fieldName',
      );
    }

    return errors;
  }

  /// Checks if a name is a PostgreSQL reserved word.
  static bool _isReservedWord(String name) {
    const reservedWords = {
      'user',
      'table',
      'column',
      'index',
      'constraint',
      'primary',
      'foreign',
      'references',
      'key',
      'unique',
      'not',
      'null',
      'default',
      'check',
      'create',
      'drop',
      'alter',
      'select',
      'insert',
      'update',
      'delete',
      'from',
      'where',
      'order',
      'group',
      'having',
      'limit',
      'offset',
      'inner',
      'outer',
      'left',
      'right',
      'join',
      'on',
      'as',
      'distinct',
      'all',
      'any',
      'some',
      'exists',
      'in',
      'between',
      'like',
      'ilike',
      'similar',
      'and',
      'or',
      'true',
      'false',
      'unknown',
    };

    return reservedWords.contains(name.toLowerCase());
  }

  /// Checks if a SQL type is numeric.
  static bool _isNumericType(String sqlType) {
    final upperType = sqlType.toUpperCase();
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
    ].any(upperType.contains);
  }

  /// Gets a default value for a Dart type (for validation purposes).
  static dynamic _getDefaultValueForType(Type type) {
    return switch (type) {
      Type() when type == String => '',
      Type() when type == int => 0,
      Type() when type == double => 0.0,
      Type() when type == bool => false,
      Type() when type == DateTime => DateTime.now(),
      Type() when type == List => <dynamic>[],
      Type() when type == Map => <String, dynamic>{},
      _ => null,
    };
  }

  /// Gets the effective column name (either specified
  /// name or generated from field name).
  ///
  /// **Parameters:**
  /// - [fieldName]: The Dart field name to use if no explicit name is provided
  ///
  /// **Returns:** The column name to use in SQL
  String getEffectiveName(String fieldName) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    // Convert camelCase to snake_case
    return fieldName
        .replaceAllMapped(
          RegExp('([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp('^_'), ''); // Remove leading underscore if present
  }

  /// Gets the SQL type with any modifiers (length, precision, scale).
  ///
  /// **Returns:** The complete SQL type specification
  String getFullSqlType() {
    if (type == null) return 'TEXT'; // Default fallback

    var sqlType = type!.sqlType;

    // Apply length modifier if specified and supported
    if (length != null && type!.supportsLength) {
      if (sqlType == 'VARCHAR' || sqlType == 'CHAR') {
        sqlType = '$sqlType($length)';
      }
    }

    // Apply precision/scale modifiers if specified and supported
    if (precision != null && type!.supportsPrecision) {
      if (scale != null) {
        sqlType = '$sqlType($precision,$scale)';
      } else {
        sqlType = '$sqlType($precision)';
      }
    }

    return sqlType;
  }

  /// Gets all constraints for this column as SQL clauses.
  ///
  /// **Returns:** A list of SQL constraint clauses
  List<String> getConstraints() {
    final constraints = <String>[];

    if (isPrimaryKey) {
      constraints.add('PRIMARY KEY');
    }

    if (!isNullable && !isPrimaryKey) {
      // Primary keys are implicitly NOT NULL
      constraints.add('NOT NULL');
    }

    if (isUnique && !isPrimaryKey) {
      // Primary keys are implicitly unique
      constraints.add('UNIQUE');
    }

    if (defaultValue != null) {
      constraints.add('DEFAULT ${defaultValue!.sqlExpression}');
    }

    for (final check in checkConstraints) {
      constraints.add('CHECK ($check)');
    }

    if (collation != null) {
      constraints.add('COLLATE "$collation"');
    }

    return constraints;
  }

  /// Returns a string representation of this column configuration.
  @override
  String toString() {
    final columnName = name ?? '[dynamic]';
    final columnType = type?.sqlType ?? '[inferred]';
    return 'DatabaseColumn(name: $columnName, type: $columnType, '
        'nullable: $isNullable)';
  }
}
