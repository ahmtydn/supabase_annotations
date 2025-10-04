/// Comprehensive showcase of all types and features in supabase_annotations
///
/// This example demonstrates every available column type, constraint,
/// validator, index type, and advanced feature supported by the library.
library;

import 'package:meta/meta.dart';
import 'package:supabase_annotations/supabase_annotations.dart';

@immutable

/// Complete demonstration of all PostgreSQL column types and features
@DatabaseTable(
  name: 'all_types_showcase',
  comment:
      'Comprehensive example showcasing all supported PostgreSQL types and features',
  enableRLS: true,
  addTimestamps: true,
  constraints: [
    CheckConstraint(
      name: 'valid_age_range',
      condition: 'age BETWEEN 0 AND 150',
      comment: 'Ensure age is within realistic range',
    ),
    CheckConstraint(
      name: 'valid_rating',
      condition: 'rating >= 0.0 AND rating <= 5.0',
      comment: 'Rating must be between 0 and 5',
    ),
    UniqueConstraint(
      name: 'unique_email_tenant',
      columns: ['email', 'tenant_id'],
      comment: 'Email must be unique per tenant',
    ),
    PrimaryKeyConstraint(
      name: 'pk_showcase_id',
      columns: ['id'],
      comment: 'Primary key constraint',
    ),
  ],
  policies: [
    RLSPolicy(
      name: 'showcase_select_policy',
      type: RLSPolicyType.select,
      roles: ['authenticated', 'anon'],
      condition: "tenant_id = auth.jwt() ->> 'tenant_id'",
      comment: 'Users can only access data from their tenant',
    ),
    RLSPolicy(
      name: 'showcase_insert_policy',
      type: RLSPolicyType.insert,
      roles: ['authenticated'],
      condition: "auth.role() = 'authenticated'",
      comment: 'Only authenticated users can insert data',
    ),
    RLSPolicy(
      name: 'showcase_update_policy',
      type: RLSPolicyType.update,
      roles: ['authenticated'],
      condition: 'created_by = auth.uid()',
      comment: 'Users can only update their own records',
    ),
    RLSPolicy(
      name: 'showcase_delete_policy',
      type: RLSPolicyType.delete,
      roles: ['authenticated'],
      condition: 'created_by = auth.uid() AND deleted_at IS NULL',
      comment: 'Users can only soft-delete their own records',
    ),
  ],
  indexes: [
    // B-tree indexes (default)
    DatabaseIndex(
      name: 'btree_email_idx',
      columns: ['email'],
      isUnique: true,
      comment: 'B-tree index for email lookups',
    ),
    DatabaseIndex(
      name: 'btree_age_range_idx',
      columns: ['age'],
      comment: 'B-tree index for age range queries',
    ),

    // Hash index for exact matches
    DatabaseIndex(
      name: 'hash_status_idx',
      columns: ['status'],
      type: IndexType.hash,
      comment: 'Hash index for exact status matching',
    ),

    // GIN index for JSONB and arrays
    DatabaseIndex(
      name: 'gin_metadata_idx',
      columns: ['metadata'],
      type: IndexType.gin,
      comment: 'GIN index for JSONB queries',
    ),
    DatabaseIndex(
      name: 'gin_tags_idx',
      columns: ['tags'],
      type: IndexType.gin,
      comment: 'GIN index for array operations',
    ),

    // GiST index for geometric data
    DatabaseIndex(
      name: 'gist_location_idx',
      columns: ['location'],
      type: IndexType.gist,
      comment: 'GiST index for geometric queries',
    ),

    // BRIN index for large tables with natural ordering
    DatabaseIndex(
      name: 'brin_created_at_idx',
      columns: ['created_at'],
      type: IndexType.brin,
      comment: 'BRIN index for time-series data',
    ),

    // Composite indexes
    DatabaseIndex(
      name: 'composite_tenant_status_idx',
      columns: ['tenant_id', 'status', 'created_at'],
      comment: 'Composite index for tenant-based queries',
    ),
  ],
)
class AllTypesShowcase {
  const AllTypesShowcase({
    // Required fields
    required this.email,
    required this.username,

    // Optional fields with defaults
    this.id,
    this.tenantId,
    this.firstName,
    this.lastName,
    this.age,
    this.isActive,
    this.rating,
    this.salary,
    this.description,
    this.biography,
    this.avatar,
    this.birthDate,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.sessionDuration,
    this.profileId,
    this.metadata,
    this.settings,
    this.tags,
    this.skills,
    this.phoneNumbers,
    this.ipAddress,
    this.networkMask,
    this.macAddress,
    this.location,
    this.boundary,
    this.region,
    this.status,
    this.priority,
    this.data,
    this.encryptedData,
    this.coordinates,
    this.measurements,
    this.prices,
    this.versions,
    this.flags,
    this.config,
    this.createdBy,
    this.statuses,
  });

