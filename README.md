# 🚀 Supabase Annotations

[![pub package](https://img.shields.io/pub/v/supabase_annotations.svg)](https://pub.dev/packages/supabase_annotations)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/ahmtydn/supabase_annotations.svg?style=social&label=Star)](https://github.com/ahmtydn/supabase_annotations)

A powerful, type-safe code generator for creating **Supabase/PostgreSQL** database schemas from Dart model classes. Build production-ready database schemas with **Row Level Security (RLS)**, **indexes**, **foreign keys**, **migrations**, and **table partitioning** - all from your Dart code.

---

## 📚 Table of Contents

- [✨ Features](#-features)
- [🚀 Quick Start](#-quick-start)
- [📖 Core Annotations](#-core-annotations)
- [🔧 Configuration](#-configuration)
- [🗄️ Column Types & Constraints](#️-column-types--constraints)
- [🔐 Security & RLS Policies](#-security--rls-policies)
- [⚡ Performance & Indexing](#-performance--indexing)
- [🔄 Migration Support](#-migration-support)
- [🎯 Advanced Examples](#-advanced-examples)
- [📝 Best Practices](#-best-practices)
- [🛠️ Development](#️-development)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## ✨ Features

### 🏗️ **Schema Generation**
- **Type-Safe SQL Generation** - Convert Dart classes to PostgreSQL schemas
- **Full PostgreSQL Support** - All column types, constraints, and features
- **Automatic Documentation** - Generate SQL comments from Dart documentation

### 🔐 **Security First**
- **Row Level Security (RLS)** - Declarative RLS policy generation
- **Fine-Grained Permissions** - Control access at the row and column level
- **Authentication Integration** - Built-in Supabase auth helpers

### ⚡ **Performance Optimization**
- **Smart Indexing** - Automatic and custom index generation
- **Query Optimization** - Composite indexes and partial indexes
- **Table Partitioning** - Range and hash partitioning support

### 🔄 **Migration & Evolution**
- **Safe Schema Evolution** - Multiple migration strategies
- **Zero-Downtime Updates** - ADD COLUMN and ALTER TABLE support
- **Rollback Support** - Safe migration with fallback options

### 🎯 **Developer Experience**
- **IDE Integration** - Full IntelliSense and code completion
- **Comprehensive Validation** - Catch errors at build time
- **Rich Documentation** - Inline help and examples

---

## 🚀 Quick Start

### 1️⃣ Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  supabase_annotations: ^1.1.1

dev_dependencies:
  build_runner: ^2.4.8
  source_gen: ^1.5.0
```

### 2️⃣ Configuration

Create `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        enabled: true
        generate_for:
          include:
            - lib/**.dart
            - example/**.dart
          exclude:
            - lib/**.g.dart
            - lib/**.schema.dart
        options:
          # 🔄 Migration Strategy
          migration_mode: 'createOrAlter'        # Safe schema evolution
          enable_column_adding: true             # Add missing columns
          generate_do_blocks: true               # PostgreSQL DO blocks
          
          # 🔐 Security Configuration
          enable_rls_by_default: false           # RLS on all tables
          
          # 📝 Code Generation
          generate_comments: true                # Include documentation
          validate_schema: true                  # Schema validation
          format_sql: true                      # Format output
```

### 3️⃣ Define Your Model

```dart
import 'package:supabase_annotations/supabase_annotations.dart';

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
@DatabaseIndex(
  name: 'users_email_idx',
  columns: ['email'],
  isUnique: true,
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
    type: ColumnType.varchar(100),
    isNullable: false,
  )
  late String fullName;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
  )
  late DateTime createdAt;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
  )
  late DateTime updatedAt;
}
```

### 4️⃣ Generate Schema

```bash
# Generate SQL schema files
dart run build_runner build

# Watch for changes and regenerate
dart run build_runner watch
```

### 5️⃣ Generated Output

```sql
-- 📄 Generated: lib/models/user.schema.sql

-- 🏗️ Create table with RLS enabled
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 🔐 Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 🛡️ Create RLS policy
CREATE POLICY users_own_data ON users 
  FOR ALL 
  USING (auth.uid() = id);

-- ⚡ Create performance indexes
CREATE UNIQUE INDEX users_email_idx ON users(email);

-- 📝 Add table comment
COMMENT ON TABLE users IS 'Application users with authentication';
```

---

## 📖 Core Annotations

### 🏗️ `@DatabaseTable`

Configure table-level settings:

```dart
@DatabaseTable(
  name: 'custom_table_name',      // 📝 Custom table name (optional)
  enableRLS: true,                // 🔐 Row Level Security
  comment: 'Table description',   // 📄 Documentation
  partitionBy: RangePartition(    // 📊 Table partitioning
    columns: ['created_at']
  ),
)
class MyTable { }
```

### 🏷️ `@DatabaseColumn`

Define column properties:

```dart
@DatabaseColumn(
  name: 'custom_column_name',     // 📝 Custom column name
  type: ColumnType.varchar(255),  // 🎯 PostgreSQL type
  isNullable: false,              // ❌ NOT NULL constraint
  isPrimaryKey: true,             // 🔑 Primary key
  isUnique: true,                 // ⭐ Unique constraint
  defaultValue: DefaultValue.currentTimestamp,  // 🔄 Default value
  comment: 'Column description',  // 📄 Documentation
  checkConstraints: ['value > 0'], // ✅ CHECK constraints
)
late String myField;
```

### 🔗 `@ForeignKey`

Define relationships:

```dart
@ForeignKey(
  table: 'users',                          // 🎯 Referenced table
  column: 'id',                           // 🔗 Referenced column
  onDelete: ForeignKeyAction.cascade,     // 🗑️ Delete behavior
  onUpdate: ForeignKeyAction.restrict,    // 🔄 Update behavior
)
@DatabaseColumn(type: ColumnType.uuid)
late String userId;
```

### ⚡ `@DatabaseIndex`

Optimize performance:

```dart
// 📊 Composite index on table
@DatabaseIndex(
  name: 'user_status_created_idx',
  columns: ['status', 'created_at'],
  type: IndexType.btree,
  isUnique: false,
  where: "status != 'deleted'",  // 🎯 Partial index
)
class User { }

// 🔍 Single column index
@DatabaseIndex(type: IndexType.hash)
@DatabaseColumn(type: ColumnType.text)
late String status;
```

### 🛡️ `@RLSPolicy`

Secure your data:

```dart
@RLSPolicy(
  name: 'user_read_own',                    // 📝 Policy name
  type: RLSPolicyType.select,              // 🎯 Operation type
  condition: 'auth.uid() = user_id',       // 🔐 Access condition
  roles: ['authenticated'],                // 👥 Database roles
  comment: 'Users can read their own data', // 📄 Documentation
)
class UserData { }
```

---

## 🔧 Configuration

### 📋 Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `migration_mode` | string | `'createOnly'` | Migration strategy |
| `enable_column_adding` | bool | `true` | Add missing columns |
| `generate_do_blocks` | bool | `true` | Use DO blocks for safety |
| `enable_rls_by_default` | bool | `false` | RLS on all tables |
| `add_timestamps` | bool | `false` | Auto-add timestamps |
| `use_explicit_nullability` | bool | `false` | Explicit NULL/NOT NULL |
| `generate_comments` | bool | `true` | Include documentation |
| `validate_schema` | bool | `true` | Schema validation |
| `format_sql` | bool | `true` | Format SQL output |

### 🎯 Environment-Specific Configurations

**🔧 Development Setup:**
```yaml
options:
  migration_mode: 'createOrAlter'    # Safe evolution
  enable_rls_by_default: false       # Easier testing
  generate_comments: true            # Full docs
  validate_schema: true              # Catch errors
  format_sql: true                  # Readable output
```

**🚀 Production Setup:**
```yaml
options:
  migration_mode: 'createOrAlter'    # Safe migrations
  enable_column_adding: true         # Allow evolution
  generate_do_blocks: true           # Extra safety
  validate_schema: true              # Strict validation
  format_sql: true                  # Clean output
```

**🤖 CI/CD Pipeline:**
```yaml
options:
  migration_mode: 'createOnly'       # Standard creation
  validate_schema: true              # Fail on errors
  generate_comments: false           # Minimal output
  format_sql: true                  # Consistent format
```

---

## 🗄️ Column Types & Constraints

### 📊 PostgreSQL Column Types

#### 📝 Text Types
```dart
ColumnType.text                    // TEXT
ColumnType.varchar(255)            // VARCHAR(255)
ColumnType.char(10)               // CHAR(10)
```

#### 🔢 Numeric Types
```dart
ColumnType.integer                 // INTEGER
ColumnType.bigint                 // BIGINT
ColumnType.decimal(10, 2)         // DECIMAL(10,2)
ColumnType.real                   // REAL
ColumnType.doublePrecision        // DOUBLE PRECISION
ColumnType.serial                 // SERIAL
ColumnType.bigserial             // BIGSERIAL
```

#### 📅 Date/Time Types
```dart
ColumnType.timestamp              // TIMESTAMP
ColumnType.timestampWithTimeZone  // TIMESTAMPTZ
ColumnType.date                   // DATE
ColumnType.time                   // TIME
ColumnType.interval              // INTERVAL
```

#### 🎯 Special Types
```dart
ColumnType.uuid                   // UUID
ColumnType.boolean               // BOOLEAN
ColumnType.json                  // JSON
ColumnType.jsonb                 // JSONB
ColumnType.bytea                 // BYTEA
ColumnType.inet                  // INET
ColumnType.macaddr              // MACADDR
ColumnType.point                // POINT
ColumnType.array(ColumnType.text) // TEXT[]
```

### 🔄 Default Values

```dart
// 📄 Literal values
DefaultValue.none                 // NULL
DefaultValue.zero                // 0
DefaultValue.one                 // 1
DefaultValue.emptyString         // ''
DefaultValue.emptyArray          // ARRAY[]
DefaultValue.emptyObject         // '{}'

// ⚡ Functions
DefaultValue.currentTimestamp    // CURRENT_TIMESTAMP
DefaultValue.currentDate         // CURRENT_DATE
DefaultValue.generateUuid        // gen_random_uuid()
DefaultValue.autoIncrement       // nextval(sequence)

// 🏭 Factory methods
DefaultValue.string('value')     // 'value'
DefaultValue.number(42)          // 42
DefaultValue.boolean(true)       // true
DefaultValue.expression('NOW()') // Custom expression
```

### ✅ Constraints

```dart
@DatabaseColumn(
  // 🔑 Primary key
  isPrimaryKey: true,
  
  // ⭐ Unique constraint
  isUnique: true,
  
  // ❌ NOT NULL constraint
  isNullable: false,
  
  // ✅ CHECK constraints
  checkConstraints: [
    'length(email) > 0',
    'email ~* \'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\$\'',
  ],
)
late String email;
```

---

## 🔐 Security & RLS Policies

### 🛡️ RLS Policy Types

```dart
RLSPolicyType.all         // 🌟 All operations (CRUD)
RLSPolicyType.select      // 👁️ Read operations only
RLSPolicyType.insert      // ➕ Insert operations only
RLSPolicyType.update      // ✏️ Update operations only
RLSPolicyType.delete      // 🗑️ Delete operations only
```

### 🎯 Common RLS Patterns

#### 👤 User Owns Data
```dart
@RLSPolicy(
  name: 'users_own_data',
  type: RLSPolicyType.all,
  condition: 'auth.uid() = user_id',
)
```

#### 🏢 Multi-tenant Isolation
```dart
@RLSPolicy(
  name: 'tenant_isolation',
  type: RLSPolicyType.all,
  condition: 'tenant_id = auth.jwt() ->> "tenant_id"',
)
```

#### 👥 Role-based Access
```dart
@RLSPolicy(
  name: 'admin_full_access',
  type: RLSPolicyType.all,
  condition: 'auth.jwt() ->> "role" = "admin"',
  roles: ['authenticated'],
)

@RLSPolicy(
  name: 'user_read_only',
  type: RLSPolicyType.select,
  condition: 'auth.jwt() ->> "role" = "user"',
  roles: ['authenticated'],
)
```

#### 🕒 Time-based Access
```dart
@RLSPolicy(
  name: 'active_records_only',
  type: RLSPolicyType.select,
  condition: 'expires_at > NOW() AND is_active = true',
)
```

---

## ⚡ Performance & Indexing

### 🔍 Index Types

```dart
IndexType.btree       // 🌳 B-tree (default, general purpose)
IndexType.hash        // #️⃣ Hash (equality only)
IndexType.gin         // 🔍 GIN (JSON, arrays, full-text)
IndexType.gist        // 🎯 GiST (geometric, full-text)
IndexType.spgist      // 📊 SP-GiST (space-partitioned)
IndexType.brin        // 📈 BRIN (large ordered tables)
```

### 📊 Index Strategies

#### 🔍 Single Column Index
```dart
@DatabaseIndex(type: IndexType.btree)
@DatabaseColumn(type: ColumnType.text)
late String status;
```

#### 📈 Composite Index
```dart
@DatabaseIndex(
  name: 'user_activity_idx',
  columns: ['user_id', 'created_at', 'activity_type'],
  type: IndexType.btree,
)
```

#### 🎯 Partial Index
```dart
@DatabaseIndex(
  name: 'active_users_idx',
  columns: ['email'],
  where: "status = 'active' AND deleted_at IS NULL",
)
```

#### 🔍 Expression Index
```dart
@DatabaseIndex(
  name: 'user_search_idx',
  expression: "to_tsvector('english', name || ' ' || email)",
  type: IndexType.gin,
)
```

#### 📱 JSON Index
```dart
@DatabaseIndex(
  name: 'metadata_search_idx',
  expression: "(metadata -> 'tags')",
  type: IndexType.gin,
)
```

---

## 🔄 Migration Support

### 🎯 Migration Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `createOnly` | Standard CREATE TABLE | 🆕 New projects |
| `createIfNotExists` | CREATE TABLE IF NOT EXISTS | 🔒 Safe creation |
| `createOrAlter` | CREATE + ALTER for new columns | 🔄 Schema evolution |
| `alterOnly` | Only ALTER TABLE statements | 🛠️ Existing schemas |
| `dropAndRecreate` | DROP and CREATE | 🧪 Development only |

### 📝 Migration Examples

#### 🆕 Adding New Column
```dart
// Add this field to existing User class
@DatabaseColumn(
  type: ColumnType.integer,
  defaultValue: DefaultValue.zero,
)
int? age;
```

**Generated Migration:**
```sql
-- 🔄 Safe column addition
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'age'
  ) THEN
    ALTER TABLE users ADD COLUMN age INTEGER DEFAULT 0;
  END IF;
END $$;
```

#### 🔗 Adding Foreign Key
```dart
// Add relationship to existing table
@ForeignKey(
  table: 'companies',
  column: 'id',
  onDelete: ForeignKeyAction.setNull,
)
@DatabaseColumn(type: ColumnType.uuid)
String? companyId;
```

**Generated Migration:**
```sql
-- 🔗 Safe foreign key addition
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'company_id'
  ) THEN
    ALTER TABLE users ADD COLUMN company_id UUID;
    ALTER TABLE users ADD CONSTRAINT users_company_id_fkey 
      FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE SET NULL;
  END IF;
END $$;
```

### 🛡️ Safe Migration Practices

```yaml
# 🎯 Recommended production configuration
options:
  migration_mode: 'createOrAlter'     # Safe evolution
  enable_column_adding: true          # Allow new columns
  generate_do_blocks: true            # Extra safety checks
  validate_schema: true               # Comprehensive validation
```

---

## 🎯 Advanced Examples

### 🏢 Multi-tenant SaaS Application

```dart
@DatabaseTable(
  name: 'documents',
  enableRLS: true,
  comment: 'Multi-tenant document storage',
)
@RLSPolicy(
  name: 'tenant_isolation',
  type: RLSPolicyType.all,
  condition: 'tenant_id = auth.jwt() ->> "tenant_id"',
)
@DatabaseIndex(
  name: 'documents_tenant_created_idx',
  columns: ['tenant_id', 'created_at'],
)
@DatabaseIndex(
  name: 'documents_search_idx',
  expression: "to_tsvector('english', title || ' ' || content)",
  type: IndexType.gin,
)
class Document {
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
  )
  String? id;

  @ForeignKey(
    table: 'tenants',
    column: 'id',
    onDelete: ForeignKeyAction.cascade,
  )
  @DatabaseColumn(
    type: ColumnType.uuid,
    isNullable: false,
  )
  late String tenantId;

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    checkConstraints: ['length(title) > 0'],
  )
  late String title;

  @DatabaseColumn(type: ColumnType.text)
  String? content;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    defaultValue: DefaultValue.emptyObject,
  )
  Map<String, dynamic>? metadata;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
  )
  late DateTime createdAt;
}
```

### 🛒 E-commerce System

```dart
@DatabaseTable(
  name: 'orders',
  enableRLS: true,
  comment: 'Customer orders with audit trail',
)
@RLSPolicy(
  name: 'customers_own_orders',
  type: RLSPolicyType.select,
  condition: 'customer_id = auth.uid()',
)
@RLSPolicy(
  name: 'staff_manage_orders',
  type: RLSPolicyType.all,
  condition: 'auth.jwt() ->> "role" IN ("admin", "staff")',
)
@DatabaseIndex(
  name: 'orders_customer_status_idx',
  columns: ['customer_id', 'status', 'created_at'],
)
@DatabaseIndex(
  name: 'orders_total_idx',
  columns: ['total_amount'],
  where: "status != 'cancelled'",
)
class Order {
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
  )
  String? id;

  @ForeignKey(
    table: 'customers',
    column: 'id',
    onDelete: ForeignKeyAction.restrict,
  )
  @DatabaseColumn(
    type: ColumnType.uuid,
    isNullable: false,
  )
  late String customerId;

  @DatabaseColumn(
    type: ColumnType.varchar(20),
    defaultValue: DefaultValue.string('pending'),
    checkConstraints: [
      "status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')"
    ],
  )
  late String status;

  @DatabaseColumn(
    type: ColumnType.decimal(10, 2),
    isNullable: false,
    checkConstraints: ['total_amount >= 0'],
  )
  late double totalAmount;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    comment: 'Order line items with product details',
  )
  List<Map<String, dynamic>>? items;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
  )
  late DateTime createdAt;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
  )
  late DateTime updatedAt;
}
```

### 📊 Analytics & Logging

```dart
@DatabaseTable(
  name: 'events',
  comment: 'Application event tracking',
  partitionBy: RangePartition(columns: ['created_at']),
)
@DatabaseIndex(
  name: 'events_type_created_idx',
  columns: ['event_type', 'created_at'],
)
@DatabaseIndex(
  name: 'events_user_session_idx',
  columns: ['user_id', 'session_id'],
  where: "user_id IS NOT NULL",
)
@DatabaseIndex(
  name: 'events_properties_idx',
  expression: "(properties -> 'category')",
  type: IndexType.gin,
)
class Event {
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
  )
  String? id;

  @DatabaseColumn(
    type: ColumnType.varchar(50),
    isNullable: false,
  )
  late String eventType;

  @DatabaseColumn(type: ColumnType.uuid)
  String? userId;

  @DatabaseColumn(type: ColumnType.uuid)
  String? sessionId;

  @DatabaseColumn(
    type: ColumnType.jsonb,
    defaultValue: DefaultValue.emptyObject,
  )
  Map<String, dynamic>? properties;

  @DatabaseColumn(
    type: ColumnType.inet,
    comment: 'Client IP address',
  )
  String? ipAddress;

  @DatabaseColumn(
    type: ColumnType.text,
    comment: 'User agent string',
  )
  String? userAgent;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.currentTimestamp,
    isNullable: false,
  )
  late DateTime createdAt;
}
```

---

## 📝 Best Practices

### 🏗️ Schema Design

#### ✅ **DO:**
- Use descriptive, meaningful names
- Follow PostgreSQL naming conventions (snake_case)
- Keep names under 63 characters
- Add comprehensive comments and documentation
- Use appropriate column types for your data

#### ❌ **DON'T:**
- Use reserved keywords as names
- Create overly complex nested structures
- Forget to add indexes on frequently queried columns
- Skip validation constraints

### 🔐 Security Guidelines

#### ✅ **DO:**
- Always enable RLS on tables with sensitive data
- Use specific, restrictive policy conditions
- Test policies thoroughly with different user roles
- Document security requirements and assumptions
- Use parameterized conditions to prevent injection

#### ❌ **DON'T:**
- Rely solely on application-level security
- Create overly permissive policies
- Forget to test edge cases in policy conditions
- Hardcode user IDs in policies

### ⚡ Performance Optimization

#### ✅ **DO:**
- Add indexes on frequently queried columns
- Use composite indexes for multi-column queries
- Consider partial indexes for filtered queries
- Use appropriate index types for your use case
- Monitor query performance regularly

#### ❌ **DON'T:**
- Create too many indexes (impacts write performance)
- Index every column "just in case"
- Forget to maintain statistics on large tables
- Ignore query execution plans

### 🔄 Migration Management

#### ✅ **DO:**
- Use migration modes for schema evolution
- Test migrations on staging data first
- Plan for rollback scenarios
- Document breaking changes thoroughly
- Use `createOrAlter` mode for production

#### ❌ **DON'T:**
- Drop tables or columns without backup
- Skip testing migrations
- Apply untested migrations to production
- Forget to version your schema changes

---

## 🛠️ Development

### 🚀 Getting Started

```bash
# Clone the repository
git clone https://github.com/ahmtydn/supabase_annotations.git
cd supabase_annotations

# Install dependencies
dart pub get

# Run tests
dart test

# Run analysis
dart analyze

# Generate documentation
dart doc
```

### 🧪 Running Examples

```bash
# Navigate to examples
cd example

# Generate schemas for all examples
dart run build_runner build

# View generated SQL files
ls lib/*.schema.sql
```

### 🔍 Project Structure

```
lib/
├── builder.dart                 # Build configuration
├── supabase_annotations.dart    # Public API
└── src/
    ├── annotations/             # Annotation definitions
    │   ├── database_column.dart
    │   ├── database_index.dart
    │   ├── database_table.dart
    │   ├── foreign_key.dart
    │   └── rls_policy.dart
    ├── generators/              # Code generation logic
    │   └── schema_generator.dart
    └── models/                  # Data models
        ├── column_types.dart
        ├── default_values.dart
        ├── foreign_key_actions.dart
        ├── index_types.dart
        ├── migration_config.dart
        ├── partition_strategy.dart
        ├── table_constraints.dart
        └── validators.dart
```

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### 🐛 Bug Reports

- Use the [issue tracker](https://github.com/ahmtydn/supabase_annotations/issues)
- Include a minimal reproduction case
- Provide environment details (Dart version, OS, etc.)

### 💡 Feature Requests

- Check existing [discussions](https://github.com/ahmtydn/supabase_annotations/discussions)
- Explain the use case and benefits
- Consider implementation complexity

### 🔧 Pull Requests

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Add** tests for new functionality
4. **Ensure** all tests pass (`dart test`)
5. **Run** analysis (`dart analyze`)
6. **Commit** changes (`git commit -m 'Add amazing feature'`)
7. **Push** to branch (`git push origin feature/amazing-feature`)
8. **Submit** a pull request

### 📋 Development Guidelines

- Follow the existing code style
- Add comprehensive tests
- Update documentation
- Include examples for new features
- Ensure backward compatibility

---

## 📞 Support & Community

### 📚 **Documentation**
- [API Reference](https://pub.dev/documentation/supabase_annotations/latest/)
- [Migration Guide](https://github.com/ahmtydn/supabase_annotations/blob/main/MIGRATION_GUIDE.md)
- [Examples](https://github.com/ahmtydn/supabase_annotations/tree/main/example)

### 💬 **Community**
- [GitHub Discussions](https://github.com/ahmtydn/supabase_annotations/discussions)
- [Issue Tracker](https://github.com/ahmtydn/supabase_annotations/issues)

### 🆘 **Need Help?**
- Check the [FAQ](https://github.com/ahmtydn/supabase_annotations/discussions/categories/q-a)
- Search existing [issues](https://github.com/ahmtydn/supabase_annotations/issues)
- Ask in [discussions](https://github.com/ahmtydn/supabase_annotations/discussions)

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Supabase Team** - For creating an amazing platform
- **Dart Team** - For excellent tooling and language features
- **PostgreSQL Community** - For the world's most advanced open source database
- **Contributors** - For making this project better

---

## 🌟 Show Your Support

If this project helped you, please consider:

- ⭐ **Star** the repository
- 🔗 **Share** with your team
- 🐛 **Report** issues
- 💡 **Suggest** improvements
- 🤝 **Contribute** code

---

<div align="center">

**Built with ❤️ for the Supabase and Dart communities**

[🌐 Website](https://github.com/ahmtydn/supabase_annotations) • [📚 Docs](https://pub.dev/packages/supabase_annotations) • [💬 Community](https://github.com/ahmtydn/supabase_annotations/discussions)

</div>
