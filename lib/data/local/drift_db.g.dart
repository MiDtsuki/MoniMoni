// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_db.dart';

// ignore_for_file: type=lint
class $LocalTransactionsTable extends LocalTransactions
    with TableInfo<$LocalTransactionsTable, LocalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    account,
    amount,
    type,
    date,
    note,
    createdAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    } else if (isInserting) {
      context.missing(_accountMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $LocalTransactionsTable createAlias(String alias) {
    return $LocalTransactionsTable(attachedDatabase, alias);
  }
}

class LocalTransaction extends DataClass
    implements Insertable<LocalTransaction> {
  final String id;
  final String category;
  final String account;
  final double amount;
  final String type;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime? deletedAt;
  const LocalTransaction({
    required this.id,
    required this.category,
    required this.account,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.createdAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['account'] = Variable<String>(account);
    map['amount'] = Variable<double>(amount);
    map['type'] = Variable<String>(type);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  LocalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionsCompanion(
      id: Value(id),
      category: Value(category),
      account: Value(account),
      amount: Value(amount),
      type: Value(type),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory LocalTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransaction(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      account: serializer.fromJson<String>(json['account']),
      amount: serializer.fromJson<double>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'account': serializer.toJson<String>(account),
      'amount': serializer.toJson<double>(amount),
      'type': serializer.toJson<String>(type),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  LocalTransaction copyWith({
    String? id,
    String? category,
    String? account,
    double? amount,
    String? type,
    DateTime? date,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => LocalTransaction(
    id: id ?? this.id,
    category: category ?? this.category,
    account: account ?? this.account,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  LocalTransaction copyWithCompanion(LocalTransactionsCompanion data) {
    return LocalTransaction(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      account: data.account.present ? data.account.value : this.account,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransaction(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('account: $account, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    account,
    amount,
    type,
    date,
    note,
    createdAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransaction &&
          other.id == this.id &&
          other.category == this.category &&
          other.account == this.account &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.date == this.date &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt);
}

class LocalTransactionsCompanion extends UpdateCompanion<LocalTransaction> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> account;
  final Value<double> amount;
  final Value<String> type;
  final Value<DateTime> date;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const LocalTransactionsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.account = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTransactionsCompanion.insert({
    required String id,
    required String category,
    required String account,
    required double amount,
    required String type,
    required DateTime date,
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       account = Value(account),
       amount = Value(amount),
       type = Value(type),
       date = Value(date);
  static Insertable<LocalTransaction> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? account,
    Expression<double>? amount,
    Expression<String>? type,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (account != null) 'account': account,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String>? account,
    Value<double>? amount,
    Value<String>? type,
    Value<DateTime>? date,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return LocalTransactionsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      account: account ?? this.account,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('account: $account, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSetting extends DataClass implements Insertable<LocalSetting> {
  final String key;
  final String value;
  const LocalSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSetting copyWith({String? key, String? value}) =>
      LocalSetting(key: key ?? this.key, value: value ?? this.value);
  LocalSetting copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalTransactionsTable localTransactions =
      $LocalTransactionsTable(this);
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final LocalTransactionDao localTransactionDao = LocalTransactionDao(
    this as AppDatabase,
  );
  late final LocalSettingsDao localSettingsDao = LocalSettingsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTransactions,
    localSettings,
  ];
}

typedef $$LocalTransactionsTableCreateCompanionBuilder =
    LocalTransactionsCompanion Function({
      required String id,
      required String category,
      required String account,
      required double amount,
      required String type,
      required DateTime date,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$LocalTransactionsTableUpdateCompanionBuilder =
    LocalTransactionsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<String> account,
      Value<double> amount,
      Value<String> type,
      Value<DateTime> date,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$LocalTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$LocalTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalTransactionsTable,
          LocalTransaction,
          $$LocalTransactionsTableFilterComposer,
          $$LocalTransactionsTableOrderingComposer,
          $$LocalTransactionsTableAnnotationComposer,
          $$LocalTransactionsTableCreateCompanionBuilder,
          $$LocalTransactionsTableUpdateCompanionBuilder,
          (
            LocalTransaction,
            BaseReferences<
              _$AppDatabase,
              $LocalTransactionsTable,
              LocalTransaction
            >,
          ),
          LocalTransaction,
          PrefetchHooks Function()
        > {
  $$LocalTransactionsTableTableManager(
    _$AppDatabase db,
    $LocalTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> account = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion(
                id: id,
                category: category,
                account: account,
                amount: amount,
                type: type,
                date: date,
                note: note,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required String account,
                required double amount,
                required String type,
                required DateTime date,
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTransactionsCompanion.insert(
                id: id,
                category: category,
                account: account,
                amount: amount,
                type: type,
                date: date,
                note: note,
                createdAt: createdAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalTransactionsTable,
      LocalTransaction,
      $$LocalTransactionsTableFilterComposer,
      $$LocalTransactionsTableOrderingComposer,
      $$LocalTransactionsTableAnnotationComposer,
      $$LocalTransactionsTableCreateCompanionBuilder,
      $$LocalTransactionsTableUpdateCompanionBuilder,
      (
        LocalTransaction,
        BaseReferences<
          _$AppDatabase,
          $LocalTransactionsTable,
          LocalTransaction
        >,
      ),
      LocalTransaction,
      PrefetchHooks Function()
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSetting,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSetting,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
          ),
          LocalSetting,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSetting,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSetting,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSetting>,
      ),
      LocalSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(_db, _db.localTransactions);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
}
