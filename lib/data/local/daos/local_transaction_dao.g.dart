// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_transaction_dao.dart';

// ignore_for_file: type=lint
mixin _$LocalTransactionDaoMixin on DatabaseAccessor<AppDatabase> {
  $LocalTransactionsTable get localTransactions =>
      attachedDatabase.localTransactions;
  LocalTransactionDaoManager get managers => LocalTransactionDaoManager(this);
}

class LocalTransactionDaoManager {
  final _$LocalTransactionDaoMixin _db;
  LocalTransactionDaoManager(this._db);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.localTransactions,
      );
}
