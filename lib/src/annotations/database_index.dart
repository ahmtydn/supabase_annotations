/// Annotation for configuring database indexes.
///
/// This annotation provides comprehensive configuration options for database
/// indexes, including type selection, partial indexes, and performance tuning.
library;

import 'package:meta/meta.dart';
import 'package:supabase_annotations/src/models/index_types.dart';

/// Annotation for configuring database indexes.
///
/// This annotation can be applied to classes (for table-level indexes) or
/// fields (for single-column indexes) to specify
/// index creation and configuration.
///
/// **Basic Usage:**
/// ```dart
/// @DatabaseTable()
/// @DatabaseIndex(columns: ['email'], isUnique: true)
/// class User {
///   String email;
///
///   @DatabaseIndex(type: IndexType.hash)
///   String status;
/// }
/// ```
///
/// **Advanced Usage:**
/// ```dart
/// @DatabaseTable()
/// @DatabaseIndex(
///   name: 'user_email_active_idx',
///   columns: ['email'],
///   type: IndexType.btree,
///   isUnique: true,
///   condition: "status = 'active'",
///   comment: 'Index for active user email lookups',
/// )
/// @DatabaseIndex(
///   name: 'user_search_idx',
///   columns: ['first_name', 'last_name'],
///   type: IndexType.gin,
///   expression: "to_tsvector('english', first_name || ' ' || last_name)",
///   comment: 'Full-text search index for user names',
/// )
/// class User {
///   String email;
///   String firstName;
///   String lastName;
///   String status;
/// }
/// ```
@immutable
class DatabaseIndex {
  /// Creates a database index annotation with the specified configuration.
  ///
  /// **Parameters:**
  /// - [name]: Custom index name. If null, will be auto-generated
  /// - [columns]: List of column names to include in the index
  /// - [type]: The index type (B-tree, Hash, GIN, GiST, etc.)
  /// - [isUnique]: Whether this is a unique index
  /// - [condition]: WHERE clause for partial indexes
  /// - [expression]: Expression for functional indexes
  /// - [includes]: Additional columns to include at leaf level (PostgreSQL 11+)
  /// - [tablespace]: Tablespace to store the index
  /// - [comment]: Documentation comment for the index
  /// - [storageParameters]: Storage parameters for index tuning
  /// - [isConcurrent]: Whether to build the index concurrently
  /// - [isDescending]: Whether to sort in descending order (for single column)
  /// - [nullsFirst]: Whether NULL values come first in ordering
  /// - [opClass]: Operator class for the index
  /// - [fillFactor]: Fill factor percentage for the index
  const DatabaseIndex({
    this.name,
    this.columns = const [],
    this.type = IndexType.btree,
    this.isUnique = false,
    this.condition,
    this.expression,
    this.includes = const [],
    this.tablespace,
    this.comment,
    this.storageParameters = const {},
    this.isConcurrent = false,
    this.isDescending = false,
    this.nullsFirst,
    this.opClass,
    this.fillFactor,
  });

  /// The index name in the database.
  ///
  /// If null, the generator will create a name based on the table name,
  /// column names, and index type.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(name: 'user_email_unique_idx')
  /// // Creates: CREATE INDEX user_email_unique_idx ON ...
  ///
  /// @DatabaseIndex() // name is null
  /// // Creates: CREATE INDEX users_email_idx ON ...
  /// ```
  final String? name;

  /// List of column names to include in the index.
  ///
  /// For single-column indexes on fields, this can be empty and the
  /// field name will be used. For composite indexes, specify all columns.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(columns: ['email'])
  /// // Single column index
  ///
  /// @DatabaseIndex(columns: ['last_name', 'first_name'])
  /// // Composite index on multiple columns
  ///
  /// @DatabaseIndex(columns: ['created_at'])
  /// // Time-based index for date range queries
  /// ```
  final List<String> columns;

