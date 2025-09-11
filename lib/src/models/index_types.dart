/// Defines PostgreSQL index types supported by the schema generator.
///
/// This enum provides comprehensive coverage of PostgreSQL index types with
/// detailed documentation, use cases, and performance characteristics.
library;

import 'package:meta/meta.dart';

/// Represents a PostgreSQL index type with metadata and usage recommendations.
///
/// Different index types are optimized for different types of queries and data
/// patterns. Choosing the right index type can significantly impact query
/// performance.
@immutable
enum IndexType {
  /// B-tree index (default for most data types).
  ///
  /// B-tree indexes are the most common and versatile index type. They work
  /// well for equality and range queries on sortable data types.
  ///
  /// **Best for:**
  /// - Equality comparisons (=)
  /// - Range queries (<, <=, >, >=)
  /// - BETWEEN clauses
  /// - ORDER BY clauses
  /// - NULL value searches
  ///
  /// **Performance:**
  /// - O(log n) lookup time
  /// - Efficient for both single values and ranges
  /// - Supports unique constraints
  ///
  /// **Storage:**
  /// - Moderate storage overhead
  /// - Self-balancing tree structure
  ///
  /// **Example use cases:**
  /// ```sql
  /// -- User ID lookups
  /// SELECT * FROM users WHERE id = 123;
  ///
  /// -- Date range queries
  /// SELECT * FROM orders WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';
  ///
  /// -- Sorting operations
  /// SELECT * FROM products ORDER BY price;
  /// ```
  btree('btree'),

  /// Hash index (equality comparisons only).
  ///
  /// Hash indexes are optimized for exact equality comparisons. They cannot
  /// be used for range queries or sorting operations.
  ///
  /// **Best for:**
  /// - Simple equality lookups (=)
  /// - High-frequency exact match queries
  /// - When you never need range queries
  ///
  /// **Performance:**
  /// - O(1) average lookup time for equality
  /// - Faster than B-tree for simple equality
  /// - Cannot support range queries
  ///
  /// **Storage:**
  /// - Lower storage overhead than B-tree
  /// - Fixed bucket structure
  ///
  /// **Limitations:**
  /// - No range queries
  /// - No sorting support
  /// - Cannot enforce unique constraints
  /// - Not WAL-logged (crash recovery issues)
  ///
  /// **Example use cases:**
  /// ```sql
  /// -- Exact user lookups
  /// SELECT * FROM users WHERE username = 'john_doe';
  ///
  /// -- Status checks
  /// SELECT * FROM orders WHERE status = 'completed';
  /// ```
  hash('hash'),

  /// GIN index (for JSONB, arrays, full-text search).
  ///
  /// Generalized Inverted Index (GIN) is designed for data types that contain
  /// multiple component values, such as arrays, JSONB, and full-text search.
  ///
  /// **Best for:**
  /// - JSONB queries (@>, ?, ?&, ?|)
  /// - Array operations (ANY, ALL, @>)
  /// - Full-text search
  /// - Trigram matching
  ///
  /// **Performance:**
  /// - Excellent for containment queries
  /// - Fast for complex JSON path queries
  /// - Scales well with data volume
  ///
  /// **Storage:**
  /// - Higher storage overhead
  /// - Inverted index structure
  /// - Compressed posting lists
  ///
  /// **Example use cases:**
  /// ```sql
  /// -- JSONB containment
  /// SELECT * FROM users WHERE metadata @> '{"premium": true}';
  ///
  /// -- Array membership
  /// SELECT * FROM posts WHERE tags @> ARRAY['postgresql'];
  ///
  /// -- Full-text search
  /// SELECT * FROM articles WHERE to_tsvector(content) @@ plainto_tsquery('database');
  /// ```
  gin('gin'),

