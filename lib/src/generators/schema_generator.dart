/// Main code generator for creating PostgreSQL schemas from annotated Dart classes.
///
/// This generator processes classes annotated with DatabaseTable and generates
/// comprehensive SQL DDL statements, including tables, indexes, foreign keys,
/// and RLS policies.
library;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:supabase_annotations/src/models/migration_config.dart';
import 'package:supabase_annotations/supabase_annotations.dart';

/// Configuration for the schema generator.
class SchemaGeneratorConfig {
  /// Creates a new schema generator configuration.
  const SchemaGeneratorConfig({
    this.formatSql = true,
    this.enableRlsByDefault = false,
    this.addTimestamps = false,
    this.useExplicitNullability = false,
    this.generateComments = true,
    this.validateSchema = true,
    this.migrationConfig = const MigrationConfig(),
  });

  /// Creates a new configuration from build options.
  factory SchemaGeneratorConfig.fromOptions(Map<String, dynamic> options) {
    // Parse migration mode
    final migrationModeStr =
        options['migration_mode'] as String? ?? 'createOnly';
    final migrationMode = MigrationMode.values.firstWhere(
      (e) => e.toString().split('.').last == migrationModeStr,
      orElse: () => MigrationMode.createOnly,
    );

    return SchemaGeneratorConfig(
      formatSql: options['format_sql'] as bool? ?? true,
      enableRlsByDefault: options['enable_rls_by_default'] as bool? ?? false,
      addTimestamps: options['add_timestamps'] as bool? ?? false,
      useExplicitNullability:
          options['use_explicit_nullability'] as bool? ?? false,
      generateComments: options['generate_comments'] as bool? ?? true,
      validateSchema: options['validate_schema'] as bool? ?? true,
      migrationConfig: MigrationConfig(
        mode: migrationMode,
        enableColumnAdding: options['enable_column_adding'] as bool? ?? true,
        enableColumnModification:
            options['enable_column_modification'] as bool? ?? true,
        enableColumnDropping:
            options['enable_column_dropping'] as bool? ?? false,
        enableIndexCreation: options['enable_index_creation'] as bool? ?? true,
        enableConstraintModification:
            options['enable_constraint_modification'] as bool? ?? true,
        generateDoBlocks: options['generate_do_blocks'] as bool? ?? true,
      ),
    );
  }

  /// Whether to format generated SQL for readability.
  final bool formatSql;

  /// Whether to enable Row Level Security by default on all tables.
  final bool enableRlsByDefault;

  /// Whether to automatically add created_at and updated_at timestamp columns.
  final bool addTimestamps;

  /// Whether to use explicit nullability in generated SQL.
  final bool useExplicitNullability;

  /// Whether to generate comments in SQL output.
  final bool generateComments;

  /// Whether to validate schema consistency and constraints.
  final bool validateSchema;

  /// Migration configuration for handling existing schemas.
  final MigrationConfig migrationConfig;

  /// Whether comments should be included (unified property).
  bool get shouldIncludeComments => generateComments;
}

/// Code generator for Supabase/PostgreSQL database schemas.
///
/// This generator processes Dart classes annotated with [DatabaseTable]
/// and creates comprehensive SQL DDL files including:
///
/// - Table creation statements
/// - Column definitions with constraints
/// - Index creation statements
/// - Foreign key constraints
/// - RLS policies and security rules
/// - Migration files for schema evolution
///
/// **Example Usage:**
/// ```dart
/// @DatabaseTable(name: 'users', enableRLS: true)
/// @RLSPolicy(
///   name: 'user_access_own_data',
///   type: RLSPolicyType.all,
///   condition: 'auth.uid() = id',
/// )
/// class User {
///   @DatabaseColumn(type: ColumnType.uuid, isPrimaryKey: true)
///   String? id;
///
///   @DatabaseColumn(type: ColumnType.text, isUnique: true)
///   String email;
/// }
/// ```
///
/// Generates:
/// ```sql
/// CREATE TABLE users (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   email TEXT UNIQUE NOT NULL
/// );
///
/// ALTER TABLE users ENABLE ROW LEVEL SECURITY;
///
/// CREATE POLICY user_access_own_data ON users
/// FOR ALL USING (auth.uid() = id);
/// ```
class SupabaseSchemaGenerator extends GeneratorForAnnotation<DatabaseTable> {
  /// Creates a new schema generator with the specified configuration.
  SupabaseSchemaGenerator([this.config = const SchemaGeneratorConfig()]);