  /// The type of index to create.
  ///
  /// Different index types are optimized for different query patterns:
  /// - B-tree: General purpose, supports ordering and range queries
  /// - Hash: Equality lookups only, very fast for exact matches
  /// - GIN: Inverted indexes for arrays, JSON, and full-text search
  /// - GiST: Spatial data and complex data types
  /// - SP-GiST: Space-partitioned GiST for specific data types
  /// - BRIN: Block range indexes for very large tables
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(type: IndexType.btree)
  /// String email; // Standard index for searches and sorting
  ///
  /// @DatabaseIndex(type: IndexType.hash)
  /// String status; // Fast equality lookups only
  ///
  /// @DatabaseIndex(type: IndexType.gin)
  /// List<String> tags; // Array and JSON queries
  /// ```
  final IndexType type;

  /// Whether this is a unique index.
  ///
  /// Unique indexes enforce uniqueness constraints while also providing
  /// query performance benefits. They can span multiple columns for
  /// composite uniqueness.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(isUnique: true)
  /// String email; // Unique constraint + index
  ///
  /// @DatabaseIndex(columns: ['user_id', 'role_id'], isUnique: true)
  /// // Composite unique constraint
  /// ```
  final bool isUnique;

  /// WHERE clause for partial indexes.
  ///
  /// Partial indexes only index rows that satisfy the condition.
  /// This can significantly reduce index size and improve performance
  /// for queries that commonly filter on the condition.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['email'],
  ///   condition: "status = 'active'",
  /// )
  /// // Only indexes active users
  ///
  /// @DatabaseIndex(
  ///   columns: ['created_at'],
  ///   condition: "created_at >= '2023-01-01'",
  /// )
  /// // Only indexes recent records
  /// ```
  final String? condition;

  /// Expression for functional indexes.
  ///
  /// Functional indexes index the result of expressions rather than
  /// simple column values. This is useful for computed values,
  /// case-insensitive searches, and complex transformations.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   expression: "LOWER(email)",
  ///   comment: "Case-insensitive email lookup",
  /// )
  /// // Indexes lowercase version of email
  ///
  /// @DatabaseIndex(
  ///   expression: "to_tsvector('english', title || ' ' || content)",
  ///   type: IndexType.gin,
  /// )
  /// // Full-text search index
  /// ```
  final String? expression;

  /// Additional columns to include at leaf level (PostgreSQL 11+).
  ///
  /// Include columns are stored at the leaf level of B-tree indexes
  /// but don't participate in the index structure. This allows
  /// index-only scans for queries that select these columns.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['user_id'],
  ///   includes: ['first_name', 'last_name', 'email'],
  /// )
  /// // Index on user_id with included columns for covering queries
  /// ```
  final List<String> includes;

  /// Tablespace to store the index.
  ///
  /// Tablespaces allow storing indexes on different storage devices
  /// for performance optimization or storage management.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['created_at'],
  ///   tablespace: 'fast_storage',
  /// )
  /// // Store frequently accessed index on SSD
  /// ```
  final String? tablespace;

  /// Documentation comment for the index.
  ///
  /// Comments are stored in the database metadata and help with
  /// database administration and documentation.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['email'],
  ///   comment: 'Fast lookup for user authentication',
  /// )
  /// ```
  final String? comment;

  /// Storage parameters for index tuning.
  ///
  /// These parameters control various aspects of index storage
  /// and behavior. Common parameters include fillfactor, pages_per_range,
  /// autosummarize, etc.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   storageParameters: {
  ///     'fillfactor': '90',
  ///     'autosummarize': 'on',
  ///   },
  /// )
  /// ```
  final Map<String, String> storageParameters;

  /// Whether to build the index concurrently.
  ///
  /// Concurrent index creation doesn't block reads or writes to the table
  /// but takes longer to complete. This is useful for adding indexes
  /// to production tables without downtime.
  ///
  /// **Note:** This only affects the CREATE INDEX statement generation,
  /// not the annotation processing itself.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['email'],
  ///   isConcurrent: true,
  /// )
  /// // Generates: CREATE INDEX CONCURRENTLY ...
  /// ```
  final bool isConcurrent;

