/// Annotation for configuring foreign key relationships.
///
/// This annotation provides comprehensive configuration options for foreign
/// key constraints, including cascade actions and validation rules.
library;

import 'package:meta/meta.dart';
import 'package:supabase_codegen/src/models/foreign_key_actions.dart';

/// Annotation for configuring foreign key relationships.
///
/// This annotation is applied to fields to establish foreign key relationships
/// with other tables, ensuring referential integrity and defining cascade behavior.
///
/// **Basic Usage:**
/// ```dart
/// @DatabaseTable()
/// class Order {
///   @ForeignKey(
///     table: 'users',
///     column: 'id',
///   )
///   String? userId;
///
///   @ForeignKey(
///     table: 'products',
///     column: 'id',
///     onDelete: ForeignKeyAction.restrict,
///   )
///   String productId;
/// }
/// ```
///
/// **Advanced Usage:**
/// ```dart
/// @DatabaseTable()
/// class OrderItem {
///   @ForeignKey(
///     name: 'fk_order_item_order',
///     table: 'orders',
///     column: 'id',
///     onDelete: ForeignKeyAction.cascade,
///     onUpdate: ForeignKeyAction.cascade,
///     deferrable: true,
///     initiallyDeferred: true,
///     comment: 'Order items are deleted when order is deleted',
///   )
///   String orderId;
///
///   @ForeignKey(
///     table: 'products',
///     column: 'id',
///     onDelete: ForeignKeyAction.restrict,
///     onUpdate: ForeignKeyAction.restrict,
///     comment: 'Prevent deletion of products that have been ordered',
///   )
///   String productId;
/// }
/// ```
///
/// **Composite Foreign Keys:**
/// ```dart
/// @DatabaseTable()
/// @ForeignKey(
///   name: 'fk_user_role_composite',
///   localColumns: ['user_id', 'role_id'],
///   foreignTable: 'user_roles',
///   foreignColumns: ['user_id', 'role_id'],
///   onDelete: ForeignKeyAction.cascade,
/// )
/// class UserPermission {
///   String userId;
///   String roleId;
///   String permission;
/// }
/// ```
@immutable
class ForeignKey {
  /// Creates a foreign key annotation with the specified configuration.
  ///
  /// **Parameters:**
  /// - [name]: Custom foreign key constraint name
  /// - [table]: Target table name (for single-column foreign keys)
  /// - [column]: Target column name (for single-column foreign keys)
  /// - [localColumns]: Source column names (for composite foreign keys)
  /// - [foreignTable]: Target table name (for composite foreign keys)
  /// - [foreignColumns]: Target column names (for composite foreign keys)
  /// - [onDelete]: Action to take when referenced row is deleted
  /// - [onUpdate]: Action to take when referenced row is updated
  /// - [deferrable]: Whether the constraint can be deferred
  /// - [initiallyDeferred]: Whether the constraint is deferred by default
  /// - [comment]: Documentation comment for the foreign key
  /// - [validate]: Whether to validate existing data when adding the constraint
  const ForeignKey({
    this.name,
    this.table,
    this.column,
    this.localColumns = const [],
    this.foreignTable,
    this.foreignColumns = const [],
    this.onDelete = ForeignKeyAction.noAction,
    this.onUpdate = ForeignKeyAction.noAction,
    this.deferrable = false,
    this.initiallyDeferred = false,
    this.comment,
    this.validate = true,
  });

  /// The foreign key constraint name in the database.
  ///
  /// If null, the generator will create a name based on the table names
  /// and column names involved in the relationship.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   name: 'fk_user_orders',
  ///   table: 'users',
  ///   column: 'id',
  /// )
  /// String userId;
  /// ```
  final String? name;

  /// The target table name for single-column foreign keys.
  ///
  /// This is used in conjunction with [column] for simple foreign key
  /// relationships. For composite foreign keys, use [foreignTable] instead.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'users',
  ///   column: 'id',
  /// )
  /// String userId;
  /// ```
  final String? table;

  /// The target column name for single-column foreign keys.
  ///
  /// This is used in conjunction with [table] for simple foreign key
  /// relationships. For composite foreign keys, use [foreignColumns] instead.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'users',
  ///   column: 'id',
  /// )
  /// String userId;
  /// ```
  final String? column;

  /// Source column names for composite foreign keys.
  ///
  /// When specified, this creates a composite foreign key that references
  /// multiple columns. Must be used with [foreignTable] and [foreignColumns].
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   localColumns: ['user_id', 'role_id'],
  ///   foreignTable: 'user_roles',
  ///   foreignColumns: ['user_id', 'role_id'],
  /// )
  /// // Applied to class, not individual fields
  /// ```
  final List<String> localColumns;

