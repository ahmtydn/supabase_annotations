# Changelog

All notable changes to the Supabase Annotations package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.5]

### Fixed
- **🔧 Constant Expressions**: Resolved "Methods can't be invoked in constant expressions" errors for `ColumnType` factory constructors
- **📝 Default Values**: Fixed `DefaultValue.jsonObject()`, `DefaultValue.nextVal()`, and `DefaultValue.expression()` to work in const contexts
- **✅ Validators**: Removed dynamic types and made all validators properly generic typed (`EnumValidator`, `AndValidator`, `OrValidator`)
- **🎯 Type Safety**: Complete elimination of `dynamic` types throughout the validator system
- **🚫 Assert Issues**: Fixed `EnumValidator` const assertion that accessed `.length` property in constant expressions

### Improved
- **🔄 Factory Constructors**: Converted static methods to const factory constructors for better const expression support
- **📦 Generic Types**: All validators now use proper generic type constraints instead of `dynamic`
- **🏗️ Architecture**: Better separation of concerns with implementation classes for different column and default value types
- **⚡ Performance**: Reduced runtime type checking by leveraging compile-time type safety

## [1.1.4]

### Improved
- **🔧 Schema Generator**: Refactored Supabase schema builder and generator for improved annotation handling
- **📦 Dependencies**: Updated source_gen version alignment with compatibility requirements
- **🛠️ Code Quality**: Enhanced builder.dart for better maintainability

## [1.1.3]

### Improved
- **📝 Documentation**: Cleaned up changelog by removing specific dates for better maintainability
- **🔄 Version Management**: Updated to semantic versioning without timestamp dependencies

## [1.1.2]

### Added
- **📚 Professional Documentation**: Complete README overhaul with comprehensive navigation
- **🎯 Enhanced Examples**: Real-world use cases for multi-tenant apps, e-commerce, and analytics
- **🔗 Navigation Links**: Table of contents with anchor links for easy navigation
- **📊 Visual Improvements**: Professional badges, emojis, and better formatting
- **🛠️ Development Guide**: Comprehensive contributor documentation
- **📞 Community Support**: Clear support channels and community guidelines

### Improved
- **📖 Documentation Structure**: Logical organization with clear sections
- **🎨 Visual Appeal**: Consistent emoji usage and professional formatting
- **📱 Responsive Design**: Markdown optimized for all platforms
- **🔍 Searchability**: Better keywords and descriptions for discoverability

### Fixed
- **📝 Documentation Accuracy**: Updated all examples to reflect current API
- **🔗 Link Consistency**: All internal and external links verified and updated

## [1.1.1]

### Fixed
- **🔧 Build System**: Resolved build configuration issues
- **📦 Dependencies**: Updated dependency constraints for better compatibility
- **🐛 Minor Bugs**: Various small fixes for improved stability

## [1.1.0]

### Added
- **🚀 Migration Support**: Complete schema migration system with 5 migration modes:
  - `createOnly`: Original behavior (default) 
  - `createIfNotExists`: Safe table creation with IF NOT EXISTS
  - `createOrAlter`: Create table if not exists, then add missing columns
  - `alterOnly`: Only generate ALTER TABLE statements for existing schemas
  - `dropAndRecreate`: Drop and recreate tables (development only)
- **🔄 PostgreSQL DO Blocks**: Conditional ALTER TABLE statements using DO blocks for maximum safety
- **⚙️ Migration Configuration**: Extensive configuration options in build.yaml:
  - `migration_mode`: Choose migration strategy
  - `enable_column_adding`: Control column addition behavior
  - `generate_do_blocks`: Use PostgreSQL DO blocks for conditional operations
- **🗂️ Table Partitioning**: Full PostgreSQL partitioning support:
  - `RangePartition`: Partition by range (ideal for time-series data)
  - `HashPartition`: Partition by hash (for even data distribution)  
  - `ListPartition`: Partition by list (for categorical data)
- **🔧 Composite Primary Keys**: Automatic composite primary key generation for partitioned tables
- **📚 Migration Documentation**: Comprehensive migration guide and examples

### Fixed
- **Critical**: PostgreSQL partitioned table primary key constraints now include all partition columns
- **Critical**: ALTER TABLE statements no longer generate conflicting PRIMARY KEY constraints
- Migration modes properly handle existing table scenarios without errors
- Partition clause SQL formatting and generation

