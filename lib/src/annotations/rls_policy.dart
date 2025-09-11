/// Annotation for configuring Row Level Security (RLS) policies.
///
/// This annotation provides comprehensive configuration options for RLS policies,
/// including policy types, roles, and conditions.
library;

import 'package:meta/meta.dart';

/// Enumeration of RLS policy types.
enum RLSPolicyType {
  /// Policy applies to all operations (SELECT, INSERT, UPDATE, DELETE)
  all,

  /// Policy applies only to SELECT operations
  select,

  /// Policy applies only to INSERT operations
  insert,

  /// Policy applies only to UPDATE operations
  update,

  /// Policy applies only to DELETE operations
  delete;

  /// Gets the SQL command for this policy type.
  String get sqlCommand {
    return switch (this) {
      RLSPolicyType.all => 'ALL',
      RLSPolicyType.select => 'SELECT',
      RLSPolicyType.insert => 'INSERT',
      RLSPolicyType.update => 'UPDATE',
      RLSPolicyType.delete => 'DELETE',
    };
  }

  /// Creates an RLS policy type from a string.
  static RLSPolicyType fromString(String value) {
    return switch (value.toLowerCase()) {
      'all' => RLSPolicyType.all,
      'select' => RLSPolicyType.select,
      'insert' => RLSPolicyType.insert,
      'update' => RLSPolicyType.update,
      'delete' => RLSPolicyType.delete,
      _ => throw ArgumentError('Invalid RLS policy type: $value'),
    };
  }
}

/// Annotation for configuring Row Level Security (RLS) policies.
///
/// This annotation is applied to classes (for table-level policies) to define
/// Row Level Security policies that control access to table data based on
/// the current user context and data values.
///
/// **Basic Usage:**
/// ```dart
/// @DatabaseTable()
/// @RLSPolicy(
///   name: 'user_own_data',
///   type: RLSPolicyType.all,
///   condition: 'user_id = auth.uid()',
/// )
/// class UserProfile {
///   String id;
///   String userId;
///   String email;
/// }
/// ```
///
/// **Advanced Usage:**
/// ```dart
/// @DatabaseTable()
/// @RLSPolicy(
///   name: 'admin_full_access',
///   type: RLSPolicyType.all,
///   roles: ['admin', 'super_admin'],
///   condition: 'true',
///   comment: 'Administrators have full access to all records',
/// )
/// @RLSPolicy(
///   name: 'user_read_own',
///   type: RLSPolicyType.select,
///   roles: ['authenticated'],
///   condition: 'user_id = auth.uid()',
///   comment: 'Users can read their own data',
/// )
/// @RLSPolicy(
///   name: 'user_update_own',
///   type: RLSPolicyType.update,
///   roles: ['authenticated'],
///   condition: 'user_id = auth.uid()',
///   checkCondition: 'user_id = auth.uid()',
///   comment: 'Users can update their own data but cannot change ownership',
/// )
/// class UserData {
///   String id;
///   String userId;
///   String data;
/// }
/// ```
///
/// **Role-based Policies:**
/// ```dart
/// @DatabaseTable()
/// @RLSPolicy(
///   name: 'public_read',
///   type: RLSPolicyType.select,
///   roles: ['anonymous', 'authenticated'],
///   condition: 'is_public = true',
/// )
/// @RLSPolicy(
///   name: 'owner_full_access',
///   type: RLSPolicyType.all,
///   roles: ['authenticated'],
///   condition: 'owner_id = auth.uid()',
/// )
/// @RLSPolicy(
///   name: 'admin_manage',
///   type: RLSPolicyType.all,
///   roles: ['admin'],
///   condition: 'true',
/// )
/// class Document {
///   String id;
///   String ownerId;
///   bool isPublic;
///   String content;
/// }
/// ```
@immutable
class RLSPolicy {
  /// Creates an RLS policy annotation with the specified configuration.
  ///
  /// **Parameters:**
  /// - [name]: Policy name (must be unique within the table)
  /// - [type]: The type of operations this policy applies to
  /// - [roles]: List of roles this policy applies to (empty = all roles)
  /// - [condition]: SQL condition that must be true for the policy to apply
  /// - [checkCondition]: Additional condition for INSERT/UPDATE operations
  /// - [comment]: Documentation comment for the policy
  /// - [isPermissive]: Whether this is a permissive or restrictive policy
  const RLSPolicy({
    required this.name,
    required this.type,
    required this.condition,
    this.roles = const [],
    this.checkCondition,
    this.comment,
    this.isPermissive = true,
  });

