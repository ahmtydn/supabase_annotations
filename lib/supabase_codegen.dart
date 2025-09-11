/// A comprehensive code generator for creating Supabase/PostgreSQL database schemas
/// from Dart model classes.
///
/// This library provides annotations and utilities
/// for generating SQL DDL statements,
/// database migrations, RLS policies, indexes, and
/// foreign key relationships from
/// annotated Dart classes.
///
/// ## Features
///
/// * **Schema Generation**: Convert Dart classes to
/// PostgreSQL CREATE TABLE statements
/// * **Type Safety**: Automatic Dart-to-PostgreSQL type mapping with validation
/// * **Relationships**: Support for foreign keys,
/// one-to-many, and many-to-many relationships
/// * **Security**: Automatic RLS (Row Level Security) policy generation
/// * **Performance**: Index creation and optimization suggestions
/// * **Migrations**: Versioned schema migrations with rollback support
/// * **Validation**: Comprehensive schema validation and error reporting
///
/// ## Quick Start
///
/// ```dart
/// import 'package:supabase_codegen/supabase_codegen.dart';
///
/// @DatabaseTable(
///   name: 'users',
///   enableRLS: true,
///   comment: 'Application users with authentication',
/// )
/// class User {
///   @DatabaseColumn(
///     type: ColumnType.uuid,
///     isPrimaryKey: true,
///     defaultValue: DefaultValue.generateUuid(),
///   )
///   String? id;
///
///   @DatabaseColumn(
///     type: ColumnType.text,
///     isUnique: true,
///     validators: [EmailValidator()],
///   )
///   String email;
///
///   @DatabaseColumn(
///     type: ColumnType.timestampWithTimeZone,
///     defaultValue: DefaultValue.currentTimestamp(),
///   )
///   DateTime? createdAt;
/// }
/// ```
///
/// Then run `dart run build_runner build` to generate the SQL schema.
///
/// ## Advanced Features
///
/// ### Custom Types and Enums
/// ```dart
/// @DatabaseEnum('user_role')
/// enum UserRole { admin, user, guest }
///
/// @DatabaseTable()
/// class User {
///   @DatabaseColumn(type: ColumnType.enumType('user_role'))
///   UserRole role;
/// }
/// ```
///
/// ### Relationships
/// ```dart
/// @DatabaseTable()
/// class Post {
///   @ForeignKey(
///     table: 'users',
///     column: 'id',
///     onDelete: ForeignKeyAction.cascade,
///   )
///   String userId;
/// }
/// ```
///
/// ### Custom Policies
/// ```dart
/// @DatabaseTable(
///   policies: [
///     RLSPolicy.authenticatedRead(),
///     RLSPolicy.ownerWrite('user_id'),
///   ],
/// )
/// class PrivateDocument { ... }
/// ```
library supabase_codegen;

export 'src/annotations/database_column.dart';
export 'src/annotations/database_index.dart';
// Core annotations
export 'src/annotations/database_table.dart';
export 'src/annotations/foreign_key.dart';
export 'src/annotations/rls_policy.dart';
// Models and types
export 'src/models/column_types.dart';
export 'src/models/default_values.dart';
export 'src/models/foreign_key_actions.dart';
export 'src/models/index_types.dart';
export 'src/models/partition_strategy.dart';
export 'src/models/table_constraints.dart';
export 'src/models/validators.dart';
