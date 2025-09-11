# Supabase Annotations Examples

This directory contains examples demonstrating how to use the `supabase_annotations` package to generate database schemas from Dart model classes.

## Examples

### Simple Test (`simple_test.dart`)
A basic example showing how to create a simple user table with RLS policies.

### Comprehensive Example (`comprehensive_example.dart`)
A complete example demonstrating advanced features including:
- Complex data types
- Foreign key relationships
- Custom indexes
- RLS policies
- Validation rules

### Advanced Features (`advanced_features.dart`)
An example showcasing the most advanced features of the package including:
- Custom constraints
- Partitioning strategies
- Complex relationships
- Performance optimizations

## Running the Examples

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   dart pub get
   ```

3. Run the code generator:
   ```bash
   dart run build_runner build
   ```

4. Check the generated `.schema.sql` files to see the resulting database schemas.

## Generated Files

Each example generates a corresponding `.schema.sql` file containing the PostgreSQL DDL statements for creating the database tables, indexes, and policies defined in the Dart models.
