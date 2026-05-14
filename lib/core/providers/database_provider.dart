import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/drift_db.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final localTransactionDaoProvider = Provider<LocalTransactionDao>((ref) =>
    ref.watch(appDatabaseProvider).localTransactionDao);

final localSettingsDaoProvider = Provider<LocalSettingsDao>((ref) =>
    ref.watch(appDatabaseProvider).localSettingsDao);
