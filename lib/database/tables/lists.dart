import 'package:drift/drift.dart';

class ListTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant(''))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get userId => text().withDefault(const Constant('local_user'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'lists';
}
