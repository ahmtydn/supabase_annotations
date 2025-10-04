/// Main code generator for creating PostgreSQL schemas from annotated Dart classes.
///
/// This generator follows a pipeline architecture where each stage has a single
/// responsibility, making the code testable, maintainable, and extensible.
library;

import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:supabase_annotations/src/models/migration_config.dart';
import 'package:supabase_annotations/supabase_annotations.dart';

// ============================================================================
// Configuration
// ============================================================================

class SchemaGeneratorConfig {
  const SchemaGeneratorConfig({
    this.formatSql = true,
    this.enableRlsByDefault = false,
    this.addTimestamps = false,
    this.useExplicitNullability = false,
    this.generateComments = true,
    this.validateSchema = true,
    this.migrationConfig = const MigrationConfig(),
  });

  factory SchemaGeneratorConfig.fromOptions(Map<String, dynamic> options) {
    return SchemaGeneratorConfig(
      formatSql: options['format_sql'] as bool? ?? true,
      enableRlsByDefault: options['enable_rls_by_default'] as bool? ?? false,
      addTimestamps: options['add_timestamps'] as bool? ?? false,
      useExplicitNullability:
          options['use_explicit_nullability'] as bool? ?? false,
      generateComments: options['generate_comments'] as bool? ?? true,
      validateSchema: options['validate_schema'] as bool? ?? true,
      migrationConfig: MigrationConfig(
        mode: _parseMigrationMode(options['migration_mode'] as String?),
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

  final bool formatSql;
  final bool enableRlsByDefault;
  final bool addTimestamps;
  final bool useExplicitNullability;
  final bool generateComments;
  final bool validateSchema;
  final MigrationConfig migrationConfig;

  static MigrationMode _parseMigrationMode(String? mode) {
    if (mode == null) return MigrationMode.createOnly;
    return MigrationMode.values.firstWhere(
      (e) => e.toString().split('.').last == mode,
      orElse: () => MigrationMode.createOnly,
    );
  }
}

// ============================================================================
// Domain Models - represent parsed schema information
// ============================================================================

class TableSchema {
  const TableSchema({
    required this.name,
    required this.columns,
    required this.indexes,
    required this.policies,
    required this.foreignKeys,
    this.comment,
    this.enableRLS = false,
    this.partitionStrategy,
  });

  final String name;
  final List<ColumnSchema> columns;
  final List<DatabaseIndex> indexes;
  final List<RLSPolicy> policies;
  final List<ForeignKey> foreignKeys;
  final String? comment;
  final bool enableRLS;
  final PartitionStrategy? partitionStrategy;

  List<String> get primaryKeyColumns =>
      columns.where((c) => c.isPrimaryKey).map((c) => c.name).toList();

  bool get hasCompositePrimaryKey => primaryKeyColumns.length > 1;
}

class ColumnSchema {
  const ColumnSchema({
    required this.name,
    required this.sqlType,
    required this.isNullable,
    this.isPrimaryKey = false,
    this.isUnique = false,
    this.defaultValue,
    this.checkConstraints = const [],
    this.collation,
    this.comment,
  });

  final String name;
  final String sqlType;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isUnique;
  final String? defaultValue;
  final List<String> checkConstraints;
  final String? collation;
  final String? comment;
}

class DatabaseIndex {
  const DatabaseIndex({
    required this.columns,
    this.name,
    this.unique = false,
    this.method,
    this.where,
    this.include,
  });

  final String? name;
  final List<String> columns;
  final bool unique;
  final String? method;
  final String? where;
  final List<String>? include;

  String generateSql(String tableName) {
    final indexName = name ?? _generateIndexName(tableName);
    final uniqueKeyword = unique ? 'UNIQUE ' : '';
    final methodClause = method != null ? ' USING $method' : '';
    final columnsStr = columns.join(', ');
    final includeClause = include != null && include!.isNotEmpty
        ? ' INCLUDE (${include!.join(', ')})'
        : '';
    final whereClause = where != null ? ' WHERE $where' : '';

    return 'CREATE ${uniqueKeyword}INDEX IF NOT EXISTS $indexName '
        'ON $tableName$methodClause ($columnsStr)$includeClause$whereClause;';
  }

  String _generateIndexName(String tableName) {
    final columnsStr = columns.join('_');
    final prefix = unique ? 'idx_unique' : 'idx';
    return '${prefix}_${tableName}_$columnsStr';
  }
}

class RLSPolicy {
  const RLSPolicy({
    required this.name,
    required this.condition,
    this.command = PolicyCommand.all,
    this.roles = const ['PUBLIC'],
    this.withCheck,
    this.comment,
  });

  final String name;
  final PolicyCommand command;
  final List<String> roles;
  final String condition;
  final String? withCheck;
  final String? comment;

  String generateSql(String tableName) {
    final commandStr = _commandToSql(command);
    final rolesStr = roles.join(', ');
    final withCheckClause = withCheck != null ? ' WITH CHECK ($withCheck)' : '';

    return 'CREATE POLICY $name ON $tableName '
        'FOR $commandStr TO $rolesStr '
        'USING ($condition)$withCheckClause;';
  }

  String? generateCommentSql(String tableName) {
    if (comment == null) return null;

    final escaped = comment!.replaceAll("'", "''");
    return "COMMENT ON POLICY $name ON $tableName IS '$escaped';";
  }

  String _commandToSql(PolicyCommand cmd) {
    return switch (cmd) {
      PolicyCommand.all => 'ALL',
      PolicyCommand.select => 'SELECT',
      PolicyCommand.insert => 'INSERT',
      PolicyCommand.update => 'UPDATE',
      PolicyCommand.delete => 'DELETE',
    };
  }
}

enum PolicyCommand { all, select, insert, update, delete }

class ForeignKey {
  const ForeignKey({
    required this.column,
    required this.table,
    this.referencedColumn = 'id',
    this.onDelete = ForeignKeyAction.noAction,
    this.onUpdate = ForeignKeyAction.noAction,
    this.name,
  });

  final String column;
  final String? table;
  final String referencedColumn;
  final ForeignKeyAction onDelete;
  final ForeignKeyAction onUpdate;
  final String? name;

  String generateSql(String tableName, String columnName) {
    if (table == null || table!.isEmpty) {
      throw StateError('Foreign key table cannot be null or empty');
    }

    final constraintName =
        name ?? 'fk_${tableName}_${columnName}_${table}_$referencedColumn';
    final onDeleteClause = _actionToSql(onDelete, 'DELETE');
    final onUpdateClause = _actionToSql(onUpdate, 'UPDATE');

    return 'ALTER TABLE $tableName '
        'ADD CONSTRAINT $constraintName '
        'FOREIGN KEY ($columnName) '
        'REFERENCES $table($referencedColumn)'
        '$onDeleteClause$onUpdateClause;';
  }

  String _actionToSql(ForeignKeyAction action, String type) {
    if (action == ForeignKeyAction.noAction) return '';

    final actionStr = action.sqlClause;

    return ' ON $type $actionStr';
  }
}

// ============================================================================
// Parsing Pipeline - extracts schema from Dart elements
// ============================================================================

class SchemaParser {
  const SchemaParser(this.config);

  final SchemaGeneratorConfig config;

  TableSchema parseClass(ClassElement element, ConstantReader annotation) {
    final tableConfig = _parseTableAnnotation(annotation);
    final className = element.name;
    final tableName = tableConfig.name ?? _toSnakeCase(className!);

    final columns = _ColumnParser(config).parseFields(element);
    final indexes = _IndexParser().parseIndexes(element);
    final policies = _PolicyParser().parsePolicies(element);
    final foreignKeys = _ForeignKeyParser().parseForeignKeys(element, columns);

    return TableSchema(
      name: tableName,
      columns: columns,
      indexes: indexes,
      policies: policies,
      foreignKeys: foreignKeys,
      comment: tableConfig.comment,
      enableRLS: tableConfig.enableRLS,
      partitionStrategy: tableConfig.partitionBy,
    );
  }

  DatabaseTable _parseTableAnnotation(ConstantReader annotation) {
    return DatabaseTable(
      name: annotation.peek('name')?.stringValue,
      comment: annotation.peek('comment')?.stringValue,
      enableRLS: annotation.peek('enableRLS')?.boolValue ?? false,
      partitionBy: _PartitionParser().parse(annotation.peek('partitionBy')),
    );
  }

  static String _toSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(RegExp('([A-Z])'), (m) => '_${m[1]!.toLowerCase()}')
        .replaceFirst(RegExp('^_'), '');
  }
}

// ============================================================================
// Specialized Parsers - single responsibility principle
// ============================================================================

class _ColumnParser {
  const _ColumnParser(this.config);

  final SchemaGeneratorConfig config;

  List<ColumnSchema> parseFields(ClassElement element) {
    final columns = <ColumnSchema>[];

    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      final annotation = _findAnnotation<DatabaseColumn>(field);
      if (annotation == null) continue;

      columns.add(_parseColumn(field, annotation));
    }

    if (config.addTimestamps) {
      columns.addAll(_generateTimestampColumns(columns));
    }

    return columns;
  }

  ColumnSchema _parseColumn(FieldElement field, ConstantReader annotation) {
    final fieldName = field.name;
    final columnName =
        annotation.peek('name')?.stringValue ?? _toSnakeCase(fieldName ?? '');
    final type = _ColumnTypeParser().parse(annotation.peek('type'));

    return ColumnSchema(
      name: columnName,
      sqlType: type.toSql(annotation),
      isNullable: annotation.peek('isNullable')?.boolValue ?? true,
      isPrimaryKey: annotation.peek('isPrimaryKey')?.boolValue ?? false,
      isUnique: annotation.peek('isUnique')?.boolValue ?? false,
      defaultValue: annotation
          .peek('defaultValue')
          ?.objectValue
          .getField('sqlExpression')
          ?.toStringValue(),
      checkConstraints: _parseCheckConstraints(annotation),
      collation: annotation.peek('collation')?.stringValue,
      comment: annotation.peek('comment')?.stringValue,
    );
  }

  List<ColumnSchema> _generateTimestampColumns(List<ColumnSchema> existing) {
    final existingNames = existing.map((c) => c.name).toSet();
    final timestamps = <ColumnSchema>[];

    if (!existingNames.contains('created_at')) {
      timestamps.add(const ColumnSchema(
        name: 'created_at',
        sqlType: 'TIMESTAMP WITH TIME ZONE',
        isNullable: false,
        defaultValue: 'CURRENT_TIMESTAMP',
      ));
    }

    if (!existingNames.contains('updated_at')) {
      timestamps.add(const ColumnSchema(
        name: 'updated_at',
        sqlType: 'TIMESTAMP WITH TIME ZONE',
        isNullable: false,
        defaultValue: 'CURRENT_TIMESTAMP',
      ));
    }

    return timestamps;
  }

  List<String> _parseCheckConstraints(ConstantReader annotation) {
    return annotation
            .peek('checkConstraints')
            ?.listValue
            .map((v) => v.toStringValue())
            .whereType<String>()
            .toList() ??
        [];
  }

  ConstantReader? _findAnnotation<T>(FieldElement field) {
    for (final metadata in field.metadata.annotations) {
      final value = metadata.computeConstantValue();
      if (value?.type?.element?.name == T.toString()) {
        return ConstantReader(value);
      }
    }
    return null;
  }

  static String _toSnakeCase(String s) => SchemaParser._toSnakeCase(s);
}

class _ColumnTypeParser {
  SqlTypeInfo parse(ConstantReader? reader) {
    if (reader == null) return const SqlTypeInfo('TEXT');

    final typeValue = reader.objectValue;
    final typeName = typeValue.type?.element?.name;

    return switch (typeName) {
      '_SimpleColumnType' => _parseSimpleType(typeValue),
      '_EnumType' => _parseEnumType(reader),
      '_VarcharType' => const SqlTypeInfo('VARCHAR'),
      '_CharType' => const SqlTypeInfo('CHAR'),
      '_DecimalType' => const SqlTypeInfo('DECIMAL'),
      '_NumericType' => const SqlTypeInfo('NUMERIC'),
      '_ArrayType' => _parseArrayType(typeValue),
      '_CustomType' => _parseCustomType(typeValue),
      _ => const SqlTypeInfo('TEXT'),
    };
  }

