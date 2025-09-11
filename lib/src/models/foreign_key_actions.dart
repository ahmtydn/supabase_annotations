/// Defines actions that can be taken when
/// foreign key constraints are triggered.
///
/// This enum provides all the standard PostgreSQL foreign key actions with
/// comprehensive documentation and validation.
library;

/// Represents an action to take when a foreign key constraint is triggered.
///
/// Foreign key actions determine what happens to dependent rows when a
/// referenced row is updated or deleted.
enum ForeignKeyAction {
  /// Prevents the update or deletion of the referenced row.
  ///
  /// This is the default and most restrictive action. If any dependent
  /// rows exist, the operation will fail with a foreign key violation error.
  ///
  /// Use this when data integrity is paramount and you want explicit control
  /// over deletions/updates.
  ///
  /// **Example:** If you try to delete a user that has posts, the deletion
  /// will be rejected.
  restrict('RESTRICT'),

  /// Automatically deletes or updates dependent rows.
  ///
  /// When the referenced row is deleted, all dependent rows are also deleted.
  /// When the referenced row is updated, the foreign key values in dependent
  /// rows are updated to match.
  ///
  /// Use this for "owned" relationships where dependent data should not
  /// exist without its parent.
  ///
  /// **Example:** When a user is deleted, all their posts are automatically
  /// deleted as well.
  cascade('CASCADE'),

  /// Sets the foreign key column to NULL.
  ///
  /// When the referenced row is deleted or updated, the foreign key column
  /// in dependent rows is set to NULL. The column must be nullable for this
  /// to work.
  ///
  /// Use this when you want to preserve dependent rows but clear the
  /// relationship.
  ///
  /// **Example:** When a category is deleted, products in that category
  /// have their category_id set to NULL.
  setNull('SET NULL'),

  /// Sets the foreign key column to its default value.
  ///
  /// When the referenced row is deleted or updated, the foreign key column
  /// in dependent rows is set to its default value. The column must have
  /// a default value defined.
  ///
  /// Use this when you want to assign dependent rows to a default parent.
  ///
  /// **Example:** When a department is deleted, employees are moved to
  /// a default "Unassigned" department.
  setDefault('SET DEFAULT'),

  /// No immediate action is taken.
  ///
  /// Similar to RESTRICT, but the check is deferred until the end of the
  /// transaction. This allows for complex operations that might temporarily
  /// violate constraints.
  ///
  /// Use this in advanced scenarios where you need to perform multiple
  /// related operations within a transaction.
  ///
  /// **Example:** Swapping primary keys between two rows in a transaction.
  noAction('NO ACTION');

  /// Creates a foreign key action with the specified SQL clause.
  const ForeignKeyAction(this.sqlClause);

  /// The SQL clause used in foreign key constraints.
  final String sqlClause;

  /// Creates a foreign key action from a string representation.
  ///
  /// This method is case-insensitive and handles common variations.
  ///
  /// **Parameters:**
  /// - [action]: The string representation of the action
  ///
  /// **Returns:** The corresponding [ForeignKeyAction]
  ///
  /// **Throws:** [ArgumentError] if the action string is not recognized
  ///
  /// **Example:**
  /// ```dart
  /// final action1 = ForeignKeyAction.fromString('cascade');
  /// final action2 = ForeignKeyAction.fromString('SET NULL');
  /// final action3 = ForeignKeyAction.fromString('RESTRICT');
  /// ```
  static ForeignKeyAction fromString(String action) {
    final normalizedAction = action.toUpperCase().replaceAll('_', ' ');

    return switch (normalizedAction) {
      'RESTRICT' => ForeignKeyAction.restrict,
      'CASCADE' => ForeignKeyAction.cascade,
      'SET NULL' || 'SETNULL' => ForeignKeyAction.setNull,
      'SET DEFAULT' || 'SETDEFAULT' => ForeignKeyAction.setDefault,
      'NO ACTION' || 'NOACTION' => ForeignKeyAction.noAction,
      _ => throw ArgumentError.value(
          action,
          'action',
          'Invalid foreign key action. Valid values are: '
              'RESTRICT, CASCADE, SET NULL, SET DEFAULT, NO ACTION',
        ),
    };
  }