  /// GiST index (for geometric data, full-text search).
  ///
  /// Generalized Search Tree (GiST) is a balanced tree structure that can
  /// be used for various data types, especially geometric and range data.
  ///
  /// **Best for:**
  /// - Geometric queries (PostGIS)
  /// - Range types and overlaps
  /// - Nearest neighbor searches
  /// - Custom data types
  ///
  /// **Performance:**
  /// - Good for range and proximity queries
  /// - Supports k-nearest neighbor
  /// - Lossy compression possible
  ///
  /// **Storage:**
  /// - Variable storage overhead
  /// - Tree structure with custom predicates
  ///
  /// **Example use cases:**
  /// ```sql
  /// -- Geometric queries
  /// SELECT * FROM locations WHERE point <-> '(0,0)'::point < 1000;
  ///
  /// -- Range overlaps
  /// SELECT * FROM bookings WHERE date_range && '[2024-01-01,2024-01-31]'::daterange;
  ///
  /// -- Nearest neighbor
  /// SELECT * FROM stores ORDER BY location <-> user_location LIMIT 5;
  /// ```
  gist('gist'),

  /// SP-GiST index (for space-partitioned data).
  ///
  /// Space-Partitioned Generalized Search Tree (SP-GiST) is designed for
  /// data that has a natural clustering or partitioning structure.
  ///
  /// **Best for:**
  /// - Non-balanced data structures
  /// - Quad-trees and k-d trees
  /// - Phone numbers, IP addresses
  /// - Text with prefix matching
  ///
  /// **Performance:**
  /// - Excellent for clustered data
  /// - Good for prefix searches
  /// - Unbalanced tree structure
  ///
  /// **Storage:**
  /// - Efficient for sparse data
  /// - Space-partitioned structure
  ///
  /// **Example use cases:**
  /// ```sql
  /// -- IP address ranges
  /// SELECT * FROM logs WHERE ip_address << inet '192.168.1.0/24';
  ///
  /// -- Text prefix matching
  /// SELECT * FROM domains WHERE name ^@ 'example';
  ///
  /// -- Phone number prefixes
  /// SELECT * FROM contacts WHERE phone ^@ '+1-555';
  /// ```
  spgist('spgist'),

  /// BRIN index (for very large tables with natural ordering).
  ///
  /// Block Range Index (BRIN) stores summary information about blocks of
  /// table pages. It's very space-efficient for large tables with natural
  /// ordering.
  ///
  /// **Best for:**
  /// - Very large tables (> 100GB)
  /// - Naturally ordered data (timestamps, IDs)
  /// - Data warehousing scenarios
  /// - Append-only tables
  ///
  /// **Performance:**
  /// - O(n) worst case, but very fast in practice
  /// - Minimal storage overhead
  /// - Good for range queries on ordered data
  ///
  /// **Storage:**
  /// - Extremely low storage overhead
  /// - Summary information only
  /// - Scales linearly with table size
  ///
  /// **Limitations:**
  /// - Requires naturally ordered data
  /// - Not suitable for random data
  /// - Limited to specific operators
  ///
  /// **Example use cases:**
  /// ```sql
  /// -- Time-series data
  /// SELECT * FROM sensor_readings
  /// WHERE timestamp BETWEEN '2024-01-01' AND '2024-01-31';
  ///
  /// -- Log files with sequential IDs
  /// SELECT * FROM audit_logs WHERE log_id > 1000000;
  ///
  /// -- Financial transactions by date
  /// SELECT * FROM transactions WHERE created_at >= NOW() - INTERVAL '1 month';
  /// ```
  brin('brin');

  /// Creates an index type with the specified SQL keyword.
  const IndexType(this.sqlKeyword);

  /// The SQL keyword used in CREATE INDEX statements.
  final String sqlKeyword;

  /// Creates an index type from a string representation.
  ///
  /// This method is case-insensitive and handles common variations.
  ///
  /// **Parameters:**
  /// - [type]: The string representation of the index type
  ///
  /// **Returns:** The corresponding [IndexType]
  ///
  /// **Throws:** [ArgumentError] if the type string is not recognized
  ///
  /// **Example:**
  /// ```dart
  /// final index1 = IndexType.fromString('btree');
  /// final index2 = IndexType.fromString('GIN');
  /// final index3 = IndexType.fromString('B-TREE');
  /// ```
  static IndexType fromString(String type) {
    final normalizedType = type.toLowerCase().replaceAll('-', '');

    return switch (normalizedType) {
      'btree' || 'b-tree' => IndexType.btree,
      'hash' => IndexType.hash,
      'gin' => IndexType.gin,
      'gist' => IndexType.gist,
      'spgist' || 'sp-gist' => IndexType.spgist,
      'brin' => IndexType.brin,
      _ => throw ArgumentError.value(
          type,
          'type',
          'Invalid index type. Valid values are: '
              'btree, hash, gin, gist, spgist, brin',
        ),
    };
  }

