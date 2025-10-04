// Test file for partition functionality
import 'package:supabase_annotations/supabase_annotations.dart';

@DatabaseTable(
  name: 'events',
  comment: 'Event logs table with range partitioning by date',
  partitionBy: RangePartition(columns: ['created_at']),
)
class Event {
  Event({
    required this.eventType,
    this.id,
    this.data,
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
  )
  String eventType = '';

  @DatabaseColumn(
    type: ColumnType.jsonb,
    isNullable: true,
  )
  Map<String, dynamic>? data;

  @DatabaseColumn(
    type: ColumnType.timestampWithTimeZone,
    defaultValue: DefaultValue.now,
    isNullable: false,
    isPrimaryKey: true, // Added to composite primary key for partitioning
  )
  DateTime? createdAt;
}

@DatabaseTable(
  name: 'user_stats',
  comment: 'User statistics with hash partitioning by user_id',
  partitionBy: HashPartition(columns: ['user_id']),
)
class UserStats {
  UserStats({
    required this.userId,
    required this.viewCount,
    required this.likeCount,
    this.id,
  });
  @DatabaseColumn(
    type: ColumnType.uuid,
    isPrimaryKey: true,
    defaultValue: DefaultValue.generateUuid,
  )
  String? id;

  @DatabaseColumn(
    type: ColumnType.uuid,
    isNullable: false,
    isPrimaryKey: true, // Added to composite primary key for partitioning
  )
  String userId = '';

  @DatabaseColumn(
    type: ColumnType.integer,
    defaultValue: DefaultValue.number(0),
  )
  int viewCount = 0;

  @DatabaseColumn(
    type: ColumnType.integer,
    defaultValue: DefaultValue.number(0),
  )
  int likeCount = 0;
}

@DatabaseTable(
  name: 'regional_data',
  comment: 'Regional data with list partitioning by region',
  partitionBy: ListPartition(columns: ['region']),
)
class RegionalData {
  RegionalData({
    required this.region,
    required this.dataValue,
    this.id,
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
    isPrimaryKey: true,
  )
  String region = '';

  @DatabaseColumn(
    type: ColumnType.text,
    isNullable: false,
  )
  String dataValue = '';
}
