/// Role management system example
library;

import 'package:supabase_schema_generator/supabase_schema_generator.dart';

/// User roles table
@DatabaseTable(
  name: 'user_roles',
  comment: 'User roles and permissions',
  enableRLS: true,
  addTimestamps: true,
  policies: [
    RLSPolicy(
      name: 'roles_select_all',
      type: RLSPolicyType.select,
      roles: ['authenticated'],
      condition: 'true',
      comment: 'All authenticated users can view roles',
    ),
    RLSPolicy(
      name: 'roles_manage_admin',
      type: RLSPolicyType.all,
      roles: ['admin'],
      condition: 'true',
      comment: 'Only admins can manage roles',
    ),
  ],
  indexes: [
    DatabaseIndex(
      name: 'idx_roles_name',
      columns: ['name'],
      isUnique: true,
      comment: 'Unique role names',
    ),
    DatabaseIndex(
      name: 'idx_roles_level',
      columns: ['level'],
      comment: 'Role level for hierarchy',
    ),
  ],
)
class UserRole {
  UserRole({
    required this.name,
    this.id,
    this.description,
    this.level = 0,
    this.permissions,
    this.active = true,
  });
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
    comment: 'Primary key',
  )
  String? id;

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    isUnique: true,
    comment: 'Role name',
    validators: [
      LengthValidator(min: 2, max: 50),
      PatternValidator(r'^[a-z_]+$'),
    ],
  )
  String name = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
    comment: 'Role description',
    validators: [
      LengthValidator(max: 500),
    ],
  )
  String? description;

  @DatabaseColumn(
    type: ColumnType.smallint,
    isNullable: false,
    defaultValue: DefaultValue.zero,
    comment: 'Role hierarchy level (higher = more permissions)',
    validators: [
      RangeValidator(min: 0, max: 100),
    ],
  )
  int level = 0;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    isNullable: true,
    defaultValue: DefaultValue.emptyJsonArray,
    comment: 'Role permissions array',
  )
  List<String>? permissions;

  @DatabaseColumn(
    type: ColumnType.boolean,
    isNullable: false,
    comment: 'Whether role is active',
  )
  bool active = true;
}

/// User sessions table with comprehensive tracking
@DatabaseTable(
  name: 'user_sessions',
  comment: 'User session tracking',
  enableRLS: true,
  addTimestamps: false,
  policies: [
    RLSPolicy(
      name: 'sessions_select_own',
      type: RLSPolicyType.select,
      roles: ['authenticated'],
      condition: 'user_id = auth.uid()',
      comment: 'Users can view their own sessions',
    ),
    RLSPolicy(
      name: 'sessions_delete_own',
      type: RLSPolicyType.delete,
      roles: ['authenticated'],
      condition: 'user_id = auth.uid()',
      comment: 'Users can delete their own sessions',
    ),
    RLSPolicy(
      name: 'sessions_admin_all',
      type: RLSPolicyType.all,
      roles: ['admin'],
      condition: 'true',
      comment: 'Admins can manage all sessions',
    ),
  ],
  indexes: [
    DatabaseIndex(
      name: 'idx_sessions_user_id',
      columns: ['user_id'],
      comment: 'User sessions lookup',
    ),
    DatabaseIndex(
      name: 'idx_sessions_token',
      columns: ['session_token'],
      type: IndexType.hash,
      isUnique: true,
      comment: 'Fast token lookup',
    ),
    DatabaseIndex(
      name: 'idx_sessions_expires_at',
      columns: ['expires_at'],
      comment: 'Session expiry cleanup',
    ),
    DatabaseIndex(
      name: 'idx_sessions_ip_address',
      columns: ['ip_address'],
      comment: 'IP-based analysis',
    ),
  ],
)
class UserSession {
  UserSession({
    required this.userId,
    required this.sessionToken,
    required this.expiresAt,
    this.id,
    this.createdAt,
    this.lastAccessedAt,
    this.ipAddress,
    this.userAgent,
    this.deviceType,
    this.isActive = true,
    this.metadata,
  });
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
    comment: 'Session ID',
  )
  String? id;

  @DatabaseColumn(
    name: 'user_id',
    type: ColumnType.uuid,
    isNullable: false,
    comment: 'User reference',
    isIndexed: true,
  )
  @ForeignKey(
    name: 'fk_sessions_user',
    table: 'users',
    column: 'id',
    onDelete: ForeignKeyAction.cascade,
    onUpdate: ForeignKeyAction.cascade,
    comment: 'Sessions belong to users',
  )
  String userId = '';

  @DatabaseColumn(
    name: 'session_token',
    type: ColumnType.text,
    isNullable: false,
    isUnique: true,
    comment: 'Unique session token',
    validators: [
      LengthValidator(min: 32, max: 255),
    ],
  )
  String sessionToken = '';

  @DatabaseColumn(
    name: 'created_at',
    type: ColumnType.timestampWithTimeZone,
    isNullable: false,
    defaultValue: DefaultValue.currentTimestamp,
    comment: 'Session creation time',
  )
  DateTime? createdAt;

  @DatabaseColumn(
    name: 'expires_at',
    type: ColumnType.timestampWithTimeZone,
    isNullable: false,
    comment: 'Session expiration time',
  )
  DateTime expiresAt = DateTime.now();

  @DatabaseColumn(
    name: 'last_accessed_at',
    type: ColumnType.timestampWithTimeZone,
    isNullable: true,
    comment: 'Last session access time',
  )
  DateTime? lastAccessedAt;

  @DatabaseColumn(
    name: 'ip_address',
    type: ColumnType.text,
    isNullable: true,
    comment: 'Client IP address',
    validators: [
      PatternValidator(
        r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$|^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$',
      ),
    ],
  )
  String? ipAddress;

  @DatabaseColumn(
    name: 'user_agent',
    type: ColumnType.text,
    isNullable: true,
    comment: 'Client user agent string',
    validators: [
      LengthValidator(max: 1000),
    ],
  )
  String? userAgent;

  @DatabaseColumn(
    name: 'device_type',
    type: ColumnType.text,
    isNullable: true,
    comment: 'Device type (mobile, desktop, tablet)',
    checkConstraints: [
      "device_type IN ('mobile', 'desktop', 'tablet', 'unknown')",
    ],
  )
  String? deviceType;

  @DatabaseColumn(
    name: 'is_active',
    type: ColumnType.boolean,
    isNullable: false,
    comment: 'Whether session is currently active',
  )
  bool isActive = true;

  @DatabaseColumn(
    name: 'metadata',
    type: ColumnType.jsonb,
    isNullable: true,
    comment: 'Additional session metadata',
  )
  Map<String, dynamic>? metadata;
}

