/// Simple test model for testing the schema generator
library;

import 'package:supabase_annotations/supabase_annotations.dart';

/// Simple user table for testing
@DatabaseTable(
  name: 'users',
  comment: 'Simple user table',
  enableRLS: true,
)
class User {
  User({required this.email, this.id, this.name});
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
  )
  String? id;

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
    isUnique: true,
    comment: 'User email address',
  )
  String email = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
    comment: 'User full name',
  )
  String? name;
}
