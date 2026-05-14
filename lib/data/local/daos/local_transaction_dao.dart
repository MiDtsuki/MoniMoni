import 'package:drift/drift.dart';

import '../drift_db.dart';

part 'local_transaction_dao.g.dart';

@DriftAccessor(tables: [LocalTransactions])
class LocalTransactionDao extends DatabaseAccessor<AppDatabase>
    with _$LocalTransactionDaoMixin {
  LocalTransactionDao(super.db);

  Future<List<LocalTransaction>> getAllActive() =>
      (select(localTransactions)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.createdAt),
            ]))
          .get();

  Future<void> upsert(LocalTransactionsCompanion entry) =>
      into(localTransactions).insertOnConflictUpdate(entry);

  Future<void> updateEntry(LocalTransactionsCompanion entry) =>
      (update(localTransactions)..where((t) => t.id.equals(entry.id.value)))
          .write(entry);

  Future<void> softDelete(String id) =>
      (update(localTransactions)..where((t) => t.id.equals(id))).write(
        LocalTransactionsCompanion(deletedAt: Value(DateTime.now())),
      );
}
