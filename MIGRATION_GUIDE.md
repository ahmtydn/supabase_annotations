# Migration Support Documentation

## Overview

The Supabase Annotations package now includes comprehensive migration support to handle existing database schemas gracefully. Instead of generating `CREATE TABLE` statements that fail when tables already exist, you can now configure the generator to produce migration-safe SQL.

## Migration Modes

### 1. `createOnly` (Default)
- **Behavior**: Original behavior - generates `CREATE TABLE` statements
- **Use Case**: Initial database setup or when you're certain tables don't exist
- **Output**: Standard `CREATE TABLE table_name (...);`

```yaml
# build.yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        options:
          migration_mode: 'createOnly'
```

### 2. `createIfNotExists` 
- **Behavior**: Generates `CREATE TABLE IF NOT EXISTS` statements
- **Use Case**: Safe table creation that won't fail if tables already exist
- **Output**: `CREATE TABLE IF NOT EXISTS table_name (...);`

```yaml
# build.yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        options:
          migration_mode: 'createIfNotExists'
```

### 3. `createOrAlter`
- **Behavior**: Creates table if not exists, then adds missing columns
- **Use Case**: Schema evolution - handles both new tables and field additions
- **Output**: 
  - `CREATE TABLE IF NOT EXISTS table_name (...);`
  - Followed by conditional `ALTER TABLE ADD COLUMN` statements

```yaml
# build.yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        options:
          migration_mode: 'createOrAlter'
          enable_column_adding: true
          generate_do_blocks: true
```

### 4. `alterOnly`
- **Behavior**: Only generates `ALTER TABLE` statements to add missing columns
- **Use Case**: When you only want to add new fields to existing tables
- **Output**: Only conditional `ALTER TABLE ADD COLUMN` statements

```yaml
# build.yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        options:
          migration_mode: 'alterOnly'
          enable_column_adding: true
```

### 5. `dropAndRecreate`
- **Behavior**: Drops existing table and creates fresh one (destructive)
- **Use Case**: Development environments where data loss is acceptable
- **Output**: 
  - `DROP TABLE IF EXISTS table_name CASCADE;`
  - Followed by `CREATE TABLE table_name (...);`

```yaml
# build.yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        options:
          migration_mode: 'dropAndRecreate'
```

## Configuration Options

### Basic Migration Options

```yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        options:
          # Migration strategy
          migration_mode: 'createOrAlter'  # Required
          
          # Column management
          enable_column_adding: true        # Add missing columns
          enable_column_modification: true  # Modify existing columns
          enable_column_dropping: false     # Drop unused columns (dangerous)
          
          # Additional features
          enable_index_creation: true       # Create missing indexes
          enable_constraint_modification: true  # Modify constraints
          generate_do_blocks: true          # Use PostgreSQL DO blocks for conditionals
          
          # Standard options
          format_sql: true
          generate_comments: true
```

### DO Blocks vs Simple Statements

When `generate_do_blocks: true` (recommended), the generator produces PostgreSQL DO blocks for safer conditional operations:

```sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'age'
  ) THEN
    ALTER TABLE users ADD COLUMN age INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;
```

When `generate_do_blocks: false`, it uses simpler statements (PostgreSQL 9.6+):

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS age INTEGER NOT NULL DEFAULT 0;
```

## Example Usage

### Development Workflow

1. **Initial Setup**: Use `createOnly` or `createIfNotExists`
2. **Schema Evolution**: Use `createOrAlter` when adding new fields
3. **Field-Only Updates**: Use `alterOnly` for incremental updates
4. **Reset Development DB**: Use `dropAndRecreate` when needed

### Production Deployment

For production environments, use `createOrAlter` or `alterOnly` to safely handle schema changes:

```yaml
# production-build.yaml
targets:
  $default:
    builders:
      supabase_annotations|schema_builder:
        options:
          migration_mode: 'createOrAlter'
          enable_column_adding: true
          enable_column_modification: false  # Be conservative in production
          enable_column_dropping: false     # Never drop columns in production
          generate_do_blocks: true           # Use safe conditional logic
```

## Example Output

Given this Dart class:

```dart
@DatabaseTable(name: 'users')
class User {
  @DatabaseColumn(type: ColumnType.uuid, isPrimaryKey: true)
  String? id;
  
  @DatabaseColumn(type: ColumnType.text, isUnique: true)
  String email = '';
  
  @DatabaseColumn(type: ColumnType.integer, defaultValue: DefaultValue.number(0))
  int age = 0;  // New field added later
}
```

### createIfNotExists Output:
```sql
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  age INTEGER NOT NULL DEFAULT 0
);
```

### createOrAlter Output:
```sql
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  age INTEGER NOT NULL DEFAULT 0
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'age'
  ) THEN
    ALTER TABLE users ADD COLUMN age INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;
```

### alterOnly Output:
```sql
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'age'
  ) THEN
    ALTER TABLE users ADD COLUMN age INTEGER NOT NULL DEFAULT 0;
  END IF;
END $$;
```

## Migration Best Practices

1. **Always backup** before running migration scripts in production
2. **Test migrations** in a development environment first
3. **Use transactions** when executing multiple migration statements
4. **Monitor performance** as ALTER TABLE can be slow on large tables
5. **Consider column order** - new columns are added at the end
6. **Validate constraints** before enabling them on existing data

## Troubleshooting

### Common Issues

1. **Column already exists errors**: Use `createOrAlter` or `alterOnly` mode
2. **Permission errors**: Ensure database user has ALTER TABLE privileges
3. **Large table performance**: Consider adding columns with NULL defaults first
4. **Data type conflicts**: Test type changes carefully in development

### PostgreSQL Version Requirements

- **DO Blocks**: PostgreSQL 9.0+
- **IF NOT EXISTS**: PostgreSQL 9.1+ for CREATE TABLE, 9.6+ for ALTER TABLE
- **ADD COLUMN IF NOT EXISTS**: PostgreSQL 9.6+

Choose `generate_do_blocks: true` for maximum compatibility.
