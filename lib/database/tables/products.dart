import 'package:drift/drift.dart';

class ProductTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  BoolColumn get isImportant => boolean().withDefault(const Constant(false))();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get listId => text().withDefault(const Constant('supermercado'))();
  RealColumn get price => real().withDefault(const Constant(0.0))();

  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastModified => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get userId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'products';
}