  /// Target table name for composite foreign keys.
  ///
  /// Used with [localColumns] and [foreignColumns] to create composite
  /// foreign keys that span multiple columns.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   localColumns: ['category_id', 'subcategory_id'],
  ///   foreignTable: 'categories',
  ///   foreignColumns: ['id', 'parent_id'],
  /// )
  /// ```
  final String? foreignTable;

  /// Target column names for composite foreign keys.
  ///
  /// Must match the order and count of [localColumns]. Each local column
  /// references the corresponding foreign column by position.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   localColumns: ['tenant_id', 'user_id'],
  ///   foreignTable: 'tenant_users',
  ///   foreignColumns: ['tenant_id', 'user_id'],
  /// )
  /// // tenant_id -> tenant_users.tenant_id
  /// // user_id -> tenant_users.user_id
  /// ```
  final List<String> foreignColumns;

  /// Action to take when the referenced row is deleted.
  ///
  /// This determines what happens to rows in this table when the row
  /// they reference is deleted from the target table.
  ///
  /// **Actions:**
  /// - NO ACTION: Prevent deletion if referencing rows exist (default)
  /// - RESTRICT: Same as NO ACTION but cannot be deferred
  /// - CASCADE: Delete referencing rows automatically
  /// - SET NULL: Set foreign key columns to NULL
  /// - SET DEFAULT: Set foreign key columns to their default values
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'users',
  ///   column: 'id',
  ///   onDelete: ForeignKeyAction.cascade,
  /// )
  /// String userId; // Delete orders when user is deleted
  ///
  /// @ForeignKey(
  ///   table: 'categories',
  ///   column: 'id',
  ///   onDelete: ForeignKeyAction.setNull,
  /// )
  /// String? categoryId; // Set to NULL when category is deleted
  /// ```
  final ForeignKeyAction onDelete;

  /// Action to take when the referenced row is updated.
  ///
  /// This determines what happens to foreign key values in this table
  /// when the primary key of the referenced row is updated.
  ///
  /// **Actions:**
  /// - NO ACTION: Prevent update if referencing rows exist (default)
  /// - RESTRICT: Same as NO ACTION but cannot be deferred
  /// - CASCADE: Update foreign key values to match the new primary key
  /// - SET NULL: Set foreign key columns to NULL
  /// - SET DEFAULT: Set foreign key columns to their default values
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'users',
  ///   column: 'id',
  ///   onUpdate: ForeignKeyAction.cascade,
  /// )
  /// String userId; // Update user_id when user.id changes
  /// ```
  final ForeignKeyAction onUpdate;

  /// Whether the constraint can be deferred.
  ///
  /// Deferrable constraints can have their checking postponed until
  /// the end of the transaction. This is useful for circular references
  /// or when you need to temporarily violate the constraint during
  /// complex operations.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'departments',
  ///   column: 'id',
  ///   deferrable: true,
  ///   initiallyDeferred: true,
  /// )
  /// String? departmentId; // Can be checked at transaction end
  /// ```
  final bool deferrable;

  /// Whether the constraint is deferred by default.
  ///
  /// When true, constraint checking is postponed until the end of the
  /// transaction by default. Only meaningful when [deferrable] is true.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'nodes',
  ///   column: 'id',
  ///   deferrable: true,
  ///   initiallyDeferred: true,
  /// )
  /// String? parentId; // For tree structures with circular references
  /// ```
  final bool initiallyDeferred;

  /// Documentation comment for the foreign key.
  ///
  /// Comments are stored in the database metadata and help with
  /// understanding relationships and business rules.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'users',
  ///   column: 'id',
  ///   comment: 'Links order to the customer who placed it',
  /// )
  /// String customerId;
  /// ```
  final String? comment;

  /// Whether to validate existing data when adding the constraint.
  ///
  /// When false, existing data that violates the constraint is allowed
  /// to remain, but new data must satisfy the constraint. This is useful
  /// when adding constraints to tables with existing invalid data.
  ///
  /// **Example:**
  /// ```dart
  /// @ForeignKey(
  ///   table: 'users',
  ///   column: 'id',
  ///   validate: false,
  /// )
  /// String userId; // Don't validate existing orphaned records
  /// ```
  final bool validate;

  /// Whether this is a composite foreign key.
  ///
  /// **Returns:** true if this foreign key references multiple columns
  bool get isComposite => localColumns.isNotEmpty;