  SqlTypeInfo _parseSimpleType(DartObject typeValue) {
    final sqlType = typeValue.getField('sqlType')?.toStringValue();
    return SqlTypeInfo(sqlType ?? 'TEXT');
  }

  SqlTypeInfo _parseEnumType(ConstantReader reader) {
    try {
      final revived = reader.revive();
      if (revived.positionalArguments.isNotEmpty) {
        final enumName = revived.positionalArguments.first.toStringValue();
        return SqlTypeInfo(enumName ?? 'TEXT');
      }
    } on Exception {
      // ignore
    }
    return const SqlTypeInfo('TEXT');
  }

  SqlTypeInfo _parseArrayType(DartObject typeValue) {
    try {
      final elementTypeField = typeValue.getField('elementType');
      if (elementTypeField != null) {
        final elementTypeParser = _ColumnTypeParser();
        final elementTypeInfo =
            elementTypeParser.parse(ConstantReader(elementTypeField));
        return SqlTypeInfo('${elementTypeInfo.baseType}[]');
      }
    } on Exception {
      // ignore
    }
    return const SqlTypeInfo('TEXT[]');
  }

  SqlTypeInfo _parseCustomType(DartObject typeValue) {
    final sqlType = typeValue.getField('sqlType')?.toStringValue();
    return SqlTypeInfo(sqlType ?? 'TEXT');
  }
}

class SqlTypeInfo {
  const SqlTypeInfo(this.baseType, {this.length, this.precision, this.scale});

