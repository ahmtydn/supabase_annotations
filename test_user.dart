import 'package:json_annotation/json_annotation.dart';
import 'package:supabase_annotations/supabase_annotations.dart';

@DatabaseTable(
  name: 'test_users',
  enableRLS: true,
  comment: 'Test table for storing user account information',
)
@RLSPolicy(
  name: 'test_users_own_data',
  type: RLSPolicyType.all,
  condition: 'auth.uid() = id::uuid',
  comment: 'Test users can access their own data',
)
@RLSPolicy(
  name: 'test_users_admin_access',
  type: RLSPolicyType.select,
  condition: "auth.jwt() ->> 'role' = 'admin'",
  comment: 'Admins can view all user data',
)
@DatabaseIndex(
  columns: ['email'],
  name: 'idx_test_users_email',
  isUnique: true,
  comment: 'Unique index for test user email addresses',
)
@DatabaseIndex(
  columns: ['status', 'created_at'],
  name: 'idx_test_users_status',
  comment: 'Index for user status queries',
)

/// [TestUser] is a test class that is used to
/// validate the supabase_annotations package functionality.
class TestUser {
  /// [TestUser] constructor
  const TestUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.status = 'active',
    this.createdAt,
    this.lastLoginAt,
    this.metadata,
  });

  /// [TestUser.empty()] is a factory method that is used
  /// to create a new instance of the [TestUser]
  const TestUser.empty()
      : id = '',
        displayName = '',
        email = '',
        photoUrl = null,
        status = 'active',
        createdAt = null,
        lastLoginAt = null,
        metadata = null;

  /// Unique identifier for the test user
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    comment: 'Primary key for test user records',
  )
  final String id;

  /// Display name of the test user
  @JsonKey(name: 'display_name')
  @DatabaseColumn(
    name: 'display_name',
    type: ColumnType.text,
    isNullable: false,
    comment: 'Display name of the test user',
  )
  final String displayName;

  /// Email address (required for test)
  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    isUnique: true,
    comment: 'Email address of the test user',
  )
  final String email;

  /// Profile photo URL
  @JsonKey(name: 'photo_url')
  @DatabaseColumn(
    name: 'photo_url',
    type: ColumnType.text,
    isNullable: true,
    comment: 'URL to the test user profile photo',
  )
  final String? photoUrl;

  /// User status (active, inactive, suspended)
  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    comment: 'Status of the test user account',
  )
  final String status;

  /// Account creation timestamp
  @JsonKey(name: 'created_at')
  @DatabaseColumn(
    name: 'created_at',
    type: ColumnType.timestampWithTimeZone,
    isNullable: true,
    comment: 'Account creation timestamp',
  )
  final String? createdAt;

  /// Last login timestamp
  @JsonKey(name: 'last_login_at')
  @DatabaseColumn(
    name: 'last_login_at',
    type: ColumnType.timestampWithTimeZone,
    isNullable: true,
    comment: 'Last login timestamp',
  )
  final String? lastLoginAt;

  /// Additional user metadata as JSON
  @DatabaseColumn(
    type: ColumnType.jsonb,
    isNullable: true,
    comment: 'Additional user metadata stored as JSONB',
  )
  final Map<String, dynamic>? metadata;

  /// Check if user is active
  bool get isActive => status == 'active';

  /// Get creation date
  DateTime? get creationDate {
    if (createdAt == null) return null;
    try {
      return DateTime.parse(createdAt!);
    } catch (e) {
      return null;
    }
  }

  /// Get last login date
  DateTime? get lastLoginDate {
    if (lastLoginAt == null) return null;
    try {
      return DateTime.parse(lastLoginAt!);
    } catch (e) {
      return null;
    }
  }

  /// [copyWith] is used to create a new
  /// instance of the [TestUser]
  TestUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? status,
    String? createdAt,
    String? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return TestUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