  /// Gets the recommended index type for different column types and query patterns.
  ///
  /// **Parameters:**
  /// - [columnType]: The SQL column type
  /// - [queryPattern]: The typical query pattern for this column
  ///
  /// **Returns:** The recommended [IndexType]
  ///
  /// **Example:**
  /// ```dart
  /// final recommendation1 = IndexType.getRecommendedType('TEXT', 'equality');
  /// // Returns hash or btree depending on use case
  ///
  /// final recommendation2 = IndexType.getRecommendedType('JSONB', 'containment');
  /// // Returns gin
  /// ```
  static IndexType getRecommendedType(String columnType, String queryPattern) {
    final normalizedType = columnType.toUpperCase();
    final normalizedPattern = queryPattern.toLowerCase();

    // JSONB and array types
    if (normalizedType.contains('JSONB') || normalizedType.contains('[]')) {
      return IndexType.gin;
    }

    // Geometric types
    if (normalizedType.contains('POINT') ||
        normalizedType.contains('POLYGON') ||
        normalizedType.contains('GEOMETRY')) {
      return IndexType.gist;
    }

    // Network types for prefix matching
    if (normalizedType == 'INET' || normalizedType == 'CIDR') {
      return normalizedPattern.contains('prefix')
          ? IndexType.spgist
          : IndexType.btree;
    }

    // Query pattern based recommendations
    return switch (normalizedPattern) {
      'equality' || 'exact' => IndexType.hash,
      'range' || 'between' || 'comparison' => IndexType.btree,
      'fulltext' || 'search' => IndexType.gin,
      'containment' || 'array' => IndexType.gin,
      'proximity' || 'nearest' => IndexType.gist,
      'prefix' || 'startswith' => IndexType.spgist,
      'timeseries' || 'ordered' => IndexType.brin,
      _ => IndexType.btree, // Safe default
    };
  }

  /// Validates if this index type supports the given operators.
  ///
  /// **Parameters:**
  /// - [operators]: List of SQL operators that will be used with this index
  ///
  /// **Returns:** True if all operators are supported
  ///
  /// **Example:**
  /// ```dart
  /// final btreeIndex = IndexType.btree;
  /// final isValid1 = btreeIndex.supportsOperators(['=', '<', '>']);
  /// // Returns true - B-tree supports all comparison operators
  ///
  /// final hashIndex = IndexType.hash;
  /// final isValid2 = hashIndex.supportsOperators(['=', '<']);
  /// // Returns false - Hash only supports equality
  /// ```
  bool supportsOperators(List<String> operators) {
    final supportedOps = getSupportedOperators();
    return operators.every(supportedOps.contains);
  }

  /// Gets the list of operators supported by this index type.
  ///
  /// **Returns:** A list of SQL operators supported by this index type
  List<String> getSupportedOperators() {
    return switch (this) {
      IndexType.btree => [
          '=',
          '<',
          '<=',
          '>',
          '>=',
          'BETWEEN',
          'IN',
          'IS NULL',
        ],
      IndexType.hash => ['=', 'IN'],
      IndexType.gin => ['@>', '<@', '?', '?&', '?|', '@@', '@@@'],
      IndexType.gist => ['<<', '&<', '&>', '>>', '<->', '&&', '~='],
      IndexType.spgist => ['<<', '^@', '~=', '<->', '&<|', '|&>'],
      IndexType.brin => ['=', '<', '<=', '>', '>=', 'BETWEEN'],
    };
  }

