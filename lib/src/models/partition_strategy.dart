/// Partition strategy definitions for database table partitioning.
///
/// This file contains classes representing PostgreSQL table partitioning
/// strategies for improved performance with large datasets.
library;

import 'package:meta/meta.dart';

/// Base class for table partitioning strategies.
///
/// PostgreSQL supports several partitioning methods to improve performance
/// and management of large tables.
@immutable
abstract class PartitionStrategy {
  /// Creates a partition strategy.
  const PartitionStrategy();

  /// Generates the SQL partition clause for table creation.
  String toSQL();

  /// Validates that this partition strategy is properly configured.
  void validate();
}

/// Range partitioning strategy.
///
/// Tables are partitioned based on a range of values for specified columns.
/// This is useful for time-series data or other naturally ordered data.
///
/// **Example:**
/// ```dart
/// RangePartition(
///   columns: ['created_date'],
/// )
/// ```
@immutable
class RangePartition extends PartitionStrategy {
  /// Creates a range partition strategy.
  ///
  /// [columns] specifies the columns to partition by.
  const RangePartition({
    required this.columns,
  });

  /// The columns to partition by.
  ///
  /// Range partitioning works best with date/time columns or other
  /// naturally ordered data types.
  final List<String> columns;

  @override
  String toSQL() {
    final columnList = columns.join(', ');
    return 'PARTITION BY RANGE ($columnList)';
  }

  @override
  void validate() {
    if (columns.isEmpty) {
      throw ArgumentError('Range partition must specify at least one column');
    }

    for (final column in columns) {
      if (column.trim().isEmpty) {
        throw ArgumentError('Partition column name cannot be empty');
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangePartition && _listEquals(other.columns, columns);
  }

  @override
  int get hashCode => Object.hashAll(columns);

  @override
  String toString() {
    return 'RangePartition(columns: $columns)';
  }
}

/// List partitioning strategy.
///
/// Tables are partitioned based on specific values in specified columns.
/// Each partition contains rows matching specific values.
///
/// **Example:**
/// ```dart
/// ListPartition(
///   columns: ['region'],
/// )
/// ```
@immutable
class ListPartition extends PartitionStrategy {
  /// Creates a list partition strategy.
  ///
  /// [columns] specifies the columns to partition by.
  const ListPartition({
    required this.columns,
  });

  /// The columns to partition by.
  ///
  /// List partitioning works well with categorical data that has
  /// a limited number of distinct values.
  final List<String> columns;

  @override
  String toSQL() {
    final columnList = columns.join(', ');
    return 'PARTITION BY LIST ($columnList)';
  }

  @override
  void validate() {
    if (columns.isEmpty) {
      throw ArgumentError('List partition must specify at least one column');
    }

    for (final column in columns) {
      if (column.trim().isEmpty) {
        throw ArgumentError('Partition column name cannot be empty');
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListPartition && _listEquals(other.columns, columns);
  }

  @override
  int get hashCode => Object.hashAll(columns);

  @override
  String toString() {
    return 'ListPartition(columns: $columns)';
  }
}

/// Hash partitioning strategy.
///
/// Tables are partitioned using a hash function on specified columns.
/// This provides even distribution of data across partitions.
///
/// **Example:**
/// ```dart
/// HashPartition(
///   columns: ['user_id'],
/// )
/// ```
@immutable
class HashPartition extends PartitionStrategy {
  /// Creates a hash partition strategy.
  ///
  /// [columns] specifies the columns to partition by.
  const HashPartition({
    required this.columns,
  });

  /// The columns to partition by.
  ///
  /// Hash partitioning provides even distribution but doesn't support
  /// range queries as efficiently as range partitioning.
  final List<String> columns;

  @override
  String toSQL() {
    final columnList = columns.join(', ');
    return 'PARTITION BY HASH ($columnList)';
  }

  @override
  void validate() {
    if (columns.isEmpty) {
      throw ArgumentError('Hash partition must specify at least one column');
    }

    for (final column in columns) {
      if (column.trim().isEmpty) {
        throw ArgumentError('Partition column name cannot be empty');
      }
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HashPartition && _listEquals(other.columns, columns);
  }

  @override
  int get hashCode => Object.hashAll(columns);

  @override
  String toString() {
    return 'HashPartition(columns: $columns)';
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