  /// Gets the recommended action for different relationship types.
  ///
  /// This method provides sensible defaults based on common use cases.
  ///
  /// **Parameters:**
  /// - [relationshipType]: The type of relationship
  /// (ownership, reference, etc.)
  ///
  /// **Returns:** The recommended [ForeignKeyAction]
  ///
  /// **Example:**
  /// ```dart
  /// final ownershipAction = ForeignKeyAction.
  /// getRecommendedAction('ownership');
  /// // Returns CASCADE - when parent is deleted, children should be deleted
  ///
  /// final referenceAction = ForeignKeyAction.
  /// getRecommendedAction('reference');
  /// // Returns SET NULL - when referenced item is deleted, clear the reference
  /// ```
  static ForeignKeyAction getRecommendedAction(String relationshipType) {
    return switch (relationshipType.toLowerCase()) {
      'ownership' ||
      'composition' ||
      'parent-child' =>
        ForeignKeyAction.cascade,
      'reference' || 'optional' => ForeignKeyAction.setNull,
      'required' || 'mandatory' => ForeignKeyAction.restrict,
      'default' || 'fallback' => ForeignKeyAction.setDefault,
      _ => ForeignKeyAction.restrict, // Safe default
    };
  }

  /// Validates if this action is compatible with the column definition.
  ///
  /// Some actions have requirements for the foreign key column:
  /// - SET NULL requires the column to be nullable
  /// - SET DEFAULT requires the column to have a default value
  ///
  /// **Parameters:**
  /// - [isNullable]: Whether the foreign key column allows NULL
  /// - [hasDefault]: Whether the foreign key column has a default value
  ///
  /// **Returns:** True if the action is compatible with the column
  ///
  /// **Example:**
  /// ```dart
  /// final setNullAction = ForeignKeyAction.setNull;
  /// final isValid1 = setNullAction.isValidForColumn(
  /// isNullable: true,
  ///  hasDefault: false);
  /// // Returns true - SET NULL is valid for nullable columns
  ///
  /// final isValid2 = setNullAction.isValidForColumn(isNullable:
  /// false, hasDefault: false);
  /// // Returns false - SET NULL requires a nullable column
  /// ```
  bool isValidForColumn({required bool isNullable, required bool hasDefault}) {
    return switch (this) {
      ForeignKeyAction.setNull => isNullable,
      ForeignKeyAction.setDefault => hasDefault,
      _ => true, // Other actions don't have special requirements
    };
  }

  /// Gets validation requirements for this action.
  ///
  /// **Returns:** A list of requirements that must be met for this action
  List<String> getValidationRequirements() {
    return switch (this) {
      ForeignKeyAction.setNull => ['Column must be nullable'],
      ForeignKeyAction.setDefault => ['Column must have a default value'],
      _ => <String>[],
    };
  }

  /// Gets a human-readable description of what this action does.
  ///
  /// **Returns:** A descriptive string explaining the action's behavior
  String get description {
    return switch (this) {
      ForeignKeyAction.restrict =>
        'Prevents deletion/update if dependent rows exist',
      ForeignKeyAction.cascade =>
        'Automatically deletes/updates dependent rows',
      ForeignKeyAction.setNull => 'Sets foreign key to NULL in dependent rows',
      ForeignKeyAction.setDefault =>
        'Sets foreign key to default value in dependent rows',
      ForeignKeyAction.noAction =>
        'Defers constraint check until end of transaction',
    };
  }

  /// Gets examples of when to use this action.
  ///
  /// **Returns:** A list of example use cases
  List<String> get useCases {
    return switch (this) {
      ForeignKeyAction.restrict => [
          'Financial records that must not be deleted',
          'Required references that need explicit handling',
          'Audit trails and compliance data',
        ],
      ForeignKeyAction.cascade => [
          'User posts when user is deleted',
          'Order items when order is deleted',
          'File attachments when document is deleted',
        ],
      ForeignKeyAction.setNull => [
          'Product category when category is deleted',
          'Employee manager when manager leaves',
          'Optional references',
        ],
      ForeignKeyAction.setDefault => [
          'Employee department to "Unassigned"',
          'Product status to "Draft"',
          'Default category assignments',
        ],
      ForeignKeyAction.noAction => [
          'Complex transactions with multiple updates',
          'Temporary constraint violations',
          'Advanced data migration scenarios',
        ],
    };
  }

  /// Returns the SQL clause for this action.
  @override
  String toString() => sqlClause;
}
