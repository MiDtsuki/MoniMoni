import 'package:drift/drift.dart';
import 'connection_native.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'connection_web.dart';

part 'drift_db.g.dart';

@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}