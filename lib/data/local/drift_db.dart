import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/local_settings_dao.dart';
import 'daos/local_transaction_dao.dart';
import 'tables/local_settings_table.dart';
import 'tables/local_transactions_table.dart';

export 'daos/local_settings_dao.dart';
export 'daos/local_transaction_dao.dart';
export 'tables/local_settings_table.dart';
export 'tables/local_transactions_table.dart';

part 'drift_db.g.dart';

@DriftDatabase(
  tables: [LocalTransactions, LocalSettings],
  daos: [LocalTransactionDao, LocalSettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(localTransactions);
        await m.createTable(localSettings);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'moni.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