  /// Factory constructor for creating test instances
  factory AllTypesShowcase.example() {
    return const AllTypesShowcase(
      email: 'john.doe@example.com',
      username: 'johndoe123',
      firstName: 'John',
      lastName: 'Doe',
      age: 30,
      isActive: true,
      rating: 4.5,
      salary: 75000,
      description: 'Senior Software Developer with 10 years of experience',
      tags: ['developer', 'postgresql', 'flutter'],
      skills: ['Dart', 'PostgreSQL', 'Flutter', 'Supabase'],
      metadata: {
        'preferences': {'theme': 'dark', 'notifications': true},
        'profile_completion': 85.0,
        'badges': ['early_adopter', 'contributor']
      },
      location: {'x': 40.7128, 'y': -74.0060}, // NYC coordinates
      status: UserStatus.active,
      priority: 'normal',
      statuses: [UserStatus.active, UserStatus.pending],
    );
  }

  // UUID Primary Key with auto-generation
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
    comment: 'Unique identifier using UUID v4',
  )
  final String? id;

  // Text columns with various constraints and validators
  @DatabaseColumn(
    type: ColumnType.varchar(255),
    isNullable: false,
    isUnique: true,
    validators: [
      EmailValidator(),
      LengthValidator(min: 5, max: 255),
    ],
    comment: 'User email address (unique, validated)',
  )
  final String email;

  @DatabaseColumn(
    type: ColumnType.varchar(50),
    isNullable: false,
    isUnique: true,
    validators: [
      LengthValidator(min: 3, max: 50),
      PatternValidator(r'^[a-zA-Z0-9_]+$',
          'Username can only contain letters, numbers, and underscores'),
    ],
    comment: 'Unique username for login',
  )
  final String username;

  @DatabaseColumn(
    type: ColumnType.varchar(100),
    validators: [
      LengthValidator(min: 1, max: 100),
      AlphaValidator(allowSpaces: true),
    ],
    comment: 'First name (alphabetic characters only)',
  )
  final String? firstName;

  @DatabaseColumn(
    type: ColumnType.varchar(100),
    validators: [
      LengthValidator(min: 1, max: 100),
      AlphaValidator(allowSpaces: true),
    ],
    comment: 'Last name (alphabetic characters only)',
  )
  final String? lastName;

  @DatabaseColumn(
    type: ColumnType.text,
    validators: [
      LengthValidator(max: 1000),
    ],
    comment: 'Short description or bio',
  )
  final String? description;

  @DatabaseColumn(
    type: ColumnType.text,
    comment: 'Extended biography or profile information',
  )
  final String? biography;

  // Numeric types with various precisions
  @DatabaseColumn(
    type: ColumnType.smallint,
    validators: [
      RangeValidator(min: 0, max: 150),
    ],
    comment: 'Age in years (0-150)',
  )
  final int? age;

  @DatabaseColumn(
    type: ColumnType.serial,
    comment: 'Auto-incrementing tenant identifier',
  )
  final int? tenantId;

  @DatabaseColumn(
    type: ColumnType.decimal(10, 2),
    validators: [
      RangeValidator(min: 0, max: 999999.99),
    ],
    comment: 'Salary with 2 decimal places',
  )
  final double? salary;

  @DatabaseColumn(
    type: ColumnType.real,
    validators: [
      RangeValidator(min: 0.0, max: 5.0),
    ],
    comment: 'Rating from 0.0 to 5.0',
  )
  final double? rating;

  // Boolean type
  @DatabaseColumn(
    type: ColumnType.boolean,
    defaultValue: DefaultValue.boolean(value: true),
    comment: 'Whether the user account is active',
  )
  final bool? isActive;

  // Date and time types
  @DatabaseColumn(
    type: ColumnType.date,
    comment: 'Birth date (date only)',
  )
  final DateTime? birthDate;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    comment: 'Last login timestamp with timezone',
  )
  final DateTime? lastLogin;

  @DatabaseColumn(
    type: ColumnType.timestamp,
    defaultValue: DefaultValue.currentTimestamp,
    comment: 'Record creation timestamp',
  )
  final DateTime? createdAt;

  @DatabaseColumn(
    type: ColumnType.timestamp,
    defaultValue: DefaultValue.currentTimestamp,
    comment: 'Record last update timestamp',
  )
  final DateTime? updatedAt;

  @DatabaseColumn(
    type: ColumnType.timestamp,
    comment: 'Soft delete timestamp',
  )
  final DateTime? deletedAt;

  @DatabaseColumn(
    type: ColumnType.interval,
    comment: 'Session duration as interval',
  )
  final Duration? sessionDuration;

  // UUID type for foreign keys
  @DatabaseColumn(
    type: ColumnType.uuid,
    comment: 'Foreign key to profiles table',
  )
  final String? profileId;

  @DatabaseColumn(
    type: ColumnType.uuid,
    comment: 'Creator of this record',
  )
  final String? createdBy;

  // JSON types
  @DatabaseColumn(
    type: ColumnType.jsonb,
    defaultValue: DefaultValue.emptyJsonObject,
    comment: 'Flexible metadata storage as JSONB',
  )
  final Map<String, dynamic>? metadata;

  @DatabaseColumn(
    type: ColumnType.json,
    defaultValue:
        DefaultValue.jsonObject('{"theme": "light", "language": "en"}'),
    comment: 'User settings as JSON',
  )
  final Map<String, dynamic>? settings;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    defaultValue: DefaultValue.emptyJsonArray,
    comment: 'Configuration data as JSONB array',
  )
  final Map<String, dynamic>? config;

  // Array types
  @DatabaseColumn(
    type: ColumnType.array(ColumnType.text),
    defaultValue: DefaultValue.emptyArray,
    comment: 'Array of user tags',
  )
  final List<String>? tags;

  @DatabaseColumn(
    type: ColumnType.array(ColumnType.varchar(100)),
    comment: 'Array of user skills',
  )
  final List<String>? skills;

  @DatabaseColumn(
    type: ColumnType.array(ColumnType.varchar(20)),
    comment: 'Array of phone numbers',
  )
  final List<String>? phoneNumbers;

  @DatabaseColumn(
    type: ColumnType.array(ColumnType.integer),
    comment: 'Array of version numbers',
  )
  final List<int>? versions;

  @DatabaseColumn(
    type: ColumnType.array(ColumnType.decimal(10, 2)),
    comment: 'Array of prices',
  )
  final List<double>? prices;

  @DatabaseColumn(
    type: ColumnType.array(ColumnType.real),
    comment: 'Array of measurements',
  )
  final List<double>? measurements;

  @DatabaseColumn(
    type: ColumnType.array(ColumnType.boolean),
    comment: 'Array of feature flags',
  )
  final List<bool>? flags;

  // Binary type
  @DatabaseColumn(
    type: ColumnType.bytea,
    comment: 'Avatar image data as binary',
  )
  final List<int>? avatar;

  @DatabaseColumn(
    type: ColumnType.bytea,
    comment: 'Encrypted sensitive data',
  )
  final List<int>? encryptedData;

  @DatabaseColumn(
    type: ColumnType.bytea,
    comment: 'Raw binary data storage',
  )
  final List<int>? data;

  // Enum array type
  @DatabaseColumn(
    type: ColumnType.array(ColumnType.enumType('user_status')),
    comment: 'Array of user statuses',
  )
  final List<UserStatus>? statuses;

  // Network types
  @DatabaseColumn(
    type: ColumnType.inet,
    validators: [
      PatternValidator(
        r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
        'Must be a valid IP address',
      ),
    ],
    comment: 'IP address with optional subnet',
  )
  final String? ipAddress;

  @DatabaseColumn(
    type: ColumnType.cidr,
    comment: 'Network address with subnet mask',
  )
  final String? networkMask;

  @DatabaseColumn(
    type: ColumnType.macaddr,
    validators: [
      PatternValidator(
        r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
        'Must be a valid MAC address',
      ),
    ],
    comment: 'MAC address',
  )
  final String? macAddress;

  // Geometric types
  @DatabaseColumn(
    type: ColumnType.point,
    comment: 'Geographic location as point (x,y)',
  )
  final Map<String, double>? location;

  @DatabaseColumn(
    type: ColumnType.box,
    comment: 'Rectangular boundary',
  )
  final Map<String, dynamic>? boundary;

  @DatabaseColumn(
    type: ColumnType.circle,
    comment: 'Circular region',
  )
  final Map<String, dynamic>? region;

  @DatabaseColumn(
    type: ColumnType.array(ColumnType.point),
    comment: 'Array of coordinate points',
  )
  final List<Map<String, double>>? coordinates;

  // Custom enum types
  @DatabaseColumn(
    type: ColumnType.enumType('user_status'),
    defaultValue: DefaultValue.string('active'),
    validators: [
      EnumValidator(['active', 'inactive', 'suspended', 'pending']),
    ],
    comment: 'User account status',
  )
  final UserStatus? status;

  @DatabaseColumn(
    type: ColumnType.enumType('priority_level'),
    defaultValue: DefaultValue.string('normal'),
    validators: [
      EnumValidator(['low', 'normal', 'high', 'urgent']),
    ],
    comment: 'Priority level for processing',
  )
  final String? priority;

  @override
  String toString() {
    return 'AllTypesShowcase{'
        'id: $id, '
        'email: $email, '
        'username: $username, '
        'firstName: $firstName, '
        'lastName: $lastName, '
        'age: $age, '
        'isActive: $isActive, '
        'rating: $rating, '
        'salary: $salary, '
        'status: $status'
        '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllTypesShowcase &&
        other.id == id &&
        other.email == email &&
        other.username == username;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, username);
  }
}