  final String baseType;
  final int? length;
  final int? precision;
  final int? scale;

  String toSql(ConstantReader annotation) {
    final buffer = StringBuffer(baseType);

    final len = length ?? annotation.peek('length')?.intValue;
    final prec = precision ?? annotation.peek('precision')?.intValue;
    final scl = scale ?? annotation.peek('scale')?.intValue;

    if (prec != null && scl != null) {
      buffer.write('($prec, $scl)');
    } else if (len != null) {
      buffer.write('($len)');
    }

    return buffer.toString();
  }
}

class _IndexParser {
  List<DatabaseIndex> parseIndexes(ClassElement element) {
    final indexes = <DatabaseIndex>[];

    for (final metadata in element.metadata.annotations) {
      final annotation = metadata.computeConstantValue();
      if (annotation == null) continue;

      final typeName = annotation.type?.element?.name;
      if (typeName != 'DatabaseIndex') continue;

      final reader = ConstantReader(annotation);
      indexes.add(_parseIndexAnnotation(reader));
    }

    return indexes;
  }

  DatabaseIndex _parseIndexAnnotation(ConstantReader reader) {
    final name = reader.peek('name')?.stringValue;
    final columns = reader
            .peek('columns')
            ?.listValue
            .map((v) => v.toStringValue())
            .whereType<String>()
            .toList() ??
        [];
    final unique = reader.peek('unique')?.boolValue ?? false;
    final method = reader.peek('method')?.stringValue;
    final where = reader.peek('where')?.stringValue;
    final include = reader
        .peek('include')
        ?.listValue
        .map((v) => v.toStringValue())
        .whereType<String>()
        .toList();

    return DatabaseIndex(
      name: name,
      columns: columns,
      unique: unique,
      method: method,
      where: where,
      include: include,
    );
  }
}

class _PolicyParser {
  List<RLSPolicy> parsePolicies(ClassElement element) {
    final policies = <RLSPolicy>[];

    for (final metadata in element.metadata.annotations) {
      final annotation = metadata.computeConstantValue();
      if (annotation == null) continue;

      final typeName = annotation.type?.element?.name;
      if (typeName != 'RLSPolicy') continue;

      final reader = ConstantReader(annotation);
      policies.add(_parsePolicyAnnotation(reader));
    }

    return policies;
  }

