/// Table constraint definitions for database schema generation.
///
/// This file contains classes representing various types of table constraints
/// that can be applied to PostgreSQL tables.
library;

import 'package:meta/meta.dart';

/// Base class for all table constraints.
///
/// Table constraints are rules that ensure data integrity and consistency
/// within a database table.
@immutable
abstract class TableConstraint {
  /// Creates a table constraint with the given name.
  const TableConstraint({
    required this.name,
  });

  /// The name of the constraint.
  ///
  /// Must be unique within the table and follow PostgreSQL naming conventions.
  final String name;

  /// Generates the SQL DDL for this constraint.
  String toSQL();

  /// Validates that this constraint is properly configured.
  ///
  /// Throws [ArgumentError] if the constraint configuration is invalid.
  void validate() {
    if (name.isEmpty) {
      throw ArgumentError('Constraint name cannot be empty');
    }

    // Basic name validation
    if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name)) {
      throw ArgumentError(
        'Constraint name must start with a letter or underscore and contain '
        'only letters, numbers, and underscores: $name',
      );
    }
  }
}

/// A CHECK constraint that enforces a boolean condition on table data.
///
/// CHECK constraints ensure that all values in a column or set of columns
/// satisfy a particular condition.
///
/// **Example:**
/// ```dart
/// CheckConstraint(
///   name: 'valid_email',
///   condition: "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'",
/// )
/// ```
@immutable
class CheckConstraint extends TableConstraint {
  /// Creates a CHECK constraint.
  ///
  /// [name] must be unique within the table.
  /// [condition] must be a valid PostgreSQL boolean expression.
  const CheckConstraint({
    required super.name,
    required this.condition,
    this.comment,
  });

  /// The boolean condition that must be satisfied.
  ///
  /// This should be a valid PostgreSQL boolean expression that can reference
  /// column names from the table.
  final String condition;

  /// Optional comment describing the constraint purpose.
  final String? comment;

  @override
  String toSQL() {
    return 'CONSTRAINT $name CHECK ($condition)';
  }

  @override
  void validate() {
    super.validate();

    if (condition.trim().isEmpty) {
      throw ArgumentError('CHECK constraint condition cannot be empty');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckConstraint &&
        other.name == name &&
        other.condition == condition &&
        other.comment == comment;
  }

  @override
  int get hashCode => Object.hash(name, condition, comment);

  @override
  String toString() {
    return 'CheckConstraint(name: $name, condition: $condition)';
  }
}

/// A UNIQUE constraint that ensures uniqueness across one or more columns.
///
/// UNIQUE constraints prevent duplicate values from being inserted into
/// the specified columns.
///
/// **Example:**
/// ```dart
/// UniqueConstraint(
///   name: 'unique_user_email',
///   columns: ['email', 'tenant_id'],
/// )
/// ```
@immutable
class UniqueConstraint extends TableConstraint {
  /// Creates a UNIQUE constraint.
  ///
  /// [name] must be unique within the table.
  /// [columns] must contain at least one column name.
  const UniqueConstraint({
    required super.name,
    required this.columns,
    this.comment,
  });

  /// The columns that must be unique together.
  ///
  /// For single-column uniqueness, use a list with one element.
  /// For composite uniqueness, include multiple column names.
  final List<String> columns;

  /// Optional comment describing the constraint purpose.
  final String? comment;

  @override
  String toSQL() {
    final columnList = columns.join(', ');
    return 'CONSTRAINT $name UNIQUE ($columnList)';
  }

  @override
  void validate() {
    super.validate();

    if (columns.isEmpty) {
      throw ArgumentError('UNIQUE constraint must specify at least one column');
    }

    for (final column in columns) {
      if (column.trim().isEmpty) {
        throw ArgumentError('Column name cannot be empty');
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UniqueConstraint &&
        other.name == name &&
        _listEquals(other.columns, columns) &&
        other.comment == comment;
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(columns), comment);

  @override
  String toString() {
    return 'UniqueConstraint(name: $name, columns: $columns)';
  }
}

/// A PRIMARY KEY constraint that uniquely identifies each row in a table.
///
/// Each table can have only one primary key constraint, which automatically
/// creates a unique index and ensures that the columns are NOT NULL.
///
/// **Example:**
/// ```dart
/// PrimaryKeyConstraint(
///   name: 'pk_users',
///   columns: ['id'],
/// )
/// ```
@immutable
class PrimaryKeyConstraint extends TableConstraint {
  /// Creates a PRIMARY KEY constraint.
  ///
  /// [name] must be unique within the table.
  /// [columns] must contain at least one column name.
  const PrimaryKeyConstraint({
    required super.name,
    required this.columns,
    this.comment,
  });

  /// The columns that form the primary key.
  ///
  /// All specified columns will automatically be set to NOT NULL.
  final List<String> columns;

  /// Optional comment describing the constraint purpose.
  final String? comment;

  @override
  String toSQL() {
    final columnList = columns.join(', ');
    return 'CONSTRAINT $name PRIMARY KEY ($columnList)';
  }

  @override
  void validate() {
    super.validate();

    if (columns.isEmpty) {
      throw ArgumentError(
        'PRIMARY KEY constraint must specify at least one column',
      );
    }

    for (final column in columns) {
      if (column.trim().isEmpty) {
        throw ArgumentError('Column name cannot be empty');
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrimaryKeyConstraint &&
        other.name == name &&
        _listEquals(other.columns, columns) &&
        other.comment == comment;
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(columns), comment);

  @override
  String toString() {
    return 'PrimaryKeyConstraint(name: $name, columns: $columns)';
  }
}

/// Helper function to compare lists for equality.
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
