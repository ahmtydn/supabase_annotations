/// Annotation for marking a Dart class as a database table.
///
/// This annotation provides comprehensive configuration options for table
/// generation, including schema settings, RLS policies, and validation rules.
library;

import 'package:meta/meta.dart';
import 'package:supabase_annotations/src/annotations/database_index.dart';
import 'package:supabase_annotations/src/annotations/rls_policy.dart';
import 'package:supabase_annotations/src/models/partition_strategy.dart';
import 'package:supabase_annotations/src/models/table_constraints.dart';
import 'package:supabase_annotations/src/models/validators.dart';

/// Annotation for marking a Dart class as a database table.
///
/// This annotation is applied to Dart classes to indicate that they should
/// be converted to PostgreSQL/Supabase database tables. It provides extensive
/// configuration options for customizing the generated table.
///
/// **Basic Usage:**
/// ```dart
/// @DatabaseTable()
/// class User {
///   String? id;
///   String email;
///   DateTime? createdAt;
/// }
/// ```
///
/// **Advanced Usage:**
/// ```dart
/// @DatabaseTable(
///   name: 'app_users',
///   schema: 'auth',
///   enableRLS: true,
///   comment: 'Application users with authentication data',
///   addTimestamps: true,
///   policies: [
///     RLSPolicy.authenticatedRead(),
///     RLSPolicy.ownerWrite('user_id'),
///   ],
/// )
/// class User { ... }
/// ```
@immutable
class DatabaseTable {
  /// Creates a database table annotation with the specified configuration.
  ///
  /// **Parameters:**
  /// - [name]: Custom table name. If null, uses the class name in snake_case
  /// - [schema]: Database schema name (default: 'public')
  /// - [enableRLS]: Whether to enable Row Level Security (default: true)
  /// - [comment]: Optional table comment for documentation
  /// - [addTimestamps]: Whether to add created_at/updated_at columns (default: true)
  /// - [policies]: List of RLS policies to apply to this table
  /// - [indexes]: List of indexes to create for this table
  /// - [constraints]: List of table-level constraints
  /// - [tablespace]: Custom tablespace for the table
  /// - [withOids]: Whether to create the table with OIDs (deprecated, default: false)
  /// - [inheritFrom]: Parent table to inherit from
  /// - [partitionBy]: Partitioning strategy for the table
  /// - [validationRules]: Custom validation rules for the table
  const DatabaseTable({
    this.name,
    this.schema = 'public',
    this.enableRLS = true,
    this.comment,
    this.addTimestamps = true,
    this.policies = const [],
    this.indexes = const [],
    this.constraints = const [],
    this.tablespace,
    this.withOids = false,
    this.inheritFrom,
    this.partitionBy,
    this.validationRules = const [],
  });

  /// The table name in the database.
  ///
  /// If null, the generator will use the class name converted to snake_case.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(name: 'user_profiles')
  /// class UserProfile { ... }
  /// // Creates table: user_profiles
  ///
  /// @DatabaseTable() // name is null
  /// class BlogPost { ... }
  /// // Creates table: blog_post
  /// ```
  final String? name;

  /// The database schema name.
  ///
  /// PostgreSQL schemas provide a way to organize tables and other database
  /// objects. The default is 'public' which is the standard schema.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(schema: 'auth')
  /// class User { ... }
  /// // Creates table: auth.users
  ///
  /// @DatabaseTable(schema: 'analytics')
  /// class Event { ... }
  /// // Creates table: analytics.events
  /// ```
  final String schema;

  /// Whether to enable Row Level Security (RLS) on this table.
  ///
  /// RLS is a PostgreSQL feature that allows you to control access to rows
  /// in a table based on the characteristics of the user executing a query.
  /// This is essential for multi-tenant applications and data security.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(enableRLS: true)
  /// class Document { ... }
  /// // Generates: ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
  ///
  /// @DatabaseTable(enableRLS: false)
  /// class PublicData { ... }
  /// // No RLS policies will be created
  /// ```
  final bool enableRLS;