  RLSPolicy _parsePolicyAnnotation(ConstantReader reader) {
    final name = reader.peek('name')?.stringValue ?? 'unnamed_policy';
    final command = _parseCommand(reader.peek('command'));
    final roles = reader
            .peek('roles')
            ?.listValue
            .map((v) => v.toStringValue())
            .whereType<String>()
            .toList() ??
        ['PUBLIC'];
    final using = reader.peek('using')?.stringValue ?? 'true';
    final withCheck = reader.peek('withCheck')?.stringValue;
    final comment = reader.peek('comment')?.stringValue;

    return RLSPolicy(
      name: name,
      command: command,
      roles: roles,
      condition: using,
      withCheck: withCheck,
      comment: comment,
    );
  }

  PolicyCommand _parseCommand(ConstantReader? reader) {
    if (reader == null || reader.isNull) return PolicyCommand.all;

    final enumValue = reader.objectValue;
    final index = enumValue.getField('index')?.toIntValue() ?? 0;

    return PolicyCommand.values[index];
  }
}

class _ForeignKeyParser {
  List<ForeignKey> parseForeignKeys(
    ClassElement element,
    List<ColumnSchema> columns,
  ) {
    final foreignKeys = <ForeignKey>[];

    // Parse from field-level annotations
    for (final field in element.fields) {
      if (field.isStatic || field.isSynthetic) continue;

      final fk = _parseForeignKeyFromField(field, columns);
      if (fk != null) {
        foreignKeys.add(fk);
      }
    }

    // Parse from class-level annotations
    foreignKeys.addAll(_parseForeignKeysFromClass(element));

    return foreignKeys;
  }