  /// Whether this is a simple (single-column) foreign key.
  ///
  /// **Returns:** true if this foreign key references a single column
  bool get isSimple => !isComposite;

  /// Gets the target table name for this foreign key.
  ///
  /// **Returns:** The table name from either [table] or [foreignTable]
  String? get targetTable => isComposite ? foreignTable : table;

  /// Gets the target column names for this foreign key.
  ///
  /// **Returns:** A list of target column names
  List<String> get targetColumns {
    if (isComposite) {
      return foreignColumns;
    } else if (column != null) {
      return [column!];
    } else {
      return [];
    }
  }

  /// Gets the source column names for this foreign key.
  ///
  /// **Parameters:**
  /// - [fieldName]: The field name for simple foreign keys
  ///
  /// **Returns:** A list of source column names
  List<String> getSourceColumns([String? fieldName]) {
    if (isComposite) {
      return localColumns;
    } else if (fieldName != null) {
      return [fieldName];
    } else {
      return [];
    }
  }

  /// Validates the foreign key configuration.
  ///
  /// This method checks for common configuration errors and returns a list
  /// of validation messages. It's called during code generation to ensure
  /// the foreign key definition is valid.
  ///
  /// **Parameters:**
  /// - [fieldName]: The field name for context (null for composite keys)
  /// - [tableName]: The source table name for error messages
  ///
  /// **Returns:** A list of validation error messages (empty if valid)
  List<String> validateConfiguration([String? fieldName, String? tableName]) {
    final errors = <String>[];
    final tableContext = tableName != null ? ' in table $tableName' : '';
    final fieldContext = fieldName != null ? ' for field $fieldName' : '';

    // Constraint name validation
    if (name != null) {
      if (name!.isEmpty) {
        errors
            .add('Foreign key name cannot be empty$fieldContext$tableContext');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name!)) {
        errors.add(
          'Foreign key name must be a valid PostgreSQL identifier$fieldContext$tableContext',
        );
      }

      if (name!.length > 63) {
        errors.add(
          'Foreign key name cannot exceed 63 characters$fieldContext$tableContext',
        );
      }
    }

    // Configuration validation
    if (isComposite) {
      // Composite foreign key validation
      if (localColumns.isEmpty) {
        errors.add(
          'Composite foreign key must specify local columns$tableContext',
        );
      }

      if (foreignTable == null) {
        errors.add(
          'Composite foreign key must specify foreign table$tableContext',
        );
      }

      if (foreignColumns.isEmpty) {
        errors.add(
          'Composite foreign key must specify foreign columns$tableContext',
        );
      }

      if (localColumns.length != foreignColumns.length) {
        errors.add(
          'Local columns and foreign columns must have the same count$tableContext',
        );
      }

      // Simple foreign key fields should not be specified
      if (table != null || column != null) {
        errors.add(
          'Composite foreign key should not specify table or column$tableContext',
        );
      }
    } else {
      // Simple foreign key validation
      if (table == null) {
        errors.add(
          'Simple foreign key must specify target table$fieldContext$tableContext',
        );
      }

      if (column == null) {
        errors.add(
          'Simple foreign key must specify target column$fieldContext$tableContext',
        );
      }

      // Composite foreign key fields should not be specified
      if (localColumns.isNotEmpty ||
          foreignTable != null ||
          foreignColumns.isNotEmpty) {
        errors.add(
          'Simple foreign key should not specify composite foreign key fields$fieldContext$tableContext',
        );
      }
    }

    // Table and column name validation
    final targetTableName = targetTable;
    if (targetTableName != null) {
      if (targetTableName.isEmpty) {
        errors
            .add('Target table name cannot be empty$fieldContext$tableContext');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(targetTableName)) {
        errors.add(
          'Target table name must be a valid PostgreSQL identifier$fieldContext$tableContext',
        );
      }
    }

    // Validate column names
    for (final columnName in targetColumns) {
      if (columnName.isEmpty) {
        errors.add('Column name cannot be empty$fieldContext$tableContext');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(columnName)) {
        errors.add(
          'Column name "$columnName" must be a valid PostgreSQL identifier$fieldContext$tableContext',
        );
      }
    }

    // Validate local column names for composite keys
    for (final columnName in localColumns) {
      if (columnName.isEmpty) {
        errors.add('Local column name cannot be empty$tableContext');
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(columnName)) {
        errors.add(
          'Local column name "$columnName" must be a valid PostgreSQL identifier$tableContext',
        );
      }
    }

    // Action validation - verify that the actions are valid
    final validActions = {
      ForeignKeyAction.noAction,
      ForeignKeyAction.restrict,
      ForeignKeyAction.cascade,
      ForeignKeyAction.setNull,
      ForeignKeyAction.setDefault,
    };

