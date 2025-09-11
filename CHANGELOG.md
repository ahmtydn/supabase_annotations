# Changelog

All notable changes to the Supabase Schema Generator package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2025-09-11

### Fixed
- Improved package reliability and build system stability

## [1.0.2] - 2025-09-11

### Fixed
- Fixed static analysis issues by removing unnecessary library names
- Added proper library directives to resolve dangling documentation comments
- Improved package score for pub.dev by addressing linting issues
- Enhanced code quality and documentation standards

## [1.0.1] - 2025-09-11

### Fixed
- Updated README.md with correct package version and repository links
- Fixed version number consistency in documentation

## [2.0.0] - 2025-09-11

### Changed
- **Configuration Defaults**: Updated default configuration values
  - `formatSql`: true (improved readability)
  - `enableRlsByDefault`: false (explicit security configuration)
  - `addTimestamps`: false (clean schema by default)
  - `useExplicitNullability`: false (use PostgreSQL defaults)
  - `generateComments`: true (include documentation)
  - `validateSchema`: true (ensure schema consistency)

### Removed
- **Unnecessary Dependencies**: Removed `dartdoc` and `mockito` from dev dependencies
- **Platform Support**: Removed Android, iOS, and Web platform targets
- **Performance Options**: Removed `parallel_processing` and `cache_generated_files` options
- **Builder Configuration**: Simplified builder configuration in build.yaml

### Fixed
- **Documentation**: Updated README with correct configuration examples
- **Package Metadata**: Cleaned up pubspec.yaml for better package management

## [1.0.0] - 2025-09-12

### Added

#### Core Features
- **PostgreSQL Schema Generation**: Convert Dart classes to SQL DDL statements
- **Type-Safe Column Mapping**: Dart-to-PostgreSQL type system
- **Row Level Security (RLS)**: Policy generation and management
- **Foreign Key Relationships**: Referential integrity support
- **Database Indexes**: Multiple index type support
- **Schema Validation**: Comprehensive validation and error reporting
- **Permissive/Restrictive**: Full PostgreSQL policy model support
- **Complex Conditions**: SQL expressions with validation

#### Foreign Keys
- **Cascade Actions**: NO ACTION, RESTRICT, CASCADE, SET NULL, SET DEFAULT
- **Composite Keys**: Multi-column foreign key relationships
- **Self-referencing**: Support for hierarchical data structures
- **Deferrable Constraints**: Transaction-level constraint checking

#### Validation & Error Handling
- **Schema Validation**: Comprehensive validation with detailed error messages
- **Type Compatibility**: Automatic Dart-to-PostgreSQL type checking
- **Constraint Validation**: CHECK constraints and business rule validation
- **Performance Warnings**: Index and query optimization suggestions

#### Code Generation
- **SQL DDL Generation**: Complete CREATE TABLE statements
- **Index Generation**: Optimized index creation statements
- **Policy Generation**: RLS policy creation and management
- **Migration Generation**: Versioned schema change scripts
- **Documentation**: Automatic comment generation

#### Developer Experience
- **Comprehensive Documentation**: Inline documentation for all features
- **Type Safety**: Full compile-time type checking
- **IDE Support**: IntelliSense and code completion
- **Error Messages**: Clear, actionable error reporting
- **Examples**: Real-world usage examples and patterns

#### Performance Features
- **Intelligent Indexing**: Automatic index recommendations
- **Query Optimization**: Performance-aware SQL generation
- **Partial Indexes**: Conditional indexing for large tables
- **Storage Optimization**: Configurable storage parameters

#### Security Features
- **RLS by Default**: Security-first approach with RLS policies
- **Injection Protection**: SQL injection prevention in conditions
- **Access Control**: Fine-grained permission management
- **Audit Support**: Built-in audit trail capabilities

### Architecture & Design

#### Software Engineering Principles
- **SOLID Principles**: Single responsibility, open/closed, dependency inversion
- **Clean Architecture**: Separation of concerns and dependency management
- **Domain-Driven Design**: Clear domain models and ubiquitous language
- **Test-Driven Development**: Comprehensive test coverage
- **Documentation-First**: Extensive documentation and examples

#### Code Quality
- **Static Analysis**: Strict linting and analysis rules
- **Type Safety**: Null safety and compile-time type checking
- **Error Handling**: Comprehensive error handling and recovery
- **Performance**: Optimized code generation and runtime performance
- **Maintainability**: Clean, readable, and well-structured code

#### Extensibility
- **Plugin Architecture**: Extensible generator system
- **Custom Validators**: Support for custom validation rules
- **Custom Types**: Extensible type system
- **Custom Generators**: Support for additional output formats

### Documentation

#### User Guides
- **Quick Start Guide**: Get up and running in minutes
- **Comprehensive API Reference**: Complete annotation documentation
- **Best Practices**: Production-ready patterns and recommendations
- **Migration Guide**: Step-by-step migration instructions
- **Troubleshooting**: Common issues and solutions

#### Examples
- **Basic Usage**: Simple table and column definitions
- **Advanced Patterns**: Complex relationships and constraints
- **Real-world Applications**: E-commerce, CMS, and SaaS examples
- **Performance Optimization**: Indexing and query optimization
- **Security Patterns**: RLS and access control examples

#### Technical Documentation
- **Architecture Overview**: System design and components
- **Extension Points**: How to extend and customize
- **Contribution Guidelines**: How to contribute to the project
- **Release Process**: How releases are managed

### Testing

#### Test Coverage
- **Unit Tests**: Comprehensive unit test coverage
- **Integration Tests**: End-to-end testing with real databases
- **Performance Tests**: Load testing and performance validation
- **Security Tests**: SQL injection and access control testing

#### Quality Assurance
- **Continuous Integration**: Automated testing on multiple platforms
- **Code Coverage**: Minimum 95% code coverage requirement
- **Static Analysis**: Automated code quality checks
- **Manual Testing**: Real-world usage validation

### Compatibility

#### Dart Compatibility
- **Dart SDK**: 3.0.0 and above
- **Flutter**: Compatible with Flutter 3.10.0+
- **Null Safety**: Full null safety support

#### PostgreSQL Compatibility
- **PostgreSQL**: 12.0 and above
- **Supabase**: All current versions
- **Extensions**: Support for common PostgreSQL extensions

#### Platform Support
- **Development**: Windows, macOS, Linux
- **Deployment**: All platforms supported by Dart/Flutter
- **CI/CD**: GitHub Actions, GitLab CI, and other platforms

---

## Development Roadmap

### Future Releases

#### v1.1.0 - Enhanced Validation
- Advanced constraint validation
- Custom validator framework
- Performance analysis tools
- Enhanced error reporting

#### v1.2.0 - Migration Tools
- Automatic migration generation
- Schema diff tools
- Rollback support
- Migration testing

#### v1.3.0 - Advanced Features
- Stored procedure generation
- Trigger support
- View generation
- Custom function support

#### v2.0.0 - Next Generation
- GraphQL schema generation
- Real-time subscription support
- Advanced caching strategies
- Cloud deployment tools

---

*For detailed information about any release, please see the corresponding release notes and documentation.*
