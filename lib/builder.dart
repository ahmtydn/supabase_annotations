/// Builder configuration for the Supabase schema generator.
///
/// This file configures the build system to run the schema generator
/// when processing annotated Dart classes.
library;

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:supabase_annotations/src/annotations/database_table.dart';
import 'package:supabase_annotations/src/generators/schema_generator.dart';

/// Creates a builder for generating Supabase schemas.
///
/// This builder processes classes annotated with [DatabaseTable]
/// and generates SQL DDL files for database schema creation.
///
/// Configuration options are read from build.yaml options section.
Builder supabaseSchemaBuilder(BuilderOptions options) {
  final config = SchemaGeneratorConfig.fromOptions(options.config);
  return SupabaseSchemaBuilder._(config);
}

/// Builder implementation for generating SQL schema files.
///
/// This builder scans Dart libraries for classes annotated with [DatabaseTable]
/// and generates corresponding SQL DDL files. Generated files are written both
/// to the standard build output and optionally to a schemas directory for
/// database migration purposes.
@sealed
class SupabaseSchemaBuilder implements Builder {
  SupabaseSchemaBuilder._(this._config);

  static const String _sqlExtension = '.schema.sql';

  final SchemaGeneratorConfig _config;
  final TypeChecker _tableChecker = const TypeChecker.typeNamed(DatabaseTable);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': [_sqlExtension],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final library = await buildStep.inputLibrary;
    final annotatedElements = _findAnnotatedElements(library);

    if (annotatedElements.isEmpty) {
      return;
    }

    try {
      final schemaContent =
          await _generateSchemaContent(annotatedElements, buildStep);

      if (schemaContent.isEmpty) {
        return;
      }

      await _writeSchemaFiles(buildStep, schemaContent);
    } on Exception catch (e, stackTrace) {
      log.severe('Failed to generate schema for ${buildStep.inputId.path}', e,
          stackTrace);
      rethrow;
    }
  }

  /// Finds all classes annotated with [DatabaseTable] in the library.
  List<ClassElement> _findAnnotatedElements(LibraryElement library) {
    return library.library.classes
        .where(_tableChecker.hasAnnotationOfExact)
        .toList();
  }

  /// Generates SQL schema content from annotated elements.
  Future<String> _generateSchemaContent(
    List<ClassElement> elements,
    BuildStep buildStep,
  ) async {
    final generator = SupabaseSchemaGenerator(_config);
    final sqlBuffer = StringBuffer();

    for (final element in elements) {
      try {
        final sql = await _generateElementSchema(element, generator, buildStep);
        if (sql.isNotEmpty) {
          sqlBuffer
            ..writeln(sql)
            ..writeln();
        }
      } on Exception catch (e) {
        log.warning(
            'Skipping schema generation for ${element.displayName}: $e');
      }
    }

    return sqlBuffer.toString().trim();
  }

  /// Generates SQL schema for a single annotated element.
  Future<String> _generateElementSchema(
    ClassElement element,
    SupabaseSchemaGenerator generator,
    BuildStep buildStep,
  ) async {
    final annotation = _tableChecker.firstAnnotationOfExact(element);
    if (annotation == null) {
      throw StateError(
          'Expected annotation not found on ${element.displayName}');
    }

    final reader = ConstantReader(annotation);
    return generator.generateForAnnotatedElement(element, reader, buildStep);
  }

  /// Writes schema content to both build output and schemas directory.
  Future<void> _writeSchemaFiles(BuildStep buildStep, String content) async {
    final outputId = buildStep.inputId.changeExtension(_sqlExtension);

    // Write to build output
    await buildStep.writeAsString(outputId, content);
    log.info('Generated schema file: ${outputId.path}');
  }
}