  /// Whether to sort in descending order (for single column indexes).
  ///
  /// This affects the default sort order when the index is used
  /// for ORDER BY queries. For multi-column indexes, use column-specific
  /// ordering in the columns specification.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['created_at'],
  ///   isDescending: true,
  /// )
  /// // Optimized for ORDER BY created_at DESC
  /// ```
  final bool isDescending;

  /// Whether NULL values come first in ordering.
  ///
  /// Controls the position of NULL values in the index ordering.
  /// If null, uses PostgreSQL default (NULLS LAST for ASC, NULLS FIRST for DESC).
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['priority'],
  ///   nullsFirst: true,
  /// )
  /// // NULL priorities appear first in results
  /// ```
  final bool? nullsFirst;

  /// Operator class for the index.
  ///
  /// Operator classes define the behavior of the index for specific
  /// data types and operations. Different operator classes support
  /// different operations and sort orders.
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['name'],
  ///   opClass: 'text_pattern_ops',
  /// )
  /// // Optimized for LIKE patterns
  ///
  /// @DatabaseIndex(
  ///   columns: ['location'],
  ///   type: IndexType.gist,
  ///   opClass: 'gist_geometry_ops_2d',
  /// )
  /// // Spatial index for geometry operations
  /// ```
  final String? opClass;

  /// Fill factor percentage for the index.
  ///
  /// The fill factor determines how full each index page should be
  /// during index creation. Lower values leave more space for updates,
  /// higher values use space more efficiently.
  ///
  /// **Range:** 10-100 (percentage)
  /// **Default:** 90 for B-tree indexes
  ///
  /// **Example:**
  /// ```dart
  /// @DatabaseIndex(
  ///   columns: ['frequently_updated_column'],
  ///   fillFactor: 70,
  /// )
  /// // Leave more space for updates to reduce page splits
  /// ```
  final int? fillFactor;

  /// Validates the index configuration.
  ///
  /// This method checks for common configuration errors and returns a list
  /// of validation messages. It's called during code generation to ensure
  /// the index definition is valid.
  ///
  /// **Parameters:**
  /// - [tableName]: The table name for context in error messages
  /// - [availableColumns]: List of available column names for validation
  ///
  /// **Returns:** A list of validation error messages (empty if valid)
  List<String> validate(String tableName, List<String> availableColumns) {
    final errors = <String>[];

    // Index name validation (if provided)
    if (name != null) {
      if (name!.isEmpty) {
        errors.add('Index name cannot be empty for table $tableName');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name!)) {
        errors.add('Index name must be a valid '
            'PostgreSQL identifier for table $tableName');
      }

      if (name!.length > 63) {
        errors
            .add('Index name cannot exceed 63 characters for table $tableName');
      }
    }

    // Column validation
    if (columns.isEmpty && expression == null) {
      errors.add(
        'Index must specify either columns or expression for table $tableName',
      );
    }

    if (columns.isNotEmpty && expression != null) {
      errors.add(
        'Index cannot specify both columns and expression for table $tableName',
      );
    }

    // Validate column names exist
    for (final column in columns) {
      if (!availableColumns.contains(column)) {
        errors.add('Column "$column" does not exist in table $tableName');
      }
    }

    // Validate include columns exist
    for (final column in includes) {
      if (!availableColumns.contains(column)) {
        errors
            .add('Include column "$column" does not exist in table $tableName');
      }
    }

    // Check for overlap between index columns and include columns
    final indexColumnSet = columns.toSet();
    final includeColumnSet = includes.toSet();
    final overlap = indexColumnSet.intersection(includeColumnSet);
    if (overlap.isNotEmpty) {
      errors.add(
        'Columns cannot be both indexed and included: ${overlap.join(', ')}',
      );
    }

