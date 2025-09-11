# Supabase Schema Generator

A Dart package that generates PostgreSQL database schemas from annotated Dart classes, designed for Supabase projects.

## Features

🚀 **Clean Architecture**: Professional code generation  
🔧 **Type Safety**: PostgreSQL type support with Dart mapping  
🛡️ **Security**: Row Level Security (RLS) policy generation  
⚡ **Performance**: Index creation and optimization  
📝 **Documentation**: Inline documentation generation  
✅ **Validation**: Schema validation with error reporting  

## Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  supabase_schema_generator: ^2.0.0

dev_dependencies:
  build_runner: ^2.4.8
  source_gen: ^1.5.0
```

### 2. Configure Build

Create `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      supabase_schema_generator|schema_builder:
        enabled: true
        generate_for:
          include:
            - lib/**.dart
            - example/**.dart
          exclude:
            - lib/**.g.dart
            - lib/**.schema.dart
        options:
          # Schema configuration
          enable_rls_by_default: false             # Enable RLS on all tables by default
          add_timestamps: false                    # Auto-add created_at/updated_at columns
          
          # Code generation options
          use_explicit_nullability: false         # Always specify NULL/NOT NULL
          generate_comments: true                  # Include comments in SQL output
          validate_schema: true                    # Validate schema consistency
          format_sql: true                        # Format SQL for readability
          
```

### 3. Define Your Models

```dart
import 'package:supabase_schema_generator/supabase_schema_generator.dart';

@DatabaseTable(
  name: 'users',
  enableRLS: true,
  comment: 'Application users with authentication',
)
@RLSPolicy(
  name: 'users_own_data',
  type: RLSPolicyType.all,
  condition: 'auth.uid() = id',
)
class User {
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
  )
  String? id;

  @DatabaseColumn(
    type: ColumnType.text,
    isUnique: true,
    isNullable: false,
  )
  late String email;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
  )
  late DateTime createdAt;
}
```

### 4. Generate Schema

```bash
dart run build_runner build
```

This generates SQL files like:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_own_data ON users 
FOR ALL USING (auth.uid() = id);
```

## Core Annotations

### `@DatabaseTable`

Marks a class as a database table with configuration options:

```dart
@DatabaseTable(
  name: 'custom_table_name',      // Optional: defaults to snake_case class name
  enableRLS: true,                // Enable Row Level Security
  comment: 'Table description',   // Documentation comment
)
class MyTable { }
```

### `@DatabaseColumn`

Configures individual table columns:

```dart
@DatabaseColumn(
  name: 'custom_column_name',     // Optional: defaults to snake_case field name
  type: ColumnType.varchar(255),  // PostgreSQL column type
  isNullable: false,              // NULL constraint (default: true)
  isPrimaryKey: true,             // PRIMARY KEY constraint
  isUnique: true,                 // UNIQUE constraint
  defaultValue: DefaultValue.currentTimestamp,
  comment: 'Column description',
  checkConstraints: ['value > 0'], // CHECK constraints
)
late String myField;
```

### `@ForeignKey`

Defines foreign key relationships:

```dart
@ForeignKey(
  table: 'users',
  column: 'id',
  onDelete: ForeignKeyAction.cascade,
  onUpdate: ForeignKeyAction.restrict,
)
@DatabaseColumn(type: ColumnType.uuid)
late String userId;
```

### `@DatabaseIndex`

Creates database indexes for performance:

```dart
// Class-level composite index
@DatabaseIndex(
  name: 'user_email_status_idx',
  columns: ['email', 'status'],
  type: IndexType.btree,
  isUnique: true,
)
class User { }

// Field-level single column index
@DatabaseIndex(type: IndexType.hash)
@DatabaseColumn(type: ColumnType.text)
late String status;
```

### `@RLSPolicy`

Defines Row Level Security policies:

```dart
@RLSPolicy(
  name: 'user_read_own',
  type: RLSPolicyType.select,
  condition: 'auth.uid() = user_id',
  roles: ['authenticated'],
  comment: 'Users can read their own data',
)
class UserData { }
```

## Column Types

Complete PostgreSQL type support:

```dart
// Text types
ColumnType.text
ColumnType.varchar(255)
ColumnType.char(10)

// Numeric types  
ColumnType.integer
ColumnType.bigint
ColumnType.decimal(10, 2)
ColumnType.real
ColumnType.doublePrecision

// Date/Time types
ColumnType.timestamp
ColumnType.timestampWithTimeZone
ColumnType.date
ColumnType.time

// JSON types
ColumnType.json
ColumnType.jsonb

// Other types
ColumnType.uuid
ColumnType.boolean
ColumnType.bytea
ColumnType.inet
```

## Default Values

Rich default value support:

```dart
// Literal values
DefaultValue.none              // NULL
DefaultValue.zero             // 0
DefaultValue.one              // 1
DefaultValue.emptyString      // ''
DefaultValue.emptyArray       // ARRAY[]

// Functions
DefaultValue.currentTimestamp  // CURRENT_TIMESTAMP
DefaultValue.currentDate      // CURRENT_DATE
DefaultValue.generateUuid     // gen_random_uuid()
DefaultValue.autoIncrement    // nextval(sequence)

// Factory methods
DefaultValue.string('value')   // 'value'
DefaultValue.number(42)       // 42
DefaultValue.boolean(true)    // true
```

## RLS Policy Types

Control data access with fine-grained policies:

```dart
RLSPolicyType.all     // All operations (SELECT, INSERT, UPDATE, DELETE)
RLSPolicyType.select  // Read operations only
RLSPolicyType.insert  // Insert operations only  
RLSPolicyType.update  // Update operations only
RLSPolicyType.delete  // Delete operations only
```

## Foreign Key Actions

Define referential integrity behavior:

```dart
ForeignKeyAction.noAction    // Prevent deletion/update (default)
ForeignKeyAction.restrict    // Same as NO ACTION but not deferrable
ForeignKeyAction.cascade     // Delete/update referencing rows
ForeignKeyAction.setNull     // Set foreign key to NULL
ForeignKeyAction.setDefault  // Set foreign key to default value
```

## Index Types

Optimize queries with appropriate index types:

```dart
IndexType.btree    // General purpose (default)
IndexType.hash     // Equality operations only
IndexType.gin      // JSON, arrays, full-text search
IndexType.gist     // Geometric data, full-text search
IndexType.spgist   // Space-partitioned data
IndexType.brin     // Large tables with natural ordering
```

## Advanced Examples

### Multi-tenant Application

```dart
@DatabaseTable(enableRLS: true)
@RLSPolicy(
  name: 'tenant_isolation',
  type: RLSPolicyType.all,
  condition: 'tenant_id = auth.jwt() ->> "tenant_id"',
)
@DatabaseIndex(columns: ['tenant_id', 'created_at'])
class Document {
  @DatabaseColumn(type: ColumnType.uuid, isPrimaryKey: true)
  String? id;
  
  @DatabaseColumn(type: ColumnType.uuid, isNullable: false)
  late String tenantId;
  
  @DatabaseColumn(type: ColumnType.text)
  late String title;
}
```

### Full-text Search

```dart
@DatabaseTable()
@DatabaseIndex(
  type: IndexType.gin,
  expression: "to_tsvector('english', title || ' ' || content)",
)
class Article {
  @DatabaseColumn(type: ColumnType.text)
  late String title;
  
  @DatabaseColumn(type: ColumnType.text)  
  late String content;
}
```

### Audit Trail

```dart
@DatabaseTable()
@DatabaseIndex(columns: ['entity_type', 'entity_id', 'created_at'])
class AuditLog {
  @DatabaseColumn(type: ColumnType.uuid, isPrimaryKey: true)
  String? id;
  
  @DatabaseColumn(type: ColumnType.text, isNullable: false)
  late String entityType;
  
  @DatabaseColumn(type: ColumnType.uuid, isNullable: false)
  late String entityId;
  
  @DatabaseColumn(type: ColumnType.text, isNullable: false)
  late String action;
  
  @DatabaseColumn(type: ColumnType.jsonb)
  Map<String, dynamic>? changes;
  
  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
  )
  late DateTime createdAt;
}
```

## Best Practices

### 1. Naming Conventions
- Use descriptive, meaningful names
- Follow PostgreSQL naming conventions (snake_case)
- Keep names under 63 characters

### 2. RLS Security
- Always enable RLS on tables with sensitive data
- Use specific policy conditions
- Test policies thoroughly
- Document security requirements

### 3. Performance Optimization
- Add indexes on frequently queried columns
- Use partial indexes for filtered queries
- Consider composite indexes for multi-column queries
- Monitor query performance

### 4. Schema Evolution
- Use migrations for schema changes
- Test migrations on staging data
- Plan for rollback scenarios
- Document breaking changes

## Migration Workflow

1. **Define Models**: Create or modify annotated Dart classes
2. **Generate Schema**: Run `dart run build_runner build`
3. **Review SQL**: Examine generated SQL files
4. **Test Locally**: Apply to local database
5. **Create Migration**: Version and apply to production

## Configuration Options

The generator can be extensively configured via `build.yaml` options:


### Schema Configuration
- **`enable_rls_by_default`** (bool, default: `false`): Enable Row Level Security on all tables automatically
- **`add_timestamps`** (bool, default: `false`): Automatically add `created_at` and `updated_at` columns to all tables

### Code Generation Options
- **`use_explicit_nullability`** (bool, default: `false`): Always specify `NULL`/`NOT NULL` explicitly in column definitions
- **`generate_comments`** (bool, default: `true`): Include documentation comments in generated SQL
- **`validate_schema`** (bool, default: `true`): Perform comprehensive schema validation during generation
- **`format_sql`** (bool, default: `true`): Format generated SQL for better readability

### Configuration Examples

**Development Setup:**
```yaml
options:
  enable_rls_by_default: false      # Disable for easier testing
  add_timestamps: false             # Keep clean schema
  generate_comments: true           # Full documentation
  validate_schema: true             # Catch errors early
  format_sql: true                 # Readable output
```

**Production Setup:**
```yaml
options:
  enable_rls_by_default: false      # Configure as needed
  use_explicit_nullability: false   # Use defaults
  validate_schema: true             # Strict validation
  generate_comments: true           # Documentation
  format_sql: true                 # Readable output
```

**CI/CD Pipeline:**
```yaml
options:
  enable_rls_by_default: false      # Configure as needed
  validate_schema: true             # Fail on errors
  generate_comments: true           # Include documentation
  format_sql: true                 # Consistent format
```

## Validation

The package includes comprehensive validation:

- **Type Safety**: Ensures Dart types match PostgreSQL types
- **Constraint Validation**: Validates CHECK constraints and foreign keys
- **RLS Policy Validation**: Checks policy syntax and logic
- **Index Validation**: Validates index types and configurations
- **Naming Validation**: Ensures valid PostgreSQL identifiers

## Error Handling

Detailed error messages help diagnose issues:

```
Error: Column type 'VARCHAR' requires a length specification for field 'name' in table 'users'
Suggestion: Use ColumnType.varchar(255) instead of ColumnType.varchar()
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📚 [Documentation](https://pub.dev/packages/supabase_schema_generator)
- 🐛 [Issue Tracker](https://github.com/your-repo/issues)
- 💬 [Discussions](https://github.com/your-repo/discussions)
- 📧 [Email Support](mailto:support@yourproject.com)

---

Built with ❤️ for the Supabase and Dart communities.