  /// The policy name in the database.
  ///
  /// Policy names must be unique within a table. Choose descriptive names
  /// that clearly indicate the policy's purpose and scope.
  ///
  /// **Example:**
  /// ```dart
  /// @RLSPolicy(
  ///   name: 'user_read_own_profile',
  ///   type: RLSPolicyType.select,
  ///   condition: 'user_id = auth.uid()',
  /// )
  /// ```
  final String name;

  /// The type of operations this policy applies to.
  ///
  /// Different policy types control different database operations:
  /// - ALL: Applies to all operations (SELECT, INSERT, UPDATE, DELETE)
  /// - SELECT: Only applies to read operations
  /// - INSERT: Only applies to row creation
  /// - UPDATE: Only applies to row modification
  /// - DELETE: Only applies to row deletion
  ///
  /// **Example:**
  /// ```dart
  /// @RLSPolicy(
  ///   name: 'read_public_posts',
  ///   type: RLSPolicyType.select,
  ///   condition: 'visibility = "public"',
  /// )
  ///
  /// @RLSPolicy(
  ///   name: 'delete_own_posts',
  ///   type: RLSPolicyType.delete,
  ///   condition: 'author_id = auth.uid()',
  /// )
  /// ```
  final RLSPolicyType type;

  /// List of roles this policy applies to.
  ///
  /// If empty, the policy applies to all roles. Specific roles can include:
  /// - 'anonymous': Unauthenticated users
  /// - 'authenticated': Any authenticated user
  /// - Custom roles defined in your authentication system
  ///
  /// **Example:**
  /// ```dart
  /// @RLSPolicy(
  ///   name: 'admin_access',
  ///   type: RLSPolicyType.all,
  ///   roles: ['admin', 'super_admin'],
  ///   condition: 'true',
  /// )
  ///
  /// @RLSPolicy(
  ///   name: 'public_read',
  ///   type: RLSPolicyType.select,
  ///   roles: ['anonymous', 'authenticated'],
  ///   condition: 'is_public = true',
  /// )
  /// ```
  final List<String> roles;

  /// SQL condition that must be true for the policy to apply.
  ///
  /// This is the main condition that determines whether a row is accessible
  /// to the current user. The condition is evaluated for each row and must
  /// return a boolean value.
  ///
  /// **Common patterns:**
  /// - Ownership: `user_id = auth.uid()`
  /// - Public visibility: `is_public = true`
  /// - Role-based: `auth.jwt() ->> 'role' = 'admin'`
  /// - Time-based: `created_at >= now() - interval '30 days'`
  /// - Complex: `(is_public = true) OR (user_id = auth.uid())`
  ///
  /// **Example:**
  /// ```dart
  /// @RLSPolicy(
  ///   name: 'user_own_data',
  ///   type: RLSPolicyType.all,
  ///   condition: 'user_id = auth.uid()',
  /// )
  ///
  /// @RLSPolicy(
  ///   name: 'team_members',
  ///   type: RLSPolicyType.select,
  ///   condition: '''
  ///     team_id IN (
  ///       SELECT team_id FROM team_members
  ///       WHERE user_id = auth.uid()
  ///     )
  ///   ''',
  /// )
  /// ```
  final String condition;

