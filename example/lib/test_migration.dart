// Test file to verify migration functionality
import 'package:supabase_annotations/supabase_annotations.dart';

@DatabaseTable(
  name: 'test_users',
  comment: 'Test users table for migration testing',
)
class TestUser {
  TestUser({
    required this.email,
    required this.age,
    this.id,
    this.name,
    this.createdAt,
  });
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
  )
  String email = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: true,
  )
  String? name;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.now,
    isNullable: false,
  )
  DateTime? createdAt;

  // New field that would require ALTER TABLE in existing database
  @DatabaseColumn(
    type: ColumnType.integer,
    defaultValue: DefaultValue.number(0),
    isNullable: false,
  )
  int age = 0;
}