    if (!validActions.contains(onDelete)) {
      errors.add(
        'Invalid onDelete action: ${onDelete.name}$fieldContext$tableContext',
      );
    }

    if (!validActions.contains(onUpdate)) {
      errors.add(
        'Invalid onUpdate action: ${onUpdate.name}$fieldContext$tableContext',
      );
    }

    // Deferrable validation
    if (initiallyDeferred && !deferrable) {
      errors.add(
        'initiallyDeferred can only be true when deferrable is true$fieldContext$tableContext',
      );
    }

    // SET NULL action validation (requires nullable columns)
    if (onDelete == ForeignKeyAction.setNull ||
        onUpdate == ForeignKeyAction.setNull) {
      // Note: We can't validate nullability here as we don't have access to column definitions
      // This validation should be done by the generator when it has full context
    }

    // Comment validation
    if (comment != null && comment!.length > 1024) {
      errors.add(
        'Foreign key comment should not exceed 1024 characters$fieldContext$tableContext',
      );
    }

    // Self-reference validation
    if (tableName != null && targetTable == tableName) {
      // Self-referencing foreign keys are allowed but should be noted
      // This is not an error, just a special case to be aware of
    }

    return errors;
  }

  /// Gets the effective foreign key constraint name.
  ///
  /// **Parameters:**
  /// - [sourceTable]: The source table name
  /// - [fieldName]: The field name for simple foreign keys
  ///
  /// **Returns:** The constraint name to use in SQL
  String getEffectiveName(String sourceTable, [String? fieldName]) {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }

    // Auto-generate name based on tables and columns
    final targetTableName = targetTable ?? 'unknown';

    if (isComposite) {
      final columnPart = localColumns.join('_');
      return 'fk_${sourceTable}_${targetTableName}_$columnPart';
    } else {
      final columnName = fieldName ?? 'unknown';
      return 'fk_${sourceTable}_${targetTableName}_$columnName';
    }
  }

  /// Generates the SQL ALTER TABLE statement to add this foreign key.
  ///
  /// **Parameters:**
  /// - [sourceTable]: The source table name
  /// - [fieldName]: The field name for simple foreign keys
  ///
  /// **Returns:** The complete ALTER TABLE SQL statement
  String generateSql(String sourceTable, [String? fieldName]) {
    final constraintName = getEffectiveName(sourceTable, fieldName);
    // ALTER TABLE
    final parts = <String>[
      'ALTER TABLE $sourceTable',
      'ADD CONSTRAINT $constraintName',
    ];

    // FOREIGN KEY
    final sourceColumns = getSourceColumns(fieldName);
    parts.add('FOREIGN KEY (${sourceColumns.join(', ')})');

    // REFERENCES
    final targetTableName = targetTable!;
    final targetCols = targetColumns;
    parts.add('REFERENCES $targetTableName (${targetCols.join(', ')})');

    // ON DELETE
    if (onDelete != ForeignKeyAction.noAction) {
      parts.add('ON DELETE ${onDelete.sqlClause}');
    }

    // ON UPDATE
    if (onUpdate != ForeignKeyAction.noAction) {
      parts.add('ON UPDATE ${onUpdate.sqlClause}');
    }

    // DEFERRABLE
    if (deferrable) {
      parts.add('DEFERRABLE');
      if (initiallyDeferred) {
        parts.add('INITIALLY DEFERRED');
      }
    }

    // NOT VALID (if validation is disabled)
    if (!validate) {
      parts.add('NOT VALID');
    }

    return '${parts.join(' ')};';
  }

  /// Generates the SQL COMMENT statement for this foreign key.
  ///
  /// **Parameters:**
  /// - [sourceTable]: The source table name
  /// - [fieldName]: The field name for simple foreign keys
  ///
  /// **Returns:** The COMMENT ON CONSTRAINT SQL statement, or null if no comment
  String? generateCommentSql(String sourceTable, [String? fieldName]) {
    if (comment == null) return null;

    final constraintName = getEffectiveName(sourceTable, fieldName);
    return "COMMENT ON CONSTRAINT $constraintName ON $sourceTable IS '${comment!.replaceAll("'", "''")}';";
  }

  /// Returns a string representation of this foreign key configuration.
  @override
  String toString() {
    final constraintName = name ?? '[auto-generated]';
    final target = isComposite
        ? '$foreignTable(${foreignColumns.join(', ')})'
        : '$table($column)';
    return 'ForeignKey(name: $constraintName, target: $target)';
  }
}