  /// Additional condition for INSERT and UPDATE operations.
  ///
  /// The check condition is evaluated against the new row values for
  /// INSERT operations and the updated row values for UPDATE operations.
  /// This allows you to enforce additional constraints on the data being
  /// written beyond what the main condition checks.
  ///
  /// **Example:**
  /// ```dart
  /// @RLSPolicy(
  ///   name: 'user_update_profile',
  ///   type: RLSPolicyType.update,
  ///   condition: 'user_id = auth.uid()', // Can update own records
  ///   checkCondition: 'user_id = auth.uid()', // Cannot change ownership
  /// )
  ///
  /// @RLSPolicy(
  ///   name: 'create_valid_posts',
  ///   type: RLSPolicyType.insert,
  ///   condition: 'true', // Anyone can create posts
  ///   checkCondition: 'author_id = auth.uid()', // But must set self as author
  /// )
  /// ```
  final String? checkCondition;

  /// Documentation comment for the policy.
  ///
  /// Comments help explain the business logic and security requirements
  /// that the policy implements. They are stored in the database metadata.
  ///
  /// **Example:**
  /// ```dart
  /// @RLSPolicy(
  ///   name: 'user_profile_access',
  ///   type: RLSPolicyType.all,
  ///   condition: 'user_id = auth.uid()',
  ///   comment: 'Users can only access and modify their own profile data',
  /// )
  /// ```
  final String? comment;

  /// Whether this is a permissive or restrictive policy.
  ///
  /// - Permissive policies (default): If any permissive
  /// policy passes, access is granted
  /// - Restrictive policies: All restrictive policies
  /// must pass for access to be granted
  ///
  /// Permissive policies are combined with OR logic,
  /// restrictive policies with AND logic.
  ///
  /// **Example:**
  /// ```dart
  /// @RLSPolicy(
  ///   name: 'allow_public_read',
  ///   type: RLSPolicyType.select,
  ///   condition: 'is_public = true',
  ///   isPermissive: true, // Allows access if condition is true
  /// )
  ///
  /// @RLSPolicy(
  ///   name: 'restrict_sensitive_data',
  ///   type: RLSPolicyType.select,
  ///   condition: 'sensitivity_level <= get_user_clearance(auth.uid())',
  ///   isPermissive: false, // Restricts access unless condition is true
  /// )
  /// ```
  final bool isPermissive;