  /// Optional comment for the table.
  ///
  /// Comments are stored in the database metadata and can be useful for
  /// documentation and database administration tools.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(
  ///   comment: 'Stores user authentication and profile information'
  /// )
  /// class User { ... }
  /// // Generates: COMMENT ON TABLE users IS 'Stores user authentication...';
  /// ```
  final String? comment;

  /// Whether to automatically add created_at and updated_at timestamp columns.
  ///
  /// When true, the generator will automatically add:
  /// - `created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`
  /// - `updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP`
  ///
  /// It will also create a trigger to automatically update `updated_at`
  /// when rows are modified.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(addTimestamps: true)
  /// class Product { ... }
  /// // Automatically adds created_at and updated_at columns
  ///
  /// @DatabaseTable(addTimestamps: false)
  /// class Configuration { ... }
  /// // No automatic timestamp columns
  /// ```
  final bool addTimestamps;

  /// List of RLS policies to apply to this table.
  ///
  /// RLS policies define the security rules for accessing rows in the table.
  /// Each policy specifies who can perform what operations under what conditions.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(
  ///   policies: [
  ///     RLSPolicy.authenticatedRead(),
  ///     RLSPolicy.ownerWrite('user_id'),
  ///     RLSPolicy.custom(
  ///       name: 'admin_access',
  ///       operation: 'ALL',
  ///       condition: "auth.jwt() ->> 'role' = 'admin'",
  ///     ),
  ///   ],
  /// )
  /// class Document { ... }
  /// ```
  final List<RLSPolicy> policies;

  /// List of indexes to create for this table.
  ///
  /// Indexes improve query performance but add overhead for write operations.
  /// The generator can create various types of indexes based on your needs.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(
  ///   indexes: [
  ///     DatabaseIndex(
  ///       columns: ['email'],
  ///       isUnique: true,
  ///       type: IndexType.btree,
  ///     ),
  ///     DatabaseIndex(
  ///       columns: ['created_at'],
  ///       type: IndexType.brin,
  ///       condition: 'created_at IS NOT NULL',
  ///     ),
  ///   ],
  /// )
  /// class User { ... }
  /// ```
  final List<DatabaseIndex> indexes;

  /// List of table-level constraints.
  ///
  /// Constraints enforce data integrity rules at the table level. These are
  /// in addition to column-level constraints.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(
  ///   constraints: [
  ///     CheckConstraint(
  ///       name: 'valid_email_format',
  ///       condition: "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'",
  ///     ),
  ///     UniqueConstraint(
  ///       name: 'unique_user_email',
  ///       columns: ['email', 'tenant_id'],
  ///     ),
  ///   ],
  /// )
  /// class User { ... }
  /// ```
  final List<TableConstraint> constraints;

  /// Custom tablespace for the table.
  ///
  /// Tablespaces allow you to control where PostgreSQL stores data files.
  /// This is useful for performance tuning and storage management.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(tablespace: 'fast_ssd')
  /// class UserSession { ... }
  /// // Creates table in the 'fast_ssd' tablespace
  ///
  /// @DatabaseTable(tablespace: 'archive_storage')
  /// class AuditLog { ... }
  /// // Creates table in the 'archive_storage' tablespace
  /// ```
  final String? tablespace;

  /// Whether to create the table with OIDs.
  ///
  /// Object Identifiers (OIDs) are deprecated in PostgreSQL and should
  /// generally not be used. This option is provided for legacy compatibility.
  ///
  /// **Default:** false (recommended)
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(withOids: true) // Not recommended
  /// class LegacyTable { ... }
  /// ```
  final bool withOids;

  /// Parent table to inherit from.
  ///
  /// PostgreSQL supports table inheritance where a child table inherits
  /// all columns from its parent table. This is useful for partitioning
  /// and certain design patterns.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable()
  /// class BaseEntity {
  ///   String? id;
  ///   DateTime? createdAt;
  /// }
  ///
  /// @DatabaseTable(inheritFrom: 'base_entity')
  /// class User {
  ///   String email; // Inherits id and createdAt from BaseEntity
  /// }
  /// ```
  final String? inheritFrom;

