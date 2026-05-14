import 'package:drift/drift.dart';

class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get account => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // 'income' | 'expense'
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
