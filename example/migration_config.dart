/// Migration strategies for handling existing database schemas.
enum MigrationMode {
  /// Only create new tables, throw error if table exists.
  createOnly,

  /// Create table with IF NOT EXISTS, ignore if exists.
  createIfNotExists,

  /// Create table if not exists, then alter to match current schema.
  createOrAlter,

  /// Only generate ALTER statements to modify existing schema.
  alterOnly,

  /// Drop and recreate table (destructive).
  dropAndRecreate,
}

/// Configuration for migration behavior.
class MigrationConfig {
  /// Creates a [MigrationConfig] with the given options.
  const MigrationConfig({
    this.mode = MigrationMode.createOnly,
    this.enableColumnAdding = true,
    this.enableColumnModification = true,
    this.enableColumnDropping = false,
    this.enableIndexCreation = true,
    this.enableConstraintModification = true,
    this.generateDoBlocks = true,
    this.maxColumnLength = 63, // PostgreSQL identifier limit
  });

  /// The migration strategy to use.
  final MigrationMode mode;

  /// Whether to add new columns found in Dart class.
  final bool enableColumnAdding;

  /// Whether to modify existing columns to match Dart class.
  final bool enableColumnModification;

  /// Whether to drop columns not found in Dart class (dangerous).
  final bool enableColumnDropping;

  /// Whether to create new indexes.
  final bool enableIndexCreation;

  /// Whether to modify constraints.
  final bool enableConstraintModification;

  /// Whether to wrap ALTER statements in DO blocks for conditional execution.
  final bool generateDoBlocks;

  /// Maximum length for PostgreSQL identifiers.
  final int maxColumnLength;

  /// Whether this mode requires existing table detection.
  bool get requiresTableDetection =>
      mode == MigrationMode.createOrAlter || mode == MigrationMode.alterOnly;

  /// Whether this mode generates CREATE TABLE statements.
  bool get generatesCreateTable =>
      mode == MigrationMode.createOnly ||
      mode == MigrationMode.createIfNotExists ||
      mode == MigrationMode.createOrAlter ||
      mode == MigrationMode.dropAndRecreate;

  /// Whether this mode generates ALTER TABLE statements.
  bool get generatesAlterTable =>
      mode == MigrationMode.createOrAlter || mode == MigrationMode.alterOnly;
}
