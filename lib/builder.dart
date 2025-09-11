/// Builder configuration for the Supabase schema generator.
///
/// This file configures the build system to run the schema generator
/// when processing annotated Dart classes.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:supabase_codegen/src/annotations/database_table.dart';
import 'package:supabase_codegen/src/generators/schema_generator.dart';

/// Creates a builder for generating Supabase schemas.
///
/// This builder processes classes annotated with [DatabaseTable]
/// and generates SQL DDL files for database schema creation.
///
/// Configuration options are read from build.yaml options section.
Builder supabaseSchemaBuilder(BuilderOptions options) {
  // Create configuration from build options
  final config = SchemaGeneratorConfig.fromOptions(options.config);

  return _SupabaseSchemaBuilder(config);
}

/// Builder implementation for generating SQL schema files.
class _SupabaseSchemaBuilder implements Builder {
  _SupabaseSchemaBuilder(this.config);

  final SchemaGeneratorConfig config;

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.schema.sql'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final generator = SupabaseSchemaGenerator(config);
    const checker = TypeChecker.fromRuntime(DatabaseTable);

    // Read the input file
    final inputId = buildStep.inputId;
    final library = await buildStep.inputLibrary;

    // Check if any classes are annotated with DatabaseTable
    final sqlOutput = StringBuffer();
    var hasAnnotatedClasses = false;

    for (final element in library.topLevelElements) {
      if (element is ClassElement && checker.hasAnnotationOfExact(element)) {
        hasAnnotatedClasses = true;
        try {
          final annotation = checker.firstAnnotationOfExact(element);
          if (annotation != null) {
            final reader = ConstantReader(annotation);
            final sql = await generator.generateForAnnotatedElement(
              element,
              reader,
              buildStep,
            );
            if (sql.isNotEmpty) {
              sqlOutput
                ..writeln(sql)
                ..writeln();
            }
          }
        } on Exception catch (e) {
          log.warning('Error generating schema for ${element.name}: $e');
        }
      }
    }

    // Only create output file if we found annotated classes
    if (hasAnnotatedClasses && sqlOutput.isNotEmpty) {
      final outputId = inputId.changeExtension('.schema.sql');
      await buildStep.writeAsString(outputId, sqlOutput.toString());
    }
  }
}