    // Index type specific validations
    switch (type) {
      case IndexType.btree:
        // B-tree indexes support all features, no specific validation needed
        break;

      case IndexType.hash:
        if (columns.length > 1) {
          errors.add(
            'Hash indexes only support single columns for table $tableName',
          );
        }
        if (isDescending) {
          errors
              .add('Hash indexes do not support ordering for table $tableName');
        }
        if (includes.isNotEmpty) {
          errors.add(
            'Hash indexes do not support include columns for table $tableName',
          );
        }

      case IndexType.gin:
        if (includes.isNotEmpty) {
          errors.add(
            'GIN indexes do not support include columns for table $tableName',
          );
        }

      case IndexType.gist:
        if (includes.isNotEmpty) {
          errors.add(
            'GiST indexes do not support include columns for table $tableName',
          );
        }

      case IndexType.spgist:
        if (includes.isNotEmpty) {
          errors.add(
            'SP-GiST indexes do not support include '
            'columns for table $tableName',
          );
        }

      case IndexType.brin:
        if (isUnique) {
          errors.add('BRIN indexes cannot be unique for table $tableName');
        }
        if (includes.isNotEmpty) {
          errors.add(
            'BRIN indexes do not support include columns for table $tableName',
          );
        }
    }

    // Fill factor validation
    if (fillFactor != null) {
      if (fillFactor! < 10 || fillFactor! > 100) {
        errors
            .add('Fill factor must be between 10 and 100 for table $tableName');
      }

      if (type != IndexType.btree && type != IndexType.hash) {
        errors.add(
          'Fill factor is only supported for '
          'B-tree and Hash indexes for table $tableName',
        );
      }
    }

    // Expression validation
    if (expression != null) {
      if (expression!.trim().isEmpty) {
        errors.add('Index expression cannot be empty for table $tableName');
      }

      // Basic syntax check for common mistakes
      if (!expression!.contains('(') && expression!.contains(' ')) {
        errors.add(
          'Index expression may be malformed for '
          'table $tableName. Did you mean to use a function call?',
        );
      }
    }

    // Condition validation
    if (condition != null) {
      if (condition!.trim().isEmpty) {
        errors.add('Index condition cannot be empty for table $tableName');
      }

      // Check for common SQL injection patterns (basic validation)
      if (condition!.toLowerCase().contains('drop') ||
          condition!.toLowerCase().contains('delete') ||
          condition!.toLowerCase().contains('insert')) {
        errors.add(
          'Index condition contains potentially dangerous SQL keywords for table $tableName',
        );
      }
    }

    // Storage parameters validation
    for (final entry in storageParameters.entries) {
      if (entry.key.isEmpty || entry.value.isEmpty) {
        errors.add(
          'Storage parameter keys and values cannot be empty for table $tableName',
        );
      }

      // Validate known parameters
      if (!_isValidStorageParameter(entry.key, type)) {
        errors.add(
          'Storage parameter "${entry.key}" is not valid for ${type.name} indexes',
        );
      }
    }

    // Tablespace validation
    if (tablespace != null) {
      if (tablespace!.isEmpty) {
        errors.add('Tablespace name cannot be empty for table $tableName');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(tablespace!)) {
        errors.add(
          'Tablespace name must be a valid PostgreSQL identifier for table $tableName',
        );
      }
    }

    // Comment validation
    if (comment != null && comment!.length > 1024) {
      errors.add(
        'Index comment should not exceed 1024 characters for table $tableName',
      );
    }