/// Activity logs for audit trail
@DatabaseTable(
  name: 'activity_logs',
  comment: 'User activity audit trail',
  enableRLS: true,
  addTimestamps: false,
  policies: [
    RLSPolicy(
      name: 'logs_select_own',
      type: RLSPolicyType.select,
      roles: ['authenticated'],
      condition: 'user_id = auth.uid()',
      comment: 'Users can view their own activity',
    ),
    RLSPolicy(
      name: 'logs_insert_own',
      type: RLSPolicyType.insert,
      roles: ['authenticated'],
      condition: 'user_id = auth.uid()',
      comment: 'Users can log their own activity',
    ),
    RLSPolicy(
      name: 'logs_admin_all',
      type: RLSPolicyType.all,
      roles: ['admin'],
      condition: 'true',
      comment: 'Admins can access all logs',
    ),
  ],
  indexes: [
    DatabaseIndex(
      name: 'idx_logs_user_id',
      columns: ['user_id'],
      comment: 'User activity lookup',
    ),
    DatabaseIndex(
      name: 'idx_logs_action_timestamp',
      columns: ['action', 'timestamp'],
      comment: 'Action-based queries with time',
    ),
    DatabaseIndex(
      name: 'idx_logs_timestamp',
      columns: ['timestamp'],
      type: IndexType.brin,
      comment: 'Time-based queries (BRIN for large datasets)',
    ),
    DatabaseIndex(
      name: 'idx_logs_resource',
      columns: ['resource_type', 'resource_id'],
      comment: 'Resource-based activity lookup',
    ),
  ],
)
class ActivityLog {
  ActivityLog({
    required this.action,
    this.id,
    this.userId,
    this.resourceType,
    this.resourceId,
    this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.details,
    this.oldValues,
    this.newValues,
  });
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
    comment: 'Log entry ID',
  )
  String? id;

  @DatabaseColumn(
    name: 'user_id',
    type: ColumnType.uuid,
    isNullable: true,
    comment: 'User who performed the action (null for system)',
    isIndexed: true,
  )
  @ForeignKey(
    name: 'fk_logs_user',
    table: 'users',
    column: 'id',
    onDelete: ForeignKeyAction.setNull,
    onUpdate: ForeignKeyAction.cascade,
    comment: 'Optional user reference',
  )
  String? userId;

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    comment: 'Action performed',
    validators: [
      LengthValidator(min: 1, max: 100),
      PatternValidator(r'^[a-z_]+$'),
    ],
    checkConstraints: [
      "action IN ('login', 'logout', 'create', 'update', 'delete', 'view', 'admin_action')",
    ],
  )
  String action = '';

  @DatabaseColumn(
    name: 'resource_type',
    type: ColumnType.text,
    isNullable: true,
    comment: 'Type of resource affected',
    validators: [
      LengthValidator(min: 1, max: 50),
    ],
  )
  String? resourceType;

  @DatabaseColumn(
    name: 'resource_id',
    type: ColumnType.text,
    isNullable: true,
    comment: 'ID of resource affected',
    validators: [
      LengthValidator(min: 1, max: 255),
    ],
  )
  String? resourceId;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    isNullable: false,
    defaultValue: DefaultValue.currentTimestamp,
    comment: 'When the action occurred',
  )
  DateTime? timestamp;

  @DatabaseColumn(
    name: 'ip_address',
    type: ColumnType.text,
    isNullable: true,
    comment: 'Client IP address',
  )
  String? ipAddress;

  @DatabaseColumn(
    name: 'user_agent',
    type: ColumnType.text,
    isNullable: true,
    comment: 'Client user agent',
  )
  String? userAgent;

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
    comment: 'Additional details about the action',
    validators: [
      LengthValidator(max: 1000),
    ],
  )
  String? details;

  @DatabaseColumn(
    name: 'old_values',
    type: ColumnType.jsonb,
    isNullable: true,
    comment: 'Previous values (for updates)',
  )
  Map<String, dynamic>? oldValues;

  @DatabaseColumn(
    name: 'new_values',
    type: ColumnType.jsonb,
    isNullable: true,
    comment: 'New values (for creates/updates)',
  )
  Map<String, dynamic>? newValues;
}