/// Additional enum types that would be created in the database
/// These would typically be created with separate SQL statements

enum UserStatus {
  active,
  inactive,
  suspended,
  pending,
}

enum PriorityLevel {
  low,
  normal,
  high,
  urgent,
}

/// Related table example showing foreign key relationships
@DatabaseTable(
  name: 'profiles',
  comment: 'Extended user profile information',
  enableRLS: true,
  indexes: [
    DatabaseIndex(
      name: 'profiles_user_id_idx',
      columns: ['user_id'],
      isUnique: true,
      comment: 'One profile per user',
    ),
  ],
)
class Profile {
  Profile({
    required this.userId,
    this.id,
    this.displayName,
    this.bio,
    this.websiteUrl,
    this.socialLinks,
    this.preferences,
  });

  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
    comment: 'Profile unique identifier',
  )
  final String? id;

  @DatabaseColumn(
    type: ColumnType.uuid,
    isNullable: false,
    comment: 'Foreign key to user table',
  )
  final String userId;

  @DatabaseColumn(
    type: ColumnType.varchar(100),
    validators: [
      LengthValidator(min: 1, max: 100),
    ],
    comment: 'Display name for profile',
  )
  final String? displayName;

  @DatabaseColumn(
    type: ColumnType.text,
    validators: [
      LengthValidator(max: 500),
    ],
    comment: 'Profile biography',
  )
  final String? bio;

  @DatabaseColumn(
    type: ColumnType.text,
    validators: [
      UrlValidator(),
    ],
    comment: 'Personal website URL',
  )
  final String? websiteUrl;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    defaultValue: DefaultValue.emptyJsonObject,
    comment: 'Social media links as JSONB',
  )
  final Map<String, dynamic>? socialLinks;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    defaultValue: DefaultValue.jsonObject(
        '{"theme": "system", "language": "en", "timezone": "UTC"}'),
    comment: 'User preferences and settings',
  )
  final Map<String, dynamic>? preferences;
}