  /// Configuration for the generator.
  final SchemaGeneratorConfig config;

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // Validate that the element is a class
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'DatabaseTable can only be applied to classes.',
        element: element,
      );
    }

    try {
      // Parse the table annotation
      final tableConfig = _parseTableAnnotation(annotation);

      // Extract class information
      final className = element.name;
      final tableName = tableConfig.name ?? _toSnakeCase(className);

      // Process fields and annotations
      final fields = _processFields(element);
      final indexes = _processIndexes(element);
      final policies = _processPolicies(element);
      final foreignKeys = _processForeignKeys(element, fields);

      // Validate schema if configured
      if (config.validateSchema) {
        _validateSchema(tableName, fields, indexes, policies, foreignKeys);
      }

      // Generate SQL components
      // 1. Create table statement
      final sqlComponents = <String>[
        _generateCreateTableSql(
          tableName,
          fields,
          tableConfig,
        ),
      ];

      // 2. Create indexes
      for (final index in indexes) {
        sqlComponents.add(index.generateSql(tableName));
      }

      // 3. Add foreign key constraints
      for (final field in fields) {
        if (field.foreignKey != null) {
          final fieldName = field.field.name;
          final columnName =
              field.annotation?.getEffectiveName(fieldName) ?? fieldName;
          sqlComponents
              .add(field.foreignKey!.generateSql(tableName, columnName));
        }
      }

      // 4. Enable RLS if configured
      if (tableConfig.enableRLS) {
        sqlComponents.add('ALTER TABLE $tableName ENABLE ROW LEVEL SECURITY;');
      }

      // 5. Create RLS policies
      for (final policy in policies) {
        sqlComponents.add(policy.generateSql(tableName));

        if (config.shouldIncludeComments) {
          final commentSql = policy.generateCommentSql(tableName);
          if (commentSql != null) {
            sqlComponents.add(commentSql);
          }
        }
      }

      // 6. Table comment
      if (config.shouldIncludeComments && tableConfig.comment != null) {
        sqlComponents
            .add(_generateTableCommentSql(tableName, tableConfig.comment!));
      }

      // Join all SQL components
      final sql = sqlComponents.where((s) => s.isNotEmpty).join('\n\n');

      // Format SQL if requested
      final formattedSql = config.formatSql ? _formatSql(sql) : sql;

      return formattedSql;
    } catch (e) {
      throw InvalidGenerationSourceError(
        'Error generating schema for ${element.name}: $e',
        element: element,
      );
    }
  }

  /// Parses the DatabaseTable annotation.
  DatabaseTable _parseTableAnnotation(ConstantReader annotation) {
    // Parse partition strategy if provided
    PartitionStrategy? partitionStrategy;
    final partitionReader = annotation.peek('partitionBy');
    if (partitionReader != null && !partitionReader.isNull) {
      partitionStrategy = _parsePartitionStrategy(partitionReader);
    }

    return DatabaseTable(
      name: annotation.peek('name')?.stringValue,
      comment: annotation.peek('comment')?.stringValue,
      enableRLS:
          annotation.peek('enableRLS')?.boolValue ?? config.enableRlsByDefault,
      partitionBy: partitionStrategy,
      // Note: Only using properties that exist in our DatabaseTable annotation
    );
  }

  /// Processes all fields in the class to extract column information.
  List<_ColumnInfo> _processFields(ClassElement classElement) {
    final columns = <_ColumnInfo>[];

    for (final field in classElement.fields) {
      // Skip static and synthetic fields
      if (field.isStatic || field.isSynthetic) continue;

      // Look for DatabaseColumn annotation
      final columnAnnotation = _getColumnAnnotation(field);
      final foreignKeyAnnotation = _getForeignKeyAnnotation(field);

      // Get column information
      final columnInfo = _ColumnInfo(
        field: field,
        annotation: columnAnnotation,
        foreignKey: foreignKeyAnnotation,
      );

      columns.add(columnInfo);
    } // Add automatic timestamp columns if configured
    if (config.addTimestamps) {
      // Check if created_at and updated_at columns already exist
      final existingColumnNames = columns
          .map(
            (c) =>
                c.annotation?.getEffectiveName(c.field.name) ?? (c.field.name),
          )
          .toSet();

      if (!existingColumnNames.contains('created_at')) {
        columns.add(
          _ColumnInfo(
            field: _createSyntheticField('created_at'),
            annotation: const DatabaseColumn(
              name: 'created_at',
              type: ColumnType.timestampWithTimeZone,
              defaultValue: DefaultValue.currentTimestamp,
              isNullable: false,
            ),
          ),
        );
      }

      if (!existingColumnNames.contains('updated_at')) {
        columns.add(
          _ColumnInfo(
            field: _createSyntheticField('updated_at'),
            annotation: const DatabaseColumn(
              name: 'updated_at',
              type: ColumnType.timestampWithTimeZone,
              defaultValue: DefaultValue.currentTimestamp,
              isNullable: false,
            ),
          ),
        );
      }
    }

    return columns;
  }

  /// Gets the DatabaseColumn annotation for a field.
  DatabaseColumn? _getColumnAnnotation(FieldElement field) {
    for (final annotation in field.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue?.type?.element?.name == 'DatabaseColumn') {
        return _parseDatabaseColumnAnnotation(
          ConstantReader(annotationValue),
        );
      }
    }
    return null;
  }

  /// Gets the ForeignKey annotation for a field.
  ForeignKey? _getForeignKeyAnnotation(FieldElement field) {
    for (final annotation in field.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue?.type?.element?.name == 'ForeignKey') {
        return _parseForeignKeyAnnotation(
          ConstantReader(annotationValue),
        );
      }
    }
    return null;
  }

  /// Parses a DatabaseColumn annotation.
  DatabaseColumn _parseDatabaseColumnAnnotation(ConstantReader annotation) {
    final type = _parseColumnType(annotation.peek('type'));

    return DatabaseColumn(
      name: annotation.peek('name')?.stringValue,
      type: type,
      isNullable: annotation.peek('isNullable')?.boolValue ?? true,
      isPrimaryKey: annotation.peek('isPrimaryKey')?.boolValue ?? false,
      isUnique: annotation.peek('isUnique')?.boolValue ?? false,
      defaultValue: _parseDefaultValue(annotation.peek('defaultValue')),
      comment: annotation.peek('comment')?.stringValue,
      checkConstraints: [
        // Existing check constraints
        ...annotation
                .peek('checkConstraints')
                ?.listValue
                .map(
                  (v) => v.toStringValue() ?? '',
                )
                .toList() ??
            <String>[],
        // Validator-generated check constraints
        ..._generateValidatorConstraints(
          annotation.peek('validators'),
          annotation.peek('name')?.stringValue ?? 'column',
        ),
      ],
      autoIncrement: annotation.peek('autoIncrement')?.boolValue ?? false,
      length: annotation.peek('length')?.intValue,
      precision: annotation.peek('precision')?.intValue,
      scale: annotation.peek('scale')?.intValue,
      collation: annotation.peek('collation')?.stringValue,
      isIndexed: annotation.peek('isIndexed')?.boolValue ?? false,
      storageType: annotation.peek('storageType')?.stringValue,
    );
  }

  /// Parses a ForeignKey annotation.
  ForeignKey _parseForeignKeyAnnotation(ConstantReader annotation) {
    return ForeignKey(
      name: annotation.peek('name')?.stringValue,
      table: annotation.peek('table')?.stringValue,
      column: annotation.peek('column')?.stringValue,
      localColumns: annotation
              .peek('localColumns')
              ?.listValue
              .map(
                (v) => v.toStringValue() ?? '',
              )
              .toList() ??
          <String>[],
      foreignTable: annotation.peek('foreignTable')?.stringValue,
      foreignColumns: annotation
              .peek('foreignColumns')
              ?.listValue
              .map(
                (v) => v.toStringValue() ?? '',
              )
              .toList() ??
          <String>[],
      onDelete: _parseForeignKeyAction(annotation.peek('onDelete')) ??
          ForeignKeyAction.noAction,
      onUpdate: _parseForeignKeyAction(annotation.peek('onUpdate')) ??
          ForeignKeyAction.noAction,
      deferrable: annotation.peek('deferrable')?.boolValue ?? false,
      initiallyDeferred:
          annotation.peek('initiallyDeferred')?.boolValue ?? false,
      comment: annotation.peek('comment')?.stringValue,
      validate: annotation.peek('validate')?.boolValue ?? true,
    );
  }

  /// Parses a ColumnType from annotation.
  ColumnType? _parseColumnType(ConstantReader? typeReader) {
    if (typeReader == null) return null;

    final typeValue = typeReader.objectValue;
    final sqlType = typeValue.getField('sqlType')?.toStringValue();

    if (sqlType == null) return null;

    // Map SQL type back to ColumnType
    return switch (sqlType) {
      'TEXT' => ColumnType.text,
      'UUID' => ColumnType.uuid,
      'INTEGER' => ColumnType.integer,
      'BIGINT' => ColumnType.bigint,
      'SMALLINT' => ColumnType.smallint,
      'BOOLEAN' => ColumnType.boolean,
      'TIMESTAMP WITH TIME ZONE' => ColumnType.timestampWithTimeZone,
      'TIMESTAMP' => ColumnType.timestamp,
      'DATE' => ColumnType.date,
      'TIME' => ColumnType.time,
      'REAL' => ColumnType.real,
      'DOUBLE PRECISION' => ColumnType.doublePrecision,
      'SERIAL' => ColumnType.serial,
      'BIGSERIAL' => ColumnType.bigserial,
      'JSONB' => ColumnType.jsonb,
      'JSON' => ColumnType.json,
      'BYTEA' => ColumnType.bytea,
      String() when sqlType.startsWith('VARCHAR') => ColumnType.varchar(),
      String() when sqlType.startsWith('CHAR') => ColumnType.char(1),
      String() when sqlType.startsWith('DECIMAL') => ColumnType.decimal(),
      String() when sqlType.startsWith('NUMERIC') => ColumnType.decimal(),
      _ => ColumnType.text, // Default fallback
    };
  }

  /// Parses a DefaultValue from annotation.
  DefaultValue? _parseDefaultValue(ConstantReader? defaultReader) {
    if (defaultReader == null) return null;

    final defaultValue = defaultReader.objectValue;
    final expression = defaultValue.getField('sqlExpression')?.toStringValue();

    if (expression != null) {
      // Create a basic DefaultValue - since we don't have raw() method
      return DefaultValue.string(expression); // Use string as a fallback
    }

    return null;
  }

  /// Parses a ForeignKeyAction from annotation.
  ForeignKeyAction? _parseForeignKeyAction(ConstantReader? actionReader) {
    if (actionReader == null) return null;

    final actionValue = actionReader.objectValue;
    final actionName = actionValue.getField('name')?.toStringValue();

    return switch (actionName) {
      'noAction' => ForeignKeyAction.noAction,
      'restrict' => ForeignKeyAction.restrict,
      'cascade' => ForeignKeyAction.cascade,
      'setNull' => ForeignKeyAction.setNull,
      'setDefault' => ForeignKeyAction.setDefault,
      _ => null,
    };
  }

  /// Processes DatabaseIndex annotations on the class.
  List<DatabaseIndex> _processIndexes(ClassElement classElement) {
    final indexes = <DatabaseIndex>[];

    for (final annotation in classElement.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue?.type?.element?.name == 'DatabaseIndex') {
        final indexAnnotation = _parseDatabaseIndexAnnotation(
          ConstantReader(annotationValue),
        );
        indexes.add(indexAnnotation);
      }
    }

    return indexes;
  }

  /// Parses a DatabaseIndex annotation.
  DatabaseIndex _parseDatabaseIndexAnnotation(ConstantReader annotation) {
    return DatabaseIndex(
      name: annotation.peek('name')?.stringValue,
      columns: annotation
              .peek('columns')
              ?.listValue
              .map(
                (v) => v.toStringValue() ?? '',
              )
              .toList() ??
          <String>[],
      type: _parseIndexType(annotation.peek('type')) ?? IndexType.btree,
      isUnique: annotation.peek('isUnique')?.boolValue ?? false,
      condition: annotation.peek('condition')?.stringValue,
      expression: annotation.peek('expression')?.stringValue,
      includes: annotation
              .peek('includes')
              ?.listValue
              .map(
                (v) => v.toStringValue() ?? '',
              )
              .toList() ??
          <String>[],
      tablespace: annotation.peek('tablespace')?.stringValue,
      comment: annotation.peek('comment')?.stringValue,
      storageParameters: annotation.peek('storageParameters')?.mapValue.map(
                (key, value) => MapEntry(
                  key?.toStringValue() ?? '',
                  value?.toStringValue() ?? '',
                ),
              ) ??
          <String, String>{},
      isConcurrent: annotation.peek('isConcurrent')?.boolValue ?? false,
      isDescending: annotation.peek('isDescending')?.boolValue ?? false,
      nullsFirst: annotation.peek('nullsFirst')?.boolValue,
      opClass: annotation.peek('opClass')?.stringValue,
      fillFactor: annotation.peek('fillFactor')?.intValue,
    );
  }

  /// Parses an IndexType from annotation.
  IndexType? _parseIndexType(ConstantReader? typeReader) {
    if (typeReader == null) return null;

    final typeValue = typeReader.objectValue;
    final typeName = typeValue.getField('name')?.toStringValue();

    return switch (typeName) {
      'btree' => IndexType.btree,
      'hash' => IndexType.hash,
      'gin' => IndexType.gin,
      'gist' => IndexType.gist,
      'spgist' => IndexType.spgist,
      'brin' => IndexType.brin,
      _ => null,
    };
  }

  /// Processes RLS policies on the class.
  List<RLSPolicy> _processPolicies(ClassElement classElement) {
    final policies = <RLSPolicy>[];

    for (final annotation in classElement.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue?.type?.element?.name == 'RLSPolicy') {
        final policyAnnotation = _parseRLSPolicyAnnotation(
          ConstantReader(annotationValue),
        );
        policies.add(policyAnnotation);
      }
    }

    return policies;
  }

  /// Parses an RLS Policy annotation.
  RLSPolicy _parseRLSPolicyAnnotation(ConstantReader annotation) {
    final typeReader = annotation.peek('type');
    if (typeReader == null) {
      throw InvalidGenerationSourceError(
        'RLSPolicy annotation must specify a type parameter.',
      );
    }

    final policyType = _parseRLSPolicyType(typeReader);
    if (policyType == null) {
      throw InvalidGenerationSourceError(
        'Invalid RLS policy type in annotation.',
      );
    }

    return RLSPolicy(
      name: annotation.read('name').stringValue,
      type: policyType,
      roles: annotation
              .peek('roles')
              ?.listValue
              .map(
                (v) => v.toStringValue() ?? '',
              )
              .toList() ??
          <String>[],
      condition: annotation.read('condition').stringValue,
      checkCondition: annotation.peek('checkCondition')?.stringValue,
      comment: annotation.peek('comment')?.stringValue,
      isPermissive: annotation.peek('isPermissive')?.boolValue ?? true,
    );
  }

  /// Parses an RLSPolicyType from annotation.
  RLSPolicyType? _parseRLSPolicyType(ConstantReader typeReader) {
    try {
      final typeValue = typeReader.objectValue;

      // Try to get the enum value directly first
      if (typeValue.type?.element?.name == 'RLSPolicyType') {
        final index = typeValue.getField('index')?.toIntValue();
        if (index != null) {
          return RLSPolicyType.values[index];
        }
      }

      // Fallback to string-based parsing
      final typeName = typeValue.getField('name')?.toStringValue() ??
          typeValue.getField('_name')?.toStringValue();

      return switch (typeName) {
        'all' => RLSPolicyType.all,
        'select' => RLSPolicyType.select,
        'insert' => RLSPolicyType.insert,
        'update' => RLSPolicyType.update,
        'delete' => RLSPolicyType.delete,
        _ => null,
      };
    } on Exception {
      return null;
    }
  }

  /// Processes foreign keys from field annotations.
  List<ForeignKey> _processForeignKeys(
    ClassElement classElement,
    List<_ColumnInfo> fields,
  ) {
    final foreignKeys = <ForeignKey>[];

    // Add foreign keys from field annotations
    for (final field in fields) {
      if (field.foreignKey != null) {
        foreignKeys.add(field.foreignKey!);
      }
    }

    // Add composite foreign keys from class annotations
    for (final annotation in classElement.metadata) {
      final annotationValue = annotation.computeConstantValue();
      if (annotationValue?.type?.element?.name == 'ForeignKey') {
        final foreignKeyAnnotation = _parseForeignKeyAnnotation(
          ConstantReader(annotationValue),
        );
        if (foreignKeyAnnotation.isComposite) {
          foreignKeys.add(foreignKeyAnnotation);
        }
      }
    }

    return foreignKeys;
  }

  /// Generates the CREATE TABLE SQL statement.
  String _generateCreateTableSql(
    String tableName,
    List<_ColumnInfo> fields,
    DatabaseTable tableConfig,
  ) {
    final migrationMode = config.migrationConfig.mode;

    // Handle different migration modes
    switch (migrationMode) {
      case MigrationMode.createOnly:
        return _generateBasicCreateTable(tableName, fields, tableConfig);

      case MigrationMode.createIfNotExists:
        return _generateCreateTableIfNotExists(tableName, fields, tableConfig);

      case MigrationMode.createOrAlter:
        return _generateCreateOrAlterTable(tableName, fields, tableConfig);

      case MigrationMode.alterOnly:
        return _generateAlterTableOnly(tableName, fields, tableConfig);

      case MigrationMode.dropAndRecreate:
        return _generateDropAndRecreateTable(tableName, fields, tableConfig);
    }
  }

  /// Generates a basic CREATE TABLE statement (original behavior).
  String _generateBasicCreateTable(
    String tableName,
    List<_ColumnInfo> fields,
    DatabaseTable tableConfig,
  ) {
    final lines = <String>['CREATE TABLE $tableName ('];

    final columnDefinitions = <String>[];
    final primaryKeyColumns = <String>[];

    // First pass: collect primary key columns
    for (final field in fields) {
      final annotation = field.annotation ?? const DatabaseColumn();
      if (annotation.isPrimaryKey) {
        final fieldName = field.field.name;
        final columnName = annotation.getEffectiveName(fieldName);
        primaryKeyColumns.add(columnName);
      }
    }

    // Add partition key columns to primary key if table is partitioned
    // This is required by PostgreSQL for unique constraints on partitioned tables
    if (tableConfig.partitionBy != null) {
      final partitionColumns = _getPartitionColumns(tableConfig.partitionBy!);
      for (final partitionColumn in partitionColumns) {
        if (!primaryKeyColumns.contains(partitionColumn)) {
          primaryKeyColumns.add(partitionColumn);
        }
      }
    }

    final hasCompositeKey = primaryKeyColumns.length > 1;

    // Second pass: generate column definitions
    for (final field in fields) {
      final fieldName = field.field.name;
      final annotation = field.annotation ?? const DatabaseColumn();

      // Get effective column name
      final columnName = annotation.getEffectiveName(fieldName);

      // Build column definition
      final columnDef = <String>['  $columnName', annotation.getFullSqlType()];

      // Add constraints with configuration (skip PRIMARY KEY for composite keys)
      final constraints = _getColumnConstraints(annotation, hasCompositeKey);
      columnDef.addAll(constraints);

      columnDefinitions.add(columnDef.join(' '));
    }

    // Add column definitions with proper comma separation
    for (var i = 0; i < columnDefinitions.length; i++) {
      final isLast = i == columnDefinitions.length - 1;
      final needsComma = !isLast || hasCompositeKey;

      lines.add(columnDefinitions[i] + (needsComma ? ',' : ''));
    }

    // Add composite primary key if multiple columns
    if (hasCompositeKey) {
      lines.add('  PRIMARY KEY (${primaryKeyColumns.join(', ')})');
    }

    lines.add(')');

    // Add partition clause if specified
    if (tableConfig.partitionBy != null) {
      try {
        tableConfig.partitionBy!.validate();
        lines.add(tableConfig.partitionBy!.toSQL());
      } on Exception catch (e) {
        throw StateError(
            'Invalid partition configuration for table "$tableName": $e');
      }
    }

    lines.add(';');

    return lines.join('\n');
  }

  /// Generates CREATE TABLE IF NOT EXISTS statement.
  String _generateCreateTableIfNotExists(
    String tableName,
    List<_ColumnInfo> fields,
    DatabaseTable tableConfig,
  ) {
    final basicCreate =
        _generateBasicCreateTable(tableName, fields, tableConfig);
    return basicCreate.replaceFirst(
        'CREATE TABLE', 'CREATE TABLE IF NOT EXISTS');
  }

  /// Generates CREATE TABLE IF NOT EXISTS followed by ALTER statements.
  String _generateCreateOrAlterTable(
    String tableName,
    List<_ColumnInfo> fields,
    DatabaseTable tableConfig,
  ) {
    final statements = <String>[];

    // First create table if not exists
    statements
        .add(_generateCreateTableIfNotExists(tableName, fields, tableConfig));

    // Then generate ALTER statements for each column
    if (config.migrationConfig.enableColumnAdding) {
      statements.add(_generateAlterTableAddColumns(tableName, fields));
    }

    return statements.where((s) => s.isNotEmpty).join('\n\n');
  }

  /// Generates only ALTER TABLE statements.
  String _generateAlterTableOnly(
    String tableName,
    List<_ColumnInfo> fields,
    DatabaseTable tableConfig,
  ) {
    final statements = <String>[];

    if (config.migrationConfig.enableColumnAdding) {
      statements.add(_generateAlterTableAddColumns(tableName, fields));
    }

    return statements.where((s) => s.isNotEmpty).join('\n\n');
  }

  /// Generates DROP and CREATE TABLE statements.
  String _generateDropAndRecreateTable(
    String tableName,
    List<_ColumnInfo> fields,
    DatabaseTable tableConfig,
  ) {
    final statements = <String>[];

    statements.add('DROP TABLE IF EXISTS $tableName CASCADE;');
    statements.add(_generateBasicCreateTable(tableName, fields, tableConfig));

    return statements.join('\n\n');
  }

  /// Generates ALTER TABLE statements to add columns conditionally.
  String _generateAlterTableAddColumns(
    String tableName,
    List<_ColumnInfo> fields,
  ) {
    if (!config.migrationConfig.generateDoBlocks) {
      // Simple ALTER TABLE ADD COLUMN IF NOT EXISTS statements
      final statements = <String>[];

      for (final field in fields) {
        final fieldName = field.field.name;
        final annotation = field.annotation ?? const DatabaseColumn();
        final columnName = annotation.getEffectiveName(fieldName);
        final sqlType = annotation.getFullSqlType();
        // Skip PRIMARY KEY constraints for ALTER TABLE - they need to be handled separately
        final constraints = _getColumnConstraints(annotation, false, true);

        final constraintStr =
            constraints.isNotEmpty ? ' ${constraints.join(' ')}' : '';
        statements.add(
            'ALTER TABLE $tableName ADD COLUMN IF NOT EXISTS $columnName $sqlType$constraintStr;');
      }

      return statements.join('\n');
    }

    // Generate DO block for conditional column addition
    final lines = <String>[];
    lines.add(r'DO $$');
    lines.add('BEGIN');

    for (final field in fields) {
      final fieldName = field.field.name;
      final annotation = field.annotation ?? const DatabaseColumn();
      final columnName = annotation.getEffectiveName(fieldName);
      final sqlType = annotation.getFullSqlType();
      // Skip PRIMARY KEY constraints for ALTER TABLE - they need to be handled separately
      final constraints = _getColumnConstraints(annotation, false, true);

      final constraintStr =
          constraints.isNotEmpty ? ' ${constraints.join(' ')}' : '';

      lines.add('  IF NOT EXISTS (');
      lines.add('    SELECT 1 FROM information_schema.columns');
      lines.add(
          "    WHERE table_name = '$tableName' AND column_name = '$columnName'");
      lines.add('  ) THEN');
      lines.add(
          '    ALTER TABLE $tableName ADD COLUMN $columnName $sqlType$constraintStr;');
      lines.add('  END IF;');
      lines.add('');
    }

    lines.add(r'END $$;');

    return lines.join('\n');
  }

  /// Generates a table comment SQL statement.
  String _generateTableCommentSql(String tableName, String comment) {
    final escapedComment = comment.replaceAll("'", "''");
    return "COMMENT ON TABLE $tableName IS '$escapedComment';";
  }

  /// Converts camelCase to snake_case.
  String _toSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(
          RegExp('([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp('^_'), '');
  }

  /// Formats SQL for better readability.
  String _formatSql(String sql) {
    // Basic SQL formatting with proper line breaks
    return sql
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(';', ';\n') // Add line breaks after statements
        .replaceAll('CREATE TABLE', '\nCREATE TABLE')
        .replaceAll('CREATE INDEX', '\nCREATE INDEX')
        .replaceAll('ALTER TABLE', '\nALTER TABLE')
        .replaceAll('COMMENT ON', '\nCOMMENT ON')
        .replaceAll(
            'PARTITION BY', '\nPARTITION BY') // Add partition formatting
        .replaceAll(RegExp(r'^\s+'), '') // Remove leading whitespace
        .replaceAll(
            RegExp(r'\n\s*\n'), '\n\n') // Normalize multiple line breaks
        .trim();
  }

  /// Parses validators from annotation list.
  List<Validator>? _parseValidators(ConstantReader? validatorsReader) {
    if (validatorsReader == null) return null;

    final validatorsList = validatorsReader.listValue;
    if (validatorsList.isEmpty) return <Validator>[];

    // For now, we'll return an empty list since we can't easily instantiate
    // validators from compile-time constants. In practice, this would require
    // a more sophisticated approach using analyzer metadata.
    // IMPLEMENTATION NOTE: Validator parsing from annotations requires
    // runtime analysis of const expressions which is complex in build_runner.
    // Future versions could implement this using source_gen's analyzer APIs.
    return <Validator>[];
  }

  /// Generates CHECK constraint strings from validators.
  List<String> _generateValidatorConstraints(
    ConstantReader? validatorsReader,
    String columnName,
  ) {
    if (validatorsReader == null) return <String>[];

    final validators = _parseValidators(validatorsReader);
    if (validators == null || validators.isEmpty) return <String>[];

    // Generate SQL expressions from validators
    return validators
        .map((validator) => validator.toSqlExpression(columnName))
        .toList();
  }

  /// Creates a synthetic field element for timestamp columns.
  FieldElement _createSyntheticField(String name) {
    // Return a minimal field element - this is used for synthetic timestamp columns
    // In practice, we only need the name since we provide the full annotation
    return _SyntheticFieldElement(name);
  }

  /// Validates the schema configuration and constraints.
  void _validateSchema(
    String tableName,
    List<_ColumnInfo> fields,
    List<DatabaseIndex> indexes,
    List<RLSPolicy> policies,
    List<ForeignKey> foreignKeys,
  ) {
    // Validate primary key exists
    final primaryKeyColumns =
        fields.where((f) => f.annotation?.isPrimaryKey ?? false).toList();

    if (primaryKeyColumns.isEmpty) {
      // Warning: No primary key defined
      // In a real implementation, you might want to log this or throw an error
    }

    // Validate foreign key references
    for (final fk in foreignKeys) {
      if ((fk.table == null || fk.table!.isEmpty) ||
          (fk.column == null || fk.column!.isEmpty)) {
        throw InvalidGenerationSourceError(
          'Foreign key in table $tableName has invalid table or column reference',
        );
      }
    }

    // Validate index columns exist
    for (final index in indexes) {
      final fieldNames = fields.map((f) => f.field.name).toSet();
      final columnNames = fields
          .map((f) =>
              f.annotation?.getEffectiveName(f.field.name) ?? f.field.name)
          .toSet();

      for (final columnName in index.columns) {
        if (!fieldNames.contains(columnName) &&
            !columnNames.contains(columnName)) {
          throw InvalidGenerationSourceError(
            'Index ${index.name} references '
            'non-existent column: $columnName in table $tableName',
          );
        }
      }
    }

    // Validate RLS policies have valid conditions
    for (final policy in policies) {
      if (policy.condition.trim().isEmpty) {
        throw InvalidGenerationSourceError(
          'RLS Policy ${policy.name} has empty condition in table $tableName',
        );
      }
    }
  }

  /// Gets column constraints with configuration-aware nullability handling.
  List<String> _getColumnConstraints(DatabaseColumn annotation,
      [bool hasCompositeKey = false, bool skipPrimaryKey = false]) {
    final constraints = <String>[];

    // Only add PRIMARY KEY constraint for single-column primary keys
    if (annotation.isPrimaryKey && !hasCompositeKey && !skipPrimaryKey) {
      constraints.add('PRIMARY KEY');
    }

    // Handle nullability based on configuration
    if (config.useExplicitNullability) {
      // Always specify NULL or NOT NULL explicitly
      if (annotation.isNullable && !annotation.isPrimaryKey) {
        constraints.add('NULL');
      } else if (!annotation.isNullable || annotation.isPrimaryKey) {
        constraints.add('NOT NULL');
      }
    } else {
      // Use default behavior (only NOT NULL when needed)
      if (!annotation.isNullable && !annotation.isPrimaryKey) {
        constraints.add('NOT NULL');
      }
    }

    if (annotation.isUnique && !annotation.isPrimaryKey) {
      // Primary keys are implicitly unique
      constraints.add('UNIQUE');
    }

    if (annotation.defaultValue != null) {
      constraints.add('DEFAULT ${annotation.defaultValue!.sqlExpression}');
    }

    for (final check in annotation.checkConstraints) {
      constraints.add('CHECK ($check)');
    }

    if (annotation.collation != null) {
      constraints.add('COLLATE "${annotation.collation}"');
    }

    return constraints;
  }

  /// Parses partition strategy from annotation constant reader.
  PartitionStrategy? _parsePartitionStrategy(ConstantReader partitionReader) {
    if (partitionReader.isNull) return null;

    try {
      final type = partitionReader.objectValue.type;
      final typeName = type?.getDisplayString(withNullability: true);

      switch (typeName) {
        case 'RangePartition':
          final columnsReader = partitionReader.peek('columns');
          if (columnsReader != null) {
            final columns = columnsReader.listValue
                .map((e) => e.toStringValue() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            return RangePartition(columns: columns);
          }

        case 'HashPartition':
          final columnsReader = partitionReader.peek('columns');
          if (columnsReader != null) {
            final columns = columnsReader.listValue
                .map((e) => e.toStringValue() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            return HashPartition(columns: columns);
          }

        case 'ListPartition':
          final columnsReader = partitionReader.peek('columns');
          if (columnsReader != null) {
            final columns = columnsReader.listValue
                .map((e) => e.toStringValue() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
            return ListPartition(columns: columns);
          }
      }
    } on Exception {
      // Failed to parse partition strategy, return null
      return null;
    }

    return null;
  }

  /// Extracts column names from partition strategy.
  List<String> _getPartitionColumns(PartitionStrategy partitionStrategy) {
    if (partitionStrategy is RangePartition) {
      return partitionStrategy.columns;
    } else if (partitionStrategy is HashPartition) {
      return partitionStrategy.columns;
    } else if (partitionStrategy is ListPartition) {
      return partitionStrategy.columns;
    }
    return [];
  }
}

/// Synthetic field element for generated timestamp columns.
class _SyntheticFieldElement implements FieldElement {
  _SyntheticFieldElement(this.name);

  @override
  final String name;

  // Minimal implementation - only name is used
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Internal class to hold column information during processing.
class _ColumnInfo {
  const _ColumnInfo({
    required this.field,
    this.annotation,
    this.foreignKey,
  });

  final FieldElement field;
  final DatabaseColumn? annotation;
  final ForeignKey? foreignKey;
}