### Improved
- Enhanced SQL formatter with partition clause support
- Better error handling for partition configuration validation
- Backward compatibility maintained - existing code continues to work
- More robust annotation parsing for complex configurations

### Examples
- Added comprehensive migration examples for all modes
- Added partition table examples with different strategies
- Updated build.yaml configuration examples

## [1.0.6]

### Fixed
- **Critical**: Fixed RLS Policy annotation parsing - resolved "Null check operator used on a null value" error when processing RLSPolicy annotations
- **Critical**: Fixed enum value handling in annotation processing - RLSPolicyType and other enums now parse correctly
- Improved error handling for null annotation values to prevent build failures
- Enhanced annotation reading safety with proper null checks

### Improved
- Better error messages for annotation parsing issues
- More robust handling of optional annotation parameters
- Enhanced test coverage for RLS policy generation

## [1.0.5]

### Fixed
- **Critical**: Fixed index column name mapping issues - indexes now properly recognize database column names vs field names
- **Critical**: Fixed column type parsing - all column types (UUID, TEXT, JSONB, TIMESTAMP WITH TIME ZONE, etc.) now generate correctly
- **Critical**: Fixed foreign key column references - foreign keys now include proper column names instead of empty references
- **Critical**: Fixed composite primary key duplication - individual columns no longer get PRIMARY KEY constraint when part of composite key
- Fixed SQL formatting issues - proper line breaks and comma separation between columns
- Fixed missing index comments in generated SQL

### Improved
- Enhanced SQL readability with proper formatting and structure
- Better error handling for null values in annotation processing
- Improved validation for database schema generation
- Added comprehensive test coverage for edge cases

## [1.0.4]

### Fixed
- Fixed static analysis issues by removing invalid @immutable annotations from enums
- Cleaned up unused imports to eliminate linting warnings
- Standardized LICENSE file to OSI-approved MIT License format for proper pub.dev recognition
- Added proper example package structure with pubspec.yaml for better pub.dev scoring
- Enhanced example documentation and build configuration

### Improved
- Significantly improved pub.dev package score by addressing all major scoring criteria
- Better package discoverability and community accessibility

## [1.0.3]

### Fixed
- Improved package reliability and build system stability
- Enhanced error handling for edge cases
- Better validation for schema generation

## [1.0.2]

### Fixed
- Fixed static analysis issues by removing unnecessary library names
- Added proper library directives to resolve dangling documentation comments
- Improved package score for pub.dev by addressing linting issues
- Enhanced code quality and documentation standards

## [1.0.1]

### Fixed
- Updated README.md with correct package version and repository links
- Fixed version number consistency in documentation
- Improved package metadata for better discoverability

## [1.0.0]

### Added

#### 🏗️ Core Features
- **PostgreSQL Schema Generation**: Convert Dart classes to SQL DDL statements
- **Type-Safe Column Mapping**: Complete Dart-to-PostgreSQL type system
- **Row Level Security (RLS)**: Declarative policy generation and management
- **Foreign Key Relationships**: Full referential integrity support
- **Database Indexes**: Multiple index types with optimization
- **Schema Validation**: Comprehensive validation and error reporting

#### 🔐 Security Features
- **RLS Policies**: Support for all policy types (SELECT, INSERT, UPDATE, DELETE, ALL)
- **Fine-Grained Permissions**: Row and column-level access control
- **Authentication Integration**: Built-in Supabase auth helpers
- **SQL Injection Protection**: Safe parameterized conditions
- **Access Control**: Role-based permission management

#### ⚡ Performance Features
- **Smart Indexing**: Automatic index recommendations
- **Multiple Index Types**: B-tree, Hash, GIN, GiST, SP-GiST, BRIN support
- **Composite Indexes**: Multi-column index optimization
- **Partial Indexes**: Conditional indexing for large tables
- **Query Optimization**: Performance-aware SQL generation

#### 🔗 Foreign Key Support
- **Cascade Actions**: NO ACTION, RESTRICT, CASCADE, SET NULL, SET DEFAULT
- **Composite Keys**: Multi-column foreign key relationships
- **Self-referencing**: Support for hierarchical data structures
- **Deferrable Constraints**: Transaction-level constraint checking