  /// Validates the RLS policy configuration.
  ///
  /// This method checks for common configuration errors and returns a list
  /// of validation messages. It's called during code generation to ensure
  /// the policy definition is valid.
  ///
  /// **Parameters:**
  /// - [tableName]: The table name for context in error messages
  ///
  /// **Returns:** A list of validation error messages (empty if valid)
  List<String> validate(String tableName) {
    final errors = <String>[];

    // Policy name validation
    if (name.isEmpty) {
      errors.add('RLS policy name cannot be empty for table $tableName');
    }

    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name)) {
      errors.add(
        'RLS policy name must be a valid '
        'PostgreSQL identifier for table $tableName',
      );
    }

    if (name.length > 63) {
      errors.add(
        'RLS policy name cannot exceed 63 characters for table $tableName',
      );
    }

    // Check for PostgreSQL reserved words
    if (_isReservedWord(name)) {
      errors.add(
        'RLS policy name "$name" is a PostgreSQL '
        'reserved word for table $tableName',
      );
    }

    // Condition validation
    if (condition.trim().isEmpty) {
      errors.add(
        'RLS policy condition cannot be empty for '
        'policy "$name" in table $tableName',
      );
    }

    // Basic SQL injection protection
    if (_containsDangerousSQL(condition)) {
      errors.add(
        'RLS policy condition contains potentially '
        'dangerous SQL for policy "$name" in table $tableName',
      );
    }

    // Check condition validation (if provided)
    if (checkCondition != null) {
      if (checkCondition!.trim().isEmpty) {
        errors.add(
          'RLS policy check condition cannot be empty '
          'for policy "$name" in table $tableName',
        );
      }

      if (_containsDangerousSQL(checkCondition!)) {
        errors.add(
          'RLS policy check condition contains potentially '
          'dangerous SQL for policy "$name" in table $tableName',
        );
      }

      // Check condition is only valid for INSERT and UPDATE
      if (type != RLSPolicyType.insert &&
          type != RLSPolicyType.update &&
          type != RLSPolicyType.all) {
        errors.add(
          'Check condition can only be used with INSERT, '
          'UPDATE, or ALL policies for policy "$name" in table $tableName',
        );
      }
    }

    // Role validation
    for (final role in roles) {
      if (role.trim().isEmpty) {
        errors.add(
          'Role name cannot be empty for policy "$name" in table $tableName',
        );
      }

      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(role)) {
        errors.add(
          'Role name "$role" must be a valid identifier '
          'for policy "$name" in table $tableName',
        );
      }
    }

    // Comment validation
    if (comment != null && comment!.length > 1024) {
      errors.add(
        'RLS policy comment should not exceed 1024 '
        'characters for policy "$name" in table $tableName',
      );
    }

    return errors;
  }

  /// Checks if a name is a PostgreSQL reserved word.
  static bool _isReservedWord(String name) {
    const reservedWords = {
      'user',
      'table',
      'column',
      'index',
      'constraint',
      'primary',
      'foreign',
      'references',
      'key',
      'unique',
      'not',
      'null',
      'default',
      'check',
      'create',
      'drop',
      'alter',
      'select',
      'insert',
      'update',
      'delete',
      'from',
      'where',
      'order',
      'group',
      'having',
      'limit',
      'offset',
      'policy',
      'enable',
      'disable',
      'force',
      'row',
      'level',
      'security',
      'permissive',
      'restrictive',
      'to',
      'using',
      'with',
    };

    return reservedWords.contains(name.toLowerCase());
  }

  /// Checks for potentially dangerous SQL patterns.
  static bool _containsDangerousSQL(String sql) {
    final dangerous = [
      'drop',
      'truncate',
      'alter',
      'create',
      'grant',
      'revoke',
      ';',
      '--',
      '/*',
      '*/',
      'xp_',
      'sp_',
      'exec',
      'execute',
    ];

    final lowerSql = sql.toLowerCase();
    return dangerous.any(lowerSql.contains);
  }

  /// Generates the SQL CREATE POLICY statement.
  ///
  /// **Parameters:**
  /// - [tableName]: The name of the table to create the policy on
  ///
  /// **Returns:** The complete CREATE POLICY SQL statement
  String generateSql(String tableName) {
    // CREATE POLICY
    final parts = <String>['CREATE POLICY $name', 'ON $tableName'];

    // AS PERMISSIVE/RESTRICTIVE
    if (!isPermissive) {
      parts.add('AS RESTRICTIVE');
    }

    // FOR command
    parts.add('FOR ${type.sqlCommand}');

    // TO roles
    if (roles.isNotEmpty) {
      parts.add('TO ${roles.join(', ')}');
    }

    // USING condition
    parts.add('USING ($condition)');

    // WITH CHECK condition
    if (checkCondition != null) {
      parts.add('WITH CHECK ($checkCondition)');
    }

    return '${parts.join(' ')};';
  }

  /// Generates the SQL COMMENT statement for this policy.
  ///
  /// **Parameters:**
  /// - [tableName]: The table name for the policy
  ///
  /// **Returns:** The COMMENT ON POLICY SQL statement, or null if no comment
  String? generateCommentSql(String tableName) {
    if (comment == null) return null;

    return """
COMMENT ON POLICY $name ON $tableName IS '${comment!.replaceAll("'", "''")}';""";
  }

  /// Returns a string representation of this RLS policy configuration.
  @override
  String toString() {
    final rolesList = roles.isNotEmpty ? ' for ${roles.join(', ')}' : '';
    return 'RLSPolicy(name: $name, type: ${type.name}$rolesList)';
  }
}