  ForeignKey? _parseForeignKeyFromField(
    FieldElement field,
    List<ColumnSchema> columns,
  ) {
    for (final metadata in field.metadata.annotations) {
      final annotation = metadata.computeConstantValue();
      if (annotation == null) continue;

      final typeName = annotation.type?.element?.name;
      if (typeName != 'ForeignKey') continue;

      final reader = ConstantReader(annotation);
      final fieldName = field.name;
      if (fieldName == null) continue;

      final columnName = columns
          .firstWhere(
            (c) => c.name == _toSnakeCase(fieldName),
            orElse: () =>
                throw StateError('Column not found for field $fieldName'),
          )
          .name;

      return _parseForeignKeyAnnotation(reader, columnName);
    }

    return null;
  }

  List<ForeignKey> _parseForeignKeysFromClass(ClassElement element) {
    final foreignKeys = <ForeignKey>[];

    for (final metadata in element.metadata.annotations) {
      final annotation = metadata.computeConstantValue();
      if (annotation == null) continue;

      final typeName = annotation.type?.element?.name;
      if (typeName != 'ForeignKey') continue;

      final reader = ConstantReader(annotation);
      final column = reader.peek('column')?.stringValue;

      if (column != null) {
        foreignKeys.add(_parseForeignKeyAnnotation(reader, column));
      }
    }

    return foreignKeys;
  }

  ForeignKey _parseForeignKeyAnnotation(ConstantReader reader, String column) {
    final table = reader.peek('table')?.stringValue;
    final referencedColumn =
        reader.peek('referencedColumn')?.stringValue ?? 'id';
    final onDelete = _parseReferentialAction(reader.peek('onDelete'));
    final onUpdate = _parseReferentialAction(reader.peek('onUpdate'));
    final name = reader.peek('name')?.stringValue;

    return ForeignKey(
      column: column,
      table: table,
      referencedColumn: referencedColumn,
      onDelete: onDelete,
      onUpdate: onUpdate,
      name: name,
    );
  }

  ForeignKeyAction _parseReferentialAction(ConstantReader? reader) {
    if (reader == null || reader.isNull) return ForeignKeyAction.noAction;

    final enumValue = reader.objectValue;
    final index = enumValue.getField('index')?.toIntValue() ?? 0;

    return ForeignKeyAction.values[index];
  }

  static String _toSnakeCase(String s) => SchemaParser._toSnakeCase(s);
}

class _PartitionParser {
  PartitionStrategy? parse(ConstantReader? reader) {
    if (reader == null || reader.isNull) return null;

    final partitionValue = reader.objectValue;
    final typeName = partitionValue.type?.element?.name;

    return switch (typeName) {
      'RangePartition' => _parseRangePartition(reader),
      'HashPartition' => _parseHashPartition(reader),
      'ListPartition' => _parseListPartition(reader),
      _ => null,
    };
  }

  RangePartition _parseRangePartition(ConstantReader reader) {
    final columns = reader
            .peek('columns')
            ?.listValue
            .map((v) => v.toStringValue())
            .whereType<String>()
            .toList() ??
        [];

    return RangePartition(columns: columns);
  }

  HashPartition _parseHashPartition(ConstantReader reader) {
    final columns = reader
            .peek('columns')
            ?.listValue
            .map((v) => v.toStringValue())
            .whereType<String>()
            .toList() ??
        [];

    return HashPartition(columns: columns);
  }

  ListPartition _parseListPartition(ConstantReader reader) {
    final columns = reader
            .peek('columns')
            ?.listValue
            .map((v) => v.toStringValue())
            .whereType<String>()
            .toList() ??
        [];

    return ListPartition(columns: columns);
  }
}

// ============================================================================
// Validation Pipeline
// ============================================================================

class SchemaValidator {
  const SchemaValidator();

  void validate(TableSchema schema) {
    _validatePrimaryKey(schema);
    _validateForeignKeys(schema);
    _validateIndexes(schema);
    _validatePolicies(schema);
    _validatePartitioning(schema);
  }

