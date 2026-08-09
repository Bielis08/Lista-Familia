import 'package:drift/native.dart';
import 'package:lista_familia/database/app_database.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}
