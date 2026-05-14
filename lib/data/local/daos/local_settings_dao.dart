import 'package:drift/drift.dart';

import '../drift_db.dart';

part 'local_settings_dao.g.dart';

@DriftAccessor(tables: [LocalSettings])
class LocalSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$LocalSettingsDaoMixin {
  LocalSettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(localSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) =>
      into(localSettings).insertOnConflictUpdate(
        LocalSettingsCompanion(key: Value(key), value: Value(value)),
      );
}