  void _validatePrimaryKey(TableSchema schema) {
    if (schema.primaryKeyColumns.isEmpty) {
      // Log warning - table without primary key
    }
  }

  void _validateForeignKeys(TableSchema schema) {
    for (final fk in schema.foreignKeys) {
      if (fk.table == null || fk.table!.isEmpty) {
        throw SchemaValidationException(
          'Foreign key in table ${schema.name} missing table reference',
        );
      }
    }
  }

  void _validateIndexes(TableSchema schema) {
    final columnNames = schema.columns.map((c) => c.name).toSet();

    for (final index in schema.indexes) {
      for (final column in index.columns) {
        if (!columnNames.contains(column)) {
          throw SchemaValidationException(
            'Index ${index.name} references non-existent column: $column',
          );
        }
      }
    }
  }

  void _validatePolicies(TableSchema schema) {
    for (final policy in schema.policies) {
      if (policy.condition.trim().isEmpty) {
        throw SchemaValidationException(
          'RLS Policy ${policy.name} has empty condition',
        );
      }
    }
  }

  void _validatePartitioning(TableSchema schema) {
    if (schema.partitionStrategy == null) return;

    try {
      schema.partitionStrategy!.validate();
    } catch (e) {
      throw SchemaValidationException(
        'Invalid partition configuration: $e',
      );
    }

    // Ensure partition columns are in primary key
    final partitionColumns =
        _extractPartitionColumns(schema.partitionStrategy!);
    final pkColumns = schema.primaryKeyColumns.toSet();

    for (final col in partitionColumns) {
      if (!pkColumns.contains(col)) {
        throw SchemaValidationException(
          'Partition column $col must be part of primary key',
        );
      }
    }
  }

  List<String> _extractPartitionColumns(PartitionStrategy strategy) {
    return switch (strategy) {
      RangePartition(columns: final cols) => cols,
      HashPartition(columns: final cols) => cols,
      ListPartition(columns: final cols) => cols,
      _ => <String>[],
    };
  }
}

class SchemaValidationException implements Exception {
  SchemaValidationException(this.message);
  final String message;

  @override
  String toString() => 'Schema Validation Error: $message';
}

// ============================================================================
// SQL Generation Strategy Pattern
// ============================================================================

abstract class SqlGenerationStrategy {
  String generate(TableSchema schema, SchemaGeneratorConfig config);

  @override
  String toString() => runtimeType.toString();
}

class CreateOnlyStrategy implements SqlGenerationStrategy {
  const CreateOnlyStrategy();

  @override
  String generate(TableSchema schema, SchemaGeneratorConfig config) {
    return (SqlStatementBuilder(config)
          ..buildCreateTable(schema)
          ..buildIndexes(schema)
          ..buildForeignKeys(schema)
          ..buildRls(schema)
          ..buildComments(schema))
        .toSql();
  }
}

class CreateIfNotExistsStrategy implements SqlGenerationStrategy {
  const CreateIfNotExistsStrategy();

  @override
  String generate(TableSchema schema, SchemaGeneratorConfig config) {
    return (SqlStatementBuilder(config)
          ..buildCreateTableIfNotExists(schema)
          ..buildIndexes(schema)
          ..buildForeignKeys(schema)
          ..buildRls(schema)
          ..buildComments(schema))
        .toSql();
  }
}

class CreateOrAlterStrategy implements SqlGenerationStrategy {
  const CreateOrAlterStrategy();

  @override
  String generate(TableSchema schema, SchemaGeneratorConfig config) {
    return (SqlStatementBuilder(config)
          ..buildCreateTableIfNotExists(schema)
          ..buildAlterTableAddColumns(schema)
          ..buildIndexes(schema)
          ..buildForeignKeys(schema)
          ..buildRls(schema)
          ..buildComments(schema))
        .toSql();
  }
}

class SqlGenerationStrategyFactory {
  static SqlGenerationStrategy create(MigrationMode mode) {
    return switch (mode) {
      MigrationMode.createOnly => const CreateOnlyStrategy(),
      MigrationMode.createIfNotExists => const CreateIfNotExistsStrategy(),
      MigrationMode.createOrAlter => const CreateOrAlterStrategy(),
      MigrationMode.alterOnly => const AlterOnlyStrategy(),
      MigrationMode.dropAndRecreate => const DropAndRecreateStrategy(),
    };
  }
}

class AlterOnlyStrategy implements SqlGenerationStrategy {
  const AlterOnlyStrategy();