#### 📊 Column Types & Constraints
- **Complete PostgreSQL Types**: All standard PostgreSQL data types
- **Custom Constraints**: CHECK constraints with validation
- **Default Values**: Rich default value support including functions
- **Nullability Control**: Explicit NULL/NOT NULL configuration
- **Primary Keys**: Single and composite primary key support

#### 🛡️ Validation & Error Handling
- **Schema Validation**: Comprehensive validation with detailed error messages
- **Type Compatibility**: Automatic Dart-to-PostgreSQL type checking
- **Constraint Validation**: Business rule and constraint validation
- **Performance Warnings**: Index and query optimization suggestions
- **Build-time Errors**: Catch issues before deployment

#### 🔧 Code Generation
- **SQL DDL Generation**: Complete CREATE TABLE statements
- **Index Generation**: Optimized index creation statements  
- **Policy Generation**: RLS policy creation and management
- **Comment Generation**: Automatic documentation in SQL
- **Clean Output**: Formatted, readable SQL generation

#### 🎯 Developer Experience
- **Type Safety**: Full compile-time type checking with null safety
- **IDE Support**: Complete IntelliSense and code completion
- **Comprehensive Documentation**: Inline help and examples
- **Clear Error Messages**: Actionable error reporting with suggestions
- **Rich Examples**: Real-world usage patterns and best practices

#### 🏛️ Architecture & Design
- **SOLID Principles**: Clean, maintainable architecture
- **Domain-Driven Design**: Clear domain models and language
- **Extensible Design**: Plugin architecture for customization
- **Test-Driven Development**: Comprehensive test coverage
- **Performance Optimized**: Efficient code generation

#### 📚 Documentation & Examples
- **Quick Start Guide**: Get running in minutes
- **API Reference**: Complete annotation documentation
- **Best Practices**: Production-ready patterns
- **Real-world Examples**: E-commerce, CMS, SaaS patterns
- **Migration Guide**: Step-by-step upgrade instructions

#### 🧪 Testing & Quality
- **Unit Tests**: Comprehensive unit test coverage
- **Integration Tests**: End-to-end database testing
- **Static Analysis**: Strict linting and quality checks
- **CI/CD**: Automated testing on multiple platforms
- **Code Coverage**: High test coverage requirements

#### 🌐 Compatibility
- **Dart SDK**: 3.2.0 and above with null safety
- **PostgreSQL**: 12.0+ with full feature support
- **Supabase**: All current versions
- **Platforms**: Windows, macOS, Linux development support

---

## 🗺️ Development Roadmap

### Planned Features

#### v1.2.0 - Advanced Migration Tools
- **Schema Diff Tools**: Automatic migration generation from schema changes
- **Rollback Support**: Safe rollback mechanisms for failed migrations
- **Migration Testing**: Built-in migration validation and testing
- **Data Migration**: Support for data transformation during schema changes

#### v1.3.0 - Extended PostgreSQL Features
- **Stored Procedures**: Generation of PostgreSQL functions and procedures
- **Triggers**: Event-driven database logic support
- **Views**: Materialized and standard view generation
- **Extensions**: Support for PostgreSQL extensions

#### v1.4.0 - Advanced Analytics
- **Query Analysis**: Performance analysis and optimization suggestions
- **Schema Metrics**: Database schema health and performance metrics
- **Usage Patterns**: Analysis of schema usage and optimization opportunities
- **Documentation Generation**: Automatic schema documentation

#### v2.0.0 - Next Generation Features
- **GraphQL Integration**: Automatic GraphQL schema generation
- **Real-time Support**: Enhanced real-time subscription features
- **Cloud Integration**: Direct cloud deployment and management
- **Advanced Caching**: Intelligent caching strategies

---

## 📞 Support & Contributing

### Getting Help
- **Documentation**: [API Reference](https://pub.dev/documentation/supabase_annotations/latest/)
- **Issues**: [GitHub Issues](https://github.com/ahmtydn/supabase_annotations/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ahmtydn/supabase_annotations/discussions)

### Contributing
We welcome contributions! Please see our [Contributing Guide](https://github.com/ahmtydn/supabase_annotations/blob/main/CONTRIBUTING.md) for details.

### Changelog Conventions
- **Added**: New features and capabilities
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes and corrections
- **Security**: Security-related improvements

---

*For detailed information about any release, please see the corresponding release notes and documentation.*
