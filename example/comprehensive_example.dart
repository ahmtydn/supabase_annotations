/// Simple comprehensive example showing all Supabase Schema Generator features
library;

import 'package:supabase_annotations/supabase_annotations.dart';

/// Basic User model with essential features
@DatabaseTable(
  name: 'users',
  comment: 'User accounts table',
  enableRLS: true,
  addTimestamps: true,
  policies: [
    RLSPolicy(
      name: 'users_select_own',
      type: RLSPolicyType.select,
      roles: ['authenticated'],
      condition: 'id = auth.uid()',
      comment: 'Users can view their own data',
    ),
    RLSPolicy(
      name: 'users_update_own',
      type: RLSPolicyType.update,
      roles: ['authenticated'],
      condition: 'id = auth.uid()',
      comment: 'Users can update their own data',
    ),
  ],
  indexes: [
    DatabaseIndex(
      name: 'idx_users_email',
      columns: ['email'],
      isUnique: true,
      comment: 'Unique email index',
    ),
    DatabaseIndex(
      name: 'idx_users_username',
      columns: ['username'],
      isUnique: true,
      comment: 'Unique username index',
    ),
  ],
)
class User {
  User({
    required this.email,
    required this.username,
    this.id,
    this.firstName,
    this.lastName,
    this.age,
    this.emailVerified = false,
    this.preferences,
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
    comment: 'User email address',
    validators: [
      EmailValidator(),
      LengthValidator(min: 5, max: 255),
    ],
  )
  String email = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    isUnique: true,
    comment: 'Unique username',
    validators: [
      LengthValidator(min: 3, max: 30),
      PatternValidator(r'^[a-zA-Z0-9_]+$'),
    ],
  )
  String username = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
    comment: 'First name',
    validators: [
      LengthValidator(min: 1, max: 50),
    ],
  )
  String? firstName;

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
    comment: 'Last name',
    validators: [
      LengthValidator(min: 1, max: 50),
    ],
  )
  String? lastName;

  @DatabaseColumn(
    type: ColumnType.smallint,
    isNullable: true,
    comment: 'User age',
    validators: [
      RangeValidator(min: 13, max: 120),
    ],
  )
  int? age;

  @DatabaseColumn(
    type: ColumnType.boolean,
    isNullable: false,
    comment: 'Email verified status',
  )
  bool emailVerified = false;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    isNullable: true,
    defaultValue: DefaultValue.emptyJsonObject,
    comment: 'User preferences',
  )
  Map<String, dynamic>? preferences;
}

/// Posts table with foreign key relationships
@DatabaseTable(
  name: 'posts',
  comment: 'User posts table',
  enableRLS: true,
  addTimestamps: true,
  policies: [
    RLSPolicy(
      name: 'posts_select_all',
      type: RLSPolicyType.select,
      roles: ['authenticated', 'anon'],
      condition: 'true',
      comment: 'Everyone can read posts',
    ),
    RLSPolicy(
      name: 'posts_insert_own',
      type: RLSPolicyType.insert,
      roles: ['authenticated'],
      condition: 'user_id = auth.uid()',
      comment: 'Users can create their own posts',
    ),
    RLSPolicy(
      name: 'posts_update_own',
      type: RLSPolicyType.update,
      roles: ['authenticated'],
      condition: 'user_id = auth.uid()',
      comment: 'Users can update their own posts',
    ),
    RLSPolicy(
      name: 'posts_delete_own',
      type: RLSPolicyType.delete,
      roles: ['authenticated'],
      condition: 'user_id = auth.uid()',
      comment: 'Users can delete their own posts',
    ),
  ],
  indexes: [
    DatabaseIndex(
      name: 'idx_posts_user_id',
      columns: ['user_id'],
      comment: 'Index for user posts lookup',
    ),
    DatabaseIndex(
      name: 'idx_posts_created_at',
      columns: ['created_at'],
      comment: 'Index for chronological sorting',
    ),
    DatabaseIndex(
      name: 'idx_posts_title_content',
      columns: ['title', 'content'],
      type: IndexType.gin,
      comment: 'Full-text search index',
    ),
  ],
)
class Post {
  Post({
    required this.userId,
    required this.title,
    this.id,
    this.content,
    this.published = true,
    this.viewCount = 0,
    this.metadata,
  });
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
    comment: 'Primary key',
  )
  String? id;

  @DatabaseColumn(
    name: 'user_id',
    type: ColumnType.uuid,
    isNullable: false,
    comment: 'Post author reference',
    isIndexed: true,
  )
  @ForeignKey(
    name: 'fk_posts_user',
    table: 'users',
    column: 'id',
    onDelete: ForeignKeyAction.cascade,
    onUpdate: ForeignKeyAction.cascade,
    comment: 'Posts belong to users',
  )
  String userId = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    comment: 'Post title',
    validators: [
      LengthValidator(min: 1, max: 200),
    ],
  )
  String title = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
    comment: 'Post content',
    validators: [
      LengthValidator(max: 10000),
    ],
  )
  String? content;

  @DatabaseColumn(
    type: ColumnType.boolean,
    isNullable: false,
    comment: 'Whether post is published',
  )
  bool published = true;

  @DatabaseColumn(
    name: 'view_count',
    type: ColumnType.integer,
    isNullable: false,
    defaultValue: DefaultValue.zero,
    comment: 'Number of views',
  )
  int viewCount = 0;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    isNullable: true,
    comment: 'Post metadata',
  )
  Map<String, dynamic>? metadata;
}