  /// Partitioning strategy for the table.
  ///
  /// Partitioning divides a large table into smaller, more manageable pieces
  /// while still presenting it as a single table to queries. This improves
  /// performance and maintenance for very large tables.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(
  ///   partitionBy: RangePartition(columns: ['created_at']),
  /// )
  /// class LogEntry { ... }
  /// // Creates a range-partitioned table by created_at
  ///
  /// @DatabaseTable(
  ///   partitionBy: HashPartition(columns: ['user_id']),
  /// )
  /// class UserData { ... }
  /// // Creates a hash-partitioned table
  /// ```
  final PartitionStrategy? partitionBy;

  /// Custom validation rules for the table.
  ///
  /// Validation rules are checked during code generation and can catch
  /// potential issues early in the development process.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseTable(
  ///   validationRules: [
  ///     RangeValidator(min: 1, max: 1000),
  ///     LengthValidator(min: 1, max: 255),
  ///     PatternValidator(r'^[a-zA-Z0-9_]+$'),
  ///   ],
  /// )
  /// class User { ... }
  /// ```
  final List<Validator<dynamic>> validationRules;

  /// Validates the table configuration.
  ///
  /// This method checks for common configuration errors and returns a list
  /// of validation messages. It's called during code generation to ensure
  /// the table definition is valid.
  ///
  /// **Returns:** A list of validation error messages (empty if valid)
  List<String> validate() {
    final errors = <String>[];

    // Schema validation
    if (schema.isEmpty) {
      errors.add('Schema name cannot be empty');
    }

    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(schema)) {
      errors.add('Schema name must be a valid PostgreSQL identifier');
    }

    // Table name validation (if provided)
    if (name != null) {
      if (name!.isEmpty) {
        errors.add('Table name cannot be empty when specified');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name!)) {
        errors.add('Table name must be a valid PostgreSQL identifier');
      }

      // Check for PostgreSQL reserved words
      if (_isReservedWord(name!)) {
        errors.add('Table name "$name" is a PostgreSQL reserved word');
      }
    }

    // Tablespace validation
    if (tablespace != null && tablespace!.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(tablespace!)) {
        errors.add('Tablespace name must be a valid PostgreSQL identifier');
      }
    }

    // Inheritance validation
    if (inheritFrom != null && inheritFrom!.isNotEmpty) {
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(inheritFrom!)) {
        errors.add('Parent table name must be a valid PostgreSQL identifier');
      }
    }

    // Comment validation
    if (comment != null && comment!.length > 1024) {
      errors.add('Table comment should not exceed 1024 characters');
    }

    // Policy validation
    if (policies.isNotEmpty && !enableRLS) {
      errors.add('RLS policies specified but RLS is disabled');
    }

    // OID validation
    if (withOids) {
      errors.add('WITH OIDS is deprecated and should not be used');
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

  /// Gets the effective table name (either specified name or generated from class name).
  ///
  /// **Parameters:**
  /// - [className]: The Dart class name to use if no explicit name is provided
  ///
  /// **Returns:** The table name to use in SQL
  String getEffectiveName(String className) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    // Convert PascalCase to snake_case
    return className
        .replaceAllMapped(
          RegExp('([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .substring(1); // Remove leading underscore
  }

  /// Gets the fully qualified table name (schema.table).
  ///
  /// **Parameters:**
  /// - [className]: The Dart class name to use if no explicit name is provided
  ///
  /// **Returns:** The fully qualified table name
  String getFullyQualifiedName(String className) {
    final tableName = getEffectiveName(className);
    return '$schema.$tableName';
  }

  /// Returns a string representation of this table configuration.
  @override
  String toString() {
    final tableName = name ?? '[dynamic]';
    return 'DatabaseTable(name: $tableName, schema: $schema, RLS: $enableRLS)';
  }
}