  /// Gets performance characteristics for this index type.
  ///
  /// **Returns:** A map of performance metrics and characteristics
  Map<String, String> getPerformanceCharacteristics() {
    return switch (this) {
      IndexType.btree => {
          'lookup_time': 'O(log n)',
          'storage_overhead': 'Moderate',
          'update_cost': 'Low',
          'best_for': 'General purpose, range queries',
          'scalability': 'Excellent',
        },
      IndexType.hash => {
          'lookup_time': 'O(1) average',
          'storage_overhead': 'Low',
          'update_cost': 'Very low',
          'best_for': 'Equality lookups only',
          'scalability': 'Good',
        },
      IndexType.gin => {
          'lookup_time': 'O(log n) + result size',
          'storage_overhead': 'High',
          'update_cost': 'High',
          'best_for': 'Complex containment queries',
          'scalability': 'Excellent for reads',
        },
      IndexType.gist => {
          'lookup_time': 'Variable, depends on data',
          'storage_overhead': 'Moderate to high',
          'update_cost': 'Moderate',
          'best_for': 'Geometric and range queries',
          'scalability': 'Good',
        },
      IndexType.spgist => {
          'lookup_time': 'Variable, depends on clustering',
          'storage_overhead': 'Low to moderate',
          'update_cost': 'Low to moderate',
          'best_for': 'Clustered data, prefix matching',
          'scalability': 'Good for clustered data',
        },
      IndexType.brin => {
          'lookup_time': 'O(n) worst case, fast in practice',
          'storage_overhead': 'Very low',
          'update_cost': 'Very low',
          'best_for': 'Large tables with natural ordering',
          'scalability': 'Excellent for storage',
        },
    };
  }

  /// Gets storage requirements and considerations for this index type.
  ///
  /// **Returns:** A list of storage-related information
  List<String> getStorageConsiderations() {
    return switch (this) {
      IndexType.btree => [
          'Balanced tree structure',
          'Moderate disk space usage',
          'Good cache locality',
          'Supports unique constraints',
        ],
      IndexType.hash => [
          'Fixed bucket structure',
          'Low disk space usage',
          'Not WAL-logged (recovery concerns)',
          'Cannot enforce uniqueness',
        ],
      IndexType.gin => [
          'Inverted index with posting lists',
          'High disk space usage initially',
          'Good compression over time',
          'Excellent for complex queries',
        ],
      IndexType.gist => [
          'Tree structure with lossy compression',
          'Variable space depending on data',
          'Good for multidimensional data',
          'Supports custom operators',
        ],
      IndexType.spgist => [
          'Space-partitioned tree',
          'Efficient for sparse data',
          'Unbalanced structure',
          'Good for naturally clustered data',
        ],
      IndexType.brin => [
          'Minimal space overhead',
          'Scales linearly with table size',
          'Summary information only',
          'Requires maintenance for optimal performance',
        ],
    };
  }

  /// Gets maintenance requirements for this index type.
  ///
  /// **Returns:** A list of maintenance considerations
  List<String> getMaintenanceRequirements() {
    return switch (this) {
      IndexType.btree => [
          'Automatic balancing',
          'Periodic VACUUM recommended',
          'REINDEX rarely needed',
        ],
      IndexType.hash => [
          'No automatic maintenance',
          'Consider rebuilding after major updates',
          'Monitor for performance degradation',
        ],
      IndexType.gin => [
          'Pending list maintenance',
          'VACUUM important for cleanup',
          'Consider gin_pending_list_limit tuning',
        ],
      IndexType.gist => [
          'Automatic tree balancing',
          'VACUUM for dead tuple cleanup',
          'May benefit from occasional REINDEX',
        ],
      IndexType.spgist => [
          'Minimal maintenance required',
          'VACUUM for cleanup',
          'Performance depends on data distribution',
        ],
      IndexType.brin => [
          'Regular VACUUM essential',
          'Consider autosummarize',
          'REINDEX for major data reorganization',
        ],
    };
  }

  /// Returns the SQL keyword for this index type.
  @override
  String toString() => sqlKeyword;
}