  @override
  String generate(TableSchema schema, SchemaGeneratorConfig config) {
    return (SqlStatementBuilder(config)..buildAlterTableAddColumns(schema))
        .toSql();
  }
}

class DropAndRecreateStrategy implements SqlGenerationStrategy {
  const DropAndRecreateStrategy();

  @override
  String generate(TableSchema schema, SchemaGeneratorConfig config) {
    return (SqlStatementBuilder(config)
          ..buildDropTable(schema)
          ..buildCreateTable(schema)
          ..buildIndexes(schema)
          ..buildForeignKeys(schema)
          ..buildRls(schema)
          ..buildComments(schema))
        .toSql();
  }
}

// ============================================================================
// SQL Statement Builder - fluent interface for constructing SQL
// ============================================================================

class SqlStatementBuilder {
  SqlStatementBuilder(this.config);

  final SchemaGeneratorConfig config;
  final List<String> _statements = [];

  void buildCreateTable(TableSchema schema) {
    _statements
        .add(_CreateTableBuilder(config).build(schema, ifNotExists: false));
  }

  void buildCreateTableIfNotExists(TableSchema schema) {
    _statements
        .add(_CreateTableBuilder(config).build(schema, ifNotExists: true));
  }

  void buildDropTable(TableSchema schema) {
    _statements.add('DROP TABLE IF EXISTS ${schema.name} CASCADE;');
  }

  void buildAlterTableAddColumns(TableSchema schema) {
    if (!config.migrationConfig.enableColumnAdding) return;

    final statements = config.migrationConfig.generateDoBlocks
        ? _buildDoBlockColumnAdditions(schema)
        : _buildSimpleColumnAdditions(schema);

    _statements.add(statements);
  }

  String _buildSimpleColumnAdditions(TableSchema schema) {
    final lines = <String>[];

    for (final column in schema.columns) {
      final constraints = _ConstraintBuilder(config).build(
        column,
        skipPrimaryKey: true,
      );
      final constraintStr =
          constraints.isNotEmpty ? ' ${constraints.join(' ')}' : '';
      lines.add('ALTER TABLE ${schema.name} ADD COLUMN IF NOT EXISTS '
          '${column.name} ${column.sqlType}$constraintStr;');
    }

    return lines.join('\n');
  }

  String _buildDoBlockColumnAdditions(TableSchema schema) {
    final lines = [r'DO $$', 'BEGIN'];

    for (final column in schema.columns) {
      final constraints = _ConstraintBuilder(config).build(
        column,
        skipPrimaryKey: true,
      );
      final constraintStr =
          constraints.isNotEmpty ? ' ${constraints.join(' ')}' : '';

      lines.addAll([
        '  IF NOT EXISTS (',
        '    SELECT 1 FROM information_schema.columns',
        "    WHERE table_name = '${schema.name}' AND column_name = '${column.name}'",
        '  ) THEN',
        '    ALTER TABLE ${schema.name} ADD COLUMN ${column.name} ${column.sqlType}$constraintStr;',
        '  END IF;',
        '',
      ]);
    }

    lines.add(r'END $$;');
    return lines.join('\n');
  }

  void buildIndexes(TableSchema schema) {
    for (final index in schema.indexes) {
      _statements.add(index.generateSql(schema.name));
    }
  }

  void buildForeignKeys(TableSchema schema) {
    for (final column in schema.columns) {
      final fk = schema.foreignKeys
          .where((fk) => fk.column == column.name)
          .firstOrNull;

      if (fk != null) {
        _statements.add(fk.generateSql(schema.name, column.name));
      }
    }
  }

  void buildRls(TableSchema schema) {
    if (schema.enableRLS) {
      _statements.add('ALTER TABLE ${schema.name} ENABLE ROW LEVEL SECURITY;');
    }

    for (final policy in schema.policies) {
      _statements.add(policy.generateSql(schema.name));

      if (config.generateComments) {
        final comment = policy.generateCommentSql(schema.name);
        if (comment != null) _statements.add(comment);
      }
    }
  }

  void buildComments(TableSchema schema) {
    if (!config.generateComments) return;

    if (schema.comment != null) {
      final escaped = schema.comment!.replaceAll("'", "''");
      _statements.add("COMMENT ON TABLE ${schema.name} IS '$escaped';");
    }
  }