/// Categories table demonstrating enum-like constraints
@DatabaseTable(
  name: 'categories',
  comment: 'Post categories',
  enableRLS: false,
  addTimestamps: false,
  indexes: [
    DatabaseIndex(
      name: 'idx_categories_name',
      columns: ['name'],
      isUnique: true,
      comment: 'Unique category names',
    ),
    DatabaseIndex(
      name: 'idx_categories_slug',
      columns: ['slug'],
      isUnique: true,
      comment: 'Unique category slugs',
    ),
  ],
)
class Category {
  Category({
    required this.name,
    required this.slug,
    this.id,
    this.description,
    this.color = '#000000',
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
    comment: 'Category name',
    validators: [
      LengthValidator(min: 1, max: 50),
    ],
  )
  String name = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    isUnique: true,
    comment: 'URL-friendly slug',
    validators: [
      LengthValidator(min: 1, max: 50),
      PatternValidator(r'^[a-z0-9-]+$'),
    ],
  )
  String slug = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
    comment: 'Category description',
    validators: [
      LengthValidator(max: 500),
    ],
  )
  String? description;

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    comment: 'Category color hex code',
    validators: [
      PatternValidator(r'^#[0-9A-Fa-f]{6}$'),
    ],
  )
  String color = '#000000';
}

/// Junction table for many-to-many relationship
@DatabaseTable(
  name: 'post_categories',
  comment: 'Post-Category relationships',
  enableRLS: true,
  addTimestamps: false,
  policies: [
    RLSPolicy(
      name: 'post_categories_select_all',
      type: RLSPolicyType.select,
      roles: ['authenticated', 'anon'],
      condition: 'true',
      comment: 'Everyone can read post categories',
    ),
    RLSPolicy(
      name: 'post_categories_manage_own',
      type: RLSPolicyType.all,
      roles: ['authenticated'],
      condition:
          'EXISTS (SELECT 1 FROM posts WHERE posts.id = post_id AND posts.user_id = auth.uid())',
      comment: 'Users can manage categories for their own posts',
    ),
  ],
  indexes: [
    DatabaseIndex(
      name: 'idx_post_categories_post_id',
      columns: ['post_id'],
      comment: 'Index for post lookup',
    ),
    DatabaseIndex(
      name: 'idx_post_categories_category_id',
      columns: ['category_id'],
      comment: 'Index for category lookup',
    ),
    DatabaseIndex(
      name: 'idx_post_categories_unique',
      columns: ['post_id', 'category_id'],
      isUnique: true,
      comment: 'Prevent duplicate associations',
    ),
  ],
)
class PostCategory {
  PostCategory({
    required this.postId,
    required this.categoryId,
  });
  @DatabaseColumn(
    name: 'post_id',
    type: ColumnType.uuid,
    isPrimaryKey: true,
    comment: 'Post reference',
  )
  @ForeignKey(
    name: 'fk_post_categories_post',
    table: 'posts',
    column: 'id',
    onDelete: ForeignKeyAction.cascade,
    onUpdate: ForeignKeyAction.cascade,
    comment: 'Link to post',
  )
  String postId = '';

  @DatabaseColumn(
    name: 'category_id',
    type: ColumnType.uuid,
    isPrimaryKey: true,
    comment: 'Category reference',
  )
  @ForeignKey(
    name: 'fk_post_categories_category',
    table: 'categories',
    column: 'id',
    onDelete: ForeignKeyAction.cascade,
    onUpdate: ForeignKeyAction.cascade,
    comment: 'Link to category',
  )
  String categoryId = '';
}