    return errors;
  }

  /// Checks if a storage parameter is valid for the given index type.
  static bool _isValidStorageParameter(String parameter, IndexType indexType) {
    const commonParameters = {'fillfactor'};

    const btreeParameters = {'deduplicate_items'};
    const ginParameters = {'fastupdate', 'gin_pending_list_limit'};
    const gistParameters = {'buffering'};
    const brinParameters = {'pages_per_range', 'autosummarize'};

    if (commonParameters.contains(parameter)) return true;

    return switch (indexType) {
      IndexType.btree => btreeParameters.contains(parameter),
      IndexType.gin => ginParameters.contains(parameter),
      IndexType.gist => gistParameters.contains(parameter),
      IndexType.brin => brinParameters.contains(parameter),
      _ => false,
    };
  }

  /// Gets the effective index name (either specified or auto-generated).
  ///
  /// **Parameters:**
  /// - [tableName]: The table name to use in auto-generated names
  /// - [fieldName]: The field name for single-column indexes
  ///
  /// **Returns:** The index name to use in SQL
  String getEffectiveName(String tableName, [String? fieldName]) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    // Auto-generate name based on table, columns, and type
    final suffix = isUnique ? 'unique' : type.name;

    if (columns.isNotEmpty) {
      final columnPart = columns.join('_');
      return '${tableName}_${columnPart}_${suffix}_idx';
    } else if (fieldName != null) {
      return '${tableName}_${fieldName}_${suffix}_idx';
    } else {
      return '${tableName}_expr_${suffix}_idx';
    }
  }

  /// Generates the SQL CREATE INDEX statement.
  ///
  /// **Parameters:**
  /// - [tableName]: The name of the table to create the index on
  /// - [fieldName]: The field name for single-column indexes (optional)
  ///
  /// **Returns:** The complete CREATE INDEX SQL statement
  String generateSql(String tableName, [String? fieldName]) {
    final indexName = getEffectiveName(tableName, fieldName);
    final parts = <String>[];

    // CREATE [UNIQUE] INDEX [CONCURRENTLY]
    parts
      ..add('CREATE')
      ..addAll(isUnique ? ['UNIQUE'] : [])
      ..add('INDEX')
      ..addAll(isConcurrent ? ['CONCURRENTLY'] : [])
      ..add(indexName)
      // USING method
      ..add('ON $tableName')
      ..addAll(type != IndexType.btree ? ['USING ${type.name}'] : []);

    // Columns or expression
    if (expression != null) {
      parts.add('($expression)');
    } else {
      final columnSpecs = <String>[];
      final targetColumns = columns.isNotEmpty ? columns : [fieldName!];

      for (final column in targetColumns) {
        var spec = column;

        if (opClass != null) {
          spec += ' $opClass';
        }

        if (isDescending) {
          spec += ' DESC';
        }

        if (nullsFirst != null) {
          spec += nullsFirst! ? ' NULLS FIRST' : ' NULLS LAST';
        }

        columnSpecs.add(spec);
      }

      parts.add('(${columnSpecs.join(', ')})');
    }

    // Include columns
    if (includes.isNotEmpty) {
      parts.add('INCLUDE (${includes.join(', ')})');
    }

    // Storage parameters
    if (storageParameters.isNotEmpty || fillFactor != null) {
      final params = <String>[];

      if (fillFactor != null) {
        params.add('fillfactor = $fillFactor');
      }

      for (final entry in storageParameters.entries) {
        params.add('${entry.key} = ${entry.value}');
      }

      parts.add('WITH (${params.join(', ')})');
    }

    // Tablespace
    if (tablespace != null) {
      parts.add('TABLESPACE $tablespace');
    }

    // Where condition
    if (condition != null) {
      parts.add('WHERE $condition');
    }

    final sql = '${parts.join(' ')};';

    // Add comment if provided
    if (comment != null && comment!.isNotEmpty) {
      final escapedComment = comment!.replaceAll("'", "''");
      final commentSql = "COMMENT ON INDEX $indexName IS '$escapedComment';";
      return '$sql\n$commentSql';
    }

    return sql;
  }

  /// Returns a string representation of this index configuration.
  @override
  String toString() {
    final indexName = name ?? '[auto-generated]';
    final columnsDesc =
        columns.isNotEmpty ? columns.join(', ') : '[expression]';
    return 'DatabaseIndex(name: $indexName, columns: [$columnsDesc], type: ${type.name})';
  }
}