  String toSql() {
    final sql = _statements.where((s) => s.isNotEmpty).join('\n\n');
    return config.formatSql ? _formatSql(sql) : sql;
  }

  String _formatSql(String sql) {
    return sql
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(';', ';\n')
        .replaceAll('CREATE TABLE', '\nCREATE TABLE')
        .replaceAll('CREATE INDEX', '\nCREATE INDEX')
        .replaceAll('ALTER TABLE', '\nALTER TABLE')
        .replaceAll('COMMENT ON', '\nCOMMENT ON')
        .replaceAll('PARTITION BY', '\nPARTITION BY')
        .replaceAll(RegExp(r'^\s+'), '')
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }
}

// ============================================================================
// Supporting Builders
// ============================================================================

class _CreateTableBuilder {
  const _CreateTableBuilder(this.config);

  final SchemaGeneratorConfig config;

  String build(TableSchema schema, {required bool ifNotExists}) {
    final lines = <String>[];
    final keyword = ifNotExists ? 'CREATE TABLE IF NOT EXISTS' : 'CREATE TABLE';
    lines.add('$keyword ${schema.name} (');

    final hasComposite = schema.hasCompositePrimaryKey;
    final columnDefs = schema.columns
        .map((c) => _buildColumnDefinition(c, hasComposite))
        .toList();

    for (var i = 0; i < columnDefs.length; i++) {
      final isLast = i == columnDefs.length - 1;
      lines.add(columnDefs[i] + (isLast && !hasComposite ? '' : ','));
    }

    if (hasComposite) {
      lines.add('  PRIMARY KEY (${schema.primaryKeyColumns.join(', ')})');
    }

    lines.add(')');

    if (schema.partitionStrategy != null) {
      lines.add(schema.partitionStrategy!.toSQL());
    }

    lines.add(';');
    return lines.join('\n');
  }

  String _buildColumnDefinition(ColumnSchema column, bool hasCompositePk) {
    final constraints = _ConstraintBuilder(config).build(
      column,
      hasCompositePk: hasCompositePk,
    );
    final parts = ['  ${column.name}', column.sqlType, ...constraints];
    return parts.join(' ');
  }
}

class _ConstraintBuilder {
  const _ConstraintBuilder(this.config);

  final SchemaGeneratorConfig config;

  List<String> build(
    ColumnSchema column, {
    bool hasCompositePk = false,
    bool skipPrimaryKey = false,
  }) {
    final constraints = <String>[];

    if (column.isPrimaryKey && !hasCompositePk && !skipPrimaryKey) {
      constraints.add('PRIMARY KEY');
    }

    constraints.add(_buildNullabilityConstraint(column));

    if (column.isUnique && !column.isPrimaryKey) {
      constraints.add('UNIQUE');
    }

    if (column.defaultValue != null) {
      constraints.add('DEFAULT ${column.defaultValue}');
    }

    for (final check in column.checkConstraints) {
      constraints.add('CHECK ($check)');
    }

    if (column.collation != null) {
      constraints.add('COLLATE "${column.collation}"');
    }

    return constraints.where((c) => c.isNotEmpty).toList();
  }

  String _buildNullabilityConstraint(ColumnSchema column) {
    if (config.useExplicitNullability) {
      return column.isNullable && !column.isPrimaryKey ? 'NULL' : 'NOT NULL';
    }
    return !column.isNullable && !column.isPrimaryKey ? 'NOT NULL' : '';
  }
}

// ============================================================================
// Main Generator - orchestrates the pipeline
// ============================================================================

class SupabaseSchemaGenerator extends GeneratorForAnnotation<DatabaseTable> {
  SupabaseSchemaGenerator([this.config = const SchemaGeneratorConfig()]);

  final SchemaGeneratorConfig config;

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'DatabaseTable can only be applied to classes.',
        element: element,
      );
    }

    try {
      // Parse: Extract schema from Dart code
      final schema = SchemaParser(config).parseClass(element, annotation);

      // Validate: Check schema integrity
      if (config.validateSchema) {
        const SchemaValidator().validate(schema);
      }

      // Generate: Create SQL using appropriate strategy
      final strategy = SqlGenerationStrategyFactory.create(
        config.migrationConfig.mode,
      );

      return strategy.generate(schema, config);
    } catch (e, stackTrace) {
      throw InvalidGenerationSourceError(
        'Failed to generate schema for ${element.name}: $e\n$stackTrace',
        element: element,
      );
    }
  }
}
