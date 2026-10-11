// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class SearchIndex extends Table
    with
        TableInfo<SearchIndex, SearchIndexData>,
        VirtualTableInfo<SearchIndex, SearchIndexData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SearchIndex(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [title, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_index';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchIndexData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  SearchIndexData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchIndexData(
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  SearchIndex createAlias(String alias) {
    return SearchIndex(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(title, body, tokenize = \'unicode61 remove_diacritics 2\', prefix = \'2 3\')';
}

class SearchIndexData extends DataClass implements Insertable<SearchIndexData> {
  final String title;
  final String body;
  const SearchIndexData({required this.title, required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    return map;
  }

  SearchIndexCompanion toCompanion(bool nullToAbsent) {
    return SearchIndexCompanion(title: Value(title), body: Value(body));
  }

  factory SearchIndexData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchIndexData(
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
    };
  }

  SearchIndexData copyWith({String? title, String? body}) =>
      SearchIndexData(title: title ?? this.title, body: body ?? this.body);
  SearchIndexData copyWithCompanion(SearchIndexCompanion data) {
    return SearchIndexData(
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexData(')
          ..write('title: $title, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(title, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchIndexData &&
          other.title == this.title &&
          other.body == this.body);
}

class SearchIndexCompanion extends UpdateCompanion<SearchIndexData> {
  final Value<String> title;
  final Value<String> body;
  final Value<int> rowid;
  const SearchIndexCompanion({
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchIndexCompanion.insert({
    required String title,
    required String body,
    this.rowid = const Value.absent(),
  }) : title = Value(title),
       body = Value(body);
  static Insertable<SearchIndexData> custom({
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchIndexCompanion copyWith({
    Value<String>? title,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return SearchIndexCompanion(
      title: title ?? this.title,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchIndexCompanion(')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SearchMap extends Table with TableInfo<SearchMap, SearchMapData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SearchMap(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  late final GeneratedColumn<int> rowId = GeneratedColumn<int>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [rowId, entity, entityId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_map';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchMapData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rowId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {entity, entityId},
  ];
  @override
  SearchMapData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchMapData(
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
    );
  }

  @override
  SearchMap createAlias(String alias) {
    return SearchMap(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(entity, entity_id)'];
  @override
  bool get dontWriteConstraints => true;
}

class SearchMapData extends DataClass implements Insertable<SearchMapData> {
  final int rowId;
  final String entity;
  final String entityId;
  const SearchMapData({
    required this.rowId,
    required this.entity,
    required this.entityId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['row_id'] = Variable<int>(rowId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    return map;
  }

  SearchMapCompanion toCompanion(bool nullToAbsent) {
    return SearchMapCompanion(
      rowId: Value(rowId),
      entity: Value(entity),
      entityId: Value(entityId),
    );
  }

  factory SearchMapData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchMapData(
      rowId: serializer.fromJson<int>(json['row_id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entity_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'row_id': serializer.toJson<int>(rowId),
      'entity': serializer.toJson<String>(entity),
      'entity_id': serializer.toJson<String>(entityId),
    };
  }

  SearchMapData copyWith({int? rowId, String? entity, String? entityId}) =>
      SearchMapData(
        rowId: rowId ?? this.rowId,
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
      );
  SearchMapData copyWithCompanion(SearchMapCompanion data) {
    return SearchMapData(
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchMapData(')
          ..write('rowId: $rowId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rowId, entity, entityId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchMapData &&
          other.rowId == this.rowId &&
          other.entity == this.entity &&
          other.entityId == this.entityId);
}

class SearchMapCompanion extends UpdateCompanion<SearchMapData> {
  final Value<int> rowId;
  final Value<String> entity;
  final Value<String> entityId;
  const SearchMapCompanion({
    this.rowId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
  });
  SearchMapCompanion.insert({
    this.rowId = const Value.absent(),
    required String entity,
    required String entityId,
  }) : entity = Value(entity),
       entityId = Value(entityId);
  static Insertable<SearchMapData> custom({
    Expression<int>? rowId,
    Expression<String>? entity,
    Expression<String>? entityId,
  }) {
    return RawValuesInsertable({
      if (rowId != null) 'row_id': rowId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
    });
  }

  SearchMapCompanion copyWith({
    Value<int>? rowId,
    Value<String>? entity,
    Value<String>? entityId,
  }) {
    return SearchMapCompanion(
      rowId: rowId ?? this.rowId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rowId.present) {
      map['row_id'] = Variable<int>(rowId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchMapCompanion(')
          ..write('rowId: $rowId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId')
          ..write(')'))
        .toString();
  }
}

class SearchPending extends Table
    with TableInfo<SearchPending, SearchPendingData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SearchPending(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [entity, entityId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_pending';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchPendingData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entity, entityId};
  @override
  SearchPendingData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchPendingData(
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
    );
  }

  @override
  SearchPending createAlias(String alias) {
    return SearchPending(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(entity, entity_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SearchPendingData extends DataClass
    implements Insertable<SearchPendingData> {
  final String entity;
  final String entityId;
  const SearchPendingData({required this.entity, required this.entityId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    return map;
  }

  SearchPendingCompanion toCompanion(bool nullToAbsent) {
    return SearchPendingCompanion(
      entity: Value(entity),
      entityId: Value(entityId),
    );
  }

  factory SearchPendingData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchPendingData(
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entity_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entity': serializer.toJson<String>(entity),
      'entity_id': serializer.toJson<String>(entityId),
    };
  }

  SearchPendingData copyWith({String? entity, String? entityId}) =>
      SearchPendingData(
        entity: entity ?? this.entity,
        entityId: entityId ?? this.entityId,
      );
  SearchPendingData copyWithCompanion(SearchPendingCompanion data) {
    return SearchPendingData(
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchPendingData(')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entity, entityId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchPendingData &&
          other.entity == this.entity &&
          other.entityId == this.entityId);
}

class SearchPendingCompanion extends UpdateCompanion<SearchPendingData> {
  final Value<String> entity;
  final Value<String> entityId;
  const SearchPendingCompanion({
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
  });
  SearchPendingCompanion.insert({
    required String entity,
    required String entityId,
  }) : entity = Value(entity),
       entityId = Value(entityId);
  static Insertable<SearchPendingData> custom({
    Expression<String>? entity,
    Expression<String>? entityId,
  }) {
    return RawValuesInsertable({
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
    });
  }

  SearchPendingCompanion copyWith({
    Value<String>? entity,
    Value<String>? entityId,
  }) {
    return SearchPendingCompanion(
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchPendingCompanion(')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, PeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthdayDayMeta = const VerificationMeta(
    'birthdayDay',
  );
  @override
  late final GeneratedColumn<int> birthdayDay = GeneratedColumn<int>(
    'birthday_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthdayMonthMeta = const VerificationMeta(
    'birthdayMonth',
  );
  @override
  late final GeneratedColumn<int> birthdayMonth = GeneratedColumn<int>(
    'birthday_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthdayYearMeta = const VerificationMeta(
    'birthdayYear',
  );
  @override
  late final GeneratedColumn<int> birthdayYear = GeneratedColumn<int>(
    'birthday_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _mergedIntoIdMeta = const VerificationMeta(
    'mergedIntoId',
  );
  @override
  late final GeneratedColumn<String> mergedIntoId = GeneratedColumn<String>(
    'merged_into_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _organisationMeta = const VerificationMeta(
    'organisation',
  );
  @override
  late final GeneratedColumn<String> organisation = GeneratedColumn<String>(
    'organisation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobTitleMeta = const VerificationMeta(
    'jobTitle',
  );
  @override
  late final GeneratedColumn<String> jobTitle = GeneratedColumn<String>(
    'job_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    name,
    birthdayDay,
    birthdayMonth,
    birthdayYear,
    note,
    mergedIntoId,
    organisation,
    jobTitle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birthday_day')) {
      context.handle(
        _birthdayDayMeta,
        birthdayDay.isAcceptableOrUnknown(
          data['birthday_day']!,
          _birthdayDayMeta,
        ),
      );
    }
    if (data.containsKey('birthday_month')) {
      context.handle(
        _birthdayMonthMeta,
        birthdayMonth.isAcceptableOrUnknown(
          data['birthday_month']!,
          _birthdayMonthMeta,
        ),
      );
    }
    if (data.containsKey('birthday_year')) {
      context.handle(
        _birthdayYearMeta,
        birthdayYear.isAcceptableOrUnknown(
          data['birthday_year']!,
          _birthdayYearMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('merged_into_id')) {
      context.handle(
        _mergedIntoIdMeta,
        mergedIntoId.isAcceptableOrUnknown(
          data['merged_into_id']!,
          _mergedIntoIdMeta,
        ),
      );
    }
    if (data.containsKey('organisation')) {
      context.handle(
        _organisationMeta,
        organisation.isAcceptableOrUnknown(
          data['organisation']!,
          _organisationMeta,
        ),
      );
    }
    if (data.containsKey('job_title')) {
      context.handle(
        _jobTitleMeta,
        jobTitle.isAcceptableOrUnknown(data['job_title']!, _jobTitleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      birthdayDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birthday_day'],
      ),
      birthdayMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birthday_month'],
      ),
      birthdayYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birthday_year'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      mergedIntoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merged_into_id'],
      ),
      organisation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organisation'],
      ),
      jobTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_title'],
      ),
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class PeopleData extends DataClass implements Insertable<PeopleData> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String name;

  /// Birthday as day and month, year optional (DD-012).
  final int? birthdayDay;
  final int? birthdayMonth;
  final int? birthdayYear;

  /// Free Markdown note (REQ-031).
  final String? note;

  /// The person this one was merged into (DD-015, T3.2b); set together
  /// with the tombstone. A reference to a merged person, for example one
  /// that arrives later through sync, is read as one to this person.
  final String? mergedIntoId;

  /// Where the person works and as what (REQ-038, DD-012); both optional.
  final String? organisation;
  final String? jobTitle;
  const PeopleData({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.name,
    this.birthdayDay,
    this.birthdayMonth,
    this.birthdayYear,
    this.note,
    this.mergedIntoId,
    this.organisation,
    this.jobTitle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || birthdayDay != null) {
      map['birthday_day'] = Variable<int>(birthdayDay);
    }
    if (!nullToAbsent || birthdayMonth != null) {
      map['birthday_month'] = Variable<int>(birthdayMonth);
    }
    if (!nullToAbsent || birthdayYear != null) {
      map['birthday_year'] = Variable<int>(birthdayYear);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || mergedIntoId != null) {
      map['merged_into_id'] = Variable<String>(mergedIntoId);
    }
    if (!nullToAbsent || organisation != null) {
      map['organisation'] = Variable<String>(organisation);
    }
    if (!nullToAbsent || jobTitle != null) {
      map['job_title'] = Variable<String>(jobTitle);
    }
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      birthdayDay: birthdayDay == null && nullToAbsent
          ? const Value.absent()
          : Value(birthdayDay),
      birthdayMonth: birthdayMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(birthdayMonth),
      birthdayYear: birthdayYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthdayYear),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      mergedIntoId: mergedIntoId == null && nullToAbsent
          ? const Value.absent()
          : Value(mergedIntoId),
      organisation: organisation == null && nullToAbsent
          ? const Value.absent()
          : Value(organisation),
      jobTitle: jobTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(jobTitle),
    );
  }

  factory PeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleData(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      birthdayDay: serializer.fromJson<int?>(json['birthdayDay']),
      birthdayMonth: serializer.fromJson<int?>(json['birthdayMonth']),
      birthdayYear: serializer.fromJson<int?>(json['birthdayYear']),
      note: serializer.fromJson<String?>(json['note']),
      mergedIntoId: serializer.fromJson<String?>(json['mergedIntoId']),
      organisation: serializer.fromJson<String?>(json['organisation']),
      jobTitle: serializer.fromJson<String?>(json['jobTitle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'birthdayDay': serializer.toJson<int?>(birthdayDay),
      'birthdayMonth': serializer.toJson<int?>(birthdayMonth),
      'birthdayYear': serializer.toJson<int?>(birthdayYear),
      'note': serializer.toJson<String?>(note),
      'mergedIntoId': serializer.toJson<String?>(mergedIntoId),
      'organisation': serializer.toJson<String?>(organisation),
      'jobTitle': serializer.toJson<String?>(jobTitle),
    };
  }

  PeopleData copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    Value<int?> birthdayDay = const Value.absent(),
    Value<int?> birthdayMonth = const Value.absent(),
    Value<int?> birthdayYear = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> mergedIntoId = const Value.absent(),
    Value<String?> organisation = const Value.absent(),
    Value<String?> jobTitle = const Value.absent(),
  }) => PeopleData(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    birthdayDay: birthdayDay.present ? birthdayDay.value : this.birthdayDay,
    birthdayMonth: birthdayMonth.present
        ? birthdayMonth.value
        : this.birthdayMonth,
    birthdayYear: birthdayYear.present ? birthdayYear.value : this.birthdayYear,
    note: note.present ? note.value : this.note,
    mergedIntoId: mergedIntoId.present ? mergedIntoId.value : this.mergedIntoId,
    organisation: organisation.present ? organisation.value : this.organisation,
    jobTitle: jobTitle.present ? jobTitle.value : this.jobTitle,
  );
  PeopleData copyWithCompanion(PeopleCompanion data) {
    return PeopleData(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      birthdayDay: data.birthdayDay.present
          ? data.birthdayDay.value
          : this.birthdayDay,
      birthdayMonth: data.birthdayMonth.present
          ? data.birthdayMonth.value
          : this.birthdayMonth,
      birthdayYear: data.birthdayYear.present
          ? data.birthdayYear.value
          : this.birthdayYear,
      note: data.note.present ? data.note.value : this.note,
      mergedIntoId: data.mergedIntoId.present
          ? data.mergedIntoId.value
          : this.mergedIntoId,
      organisation: data.organisation.present
          ? data.organisation.value
          : this.organisation,
      jobTitle: data.jobTitle.present ? data.jobTitle.value : this.jobTitle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleData(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('birthdayDay: $birthdayDay, ')
          ..write('birthdayMonth: $birthdayMonth, ')
          ..write('birthdayYear: $birthdayYear, ')
          ..write('note: $note, ')
          ..write('mergedIntoId: $mergedIntoId, ')
          ..write('organisation: $organisation, ')
          ..write('jobTitle: $jobTitle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deletedAt,
    name,
    birthdayDay,
    birthdayMonth,
    birthdayYear,
    note,
    mergedIntoId,
    organisation,
    jobTitle,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleData &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.birthdayDay == this.birthdayDay &&
          other.birthdayMonth == this.birthdayMonth &&
          other.birthdayYear == this.birthdayYear &&
          other.note == this.note &&
          other.mergedIntoId == this.mergedIntoId &&
          other.organisation == this.organisation &&
          other.jobTitle == this.jobTitle);
}

class PeopleCompanion extends UpdateCompanion<PeopleData> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<int?> birthdayDay;
  final Value<int?> birthdayMonth;
  final Value<int?> birthdayYear;
  final Value<String?> note;
  final Value<String?> mergedIntoId;
  final Value<String?> organisation;
  final Value<String?> jobTitle;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.birthdayDay = const Value.absent(),
    this.birthdayMonth = const Value.absent(),
    this.birthdayYear = const Value.absent(),
    this.note = const Value.absent(),
    this.mergedIntoId = const Value.absent(),
    this.organisation = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String name,
    this.birthdayDay = const Value.absent(),
    this.birthdayMonth = const Value.absent(),
    this.birthdayYear = const Value.absent(),
    this.note = const Value.absent(),
    this.mergedIntoId = const Value.absent(),
    this.organisation = const Value.absent(),
    this.jobTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       name = Value(name);
  static Insertable<PeopleData> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<int>? birthdayDay,
    Expression<int>? birthdayMonth,
    Expression<int>? birthdayYear,
    Expression<String>? note,
    Expression<String>? mergedIntoId,
    Expression<String>? organisation,
    Expression<String>? jobTitle,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (birthdayDay != null) 'birthday_day': birthdayDay,
      if (birthdayMonth != null) 'birthday_month': birthdayMonth,
      if (birthdayYear != null) 'birthday_year': birthdayYear,
      if (note != null) 'note': note,
      if (mergedIntoId != null) 'merged_into_id': mergedIntoId,
      if (organisation != null) 'organisation': organisation,
      if (jobTitle != null) 'job_title': jobTitle,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<int?>? birthdayDay,
    Value<int?>? birthdayMonth,
    Value<int?>? birthdayYear,
    Value<String?>? note,
    Value<String?>? mergedIntoId,
    Value<String?>? organisation,
    Value<String?>? jobTitle,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      birthdayDay: birthdayDay ?? this.birthdayDay,
      birthdayMonth: birthdayMonth ?? this.birthdayMonth,
      birthdayYear: birthdayYear ?? this.birthdayYear,
      note: note ?? this.note,
      mergedIntoId: mergedIntoId ?? this.mergedIntoId,
      organisation: organisation ?? this.organisation,
      jobTitle: jobTitle ?? this.jobTitle,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthdayDay.present) {
      map['birthday_day'] = Variable<int>(birthdayDay.value);
    }
    if (birthdayMonth.present) {
      map['birthday_month'] = Variable<int>(birthdayMonth.value);
    }
    if (birthdayYear.present) {
      map['birthday_year'] = Variable<int>(birthdayYear.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (mergedIntoId.present) {
      map['merged_into_id'] = Variable<String>(mergedIntoId.value);
    }
    if (organisation.present) {
      map['organisation'] = Variable<String>(organisation.value);
    }
    if (jobTitle.present) {
      map['job_title'] = Variable<String>(jobTitle.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('birthdayDay: $birthdayDay, ')
          ..write('birthdayMonth: $birthdayMonth, ')
          ..write('birthdayYear: $birthdayYear, ')
          ..write('note: $note, ')
          ..write('mergedIntoId: $mergedIntoId, ')
          ..write('organisation: $organisation, ')
          ..write('jobTitle: $jobTitle, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextsTable extends Contexts with TableInfo<$ContextsTable, Context> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contexts (id)',
    ),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    name,
    parentId,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Context> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Context map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Context(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $ContextsTable createAlias(String alias) {
    return $ContextsTable(attachedDatabase, alias);
  }
}

class Context extends DataClass implements Insertable<Context> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String name;
  final String? parentId;

  /// When the project was archived; null while it is in use (DD-018 point
  /// 6). User data, synchronised like every other column.
  final DateTime? archivedAt;
  const Context({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.name,
    this.parentId,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  ContextsCompanion toCompanion(bool nullToAbsent) {
    return ContextsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Context.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Context(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  Context copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => Context(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  Context copyWithCompanion(ContextsCompanion data) {
    return Context(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Context(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deletedAt, name, parentId, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Context &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.archivedAt == this.archivedAt);
}

class ContextsCompanion extends UpdateCompanion<Context> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const ContextsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       name = Value(name);
  static Insertable<Context> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String?>? parentId,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return ContextsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemType?, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ItemType?>($ItemsTable.$convertertypen);
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemStatus>($ItemsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<ItemSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemSource>($ItemsTable.$convertersource);
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisitAtMeta = const VerificationMeta(
    'revisitAt',
  );
  @override
  late final GeneratedColumn<DateTime> revisitAt = GeneratedColumn<DateTime>(
    'revisit_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requesterIdMeta = const VerificationMeta(
    'requesterId',
  );
  @override
  late final GeneratedColumn<String> requesterId = GeneratedColumn<String>(
    'requester_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _waitingOnIdMeta = const VerificationMeta(
    'waitingOnId',
  );
  @override
  late final GeneratedColumn<String> waitingOnId = GeneratedColumn<String>(
    'waiting_on_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _contextIdMeta = const VerificationMeta(
    'contextId',
  );
  @override
  late final GeneratedColumn<String> contextId = GeneratedColumn<String>(
    'context_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contexts (id)',
    ),
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemPriority?, String> priority =
      GeneratedColumn<String>(
        'priority',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<ItemPriority?>($ItemsTable.$converterpriorityn);
  static const VerificationMeta _askedAtMeta = const VerificationMeta(
    'askedAt',
  );
  @override
  late final GeneratedColumn<DateTime> askedAt = GeneratedColumn<DateTime>(
    'asked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _promiseMeta = const VerificationMeta(
    'promise',
  );
  @override
  late final GeneratedColumn<String> promise = GeneratedColumn<String>(
    'promise',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedAtMeta = const VerificationMeta(
    'expectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> expectedAt = GeneratedColumn<DateTime>(
    'expected_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    rawText,
    title,
    body,
    type,
    status,
    source,
    dueAt,
    revisitAt,
    requesterId,
    waitingOnId,
    contextId,
    reviewedAt,
    priority,
    askedAt,
    promise,
    expectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('revisit_at')) {
      context.handle(
        _revisitAtMeta,
        revisitAt.isAcceptableOrUnknown(data['revisit_at']!, _revisitAtMeta),
      );
    }
    if (data.containsKey('requester_id')) {
      context.handle(
        _requesterIdMeta,
        requesterId.isAcceptableOrUnknown(
          data['requester_id']!,
          _requesterIdMeta,
        ),
      );
    }
    if (data.containsKey('waiting_on_id')) {
      context.handle(
        _waitingOnIdMeta,
        waitingOnId.isAcceptableOrUnknown(
          data['waiting_on_id']!,
          _waitingOnIdMeta,
        ),
      );
    }
    if (data.containsKey('context_id')) {
      context.handle(
        _contextIdMeta,
        contextId.isAcceptableOrUnknown(data['context_id']!, _contextIdMeta),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    if (data.containsKey('asked_at')) {
      context.handle(
        _askedAtMeta,
        askedAt.isAcceptableOrUnknown(data['asked_at']!, _askedAtMeta),
      );
    }
    if (data.containsKey('promise')) {
      context.handle(
        _promiseMeta,
        promise.isAcceptableOrUnknown(data['promise']!, _promiseMeta),
      );
    }
    if (data.containsKey('expected_at')) {
      context.handle(
        _expectedAtMeta,
        expectedAt.isAcceptableOrUnknown(data['expected_at']!, _expectedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      type: $ItemsTable.$convertertypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        ),
      ),
      status: $ItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      source: $ItemsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      revisitAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}revisit_at'],
      ),
      requesterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requester_id'],
      ),
      waitingOnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waiting_on_id'],
      ),
      contextId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_id'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      ),
      priority: $ItemsTable.$converterpriorityn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}priority'],
        ),
      ),
      askedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}asked_at'],
      ),
      promise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}promise'],
      ),
      expectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_at'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ItemType, String, String> $convertertype =
      const EnumNameConverter<ItemType>(ItemType.values);
  static JsonTypeConverter2<ItemType?, String?, String?> $convertertypen =
      JsonTypeConverter2.asNullable($convertertype);
  static JsonTypeConverter2<ItemStatus, String, String> $converterstatus =
      const EnumNameConverter<ItemStatus>(ItemStatus.values);
  static JsonTypeConverter2<ItemSource, String, String> $convertersource =
      const EnumNameConverter<ItemSource>(ItemSource.values);
  static JsonTypeConverter2<ItemPriority, String, String> $converterpriority =
      const EnumNameConverter<ItemPriority>(ItemPriority.values);
  static JsonTypeConverter2<ItemPriority?, String?, String?>
  $converterpriorityn = JsonTypeConverter2.asNullable($converterpriority);
}

class Item extends DataClass implements Insertable<Item> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;

  /// Text exactly as captured; the source of truth for tokens (DD-004).
  final String rawText;
  final String? title;

  /// Markdown.
  final String? body;
  final ItemType? type;
  final ItemStatus status;
  final ItemSource source;
  final DateTime? dueAt;
  final DateTime? revisitAt;
  final String? requesterId;
  final String? waitingOnId;
  final String? contextId;

  /// When the user last chose *Keep* or *Still waiting* in the weekly review
  /// (AC REQ-051, DD-018 point 8): a user fact, synchronised. The last touch
  /// itself is worked out from this and the HLC, never stored (rule 6).
  final DateTime? reviewedAt;

  /// High, normal or low, from `*hoog`, `*2`, `*laag` in [rawText] (REQ-050,
  /// DD-004 point 11); follows the text like [dueAt]. Null when the text has
  /// no priority.
  final ItemPriority? priority;

  /// The day it was asked (REQ-046, DD-018 point 10), date-only as `due_at`;
  /// null: the day it was captured. Stored only when the user changes it.
  final DateTime? askedAt;

  /// What I promised, in short (REQ-046); null: the item's title.
  final String? promise;

  /// For a waiting item: the day I expect it by (REQ-047), date-only as
  /// `due_at`; never the deadline.
  final DateTime? expectedAt;
  const Item({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.rawText,
    this.title,
    this.body,
    this.type,
    required this.status,
    required this.source,
    this.dueAt,
    this.revisitAt,
    this.requesterId,
    this.waitingOnId,
    this.contextId,
    this.reviewedAt,
    this.priority,
    this.askedAt,
    this.promise,
    this.expectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>($ItemsTable.$convertertypen.toSql(type));
    }
    {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status),
      );
    }
    {
      map['source'] = Variable<String>(
        $ItemsTable.$convertersource.toSql(source),
      );
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || revisitAt != null) {
      map['revisit_at'] = Variable<DateTime>(revisitAt);
    }
    if (!nullToAbsent || requesterId != null) {
      map['requester_id'] = Variable<String>(requesterId);
    }
    if (!nullToAbsent || waitingOnId != null) {
      map['waiting_on_id'] = Variable<String>(waitingOnId);
    }
    if (!nullToAbsent || contextId != null) {
      map['context_id'] = Variable<String>(contextId);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(
        $ItemsTable.$converterpriorityn.toSql(priority),
      );
    }
    if (!nullToAbsent || askedAt != null) {
      map['asked_at'] = Variable<DateTime>(askedAt);
    }
    if (!nullToAbsent || promise != null) {
      map['promise'] = Variable<String>(promise);
    }
    if (!nullToAbsent || expectedAt != null) {
      map['expected_at'] = Variable<DateTime>(expectedAt);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      rawText: Value(rawText),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      status: Value(status),
      source: Value(source),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      revisitAt: revisitAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revisitAt),
      requesterId: requesterId == null && nullToAbsent
          ? const Value.absent()
          : Value(requesterId),
      waitingOnId: waitingOnId == null && nullToAbsent
          ? const Value.absent()
          : Value(waitingOnId),
      contextId: contextId == null && nullToAbsent
          ? const Value.absent()
          : Value(contextId),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      askedAt: askedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(askedAt),
      promise: promise == null && nullToAbsent
          ? const Value.absent()
          : Value(promise),
      expectedAt: expectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      rawText: serializer.fromJson<String>(json['rawText']),
      title: serializer.fromJson<String?>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      type: $ItemsTable.$convertertypen.fromJson(
        serializer.fromJson<String?>(json['type']),
      ),
      status: $ItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      source: $ItemsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      revisitAt: serializer.fromJson<DateTime?>(json['revisitAt']),
      requesterId: serializer.fromJson<String?>(json['requesterId']),
      waitingOnId: serializer.fromJson<String?>(json['waitingOnId']),
      contextId: serializer.fromJson<String?>(json['contextId']),
      reviewedAt: serializer.fromJson<DateTime?>(json['reviewedAt']),
      priority: $ItemsTable.$converterpriorityn.fromJson(
        serializer.fromJson<String?>(json['priority']),
      ),
      askedAt: serializer.fromJson<DateTime?>(json['askedAt']),
      promise: serializer.fromJson<String?>(json['promise']),
      expectedAt: serializer.fromJson<DateTime?>(json['expectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'rawText': serializer.toJson<String>(rawText),
      'title': serializer.toJson<String?>(title),
      'body': serializer.toJson<String?>(body),
      'type': serializer.toJson<String?>(
        $ItemsTable.$convertertypen.toJson(type),
      ),
      'status': serializer.toJson<String>(
        $ItemsTable.$converterstatus.toJson(status),
      ),
      'source': serializer.toJson<String>(
        $ItemsTable.$convertersource.toJson(source),
      ),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'revisitAt': serializer.toJson<DateTime?>(revisitAt),
      'requesterId': serializer.toJson<String?>(requesterId),
      'waitingOnId': serializer.toJson<String?>(waitingOnId),
      'contextId': serializer.toJson<String?>(contextId),
      'reviewedAt': serializer.toJson<DateTime?>(reviewedAt),
      'priority': serializer.toJson<String?>(
        $ItemsTable.$converterpriorityn.toJson(priority),
      ),
      'askedAt': serializer.toJson<DateTime?>(askedAt),
      'promise': serializer.toJson<String?>(promise),
      'expectedAt': serializer.toJson<DateTime?>(expectedAt),
    };
  }

  Item copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? rawText,
    Value<String?> title = const Value.absent(),
    Value<String?> body = const Value.absent(),
    Value<ItemType?> type = const Value.absent(),
    ItemStatus? status,
    ItemSource? source,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> revisitAt = const Value.absent(),
    Value<String?> requesterId = const Value.absent(),
    Value<String?> waitingOnId = const Value.absent(),
    Value<String?> contextId = const Value.absent(),
    Value<DateTime?> reviewedAt = const Value.absent(),
    Value<ItemPriority?> priority = const Value.absent(),
    Value<DateTime?> askedAt = const Value.absent(),
    Value<String?> promise = const Value.absent(),
    Value<DateTime?> expectedAt = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    rawText: rawText ?? this.rawText,
    title: title.present ? title.value : this.title,
    body: body.present ? body.value : this.body,
    type: type.present ? type.value : this.type,
    status: status ?? this.status,
    source: source ?? this.source,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    revisitAt: revisitAt.present ? revisitAt.value : this.revisitAt,
    requesterId: requesterId.present ? requesterId.value : this.requesterId,
    waitingOnId: waitingOnId.present ? waitingOnId.value : this.waitingOnId,
    contextId: contextId.present ? contextId.value : this.contextId,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
    priority: priority.present ? priority.value : this.priority,
    askedAt: askedAt.present ? askedAt.value : this.askedAt,
    promise: promise.present ? promise.value : this.promise,
    expectedAt: expectedAt.present ? expectedAt.value : this.expectedAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      revisitAt: data.revisitAt.present ? data.revisitAt.value : this.revisitAt,
      requesterId: data.requesterId.present
          ? data.requesterId.value
          : this.requesterId,
      waitingOnId: data.waitingOnId.present
          ? data.waitingOnId.value
          : this.waitingOnId,
      contextId: data.contextId.present ? data.contextId.value : this.contextId,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      askedAt: data.askedAt.present ? data.askedAt.value : this.askedAt,
      promise: data.promise.present ? data.promise.value : this.promise,
      expectedAt: data.expectedAt.present
          ? data.expectedAt.value
          : this.expectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rawText: $rawText, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('dueAt: $dueAt, ')
          ..write('revisitAt: $revisitAt, ')
          ..write('requesterId: $requesterId, ')
          ..write('waitingOnId: $waitingOnId, ')
          ..write('contextId: $contextId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('priority: $priority, ')
          ..write('askedAt: $askedAt, ')
          ..write('promise: $promise, ')
          ..write('expectedAt: $expectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deletedAt,
    rawText,
    title,
    body,
    type,
    status,
    source,
    dueAt,
    revisitAt,
    requesterId,
    waitingOnId,
    contextId,
    reviewedAt,
    priority,
    askedAt,
    promise,
    expectedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.rawText == this.rawText &&
          other.title == this.title &&
          other.body == this.body &&
          other.type == this.type &&
          other.status == this.status &&
          other.source == this.source &&
          other.dueAt == this.dueAt &&
          other.revisitAt == this.revisitAt &&
          other.requesterId == this.requesterId &&
          other.waitingOnId == this.waitingOnId &&
          other.contextId == this.contextId &&
          other.reviewedAt == this.reviewedAt &&
          other.priority == this.priority &&
          other.askedAt == this.askedAt &&
          other.promise == this.promise &&
          other.expectedAt == this.expectedAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> rawText;
  final Value<String?> title;
  final Value<String?> body;
  final Value<ItemType?> type;
  final Value<ItemStatus> status;
  final Value<ItemSource> source;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> revisitAt;
  final Value<String?> requesterId;
  final Value<String?> waitingOnId;
  final Value<String?> contextId;
  final Value<DateTime?> reviewedAt;
  final Value<ItemPriority?> priority;
  final Value<DateTime?> askedAt;
  final Value<String?> promise;
  final Value<DateTime?> expectedAt;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rawText = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.revisitAt = const Value.absent(),
    this.requesterId = const Value.absent(),
    this.waitingOnId = const Value.absent(),
    this.contextId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.askedAt = const Value.absent(),
    this.promise = const Value.absent(),
    this.expectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String rawText,
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.type = const Value.absent(),
    required ItemStatus status,
    required ItemSource source,
    this.dueAt = const Value.absent(),
    this.revisitAt = const Value.absent(),
    this.requesterId = const Value.absent(),
    this.waitingOnId = const Value.absent(),
    this.contextId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.askedAt = const Value.absent(),
    this.promise = const Value.absent(),
    this.expectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       rawText = Value(rawText),
       status = Value(status),
       source = Value(source);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? rawText,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? type,
    Expression<String>? status,
    Expression<String>? source,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? revisitAt,
    Expression<String>? requesterId,
    Expression<String>? waitingOnId,
    Expression<String>? contextId,
    Expression<DateTime>? reviewedAt,
    Expression<String>? priority,
    Expression<DateTime>? askedAt,
    Expression<String>? promise,
    Expression<DateTime>? expectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rawText != null) 'raw_text': rawText,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (dueAt != null) 'due_at': dueAt,
      if (revisitAt != null) 'revisit_at': revisitAt,
      if (requesterId != null) 'requester_id': requesterId,
      if (waitingOnId != null) 'waiting_on_id': waitingOnId,
      if (contextId != null) 'context_id': contextId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (priority != null) 'priority': priority,
      if (askedAt != null) 'asked_at': askedAt,
      if (promise != null) 'promise': promise,
      if (expectedAt != null) 'expected_at': expectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? rawText,
    Value<String?>? title,
    Value<String?>? body,
    Value<ItemType?>? type,
    Value<ItemStatus>? status,
    Value<ItemSource>? source,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? revisitAt,
    Value<String?>? requesterId,
    Value<String?>? waitingOnId,
    Value<String?>? contextId,
    Value<DateTime?>? reviewedAt,
    Value<ItemPriority?>? priority,
    Value<DateTime?>? askedAt,
    Value<String?>? promise,
    Value<DateTime?>? expectedAt,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      rawText: rawText ?? this.rawText,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      status: status ?? this.status,
      source: source ?? this.source,
      dueAt: dueAt ?? this.dueAt,
      revisitAt: revisitAt ?? this.revisitAt,
      requesterId: requesterId ?? this.requesterId,
      waitingOnId: waitingOnId ?? this.waitingOnId,
      contextId: contextId ?? this.contextId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      priority: priority ?? this.priority,
      askedAt: askedAt ?? this.askedAt,
      promise: promise ?? this.promise,
      expectedAt: expectedAt ?? this.expectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $ItemsTable.$convertertypen.toSql(type.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $ItemsTable.$convertersource.toSql(source.value),
      );
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (revisitAt.present) {
      map['revisit_at'] = Variable<DateTime>(revisitAt.value);
    }
    if (requesterId.present) {
      map['requester_id'] = Variable<String>(requesterId.value);
    }
    if (waitingOnId.present) {
      map['waiting_on_id'] = Variable<String>(waitingOnId.value);
    }
    if (contextId.present) {
      map['context_id'] = Variable<String>(contextId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(
        $ItemsTable.$converterpriorityn.toSql(priority.value),
      );
    }
    if (askedAt.present) {
      map['asked_at'] = Variable<DateTime>(askedAt.value);
    }
    if (promise.present) {
      map['promise'] = Variable<String>(promise.value);
    }
    if (expectedAt.present) {
      map['expected_at'] = Variable<DateTime>(expectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rawText: $rawText, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('dueAt: $dueAt, ')
          ..write('revisitAt: $revisitAt, ')
          ..write('requesterId: $requesterId, ')
          ..write('waitingOnId: $waitingOnId, ')
          ..write('contextId: $contextId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('priority: $priority, ')
          ..write('askedAt: $askedAt, ')
          ..write('promise: $promise, ')
          ..write('expectedAt: $expectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonAliasesTable extends PersonAliases
    with TableInfo<$PersonAliasesTable, PersonAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deletedAt, personId, alias];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonAliase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonAliase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
    );
  }

  @override
  $PersonAliasesTable createAlias(String alias) {
    return $PersonAliasesTable(attachedDatabase, alias);
  }
}

class PersonAliase extends DataClass implements Insertable<PersonAliase> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String personId;
  final String alias;
  const PersonAliase({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.personId,
    required this.alias,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['person_id'] = Variable<String>(personId);
    map['alias'] = Variable<String>(alias);
    return map;
  }

  PersonAliasesCompanion toCompanion(bool nullToAbsent) {
    return PersonAliasesCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      personId: Value(personId),
      alias: Value(alias),
    );
  }

  factory PersonAliase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonAliase(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      personId: serializer.fromJson<String>(json['personId']),
      alias: serializer.fromJson<String>(json['alias']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'personId': serializer.toJson<String>(personId),
      'alias': serializer.toJson<String>(alias),
    };
  }

  PersonAliase copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? personId,
    String? alias,
  }) => PersonAliase(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    personId: personId ?? this.personId,
    alias: alias ?? this.alias,
  );
  PersonAliase copyWithCompanion(PersonAliasesCompanion data) {
    return PersonAliase(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      personId: data.personId.present ? data.personId.value : this.personId,
      alias: data.alias.present ? data.alias.value : this.alias,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonAliase(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('personId: $personId, ')
          ..write('alias: $alias')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deletedAt, personId, alias);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonAliase &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.personId == this.personId &&
          other.alias == this.alias);
}

class PersonAliasesCompanion extends UpdateCompanion<PersonAliase> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> personId;
  final Value<String> alias;
  final Value<int> rowid;
  const PersonAliasesCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.personId = const Value.absent(),
    this.alias = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonAliasesCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String personId,
    required String alias,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       personId = Value(personId),
       alias = Value(alias);
  static Insertable<PersonAliase> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? personId,
    Expression<String>? alias,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (personId != null) 'person_id': personId,
      if (alias != null) 'alias': alias,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonAliasesCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? personId,
    Value<String>? alias,
    Value<int>? rowid,
  }) {
    return PersonAliasesCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      personId: personId ?? this.personId,
      alias: alias ?? this.alias,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonAliasesCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('personId: $personId, ')
          ..write('alias: $alias, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactDetailsTable extends ContactDetails
    with TableInfo<$ContactDetailsTable, ContactDetailRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactDetailsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ContactKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ContactKind>($ContactDetailsTable.$converterkind);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    personId,
    kind,
    value,
    label,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_details';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactDetailRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContactDetailRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactDetailRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      kind: $ContactDetailsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ContactDetailsTable createAlias(String alias) {
    return $ContactDetailsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContactKind, String, String> $converterkind =
      const EnumNameConverter<ContactKind>(ContactKind.values);
}

class ContactDetailRow extends DataClass
    implements Insertable<ContactDetailRow> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String personId;
  final ContactKind kind;
  final String value;

  /// A standard label (`work`, `mobile`, `private`, `other`, shown
  /// translated) or the user's own text; optional.
  final String? label;

  /// The order within the person's list.
  final int sortOrder;
  const ContactDetailRow({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.personId,
    required this.kind,
    required this.value,
    this.label,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['person_id'] = Variable<String>(personId);
    {
      map['kind'] = Variable<String>(
        $ContactDetailsTable.$converterkind.toSql(kind),
      );
    }
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ContactDetailsCompanion toCompanion(bool nullToAbsent) {
    return ContactDetailsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      personId: Value(personId),
      kind: Value(kind),
      value: Value(value),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      sortOrder: Value(sortOrder),
    );
  }

  factory ContactDetailRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactDetailRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      personId: serializer.fromJson<String>(json['personId']),
      kind: $ContactDetailsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      value: serializer.fromJson<String>(json['value']),
      label: serializer.fromJson<String?>(json['label']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'personId': serializer.toJson<String>(personId),
      'kind': serializer.toJson<String>(
        $ContactDetailsTable.$converterkind.toJson(kind),
      ),
      'value': serializer.toJson<String>(value),
      'label': serializer.toJson<String?>(label),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ContactDetailRow copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? personId,
    ContactKind? kind,
    String? value,
    Value<String?> label = const Value.absent(),
    int? sortOrder,
  }) => ContactDetailRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    personId: personId ?? this.personId,
    kind: kind ?? this.kind,
    value: value ?? this.value,
    label: label.present ? label.value : this.label,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ContactDetailRow copyWithCompanion(ContactDetailsCompanion data) {
    return ContactDetailRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      personId: data.personId.present ? data.personId.value : this.personId,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
      label: data.label.present ? data.label.value : this.label,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactDetailRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('personId: $personId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deletedAt, personId, kind, value, label, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactDetailRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.personId == this.personId &&
          other.kind == this.kind &&
          other.value == this.value &&
          other.label == this.label &&
          other.sortOrder == this.sortOrder);
}

class ContactDetailsCompanion extends UpdateCompanion<ContactDetailRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> personId;
  final Value<ContactKind> kind;
  final Value<String> value;
  final Value<String?> label;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ContactDetailsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.personId = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.label = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactDetailsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String personId,
    required ContactKind kind,
    required String value,
    this.label = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       personId = Value(personId),
       kind = Value(kind),
       value = Value(value),
       sortOrder = Value(sortOrder);
  static Insertable<ContactDetailRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? personId,
    Expression<String>? kind,
    Expression<String>? value,
    Expression<String>? label,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (personId != null) 'person_id': personId,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (label != null) 'label': label,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactDetailsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? personId,
    Value<ContactKind>? kind,
    Value<String>? value,
    Value<String?>? label,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ContactDetailsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      personId: personId ?? this.personId,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      label: label ?? this.label,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ContactDetailsTable.$converterkind.toSql(kind.value),
      );
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactDetailsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('personId: $personId, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('label: $label, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, hlc, deletedAt, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String name;
  const Tag({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
    };
  }

  Tag copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
  }) => Tag(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deletedAt, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pipelineVersionMeta = const VerificationMeta(
    'pipelineVersion',
  );
  @override
  late final GeneratedColumn<int> pipelineVersion = GeneratedColumn<int>(
    'pipeline_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    itemId,
    personId,
    mimeType,
    sizeBytes,
    storagePath,
    pipelineVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storagePathMeta);
    }
    if (data.containsKey('pipeline_version')) {
      context.handle(
        _pipelineVersionMeta,
        pipelineVersion.isAcceptableOrUnknown(
          data['pipeline_version']!,
          _pipelineVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pipelineVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      )!,
      pipelineVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pipeline_version'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String? itemId;
  final String? personId;
  final String mimeType;
  final int sizeBytes;

  /// Location of the encrypted file (for photos: the display version).
  final String storagePath;

  /// Version of the photo pipeline that produced the file (DD-006/D6).
  final int pipelineVersion;
  const Attachment({
    required this.id,
    required this.hlc,
    this.deletedAt,
    this.itemId,
    this.personId,
    required this.mimeType,
    required this.sizeBytes,
    required this.storagePath,
    required this.pipelineVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['storage_path'] = Variable<String>(storagePath);
    map['pipeline_version'] = Variable<int>(pipelineVersion);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      storagePath: Value(storagePath),
      pipelineVersion: Value(pipelineVersion),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      personId: serializer.fromJson<String?>(json['personId']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      storagePath: serializer.fromJson<String>(json['storagePath']),
      pipelineVersion: serializer.fromJson<int>(json['pipelineVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'itemId': serializer.toJson<String?>(itemId),
      'personId': serializer.toJson<String?>(personId),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'storagePath': serializer.toJson<String>(storagePath),
      'pipelineVersion': serializer.toJson<int>(pipelineVersion),
    };
  }

  Attachment copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> itemId = const Value.absent(),
    Value<String?> personId = const Value.absent(),
    String? mimeType,
    int? sizeBytes,
    String? storagePath,
    int? pipelineVersion,
  }) => Attachment(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    itemId: itemId.present ? itemId.value : this.itemId,
    personId: personId.present ? personId.value : this.personId,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    storagePath: storagePath ?? this.storagePath,
    pipelineVersion: pipelineVersion ?? this.pipelineVersion,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      personId: data.personId.present ? data.personId.value : this.personId,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      storagePath: data.storagePath.present
          ? data.storagePath.value
          : this.storagePath,
      pipelineVersion: data.pipelineVersion.present
          ? data.pipelineVersion.value
          : this.pipelineVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('personId: $personId, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('storagePath: $storagePath, ')
          ..write('pipelineVersion: $pipelineVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deletedAt,
    itemId,
    personId,
    mimeType,
    sizeBytes,
    storagePath,
    pipelineVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.itemId == this.itemId &&
          other.personId == this.personId &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.storagePath == this.storagePath &&
          other.pipelineVersion == this.pipelineVersion);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String?> itemId;
  final Value<String?> personId;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String> storagePath;
  final Value<int> pipelineVersion;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.personId = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.pipelineVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.personId = const Value.absent(),
    required String mimeType,
    required int sizeBytes,
    required String storagePath,
    required int pipelineVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       storagePath = Value(storagePath),
       pipelineVersion = Value(pipelineVersion);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? itemId,
    Expression<String>? personId,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? storagePath,
    Expression<int>? pipelineVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (itemId != null) 'item_id': itemId,
      if (personId != null) 'person_id': personId,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (storagePath != null) 'storage_path': storagePath,
      if (pipelineVersion != null) 'pipeline_version': pipelineVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String?>? itemId,
    Value<String?>? personId,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<String>? storagePath,
    Value<int>? pipelineVersion,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      itemId: itemId ?? this.itemId,
      personId: personId ?? this.personId,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      storagePath: storagePath ?? this.storagePath,
      pipelineVersion: pipelineVersion ?? this.pipelineVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (pipelineVersion.present) {
      map['pipeline_version'] = Variable<int>(pipelineVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('personId: $personId, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('storagePath: $storagePath, ')
          ..write('pipelineVersion: $pipelineVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemLinksTable extends ItemLinks
    with TableInfo<$ItemLinksTable, ItemLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _fromItemIdMeta = const VerificationMeta(
    'fromItemId',
  );
  @override
  late final GeneratedColumn<String> fromItemId = GeneratedColumn<String>(
    'from_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _toItemIdMeta = const VerificationMeta(
    'toItemId',
  );
  @override
  late final GeneratedColumn<String> toItemId = GeneratedColumn<String>(
    'to_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    fromItemId,
    toItemId,
    kind,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('from_item_id')) {
      context.handle(
        _fromItemIdMeta,
        fromItemId.isAcceptableOrUnknown(
          data['from_item_id']!,
          _fromItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromItemIdMeta);
    }
    if (data.containsKey('to_item_id')) {
      context.handle(
        _toItemIdMeta,
        toItemId.isAcceptableOrUnknown(data['to_item_id']!, _toItemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toItemIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      fromItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_item_id'],
      )!,
      toItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_item_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
    );
  }

  @override
  $ItemLinksTable createAlias(String alias) {
    return $ItemLinksTable(attachedDatabase, alias);
  }
}

class ItemLink extends DataClass implements Insertable<ItemLink> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String fromItemId;
  final String toItemId;
  final String kind;

  /// Schema v11 (T10.9).
  final String? label;
  const ItemLink({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.fromItemId,
    required this.toItemId,
    required this.kind,
    this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['from_item_id'] = Variable<String>(fromItemId);
    map['to_item_id'] = Variable<String>(toItemId);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  ItemLinksCompanion toCompanion(bool nullToAbsent) {
    return ItemLinksCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      fromItemId: Value(fromItemId),
      toItemId: Value(toItemId),
      kind: Value(kind),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
    );
  }

  factory ItemLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemLink(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      fromItemId: serializer.fromJson<String>(json['fromItemId']),
      toItemId: serializer.fromJson<String>(json['toItemId']),
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'fromItemId': serializer.toJson<String>(fromItemId),
      'toItemId': serializer.toJson<String>(toItemId),
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String?>(label),
    };
  }

  ItemLink copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? fromItemId,
    String? toItemId,
    String? kind,
    Value<String?> label = const Value.absent(),
  }) => ItemLink(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    fromItemId: fromItemId ?? this.fromItemId,
    toItemId: toItemId ?? this.toItemId,
    kind: kind ?? this.kind,
    label: label.present ? label.value : this.label,
  );
  ItemLink copyWithCompanion(ItemLinksCompanion data) {
    return ItemLink(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      fromItemId: data.fromItemId.present
          ? data.fromItemId.value
          : this.fromItemId,
      toItemId: data.toItemId.present ? data.toItemId.value : this.toItemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemLink(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fromItemId: $fromItemId, ')
          ..write('toItemId: $toItemId, ')
          ..write('kind: $kind, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deletedAt, fromItemId, toItemId, kind, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemLink &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.fromItemId == this.fromItemId &&
          other.toItemId == this.toItemId &&
          other.kind == this.kind &&
          other.label == this.label);
}

class ItemLinksCompanion extends UpdateCompanion<ItemLink> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> fromItemId;
  final Value<String> toItemId;
  final Value<String> kind;
  final Value<String?> label;
  final Value<int> rowid;
  const ItemLinksCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.fromItemId = const Value.absent(),
    this.toItemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemLinksCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String fromItemId,
    required String toItemId,
    required String kind,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       fromItemId = Value(fromItemId),
       toItemId = Value(toItemId),
       kind = Value(kind);
  static Insertable<ItemLink> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? fromItemId,
    Expression<String>? toItemId,
    Expression<String>? kind,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (fromItemId != null) 'from_item_id': fromItemId,
      if (toItemId != null) 'to_item_id': toItemId,
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? fromItemId,
    Value<String>? toItemId,
    Value<String>? kind,
    Value<String?>? label,
    Value<int>? rowid,
  }) {
    return ItemLinksCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      fromItemId: fromItemId ?? this.fromItemId,
      toItemId: toItemId ?? this.toItemId,
      kind: kind ?? this.kind,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (fromItemId.present) {
      map['from_item_id'] = Variable<String>(fromItemId.value);
    }
    if (toItemId.present) {
      map['to_item_id'] = Variable<String>(toItemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemLinksCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fromItemId: $fromItemId, ')
          ..write('toItemId: $toItemId, ')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemCompletionsTable extends ItemCompletions
    with TableInfo<$ItemCompletionsTable, ItemCompletion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemCompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _occurrenceOnMeta = const VerificationMeta(
    'occurrenceOn',
  );
  @override
  late final GeneratedColumn<DateTime> occurrenceOn = GeneratedColumn<DateTime>(
    'occurrence_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedOnMeta = const VerificationMeta(
    'completedOn',
  );
  @override
  late final GeneratedColumn<DateTime> completedOn = GeneratedColumn<DateTime>(
    'completed_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    itemId,
    occurrenceOn,
    completedOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemCompletion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('occurrence_on')) {
      context.handle(
        _occurrenceOnMeta,
        occurrenceOn.isAcceptableOrUnknown(
          data['occurrence_on']!,
          _occurrenceOnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceOnMeta);
    }
    if (data.containsKey('completed_on')) {
      context.handle(
        _completedOnMeta,
        completedOn.isAcceptableOrUnknown(
          data['completed_on']!,
          _completedOnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedOnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemCompletion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemCompletion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      occurrenceOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurrence_on'],
      )!,
      completedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_on'],
      )!,
    );
  }

  @override
  $ItemCompletionsTable createAlias(String alias) {
    return $ItemCompletionsTable(attachedDatabase, alias);
  }
}

class ItemCompletion extends DataClass implements Insertable<ItemCompletion> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String itemId;

  /// The date of the completed time, date-only as `items.due_at`.
  final DateTime occurrenceOn;

  /// The local day it was done, date-only as `items.due_at`: a user fact,
  /// so every device works out the same next date.
  final DateTime completedOn;
  const ItemCompletion({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.itemId,
    required this.occurrenceOn,
    required this.completedOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['item_id'] = Variable<String>(itemId);
    map['occurrence_on'] = Variable<DateTime>(occurrenceOn);
    map['completed_on'] = Variable<DateTime>(completedOn);
    return map;
  }

  ItemCompletionsCompanion toCompanion(bool nullToAbsent) {
    return ItemCompletionsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      itemId: Value(itemId),
      occurrenceOn: Value(occurrenceOn),
      completedOn: Value(completedOn),
    );
  }

  factory ItemCompletion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemCompletion(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      itemId: serializer.fromJson<String>(json['itemId']),
      occurrenceOn: serializer.fromJson<DateTime>(json['occurrenceOn']),
      completedOn: serializer.fromJson<DateTime>(json['completedOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'itemId': serializer.toJson<String>(itemId),
      'occurrenceOn': serializer.toJson<DateTime>(occurrenceOn),
      'completedOn': serializer.toJson<DateTime>(completedOn),
    };
  }

  ItemCompletion copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? itemId,
    DateTime? occurrenceOn,
    DateTime? completedOn,
  }) => ItemCompletion(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    itemId: itemId ?? this.itemId,
    occurrenceOn: occurrenceOn ?? this.occurrenceOn,
    completedOn: completedOn ?? this.completedOn,
  );
  ItemCompletion copyWithCompanion(ItemCompletionsCompanion data) {
    return ItemCompletion(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      occurrenceOn: data.occurrenceOn.present
          ? data.occurrenceOn.value
          : this.occurrenceOn,
      completedOn: data.completedOn.present
          ? data.completedOn.value
          : this.completedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemCompletion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceOn: $occurrenceOn, ')
          ..write('completedOn: $completedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, hlc, deletedAt, itemId, occurrenceOn, completedOn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemCompletion &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.itemId == this.itemId &&
          other.occurrenceOn == this.occurrenceOn &&
          other.completedOn == this.completedOn);
}

class ItemCompletionsCompanion extends UpdateCompanion<ItemCompletion> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> itemId;
  final Value<DateTime> occurrenceOn;
  final Value<DateTime> completedOn;
  final Value<int> rowid;
  const ItemCompletionsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.occurrenceOn = const Value.absent(),
    this.completedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemCompletionsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String itemId,
    required DateTime occurrenceOn,
    required DateTime completedOn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       itemId = Value(itemId),
       occurrenceOn = Value(occurrenceOn),
       completedOn = Value(completedOn);
  static Insertable<ItemCompletion> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? itemId,
    Expression<DateTime>? occurrenceOn,
    Expression<DateTime>? completedOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (itemId != null) 'item_id': itemId,
      if (occurrenceOn != null) 'occurrence_on': occurrenceOn,
      if (completedOn != null) 'completed_on': completedOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemCompletionsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? itemId,
    Value<DateTime>? occurrenceOn,
    Value<DateTime>? completedOn,
    Value<int>? rowid,
  }) {
    return ItemCompletionsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      itemId: itemId ?? this.itemId,
      occurrenceOn: occurrenceOn ?? this.occurrenceOn,
      completedOn: completedOn ?? this.completedOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (occurrenceOn.present) {
      map['occurrence_on'] = Variable<DateTime>(occurrenceOn.value);
    }
    if (completedOn.present) {
      map['completed_on'] = Variable<DateTime>(completedOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemCompletionsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('occurrenceOn: $occurrenceOn, ')
          ..write('completedOn: $completedOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DuplicateDismissalsTable extends DuplicateDismissals
    with TableInfo<$DuplicateDismissalsTable, DuplicateDismissal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DuplicateDismissalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _otherItemIdMeta = const VerificationMeta(
    'otherItemId',
  );
  @override
  late final GeneratedColumn<String> otherItemId = GeneratedColumn<String>(
    'other_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    itemId,
    otherItemId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'duplicate_dismissals';
  @override
  VerificationContext validateIntegrity(
    Insertable<DuplicateDismissal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('other_item_id')) {
      context.handle(
        _otherItemIdMeta,
        otherItemId.isAcceptableOrUnknown(
          data['other_item_id']!,
          _otherItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_otherItemIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DuplicateDismissal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DuplicateDismissal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      otherItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_item_id'],
      )!,
    );
  }

  @override
  $DuplicateDismissalsTable createAlias(String alias) {
    return $DuplicateDismissalsTable(attachedDatabase, alias);
  }
}

class DuplicateDismissal extends DataClass
    implements Insertable<DuplicateDismissal> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String itemId;
  final String otherItemId;
  const DuplicateDismissal({
    required this.id,
    required this.hlc,
    this.deletedAt,
    required this.itemId,
    required this.otherItemId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['item_id'] = Variable<String>(itemId);
    map['other_item_id'] = Variable<String>(otherItemId);
    return map;
  }

  DuplicateDismissalsCompanion toCompanion(bool nullToAbsent) {
    return DuplicateDismissalsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      itemId: Value(itemId),
      otherItemId: Value(otherItemId),
    );
  }

  factory DuplicateDismissal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DuplicateDismissal(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      itemId: serializer.fromJson<String>(json['itemId']),
      otherItemId: serializer.fromJson<String>(json['otherItemId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'itemId': serializer.toJson<String>(itemId),
      'otherItemId': serializer.toJson<String>(otherItemId),
    };
  }

  DuplicateDismissal copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? itemId,
    String? otherItemId,
  }) => DuplicateDismissal(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    itemId: itemId ?? this.itemId,
    otherItemId: otherItemId ?? this.otherItemId,
  );
  DuplicateDismissal copyWithCompanion(DuplicateDismissalsCompanion data) {
    return DuplicateDismissal(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      otherItemId: data.otherItemId.present
          ? data.otherItemId.value
          : this.otherItemId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateDismissal(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('otherItemId: $otherItemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, hlc, deletedAt, itemId, otherItemId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DuplicateDismissal &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.itemId == this.itemId &&
          other.otherItemId == this.otherItemId);
}

class DuplicateDismissalsCompanion extends UpdateCompanion<DuplicateDismissal> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String> itemId;
  final Value<String> otherItemId;
  final Value<int> rowid;
  const DuplicateDismissalsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.otherItemId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DuplicateDismissalsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    required String itemId,
    required String otherItemId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc),
       itemId = Value(itemId),
       otherItemId = Value(otherItemId);
  static Insertable<DuplicateDismissal> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? itemId,
    Expression<String>? otherItemId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (itemId != null) 'item_id': itemId,
      if (otherItemId != null) 'other_item_id': otherItemId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DuplicateDismissalsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String>? itemId,
    Value<String>? otherItemId,
    Value<int>? rowid,
  }) {
    return DuplicateDismissalsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      itemId: itemId ?? this.itemId,
      otherItemId: otherItemId ?? this.otherItemId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (otherItemId.present) {
      map['other_item_id'] = Variable<String>(otherItemId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DuplicateDismissalsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('otherItemId: $otherItemId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SnapshotsTable extends Snapshots
    with TableInfo<$SnapshotsTable, SnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _contextIdMeta = const VerificationMeta(
    'contextId',
  );
  @override
  late final GeneratedColumn<String> contextId = GeneratedColumn<String>(
    'context_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES contexts (id)',
    ),
  );
  static const VerificationMeta _nextStepMeta = const VerificationMeta(
    'nextStep',
  );
  @override
  late final GeneratedColumn<String> nextStep = GeneratedColumn<String>(
    'next_step',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inMindMeta = const VerificationMeta('inMind');
  @override
  late final GeneratedColumn<String> inMind = GeneratedColumn<String>(
    'in_mind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumedAtMeta = const VerificationMeta(
    'resumedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resumedAt = GeneratedColumn<DateTime>(
    'resumed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlc,
    deletedAt,
    itemId,
    contextId,
    nextStep,
    inMind,
    resumedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('context_id')) {
      context.handle(
        _contextIdMeta,
        contextId.isAcceptableOrUnknown(data['context_id']!, _contextIdMeta),
      );
    }
    if (data.containsKey('next_step')) {
      context.handle(
        _nextStepMeta,
        nextStep.isAcceptableOrUnknown(data['next_step']!, _nextStepMeta),
      );
    }
    if (data.containsKey('in_mind')) {
      context.handle(
        _inMindMeta,
        inMind.isAcceptableOrUnknown(data['in_mind']!, _inMindMeta),
      );
    }
    if (data.containsKey('resumed_at')) {
      context.handle(
        _resumedAtMeta,
        resumedAt.isAcceptableOrUnknown(data['resumed_at']!, _resumedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SnapshotRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      contextId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_id'],
      ),
      nextStep: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_step'],
      ),
      inMind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_mind'],
      ),
      resumedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resumed_at'],
      ),
    );
  }

  @override
  $SnapshotsTable createAlias(String alias) {
    return $SnapshotsTable(attachedDatabase, alias);
  }
}

class SnapshotRow extends DataClass implements Insertable<SnapshotRow> {
  /// UUIDv7, generated by the domain layer.
  final String id;

  /// Packed HLC of the last change (see `Hlc.pack`).
  final String hlc;

  /// Tombstone: set instead of deleting the row.
  final DateTime? deletedAt;
  final String? itemId;
  final String? contextId;
  final String? nextStep;
  final String? inMind;
  final DateTime? resumedAt;
  const SnapshotRow({
    required this.id,
    required this.hlc,
    this.deletedAt,
    this.itemId,
    this.contextId,
    this.nextStep,
    this.inMind,
    this.resumedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc'] = Variable<String>(hlc);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || contextId != null) {
      map['context_id'] = Variable<String>(contextId);
    }
    if (!nullToAbsent || nextStep != null) {
      map['next_step'] = Variable<String>(nextStep);
    }
    if (!nullToAbsent || inMind != null) {
      map['in_mind'] = Variable<String>(inMind);
    }
    if (!nullToAbsent || resumedAt != null) {
      map['resumed_at'] = Variable<DateTime>(resumedAt);
    }
    return map;
  }

  SnapshotsCompanion toCompanion(bool nullToAbsent) {
    return SnapshotsCompanion(
      id: Value(id),
      hlc: Value(hlc),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      contextId: contextId == null && nullToAbsent
          ? const Value.absent()
          : Value(contextId),
      nextStep: nextStep == null && nullToAbsent
          ? const Value.absent()
          : Value(nextStep),
      inMind: inMind == null && nullToAbsent
          ? const Value.absent()
          : Value(inMind),
      resumedAt: resumedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resumedAt),
    );
  }

  factory SnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SnapshotRow(
      id: serializer.fromJson<String>(json['id']),
      hlc: serializer.fromJson<String>(json['hlc']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      contextId: serializer.fromJson<String?>(json['contextId']),
      nextStep: serializer.fromJson<String?>(json['nextStep']),
      inMind: serializer.fromJson<String?>(json['inMind']),
      resumedAt: serializer.fromJson<DateTime?>(json['resumedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlc': serializer.toJson<String>(hlc),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'itemId': serializer.toJson<String?>(itemId),
      'contextId': serializer.toJson<String?>(contextId),
      'nextStep': serializer.toJson<String?>(nextStep),
      'inMind': serializer.toJson<String?>(inMind),
      'resumedAt': serializer.toJson<DateTime?>(resumedAt),
    };
  }

  SnapshotRow copyWith({
    String? id,
    String? hlc,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> itemId = const Value.absent(),
    Value<String?> contextId = const Value.absent(),
    Value<String?> nextStep = const Value.absent(),
    Value<String?> inMind = const Value.absent(),
    Value<DateTime?> resumedAt = const Value.absent(),
  }) => SnapshotRow(
    id: id ?? this.id,
    hlc: hlc ?? this.hlc,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    itemId: itemId.present ? itemId.value : this.itemId,
    contextId: contextId.present ? contextId.value : this.contextId,
    nextStep: nextStep.present ? nextStep.value : this.nextStep,
    inMind: inMind.present ? inMind.value : this.inMind,
    resumedAt: resumedAt.present ? resumedAt.value : this.resumedAt,
  );
  SnapshotRow copyWithCompanion(SnapshotsCompanion data) {
    return SnapshotRow(
      id: data.id.present ? data.id.value : this.id,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      contextId: data.contextId.present ? data.contextId.value : this.contextId,
      nextStep: data.nextStep.present ? data.nextStep.value : this.nextStep,
      inMind: data.inMind.present ? data.inMind.value : this.inMind,
      resumedAt: data.resumedAt.present ? data.resumedAt.value : this.resumedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotRow(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('contextId: $contextId, ')
          ..write('nextStep: $nextStep, ')
          ..write('inMind: $inMind, ')
          ..write('resumedAt: $resumedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlc,
    deletedAt,
    itemId,
    contextId,
    nextStep,
    inMind,
    resumedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapshotRow &&
          other.id == this.id &&
          other.hlc == this.hlc &&
          other.deletedAt == this.deletedAt &&
          other.itemId == this.itemId &&
          other.contextId == this.contextId &&
          other.nextStep == this.nextStep &&
          other.inMind == this.inMind &&
          other.resumedAt == this.resumedAt);
}

class SnapshotsCompanion extends UpdateCompanion<SnapshotRow> {
  final Value<String> id;
  final Value<String> hlc;
  final Value<DateTime?> deletedAt;
  final Value<String?> itemId;
  final Value<String?> contextId;
  final Value<String?> nextStep;
  final Value<String?> inMind;
  final Value<DateTime?> resumedAt;
  final Value<int> rowid;
  const SnapshotsCompanion({
    this.id = const Value.absent(),
    this.hlc = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.contextId = const Value.absent(),
    this.nextStep = const Value.absent(),
    this.inMind = const Value.absent(),
    this.resumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SnapshotsCompanion.insert({
    required String id,
    required String hlc,
    this.deletedAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.contextId = const Value.absent(),
    this.nextStep = const Value.absent(),
    this.inMind = const Value.absent(),
    this.resumedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hlc = Value(hlc);
  static Insertable<SnapshotRow> custom({
    Expression<String>? id,
    Expression<String>? hlc,
    Expression<DateTime>? deletedAt,
    Expression<String>? itemId,
    Expression<String>? contextId,
    Expression<String>? nextStep,
    Expression<String>? inMind,
    Expression<DateTime>? resumedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlc != null) 'hlc': hlc,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (itemId != null) 'item_id': itemId,
      if (contextId != null) 'context_id': contextId,
      if (nextStep != null) 'next_step': nextStep,
      if (inMind != null) 'in_mind': inMind,
      if (resumedAt != null) 'resumed_at': resumedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? hlc,
    Value<DateTime?>? deletedAt,
    Value<String?>? itemId,
    Value<String?>? contextId,
    Value<String?>? nextStep,
    Value<String?>? inMind,
    Value<DateTime?>? resumedAt,
    Value<int>? rowid,
  }) {
    return SnapshotsCompanion(
      id: id ?? this.id,
      hlc: hlc ?? this.hlc,
      deletedAt: deletedAt ?? this.deletedAt,
      itemId: itemId ?? this.itemId,
      contextId: contextId ?? this.contextId,
      nextStep: nextStep ?? this.nextStep,
      inMind: inMind ?? this.inMind,
      resumedAt: resumedAt ?? this.resumedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (contextId.present) {
      map['context_id'] = Variable<String>(contextId.value);
    }
    if (nextStep.present) {
      map['next_step'] = Variable<String>(nextStep.value);
    }
    if (inMind.present) {
      map['in_mind'] = Variable<String>(inMind.value);
    }
    if (resumedAt.present) {
      map['resumed_at'] = Variable<DateTime>(resumedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('hlc: $hlc, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('itemId: $itemId, ')
          ..write('contextId: $contextId, ')
          ..write('nextStep: $nextStep, ')
          ..write('inMind: $inMind, ')
          ..write('resumedAt: $resumedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TokensTable extends Tokens with TableInfo<$TokensTable, Token> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _tokenTypeMeta = const VerificationMeta(
    'tokenType',
  );
  @override
  late final GeneratedColumn<String> tokenType = GeneratedColumn<String>(
    'token_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawValueMeta = const VerificationMeta(
    'rawValue',
  );
  @override
  late final GeneratedColumn<String> rawValue = GeneratedColumn<String>(
    'raw_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedValueMeta = const VerificationMeta(
    'resolvedValue',
  );
  @override
  late final GeneratedColumn<String> resolvedValue = GeneratedColumn<String>(
    'resolved_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parserVersionMeta = const VerificationMeta(
    'parserVersion',
  );
  @override
  late final GeneratedColumn<int> parserVersion = GeneratedColumn<int>(
    'parser_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    tokenType,
    rawValue,
    resolvedValue,
    parserVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<Token> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('token_type')) {
      context.handle(
        _tokenTypeMeta,
        tokenType.isAcceptableOrUnknown(data['token_type']!, _tokenTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_tokenTypeMeta);
    }
    if (data.containsKey('raw_value')) {
      context.handle(
        _rawValueMeta,
        rawValue.isAcceptableOrUnknown(data['raw_value']!, _rawValueMeta),
      );
    } else if (isInserting) {
      context.missing(_rawValueMeta);
    }
    if (data.containsKey('resolved_value')) {
      context.handle(
        _resolvedValueMeta,
        resolvedValue.isAcceptableOrUnknown(
          data['resolved_value']!,
          _resolvedValueMeta,
        ),
      );
    }
    if (data.containsKey('parser_version')) {
      context.handle(
        _parserVersionMeta,
        parserVersion.isAcceptableOrUnknown(
          data['parser_version']!,
          _parserVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parserVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Token map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Token(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      tokenType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}token_type'],
      )!,
      rawValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_value'],
      )!,
      resolvedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_value'],
      ),
      parserVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parser_version'],
      )!,
    );
  }

  @override
  $TokensTable createAlias(String alias) {
    return $TokensTable(attachedDatabase, alias);
  }
}

class Token extends DataClass implements Insertable<Token> {
  /// UUIDv7.
  final String id;
  final String itemId;
  final String tokenType;
  final String rawValue;
  final String? resolvedValue;
  final int parserVersion;
  const Token({
    required this.id,
    required this.itemId,
    required this.tokenType,
    required this.rawValue,
    this.resolvedValue,
    required this.parserVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['token_type'] = Variable<String>(tokenType);
    map['raw_value'] = Variable<String>(rawValue);
    if (!nullToAbsent || resolvedValue != null) {
      map['resolved_value'] = Variable<String>(resolvedValue);
    }
    map['parser_version'] = Variable<int>(parserVersion);
    return map;
  }

  TokensCompanion toCompanion(bool nullToAbsent) {
    return TokensCompanion(
      id: Value(id),
      itemId: Value(itemId),
      tokenType: Value(tokenType),
      rawValue: Value(rawValue),
      resolvedValue: resolvedValue == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedValue),
      parserVersion: Value(parserVersion),
    );
  }

  factory Token.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Token(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      tokenType: serializer.fromJson<String>(json['tokenType']),
      rawValue: serializer.fromJson<String>(json['rawValue']),
      resolvedValue: serializer.fromJson<String?>(json['resolvedValue']),
      parserVersion: serializer.fromJson<int>(json['parserVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'tokenType': serializer.toJson<String>(tokenType),
      'rawValue': serializer.toJson<String>(rawValue),
      'resolvedValue': serializer.toJson<String?>(resolvedValue),
      'parserVersion': serializer.toJson<int>(parserVersion),
    };
  }

  Token copyWith({
    String? id,
    String? itemId,
    String? tokenType,
    String? rawValue,
    Value<String?> resolvedValue = const Value.absent(),
    int? parserVersion,
  }) => Token(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    tokenType: tokenType ?? this.tokenType,
    rawValue: rawValue ?? this.rawValue,
    resolvedValue: resolvedValue.present
        ? resolvedValue.value
        : this.resolvedValue,
    parserVersion: parserVersion ?? this.parserVersion,
  );
  Token copyWithCompanion(TokensCompanion data) {
    return Token(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      tokenType: data.tokenType.present ? data.tokenType.value : this.tokenType,
      rawValue: data.rawValue.present ? data.rawValue.value : this.rawValue,
      resolvedValue: data.resolvedValue.present
          ? data.resolvedValue.value
          : this.resolvedValue,
      parserVersion: data.parserVersion.present
          ? data.parserVersion.value
          : this.parserVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Token(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('tokenType: $tokenType, ')
          ..write('rawValue: $rawValue, ')
          ..write('resolvedValue: $resolvedValue, ')
          ..write('parserVersion: $parserVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    tokenType,
    rawValue,
    resolvedValue,
    parserVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Token &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.tokenType == this.tokenType &&
          other.rawValue == this.rawValue &&
          other.resolvedValue == this.resolvedValue &&
          other.parserVersion == this.parserVersion);
}

class TokensCompanion extends UpdateCompanion<Token> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> tokenType;
  final Value<String> rawValue;
  final Value<String?> resolvedValue;
  final Value<int> parserVersion;
  final Value<int> rowid;
  const TokensCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.tokenType = const Value.absent(),
    this.rawValue = const Value.absent(),
    this.resolvedValue = const Value.absent(),
    this.parserVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TokensCompanion.insert({
    required String id,
    required String itemId,
    required String tokenType,
    required String rawValue,
    this.resolvedValue = const Value.absent(),
    required int parserVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       tokenType = Value(tokenType),
       rawValue = Value(rawValue),
       parserVersion = Value(parserVersion);
  static Insertable<Token> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? tokenType,
    Expression<String>? rawValue,
    Expression<String>? resolvedValue,
    Expression<int>? parserVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (tokenType != null) 'token_type': tokenType,
      if (rawValue != null) 'raw_value': rawValue,
      if (resolvedValue != null) 'resolved_value': resolvedValue,
      if (parserVersion != null) 'parser_version': parserVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TokensCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? tokenType,
    Value<String>? rawValue,
    Value<String?>? resolvedValue,
    Value<int>? parserVersion,
    Value<int>? rowid,
  }) {
    return TokensCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      tokenType: tokenType ?? this.tokenType,
      rawValue: rawValue ?? this.rawValue,
      resolvedValue: resolvedValue ?? this.resolvedValue,
      parserVersion: parserVersion ?? this.parserVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (tokenType.present) {
      map['token_type'] = Variable<String>(tokenType.value);
    }
    if (rawValue.present) {
      map['raw_value'] = Variable<String>(rawValue.value);
    }
    if (resolvedValue.present) {
      map['resolved_value'] = Variable<String>(resolvedValue.value);
    }
    if (parserVersion.present) {
      map['parser_version'] = Variable<int>(parserVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TokensCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('tokenType: $tokenType, ')
          ..write('rawValue: $rawValue, ')
          ..write('resolvedValue: $resolvedValue, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChangeLogTable extends ChangeLog
    with TableInfo<$ChangeLogTable, ChangeLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChangeLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ChangeOperation, String>
  operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ChangeOperation>($ChangeLogTable.$converteroperation);
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    entityId,
    hlc,
    operation,
    payload,
    formatVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_formatVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChangeLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      operation: $ChangeLogTable.$converteroperation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}operation'],
        )!,
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
    );
  }

  @override
  $ChangeLogTable createAlias(String alias) {
    return $ChangeLogTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ChangeOperation, String, String>
  $converteroperation = const EnumNameConverter<ChangeOperation>(
    ChangeOperation.values,
  );
}

class ChangeLogData extends DataClass implements Insertable<ChangeLogData> {
  /// UUIDv7.
  final String id;

  /// Table name of the changed entity.
  final String entity;
  final String entityId;
  final String hlc;
  final ChangeOperation operation;

  /// JSON object with the full new values of the changed columns, keyed by
  /// column name; never a reference to the current database state.
  final String payload;

  /// Version of the payload format (`changeLogFormatVersion`).
  final int formatVersion;
  const ChangeLogData({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.hlc,
    required this.operation,
    required this.payload,
    required this.formatVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['hlc'] = Variable<String>(hlc);
    {
      map['operation'] = Variable<String>(
        $ChangeLogTable.$converteroperation.toSql(operation),
      );
    }
    map['payload'] = Variable<String>(payload);
    map['format_version'] = Variable<int>(formatVersion);
    return map;
  }

  ChangeLogCompanion toCompanion(bool nullToAbsent) {
    return ChangeLogCompanion(
      id: Value(id),
      entity: Value(entity),
      entityId: Value(entityId),
      hlc: Value(hlc),
      operation: Value(operation),
      payload: Value(payload),
      formatVersion: Value(formatVersion),
    );
  }

  factory ChangeLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeLogData(
      id: serializer.fromJson<String>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      operation: $ChangeLogTable.$converteroperation.fromJson(
        serializer.fromJson<String>(json['operation']),
      ),
      payload: serializer.fromJson<String>(json['payload']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'hlc': serializer.toJson<String>(hlc),
      'operation': serializer.toJson<String>(
        $ChangeLogTable.$converteroperation.toJson(operation),
      ),
      'payload': serializer.toJson<String>(payload),
      'formatVersion': serializer.toJson<int>(formatVersion),
    };
  }

  ChangeLogData copyWith({
    String? id,
    String? entity,
    String? entityId,
    String? hlc,
    ChangeOperation? operation,
    String? payload,
    int? formatVersion,
  }) => ChangeLogData(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    hlc: hlc ?? this.hlc,
    operation: operation ?? this.operation,
    payload: payload ?? this.payload,
    formatVersion: formatVersion ?? this.formatVersion,
  );
  ChangeLogData copyWithCompanion(ChangeLogCompanion data) {
    return ChangeLogData(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      operation: data.operation.present ? data.operation.value : this.operation,
      payload: data.payload.present ? data.payload.value : this.payload,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogData(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('hlc: $hlc, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('formatVersion: $formatVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entity, entityId, hlc, operation, payload, formatVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeLogData &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.hlc == this.hlc &&
          other.operation == this.operation &&
          other.payload == this.payload &&
          other.formatVersion == this.formatVersion);
}

class ChangeLogCompanion extends UpdateCompanion<ChangeLogData> {
  final Value<String> id;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> hlc;
  final Value<ChangeOperation> operation;
  final Value<String> payload;
  final Value<int> formatVersion;
  final Value<int> rowid;
  const ChangeLogCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.operation = const Value.absent(),
    this.payload = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChangeLogCompanion.insert({
    required String id,
    required String entity,
    required String entityId,
    required String hlc,
    required ChangeOperation operation,
    required String payload,
    required int formatVersion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entity = Value(entity),
       entityId = Value(entityId),
       hlc = Value(hlc),
       operation = Value(operation),
       payload = Value(payload),
       formatVersion = Value(formatVersion);
  static Insertable<ChangeLogData> custom({
    Expression<String>? id,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? hlc,
    Expression<String>? operation,
    Expression<String>? payload,
    Expression<int>? formatVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (hlc != null) 'hlc': hlc,
      if (operation != null) 'operation': operation,
      if (payload != null) 'payload': payload,
      if (formatVersion != null) 'format_version': formatVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChangeLogCompanion copyWith({
    Value<String>? id,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? hlc,
    Value<ChangeOperation>? operation,
    Value<String>? payload,
    Value<int>? formatVersion,
    Value<int>? rowid,
  }) {
    return ChangeLogCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      hlc: hlc ?? this.hlc,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      formatVersion: formatVersion ?? this.formatVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(
        $ChangeLogTable.$converteroperation.toSql(operation.value),
      );
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('hlc: $hlc, ')
          ..write('operation: $operation, ')
          ..write('payload: $payload, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalStateTable extends LocalState
    with TableInfo<$LocalStateTable, LocalStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStateTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'local_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalStateData> instance, {
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
  LocalStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStateData(
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
  $LocalStateTable createAlias(String alias) {
    return $LocalStateTable(attachedDatabase, alias);
  }
}

class LocalStateData extends DataClass implements Insertable<LocalStateData> {
  final String key;
  final String value;
  const LocalStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalStateCompanion toCompanion(bool nullToAbsent) {
    return LocalStateCompanion(key: Value(key), value: Value(value));
  }

  factory LocalStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStateData(
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

  LocalStateData copyWith({String? key, String? value}) =>
      LocalStateData(key: key ?? this.key, value: value ?? this.value);
  LocalStateData copyWithCompanion(LocalStateCompanion data) {
    return LocalStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStateData(')
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
      (other is LocalStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalStateCompanion extends UpdateCompanion<LocalStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalStateData> custom({
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

  LocalStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalStateCompanion(
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
    return (StringBuffer('LocalStateCompanion(')
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
  late final SearchIndex searchIndex = SearchIndex(this);
  late final SearchMap searchMap = SearchMap(this);
  late final SearchPending searchPending = SearchPending(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $ContextsTable contexts = $ContextsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final Trigger itemsSearchInsert = Trigger(
    'CREATE TRIGGER items_search_insert AFTER INSERT ON items BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'items\', new.id);END',
    'items_search_insert',
  );
  late final Trigger itemsSearchUpdate = Trigger(
    'CREATE TRIGGER items_search_update AFTER UPDATE OF raw_text, title, body, deleted_at ON items BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'items\', new.id);END',
    'items_search_update',
  );
  late final Trigger peopleSearchInsert = Trigger(
    'CREATE TRIGGER people_search_insert AFTER INSERT ON people BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', new.id);END',
    'people_search_insert',
  );
  late final Trigger peopleSearchUpdate = Trigger(
    'CREATE TRIGGER people_search_update AFTER UPDATE OF name, note, organisation, job_title, deleted_at ON people BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', new.id);END',
    'people_search_update',
  );
  late final $PersonAliasesTable personAliases = $PersonAliasesTable(this);
  late final Trigger personAliasesSearchInsert = Trigger(
    'CREATE TRIGGER person_aliases_search_insert AFTER INSERT ON person_aliases BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', new.person_id);END',
    'person_aliases_search_insert',
  );
  late final Trigger personAliasesSearchUpdate = Trigger(
    'CREATE TRIGGER person_aliases_search_update AFTER UPDATE OF alias, person_id, deleted_at ON person_aliases BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', old.person_id);INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', new.person_id);END',
    'person_aliases_search_update',
  );
  late final $ContactDetailsTable contactDetails = $ContactDetailsTable(this);
  late final Trigger contactDetailsSearchInsert = Trigger(
    'CREATE TRIGGER contact_details_search_insert AFTER INSERT ON contact_details BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', new.person_id);END',
    'contact_details_search_insert',
  );
  late final Trigger contactDetailsSearchUpdate = Trigger(
    'CREATE TRIGGER contact_details_search_update AFTER UPDATE OF value, label, person_id, deleted_at ON contact_details BEGIN INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', old.person_id);INSERT OR IGNORE INTO search_pending (entity, entity_id) VALUES (\'people\', new.person_id);END',
    'contact_details_search_update',
  );
  late final $TagsTable tags = $TagsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ItemLinksTable itemLinks = $ItemLinksTable(this);
  late final $ItemCompletionsTable itemCompletions = $ItemCompletionsTable(
    this,
  );
  late final $DuplicateDismissalsTable duplicateDismissals =
      $DuplicateDismissalsTable(this);
  late final $SnapshotsTable snapshots = $SnapshotsTable(this);
  late final $TokensTable tokens = $TokensTable(this);
  late final $ChangeLogTable changeLog = $ChangeLogTable(this);
  late final $LocalStateTable localState = $LocalStateTable(this);
  late final Index itemsStatus = Index(
    'items_status',
    'CREATE INDEX items_status ON items (status)',
  );
  late final Index itemsDueAt = Index(
    'items_due_at',
    'CREATE INDEX items_due_at ON items (due_at)',
  );
  late final Index itemsRevisitAt = Index(
    'items_revisit_at',
    'CREATE INDEX items_revisit_at ON items (revisit_at)',
  );
  late final Index itemsRequesterId = Index(
    'items_requester_id',
    'CREATE INDEX items_requester_id ON items (requester_id)',
  );
  late final Index itemsWaitingOnId = Index(
    'items_waiting_on_id',
    'CREATE INDEX items_waiting_on_id ON items (waiting_on_id)',
  );
  late final Index itemsContextId = Index(
    'items_context_id',
    'CREATE INDEX items_context_id ON items (context_id)',
  );
  late final Index personAliasesPersonId = Index(
    'person_aliases_person_id',
    'CREATE INDEX person_aliases_person_id ON person_aliases (person_id)',
  );
  late final Index personAliasesAlias = Index(
    'person_aliases_alias',
    'CREATE INDEX person_aliases_alias ON person_aliases (alias COLLATE NOCASE)',
  );
  late final Index contextsParentId = Index(
    'contexts_parent_id',
    'CREATE INDEX contexts_parent_id ON contexts (parent_id)',
  );
  late final Index contactDetailsPersonId = Index(
    'contact_details_person_id',
    'CREATE INDEX contact_details_person_id ON contact_details (person_id)',
  );
  late final Index snapshotsItemId = Index(
    'snapshots_item_id',
    'CREATE INDEX snapshots_item_id ON snapshots (item_id)',
  );
  late final Index snapshotsContextId = Index(
    'snapshots_context_id',
    'CREATE INDEX snapshots_context_id ON snapshots (context_id)',
  );
  late final Index tagsNameLive = Index(
    'tags_name_live',
    'CREATE UNIQUE INDEX tags_name_live ON tags (name COLLATE NOCASE) WHERE deleted_at IS NULL',
  );
  late final Index attachmentsItemId = Index(
    'attachments_item_id',
    'CREATE INDEX attachments_item_id ON attachments (item_id)',
  );
  late final Index attachmentsPersonId = Index(
    'attachments_person_id',
    'CREATE INDEX attachments_person_id ON attachments (person_id)',
  );
  late final Index itemLinksFrom = Index(
    'item_links_from',
    'CREATE INDEX item_links_from ON item_links (from_item_id)',
  );
  late final Index itemLinksTo = Index(
    'item_links_to',
    'CREATE INDEX item_links_to ON item_links (to_item_id)',
  );
  late final Index itemCompletionsItemId = Index(
    'item_completions_item_id',
    'CREATE INDEX item_completions_item_id ON item_completions (item_id)',
  );
  late final Index duplicateDismissalsItemId = Index(
    'duplicate_dismissals_item_id',
    'CREATE INDEX duplicate_dismissals_item_id ON duplicate_dismissals (item_id)',
  );
  late final Index duplicateDismissalsOtherId = Index(
    'duplicate_dismissals_other_id',
    'CREATE INDEX duplicate_dismissals_other_id ON duplicate_dismissals (other_item_id)',
  );
  late final Index tokensItemId = Index(
    'tokens_item_id',
    'CREATE INDEX tokens_item_id ON tokens (item_id)',
  );
  late final Index tokensTypeValue = Index(
    'tokens_type_value',
    'CREATE INDEX tokens_type_value ON tokens (token_type, resolved_value)',
  );
  late final Index changeLogHlc = Index(
    'change_log_hlc',
    'CREATE INDEX change_log_hlc ON change_log (hlc)',
  );
  late final Index changeLogEntity = Index(
    'change_log_entity',
    'CREATE INDEX change_log_entity ON change_log (entity, entity_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    searchIndex,
    searchMap,
    searchPending,
    people,
    contexts,
    items,
    itemsSearchInsert,
    itemsSearchUpdate,
    peopleSearchInsert,
    peopleSearchUpdate,
    personAliases,
    personAliasesSearchInsert,
    personAliasesSearchUpdate,
    contactDetails,
    contactDetailsSearchInsert,
    contactDetailsSearchUpdate,
    tags,
    attachments,
    itemLinks,
    itemCompletions,
    duplicateDismissals,
    snapshots,
    tokens,
    changeLog,
    localState,
    itemsStatus,
    itemsDueAt,
    itemsRevisitAt,
    itemsRequesterId,
    itemsWaitingOnId,
    itemsContextId,
    personAliasesPersonId,
    personAliasesAlias,
    contextsParentId,
    contactDetailsPersonId,
    snapshotsItemId,
    snapshotsContextId,
    tagsNameLive,
    attachmentsItemId,
    attachmentsPersonId,
    itemLinksFrom,
    itemLinksTo,
    itemCompletionsItemId,
    duplicateDismissalsItemId,
    duplicateDismissalsOtherId,
    tokensItemId,
    tokensTypeValue,
    changeLogHlc,
    changeLogEntity,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'people',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'person_aliases',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'person_aliases',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contact_details',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'contact_details',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('search_pending', kind: UpdateKind.insert)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $SearchIndexCreateCompanionBuilder =
    SearchIndexCompanion Function({
      required String title,
      required String body,
      Value<int> rowid,
    });
typedef $SearchIndexUpdateCompanionBuilder =
    SearchIndexCompanion Function({
      Value<String> title,
      Value<String> body,
      Value<int> rowid,
    });

class $SearchIndexFilterComposer extends Composer<_$AppDatabase, SearchIndex> {
  $SearchIndexFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $SearchIndexOrderingComposer
    extends Composer<_$AppDatabase, SearchIndex> {
  $SearchIndexOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SearchIndexAnnotationComposer
    extends Composer<_$AppDatabase, SearchIndex> {
  $SearchIndexAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $SearchIndexTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SearchIndex,
          SearchIndexData,
          $SearchIndexFilterComposer,
          $SearchIndexOrderingComposer,
          $SearchIndexAnnotationComposer,
          $SearchIndexCreateCompanionBuilder,
          $SearchIndexUpdateCompanionBuilder,
          (
            SearchIndexData,
            BaseReferences<_$AppDatabase, SearchIndex, SearchIndexData>,
          ),
          SearchIndexData,
          PrefetchHooks Function()
        > {
  $SearchIndexTableManager(_$AppDatabase db, SearchIndex table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SearchIndexFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SearchIndexOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SearchIndexAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  SearchIndexCompanion(title: title, body: body, rowid: rowid),
          createCompanionCallback:
              ({
                required String title,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => SearchIndexCompanion.insert(
                title: title,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SearchIndex, SearchIndexData>(table),
                  BaseReferences<_$AppDatabase, SearchIndex, SearchIndexData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SearchIndexProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SearchIndex,
      SearchIndexData,
      $SearchIndexFilterComposer,
      $SearchIndexOrderingComposer,
      $SearchIndexAnnotationComposer,
      $SearchIndexCreateCompanionBuilder,
      $SearchIndexUpdateCompanionBuilder,
      (
        SearchIndexData,
        BaseReferences<_$AppDatabase, SearchIndex, SearchIndexData>,
      ),
      SearchIndexData,
      PrefetchHooks Function()
    >;
typedef $SearchMapCreateCompanionBuilder =
    SearchMapCompanion Function({
      Value<int> rowId,
      required String entity,
      required String entityId,
    });
typedef $SearchMapUpdateCompanionBuilder =
    SearchMapCompanion Function({
      Value<int> rowId,
      Value<String> entity,
      Value<String> entityId,
    });

class $SearchMapFilterComposer extends Composer<_$AppDatabase, SearchMap> {
  $SearchMapFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );
}

class $SearchMapOrderingComposer extends Composer<_$AppDatabase, SearchMap> {
  $SearchMapOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SearchMapAnnotationComposer extends Composer<_$AppDatabase, SearchMap> {
  $SearchMapAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);
}

class $SearchMapTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SearchMap,
          SearchMapData,
          $SearchMapFilterComposer,
          $SearchMapOrderingComposer,
          $SearchMapAnnotationComposer,
          $SearchMapCreateCompanionBuilder,
          $SearchMapUpdateCompanionBuilder,
          (
            SearchMapData,
            BaseReferences<_$AppDatabase, SearchMap, SearchMapData>,
          ),
          SearchMapData,
          PrefetchHooks Function()
        > {
  $SearchMapTableManager(_$AppDatabase db, SearchMap table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SearchMapFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SearchMapOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SearchMapAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
              }) => SearchMapCompanion(
                rowId: rowId,
                entity: entity,
                entityId: entityId,
              ),
          createCompanionCallback:
              ({
                Value<int> rowId = const Value.absent(),
                required String entity,
                required String entityId,
              }) => SearchMapCompanion.insert(
                rowId: rowId,
                entity: entity,
                entityId: entityId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SearchMap, SearchMapData>(table),
                  BaseReferences<_$AppDatabase, SearchMap, SearchMapData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SearchMapProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SearchMap,
      SearchMapData,
      $SearchMapFilterComposer,
      $SearchMapOrderingComposer,
      $SearchMapAnnotationComposer,
      $SearchMapCreateCompanionBuilder,
      $SearchMapUpdateCompanionBuilder,
      (SearchMapData, BaseReferences<_$AppDatabase, SearchMap, SearchMapData>),
      SearchMapData,
      PrefetchHooks Function()
    >;
typedef $SearchPendingCreateCompanionBuilder =
    SearchPendingCompanion Function({
      required String entity,
      required String entityId,
    });
typedef $SearchPendingUpdateCompanionBuilder =
    SearchPendingCompanion Function({
      Value<String> entity,
      Value<String> entityId,
    });

class $SearchPendingFilterComposer
    extends Composer<_$AppDatabase, SearchPending> {
  $SearchPendingFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );
}

class $SearchPendingOrderingComposer
    extends Composer<_$AppDatabase, SearchPending> {
  $SearchPendingOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SearchPendingAnnotationComposer
    extends Composer<_$AppDatabase, SearchPending> {
  $SearchPendingAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);
}

class $SearchPendingTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SearchPending,
          SearchPendingData,
          $SearchPendingFilterComposer,
          $SearchPendingOrderingComposer,
          $SearchPendingAnnotationComposer,
          $SearchPendingCreateCompanionBuilder,
          $SearchPendingUpdateCompanionBuilder,
          (
            SearchPendingData,
            BaseReferences<_$AppDatabase, SearchPending, SearchPendingData>,
          ),
          SearchPendingData,
          PrefetchHooks Function()
        > {
  $SearchPendingTableManager(_$AppDatabase db, SearchPending table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SearchPendingFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SearchPendingOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SearchPendingAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
              }) => SearchPendingCompanion(entity: entity, entityId: entityId),
          createCompanionCallback:
              ({required String entity, required String entityId}) =>
                  SearchPendingCompanion.insert(
                    entity: entity,
                    entityId: entityId,
                  ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SearchPending, SearchPendingData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    SearchPending,
                    SearchPendingData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SearchPendingProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SearchPending,
      SearchPendingData,
      $SearchPendingFilterComposer,
      $SearchPendingOrderingComposer,
      $SearchPendingAnnotationComposer,
      $SearchPendingCreateCompanionBuilder,
      $SearchPendingUpdateCompanionBuilder,
      (
        SearchPendingData,
        BaseReferences<_$AppDatabase, SearchPending, SearchPendingData>,
      ),
      SearchPendingData,
      PrefetchHooks Function()
    >;
typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String name,
      Value<int?> birthdayDay,
      Value<int?> birthdayMonth,
      Value<int?> birthdayYear,
      Value<String?> note,
      Value<String?> mergedIntoId,
      Value<String?> organisation,
      Value<String?> jobTitle,
      Value<int> rowid,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<int?> birthdayDay,
      Value<int?> birthdayMonth,
      Value<int?> birthdayYear,
      Value<String?> note,
      Value<String?> mergedIntoId,
      Value<String?> organisation,
      Value<String?> jobTitle,
      Value<int> rowid,
    });

final class $$PeopleTableReferences
    extends BaseReferences<_$AppDatabase, $PeopleTable, PeopleData> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _mergedIntoIdTable(_$AppDatabase db) =>
      db.people.createAlias('people__merged_into_id__people__id');

  $$PeopleTableProcessedTableManager? get mergedIntoId {
    final $_column = $_itemColumn<String>('merged_into_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mergedIntoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PersonAliasesTable, List<PersonAliase>>
  _personAliasesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.personAliases,
    aliasName: 'people__id__person_aliases__person_id',
  );

  $$PersonAliasesTableProcessedTableManager get personAliasesRefs {
    final manager = $$PersonAliasesTableTableManager(
      $_db,
      $_db.personAliases,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_personAliasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ContactDetailsTable, List<ContactDetailRow>>
  _contactDetailsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.contactDetails,
    aliasName: 'people__id__contact_details__person_id',
  );

  $$ContactDetailsTableProcessedTableManager get contactDetailsRefs {
    final manager = $$ContactDetailsTableTableManager(
      $_db,
      $_db.contactDetails,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_contactDetailsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'people__id__attachments__person_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthdayDay => $composableBuilder(
    column: $table.birthdayDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthdayMonth => $composableBuilder(
    column: $table.birthdayMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthdayYear => $composableBuilder(
    column: $table.birthdayYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organisation => $composableBuilder(
    column: $table.organisation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobTitle => $composableBuilder(
    column: $table.jobTitle,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get mergedIntoId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> personAliasesRefs(
    Expression<bool> Function($$PersonAliasesTableFilterComposer f) f,
  ) {
    final $$PersonAliasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personAliases,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonAliasesTableFilterComposer(
            $db: $db,
            $table: $db.personAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> contactDetailsRefs(
    Expression<bool> Function($$ContactDetailsTableFilterComposer f) f,
  ) {
    final $$ContactDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactDetails,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactDetailsTableFilterComposer(
            $db: $db,
            $table: $db.contactDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthdayDay => $composableBuilder(
    column: $table.birthdayDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthdayMonth => $composableBuilder(
    column: $table.birthdayMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthdayYear => $composableBuilder(
    column: $table.birthdayYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organisation => $composableBuilder(
    column: $table.organisation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobTitle => $composableBuilder(
    column: $table.jobTitle,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get mergedIntoId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get birthdayDay => $composableBuilder(
    column: $table.birthdayDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get birthdayMonth => $composableBuilder(
    column: $table.birthdayMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get birthdayYear => $composableBuilder(
    column: $table.birthdayYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get organisation => $composableBuilder(
    column: $table.organisation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jobTitle =>
      $composableBuilder(column: $table.jobTitle, builder: (column) => column);

  $$PeopleTableAnnotationComposer get mergedIntoId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mergedIntoId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> personAliasesRefs<T extends Object>(
    Expression<T> Function($$PersonAliasesTableAnnotationComposer a) f,
  ) {
    final $$PersonAliasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.personAliases,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonAliasesTableAnnotationComposer(
            $db: $db,
            $table: $db.personAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> contactDetailsRefs<T extends Object>(
    Expression<T> Function($$ContactDetailsTableAnnotationComposer a) f,
  ) {
    final $$ContactDetailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contactDetails,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContactDetailsTableAnnotationComposer(
            $db: $db,
            $table: $db.contactDetails,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeopleTable,
          PeopleData,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (PeopleData, $$PeopleTableReferences),
          PeopleData,
          PrefetchHooks Function({
            bool mergedIntoId,
            bool personAliasesRefs,
            bool contactDetailsRefs,
            bool attachmentsRefs,
          })
        > {
  $$PeopleTableTableManager(_$AppDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> birthdayDay = const Value.absent(),
                Value<int?> birthdayMonth = const Value.absent(),
                Value<int?> birthdayYear = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> mergedIntoId = const Value.absent(),
                Value<String?> organisation = const Value.absent(),
                Value<String?> jobTitle = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                name: name,
                birthdayDay: birthdayDay,
                birthdayMonth: birthdayMonth,
                birthdayYear: birthdayYear,
                note: note,
                mergedIntoId: mergedIntoId,
                organisation: organisation,
                jobTitle: jobTitle,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<int?> birthdayDay = const Value.absent(),
                Value<int?> birthdayMonth = const Value.absent(),
                Value<int?> birthdayYear = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> mergedIntoId = const Value.absent(),
                Value<String?> organisation = const Value.absent(),
                Value<String?> jobTitle = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                name: name,
                birthdayDay: birthdayDay,
                birthdayMonth: birthdayMonth,
                birthdayYear: birthdayYear,
                note: note,
                mergedIntoId: mergedIntoId,
                organisation: organisation,
                jobTitle: jobTitle,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, PeopleData>(table),
                  $$PeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                mergedIntoId = false,
                personAliasesRefs = false,
                contactDetailsRefs = false,
                attachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (personAliasesRefs) db.personAliases,
                    if (contactDetailsRefs) db.contactDetails,
                    if (attachmentsRefs) db.attachments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (mergedIntoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.mergedIntoId,
                                    referencedTable: $$PeopleTableReferences
                                        ._mergedIntoIdTable(db),
                                    referencedColumn: $$PeopleTableReferences
                                        ._mergedIntoIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (personAliasesRefs)
                        await $_getPrefetchedData<
                          PeopleData,
                          $PeopleTable,
                          PersonAliase
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._personAliasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).personAliasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (contactDetailsRefs)
                        await $_getPrefetchedData<
                          PeopleData,
                          $PeopleTable,
                          ContactDetailRow
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._contactDetailsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).contactDetailsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          PeopleData,
                          $PeopleTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$PeopleTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PeopleTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeopleTable,
      PeopleData,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (PeopleData, $$PeopleTableReferences),
      PeopleData,
      PrefetchHooks Function({
        bool mergedIntoId,
        bool personAliasesRefs,
        bool contactDetailsRefs,
        bool attachmentsRefs,
      })
    >;
typedef $$ContextsTableCreateCompanionBuilder =
    ContextsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String name,
      Value<String?> parentId,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });
typedef $$ContextsTableUpdateCompanionBuilder =
    ContextsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<String?> parentId,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });

final class $$ContextsTableReferences
    extends BaseReferences<_$AppDatabase, $ContextsTable, Context> {
  $$ContextsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ContextsTable _parentIdTable(_$AppDatabase db) =>
      db.contexts.createAlias('contexts__parent_id__contexts__id');

  $$ContextsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$ContextsTableTableManager(
      $_db,
      $_db.contexts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'contexts__id__items__context_id',
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.contextId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SnapshotsTable, List<SnapshotRow>>
  _snapshotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.snapshots,
    aliasName: 'contexts__id__snapshots__context_id',
  );

  $$SnapshotsTableProcessedTableManager get snapshotsRefs {
    final manager = $$SnapshotsTableTableManager(
      $_db,
      $_db.snapshots,
    ).filter((f) => f.contextId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_snapshotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ContextsTableFilterComposer
    extends Composer<_$AppDatabase, $ContextsTable> {
  $$ContextsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ContextsTableFilterComposer get parentId {
    final $$ContextsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableFilterComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.contextId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> snapshotsRefs(
    Expression<bool> Function($$SnapshotsTableFilterComposer f) f,
  ) {
    final $$SnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snapshots,
      getReferencedColumn: (t) => t.contextId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.snapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContextsTable> {
  $$ContextsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ContextsTableOrderingComposer get parentId {
    final $$ContextsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableOrderingComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContextsTable> {
  $$ContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  $$ContextsTableAnnotationComposer get parentId {
    final $$ContextsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableAnnotationComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.contextId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> snapshotsRefs<T extends Object>(
    Expression<T> Function($$SnapshotsTableAnnotationComposer a) f,
  ) {
    final $$SnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snapshots,
      getReferencedColumn: (t) => t.contextId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.snapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ContextsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContextsTable,
          Context,
          $$ContextsTableFilterComposer,
          $$ContextsTableOrderingComposer,
          $$ContextsTableAnnotationComposer,
          $$ContextsTableCreateCompanionBuilder,
          $$ContextsTableUpdateCompanionBuilder,
          (Context, $$ContextsTableReferences),
          Context,
          PrefetchHooks Function({
            bool parentId,
            bool itemsRefs,
            bool snapshotsRefs,
          })
        > {
  $$ContextsTableTableManager(_$AppDatabase db, $ContextsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContextsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                name: name,
                parentId: parentId,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContextsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                name: name,
                parentId: parentId,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContextsTable, Context>(table),
                  $$ContextsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({parentId = false, itemsRefs = false, snapshotsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemsRefs) db.items,
                    if (snapshotsRefs) db.snapshots,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$ContextsTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn: $$ContextsTableReferences
                                        ._parentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemsRefs)
                        await $_getPrefetchedData<
                          Context,
                          $ContextsTable,
                          Item
                        >(
                          currentTable: table,
                          referencedTable: $$ContextsTableReferences
                              ._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContextsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contextId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (snapshotsRefs)
                        await $_getPrefetchedData<
                          Context,
                          $ContextsTable,
                          SnapshotRow
                        >(
                          currentTable: table,
                          referencedTable: $$ContextsTableReferences
                              ._snapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ContextsTableReferences(
                                db,
                                table,
                                p0,
                              ).snapshotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.contextId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContextsTable,
      Context,
      $$ContextsTableFilterComposer,
      $$ContextsTableOrderingComposer,
      $$ContextsTableAnnotationComposer,
      $$ContextsTableCreateCompanionBuilder,
      $$ContextsTableUpdateCompanionBuilder,
      (Context, $$ContextsTableReferences),
      Context,
      PrefetchHooks Function({
        bool parentId,
        bool itemsRefs,
        bool snapshotsRefs,
      })
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String rawText,
      Value<String?> title,
      Value<String?> body,
      Value<ItemType?> type,
      required ItemStatus status,
      required ItemSource source,
      Value<DateTime?> dueAt,
      Value<DateTime?> revisitAt,
      Value<String?> requesterId,
      Value<String?> waitingOnId,
      Value<String?> contextId,
      Value<DateTime?> reviewedAt,
      Value<ItemPriority?> priority,
      Value<DateTime?> askedAt,
      Value<String?> promise,
      Value<DateTime?> expectedAt,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> rawText,
      Value<String?> title,
      Value<String?> body,
      Value<ItemType?> type,
      Value<ItemStatus> status,
      Value<ItemSource> source,
      Value<DateTime?> dueAt,
      Value<DateTime?> revisitAt,
      Value<String?> requesterId,
      Value<String?> waitingOnId,
      Value<String?> contextId,
      Value<DateTime?> reviewedAt,
      Value<ItemPriority?> priority,
      Value<DateTime?> askedAt,
      Value<String?> promise,
      Value<DateTime?> expectedAt,
      Value<int> rowid,
    });

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PeopleTable _requesterIdTable(_$AppDatabase db) =>
      db.people.createAlias('items__requester_id__people__id');

  $$PeopleTableProcessedTableManager? get requesterId {
    final $_column = $_itemColumn<String>('requester_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_requesterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _waitingOnIdTable(_$AppDatabase db) =>
      db.people.createAlias('items__waiting_on_id__people__id');

  $$PeopleTableProcessedTableManager? get waitingOnId {
    final $_column = $_itemColumn<String>('waiting_on_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_waitingOnIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContextsTable _contextIdTable(_$AppDatabase db) =>
      db.contexts.createAlias('items__context_id__contexts__id');

  $$ContextsTableProcessedTableManager? get contextId {
    final $_column = $_itemColumn<String>('context_id');
    if ($_column == null) return null;
    final manager = $$ContextsTableTableManager(
      $_db,
      $_db.contexts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contextIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: 'items__id__attachments__item_id',
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemCompletionsTable, List<ItemCompletion>>
  _itemCompletionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemCompletions,
    aliasName: 'items__id__item_completions__item_id',
  );

  $$ItemCompletionsTableProcessedTableManager get itemCompletionsRefs {
    final manager = $$ItemCompletionsTableTableManager(
      $_db,
      $_db.itemCompletions,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemCompletionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SnapshotsTable, List<SnapshotRow>>
  _snapshotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.snapshots,
    aliasName: 'items__id__snapshots__item_id',
  );

  $$SnapshotsTableProcessedTableManager get snapshotsRefs {
    final manager = $$SnapshotsTableTableManager(
      $_db,
      $_db.snapshots,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_snapshotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TokensTable, List<Token>> _tokensRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tokens,
    aliasName: 'items__id__tokens__item_id',
  );

  $$TokensTableProcessedTableManager get tokensRefs {
    final manager = $$TokensTableTableManager(
      $_db,
      $_db.tokens,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tokensRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemType?, ItemType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ItemStatus, ItemStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ItemSource, ItemSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get revisitAt => $composableBuilder(
    column: $table.revisitAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemPriority?, ItemPriority, String>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get askedAt => $composableBuilder(
    column: $table.askedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promise => $composableBuilder(
    column: $table.promise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedAt => $composableBuilder(
    column: $table.expectedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get requesterId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.requesterId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get waitingOnId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waitingOnId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextsTableFilterComposer get contextId {
    final $$ContextsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableFilterComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemCompletionsRefs(
    Expression<bool> Function($$ItemCompletionsTableFilterComposer f) f,
  ) {
    final $$ItemCompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemCompletions,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemCompletionsTableFilterComposer(
            $db: $db,
            $table: $db.itemCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> snapshotsRefs(
    Expression<bool> Function($$SnapshotsTableFilterComposer f) f,
  ) {
    final $$SnapshotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snapshots,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotsTableFilterComposer(
            $db: $db,
            $table: $db.snapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tokensRefs(
    Expression<bool> Function($$TokensTableFilterComposer f) f,
  ) {
    final $$TokensTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tokens,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TokensTableFilterComposer(
            $db: $db,
            $table: $db.tokens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get revisitAt => $composableBuilder(
    column: $table.revisitAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get askedAt => $composableBuilder(
    column: $table.askedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promise => $composableBuilder(
    column: $table.promise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedAt => $composableBuilder(
    column: $table.expectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get requesterId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.requesterId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get waitingOnId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waitingOnId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextsTableOrderingComposer get contextId {
    final $$ContextsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableOrderingComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemType?, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get revisitAt =>
      $composableBuilder(column: $table.revisitAt, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ItemPriority?, String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get askedAt =>
      $composableBuilder(column: $table.askedAt, builder: (column) => column);

  GeneratedColumn<String> get promise =>
      $composableBuilder(column: $table.promise, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedAt => $composableBuilder(
    column: $table.expectedAt,
    builder: (column) => column,
  );

  $$PeopleTableAnnotationComposer get requesterId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.requesterId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get waitingOnId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.waitingOnId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextsTableAnnotationComposer get contextId {
    final $$ContextsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableAnnotationComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemCompletionsRefs<T extends Object>(
    Expression<T> Function($$ItemCompletionsTableAnnotationComposer a) f,
  ) {
    final $$ItemCompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemCompletions,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemCompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemCompletions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> snapshotsRefs<T extends Object>(
    Expression<T> Function($$SnapshotsTableAnnotationComposer a) f,
  ) {
    final $$SnapshotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.snapshots,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SnapshotsTableAnnotationComposer(
            $db: $db,
            $table: $db.snapshots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tokensRefs<T extends Object>(
    Expression<T> Function($$TokensTableAnnotationComposer a) f,
  ) {
    final $$TokensTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tokens,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TokensTableAnnotationComposer(
            $db: $db,
            $table: $db.tokens,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({
            bool requesterId,
            bool waitingOnId,
            bool contextId,
            bool attachmentsRefs,
            bool itemCompletionsRefs,
            bool snapshotsRefs,
            bool tokensRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<ItemType?> type = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<ItemSource> source = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> revisitAt = const Value.absent(),
                Value<String?> requesterId = const Value.absent(),
                Value<String?> waitingOnId = const Value.absent(),
                Value<String?> contextId = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<ItemPriority?> priority = const Value.absent(),
                Value<DateTime?> askedAt = const Value.absent(),
                Value<String?> promise = const Value.absent(),
                Value<DateTime?> expectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                rawText: rawText,
                title: title,
                body: body,
                type: type,
                status: status,
                source: source,
                dueAt: dueAt,
                revisitAt: revisitAt,
                requesterId: requesterId,
                waitingOnId: waitingOnId,
                contextId: contextId,
                reviewedAt: reviewedAt,
                priority: priority,
                askedAt: askedAt,
                promise: promise,
                expectedAt: expectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String rawText,
                Value<String?> title = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<ItemType?> type = const Value.absent(),
                required ItemStatus status,
                required ItemSource source,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> revisitAt = const Value.absent(),
                Value<String?> requesterId = const Value.absent(),
                Value<String?> waitingOnId = const Value.absent(),
                Value<String?> contextId = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<ItemPriority?> priority = const Value.absent(),
                Value<DateTime?> askedAt = const Value.absent(),
                Value<String?> promise = const Value.absent(),
                Value<DateTime?> expectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                rawText: rawText,
                title: title,
                body: body,
                type: type,
                status: status,
                source: source,
                dueAt: dueAt,
                revisitAt: revisitAt,
                requesterId: requesterId,
                waitingOnId: waitingOnId,
                contextId: contextId,
                reviewedAt: reviewedAt,
                priority: priority,
                askedAt: askedAt,
                promise: promise,
                expectedAt: expectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, Item>(table),
                  $$ItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                requesterId = false,
                waitingOnId = false,
                contextId = false,
                attachmentsRefs = false,
                itemCompletionsRefs = false,
                snapshotsRefs = false,
                tokensRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attachmentsRefs) db.attachments,
                    if (itemCompletionsRefs) db.itemCompletions,
                    if (snapshotsRefs) db.snapshots,
                    if (tokensRefs) db.tokens,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (requesterId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.requesterId,
                                    referencedTable: $$ItemsTableReferences
                                        ._requesterIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._requesterIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (waitingOnId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.waitingOnId,
                                    referencedTable: $$ItemsTableReferences
                                        ._waitingOnIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._waitingOnIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (contextId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.contextId,
                                    referencedTable: $$ItemsTableReferences
                                        ._contextIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._contextIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          Attachment
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemCompletionsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          ItemCompletion
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._itemCompletionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemCompletionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (snapshotsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          SnapshotRow
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._snapshotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).snapshotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tokensRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, Token>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._tokensRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(db, table, p0).tokensRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({
        bool requesterId,
        bool waitingOnId,
        bool contextId,
        bool attachmentsRefs,
        bool itemCompletionsRefs,
        bool snapshotsRefs,
        bool tokensRefs,
      })
    >;
typedef $$PersonAliasesTableCreateCompanionBuilder =
    PersonAliasesCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String personId,
      required String alias,
      Value<int> rowid,
    });
typedef $$PersonAliasesTableUpdateCompanionBuilder =
    PersonAliasesCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> personId,
      Value<String> alias,
      Value<int> rowid,
    });

final class $$PersonAliasesTableReferences
    extends BaseReferences<_$AppDatabase, $PersonAliasesTable, PersonAliase> {
  $$PersonAliasesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('person_aliases__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PersonAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $PersonAliasesTable> {
  $$PersonAliasesTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonAliasesTable> {
  $$PersonAliasesTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonAliasesTable> {
  $$PersonAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonAliasesTable,
          PersonAliase,
          $$PersonAliasesTableFilterComposer,
          $$PersonAliasesTableOrderingComposer,
          $$PersonAliasesTableAnnotationComposer,
          $$PersonAliasesTableCreateCompanionBuilder,
          $$PersonAliasesTableUpdateCompanionBuilder,
          (PersonAliase, $$PersonAliasesTableReferences),
          PersonAliase,
          PrefetchHooks Function({bool personId})
        > {
  $$PersonAliasesTableTableManager(_$AppDatabase db, $PersonAliasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonAliasesCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                personId: personId,
                alias: alias,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String personId,
                required String alias,
                Value<int> rowid = const Value.absent(),
              }) => PersonAliasesCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                personId: personId,
                alias: alias,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PersonAliasesTable, PersonAliase>(table),
                  $$PersonAliasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$PersonAliasesTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$PersonAliasesTableReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PersonAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonAliasesTable,
      PersonAliase,
      $$PersonAliasesTableFilterComposer,
      $$PersonAliasesTableOrderingComposer,
      $$PersonAliasesTableAnnotationComposer,
      $$PersonAliasesTableCreateCompanionBuilder,
      $$PersonAliasesTableUpdateCompanionBuilder,
      (PersonAliase, $$PersonAliasesTableReferences),
      PersonAliase,
      PrefetchHooks Function({bool personId})
    >;
typedef $$ContactDetailsTableCreateCompanionBuilder =
    ContactDetailsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String personId,
      required ContactKind kind,
      required String value,
      Value<String?> label,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$ContactDetailsTableUpdateCompanionBuilder =
    ContactDetailsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> personId,
      Value<ContactKind> kind,
      Value<String> value,
      Value<String?> label,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$ContactDetailsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ContactDetailsTable, ContactDetailRow> {
  $$ContactDetailsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('contact_details__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContactDetailsTableFilterComposer
    extends Composer<_$AppDatabase, $ContactDetailsTable> {
  $$ContactDetailsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ContactKind, ContactKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactDetailsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContactDetailsTable> {
  $$ContactDetailsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactDetailsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContactDetailsTable> {
  $$ContactDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContactKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContactDetailsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContactDetailsTable,
          ContactDetailRow,
          $$ContactDetailsTableFilterComposer,
          $$ContactDetailsTableOrderingComposer,
          $$ContactDetailsTableAnnotationComposer,
          $$ContactDetailsTableCreateCompanionBuilder,
          $$ContactDetailsTableUpdateCompanionBuilder,
          (ContactDetailRow, $$ContactDetailsTableReferences),
          ContactDetailRow,
          PrefetchHooks Function({bool personId})
        > {
  $$ContactDetailsTableTableManager(
    _$AppDatabase db,
    $ContactDetailsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContactDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContactDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContactDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<ContactKind> kind = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContactDetailsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                personId: personId,
                kind: kind,
                value: value,
                label: label,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String personId,
                required ContactKind kind,
                required String value,
                Value<String?> label = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => ContactDetailsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                personId: personId,
                kind: kind,
                value: value,
                label: label,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContactDetailsTable, ContactDetailRow>(table),
                  $$ContactDetailsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$ContactDetailsTableReferences
                                    ._personIdTable(db),
                                referencedColumn:
                                    $$ContactDetailsTableReferences
                                        ._personIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ContactDetailsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContactDetailsTable,
      ContactDetailRow,
      $$ContactDetailsTableFilterComposer,
      $$ContactDetailsTableOrderingComposer,
      $$ContactDetailsTableAnnotationComposer,
      $$ContactDetailsTableCreateCompanionBuilder,
      $$ContactDetailsTableUpdateCompanionBuilder,
      (ContactDetailRow, $$ContactDetailsTableReferences),
      ContactDetailRow,
      PrefetchHooks Function({bool personId})
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String name,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  BaseReferences<_$AppDatabase, $TagsTable, Tag>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      Value<String?> itemId,
      Value<String?> personId,
      required String mimeType,
      required int sizeBytes,
      required String storagePath,
      required int pipelineVersion,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String?> itemId,
      Value<String?> personId,
      Value<String> mimeType,
      Value<int> sizeBytes,
      Value<String> storagePath,
      Value<int> pipelineVersion,
      Value<int> rowid,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('attachments__item_id__items__id');

  $$ItemsTableProcessedTableManager? get itemId {
    final $_column = $_itemColumn<String>('item_id');
    if ($_column == null) return null;
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$AppDatabase db) =>
      db.people.createAlias('attachments__person_id__people__id');

  $$PeopleTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<String>('person_id');
    if ($_column == null) return null;
    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pipelineVersion => $composableBuilder(
    column: $table.pipelineVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pipelineVersion => $composableBuilder(
    column: $table.pipelineVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pipelineVersion => $composableBuilder(
    column: $table.pipelineVersion,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (Attachment, $$AttachmentsTableReferences),
          Attachment,
          PrefetchHooks Function({bool itemId, bool personId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> storagePath = const Value.absent(),
                Value<int> pipelineVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                personId: personId,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                storagePath: storagePath,
                pipelineVersion: pipelineVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                required String mimeType,
                required int sizeBytes,
                required String storagePath,
                required int pipelineVersion,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                personId: personId,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                storagePath: storagePath,
                pipelineVersion: pipelineVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentsTable, Attachment>(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$AttachmentsTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$AttachmentsTableReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (Attachment, $$AttachmentsTableReferences),
      Attachment,
      PrefetchHooks Function({bool itemId, bool personId})
    >;
typedef $$ItemLinksTableCreateCompanionBuilder =
    ItemLinksCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String fromItemId,
      required String toItemId,
      required String kind,
      Value<String?> label,
      Value<int> rowid,
    });
typedef $$ItemLinksTableUpdateCompanionBuilder =
    ItemLinksCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> fromItemId,
      Value<String> toItemId,
      Value<String> kind,
      Value<String?> label,
      Value<int> rowid,
    });

final class $$ItemLinksTableReferences
    extends BaseReferences<_$AppDatabase, $ItemLinksTable, ItemLink> {
  $$ItemLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _fromItemIdTable(_$AppDatabase db) =>
      db.items.createAlias('item_links__from_item_id__items__id');

  $$ItemsTableProcessedTableManager get fromItemId {
    final $_column = $_itemColumn<String>('from_item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _toItemIdTable(_$AppDatabase db) =>
      db.items.createAlias('item_links__to_item_id__items__id');

  $$ItemsTableProcessedTableManager get toItemId {
    final $_column = $_itemColumn<String>('to_item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemLinksTableFilterComposer
    extends Composer<_$AppDatabase, $ItemLinksTable> {
  $$ItemLinksTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get fromItemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get toItemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemLinksTable> {
  $$ItemLinksTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get fromItemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get toItemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemLinksTable> {
  $$ItemLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  $$ItemsTableAnnotationComposer get fromItemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get toItemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemLinksTable,
          ItemLink,
          $$ItemLinksTableFilterComposer,
          $$ItemLinksTableOrderingComposer,
          $$ItemLinksTableAnnotationComposer,
          $$ItemLinksTableCreateCompanionBuilder,
          $$ItemLinksTableUpdateCompanionBuilder,
          (ItemLink, $$ItemLinksTableReferences),
          ItemLink,
          PrefetchHooks Function({bool fromItemId, bool toItemId})
        > {
  $$ItemLinksTableTableManager(_$AppDatabase db, $ItemLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> fromItemId = const Value.absent(),
                Value<String> toItemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemLinksCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                fromItemId: fromItemId,
                toItemId: toItemId,
                kind: kind,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String fromItemId,
                required String toItemId,
                required String kind,
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemLinksCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                fromItemId: fromItemId,
                toItemId: toItemId,
                kind: kind,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemLinksTable, ItemLink>(table),
                  $$ItemLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fromItemId = false, toItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fromItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fromItemId,
                                referencedTable: $$ItemLinksTableReferences
                                    ._fromItemIdTable(db),
                                referencedColumn: $$ItemLinksTableReferences
                                    ._fromItemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (toItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.toItemId,
                                referencedTable: $$ItemLinksTableReferences
                                    ._toItemIdTable(db),
                                referencedColumn: $$ItemLinksTableReferences
                                    ._toItemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemLinksTable,
      ItemLink,
      $$ItemLinksTableFilterComposer,
      $$ItemLinksTableOrderingComposer,
      $$ItemLinksTableAnnotationComposer,
      $$ItemLinksTableCreateCompanionBuilder,
      $$ItemLinksTableUpdateCompanionBuilder,
      (ItemLink, $$ItemLinksTableReferences),
      ItemLink,
      PrefetchHooks Function({bool fromItemId, bool toItemId})
    >;
typedef $$ItemCompletionsTableCreateCompanionBuilder =
    ItemCompletionsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String itemId,
      required DateTime occurrenceOn,
      required DateTime completedOn,
      Value<int> rowid,
    });
typedef $$ItemCompletionsTableUpdateCompanionBuilder =
    ItemCompletionsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> itemId,
      Value<DateTime> occurrenceOn,
      Value<DateTime> completedOn,
      Value<int> rowid,
    });

final class $$ItemCompletionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ItemCompletionsTable, ItemCompletion> {
  $$ItemCompletionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('item_completions__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemCompletionsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemCompletionsTable> {
  $$ItemCompletionsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurrenceOn => $composableBuilder(
    column: $table.occurrenceOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemCompletionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemCompletionsTable> {
  $$ItemCompletionsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurrenceOn => $composableBuilder(
    column: $table.occurrenceOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemCompletionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemCompletionsTable> {
  $$ItemCompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get occurrenceOn => $composableBuilder(
    column: $table.occurrenceOn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedOn => $composableBuilder(
    column: $table.completedOn,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemCompletionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemCompletionsTable,
          ItemCompletion,
          $$ItemCompletionsTableFilterComposer,
          $$ItemCompletionsTableOrderingComposer,
          $$ItemCompletionsTableAnnotationComposer,
          $$ItemCompletionsTableCreateCompanionBuilder,
          $$ItemCompletionsTableUpdateCompanionBuilder,
          (ItemCompletion, $$ItemCompletionsTableReferences),
          ItemCompletion,
          PrefetchHooks Function({bool itemId})
        > {
  $$ItemCompletionsTableTableManager(
    _$AppDatabase db,
    $ItemCompletionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemCompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemCompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemCompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<DateTime> occurrenceOn = const Value.absent(),
                Value<DateTime> completedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemCompletionsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                occurrenceOn: occurrenceOn,
                completedOn: completedOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String itemId,
                required DateTime occurrenceOn,
                required DateTime completedOn,
                Value<int> rowid = const Value.absent(),
              }) => ItemCompletionsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                occurrenceOn: occurrenceOn,
                completedOn: completedOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemCompletionsTable, ItemCompletion>(table),
                  $$ItemCompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$ItemCompletionsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$ItemCompletionsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemCompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemCompletionsTable,
      ItemCompletion,
      $$ItemCompletionsTableFilterComposer,
      $$ItemCompletionsTableOrderingComposer,
      $$ItemCompletionsTableAnnotationComposer,
      $$ItemCompletionsTableCreateCompanionBuilder,
      $$ItemCompletionsTableUpdateCompanionBuilder,
      (ItemCompletion, $$ItemCompletionsTableReferences),
      ItemCompletion,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$DuplicateDismissalsTableCreateCompanionBuilder =
    DuplicateDismissalsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      required String itemId,
      required String otherItemId,
      Value<int> rowid,
    });
typedef $$DuplicateDismissalsTableUpdateCompanionBuilder =
    DuplicateDismissalsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String> itemId,
      Value<String> otherItemId,
      Value<int> rowid,
    });

final class $$DuplicateDismissalsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DuplicateDismissalsTable,
          DuplicateDismissal
        > {
  $$DuplicateDismissalsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('duplicate_dismissals__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _otherItemIdTable(_$AppDatabase db) =>
      db.items.createAlias('duplicate_dismissals__other_item_id__items__id');

  $$ItemsTableProcessedTableManager get otherItemId {
    final $_column = $_itemColumn<String>('other_item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_otherItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DuplicateDismissalsTableFilterComposer
    extends Composer<_$AppDatabase, $DuplicateDismissalsTable> {
  $$DuplicateDismissalsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get otherItemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.otherItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateDismissalsTableOrderingComposer
    extends Composer<_$AppDatabase, $DuplicateDismissalsTable> {
  $$DuplicateDismissalsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get otherItemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.otherItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateDismissalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DuplicateDismissalsTable> {
  $$DuplicateDismissalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get otherItemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.otherItemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DuplicateDismissalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DuplicateDismissalsTable,
          DuplicateDismissal,
          $$DuplicateDismissalsTableFilterComposer,
          $$DuplicateDismissalsTableOrderingComposer,
          $$DuplicateDismissalsTableAnnotationComposer,
          $$DuplicateDismissalsTableCreateCompanionBuilder,
          $$DuplicateDismissalsTableUpdateCompanionBuilder,
          (DuplicateDismissal, $$DuplicateDismissalsTableReferences),
          DuplicateDismissal,
          PrefetchHooks Function({bool itemId, bool otherItemId})
        > {
  $$DuplicateDismissalsTableTableManager(
    _$AppDatabase db,
    $DuplicateDismissalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DuplicateDismissalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DuplicateDismissalsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DuplicateDismissalsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> otherItemId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DuplicateDismissalsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                otherItemId: otherItemId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String itemId,
                required String otherItemId,
                Value<int> rowid = const Value.absent(),
              }) => DuplicateDismissalsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                otherItemId: otherItemId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DuplicateDismissalsTable, DuplicateDismissal>(
                    table,
                  ),
                  $$DuplicateDismissalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, otherItemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$DuplicateDismissalsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$DuplicateDismissalsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (otherItemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.otherItemId,
                                referencedTable:
                                    $$DuplicateDismissalsTableReferences
                                        ._otherItemIdTable(db),
                                referencedColumn:
                                    $$DuplicateDismissalsTableReferences
                                        ._otherItemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DuplicateDismissalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DuplicateDismissalsTable,
      DuplicateDismissal,
      $$DuplicateDismissalsTableFilterComposer,
      $$DuplicateDismissalsTableOrderingComposer,
      $$DuplicateDismissalsTableAnnotationComposer,
      $$DuplicateDismissalsTableCreateCompanionBuilder,
      $$DuplicateDismissalsTableUpdateCompanionBuilder,
      (DuplicateDismissal, $$DuplicateDismissalsTableReferences),
      DuplicateDismissal,
      PrefetchHooks Function({bool itemId, bool otherItemId})
    >;
typedef $$SnapshotsTableCreateCompanionBuilder =
    SnapshotsCompanion Function({
      required String id,
      required String hlc,
      Value<DateTime?> deletedAt,
      Value<String?> itemId,
      Value<String?> contextId,
      Value<String?> nextStep,
      Value<String?> inMind,
      Value<DateTime?> resumedAt,
      Value<int> rowid,
    });
typedef $$SnapshotsTableUpdateCompanionBuilder =
    SnapshotsCompanion Function({
      Value<String> id,
      Value<String> hlc,
      Value<DateTime?> deletedAt,
      Value<String?> itemId,
      Value<String?> contextId,
      Value<String?> nextStep,
      Value<String?> inMind,
      Value<DateTime?> resumedAt,
      Value<int> rowid,
    });

final class $$SnapshotsTableReferences
    extends BaseReferences<_$AppDatabase, $SnapshotsTable, SnapshotRow> {
  $$SnapshotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('snapshots__item_id__items__id');

  $$ItemsTableProcessedTableManager? get itemId {
    final $_column = $_itemColumn<String>('item_id');
    if ($_column == null) return null;
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ContextsTable _contextIdTable(_$AppDatabase db) =>
      db.contexts.createAlias('snapshots__context_id__contexts__id');

  $$ContextsTableProcessedTableManager? get contextId {
    final $_column = $_itemColumn<String>('context_id');
    if ($_column == null) return null;
    final manager = $$ContextsTableTableManager(
      $_db,
      $_db.contexts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contextIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableFilterComposer({
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

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextStep => $composableBuilder(
    column: $table.nextStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inMind => $composableBuilder(
    column: $table.inMind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resumedAt => $composableBuilder(
    column: $table.resumedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextsTableFilterComposer get contextId {
    final $$ContextsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableFilterComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextStep => $composableBuilder(
    column: $table.nextStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inMind => $composableBuilder(
    column: $table.inMind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resumedAt => $composableBuilder(
    column: $table.resumedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextsTableOrderingComposer get contextId {
    final $$ContextsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableOrderingComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SnapshotsTable> {
  $$SnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get nextStep =>
      $composableBuilder(column: $table.nextStep, builder: (column) => column);

  GeneratedColumn<String> get inMind =>
      $composableBuilder(column: $table.inMind, builder: (column) => column);

  GeneratedColumn<DateTime> get resumedAt =>
      $composableBuilder(column: $table.resumedAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ContextsTableAnnotationComposer get contextId {
    final $$ContextsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contextId,
      referencedTable: $db.contexts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContextsTableAnnotationComposer(
            $db: $db,
            $table: $db.contexts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SnapshotsTable,
          SnapshotRow,
          $$SnapshotsTableFilterComposer,
          $$SnapshotsTableOrderingComposer,
          $$SnapshotsTableAnnotationComposer,
          $$SnapshotsTableCreateCompanionBuilder,
          $$SnapshotsTableUpdateCompanionBuilder,
          (SnapshotRow, $$SnapshotsTableReferences),
          SnapshotRow,
          PrefetchHooks Function({bool itemId, bool contextId})
        > {
  $$SnapshotsTableTableManager(_$AppDatabase db, $SnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> contextId = const Value.absent(),
                Value<String?> nextStep = const Value.absent(),
                Value<String?> inMind = const Value.absent(),
                Value<DateTime?> resumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                contextId: contextId,
                nextStep: nextStep,
                inMind: inMind,
                resumedAt: resumedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String hlc,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> contextId = const Value.absent(),
                Value<String?> nextStep = const Value.absent(),
                Value<String?> inMind = const Value.absent(),
                Value<DateTime?> resumedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SnapshotsCompanion.insert(
                id: id,
                hlc: hlc,
                deletedAt: deletedAt,
                itemId: itemId,
                contextId: contextId,
                nextStep: nextStep,
                inMind: inMind,
                resumedAt: resumedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SnapshotsTable, SnapshotRow>(table),
                  $$SnapshotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, contextId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$SnapshotsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$SnapshotsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (contextId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contextId,
                                referencedTable: $$SnapshotsTableReferences
                                    ._contextIdTable(db),
                                referencedColumn: $$SnapshotsTableReferences
                                    ._contextIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SnapshotsTable,
      SnapshotRow,
      $$SnapshotsTableFilterComposer,
      $$SnapshotsTableOrderingComposer,
      $$SnapshotsTableAnnotationComposer,
      $$SnapshotsTableCreateCompanionBuilder,
      $$SnapshotsTableUpdateCompanionBuilder,
      (SnapshotRow, $$SnapshotsTableReferences),
      SnapshotRow,
      PrefetchHooks Function({bool itemId, bool contextId})
    >;
typedef $$TokensTableCreateCompanionBuilder =
    TokensCompanion Function({
      required String id,
      required String itemId,
      required String tokenType,
      required String rawValue,
      Value<String?> resolvedValue,
      required int parserVersion,
      Value<int> rowid,
    });
typedef $$TokensTableUpdateCompanionBuilder =
    TokensCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> tokenType,
      Value<String> rawValue,
      Value<String?> resolvedValue,
      Value<int> parserVersion,
      Value<int> rowid,
    });

final class $$TokensTableReferences
    extends BaseReferences<_$AppDatabase, $TokensTable, Token> {
  $$TokensTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('tokens__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TokensTableFilterComposer
    extends Composer<_$AppDatabase, $TokensTable> {
  $$TokensTableFilterComposer({
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

  ColumnFilters<String> get tokenType => $composableBuilder(
    column: $table.tokenType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedValue => $composableBuilder(
    column: $table.resolvedValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TokensTableOrderingComposer
    extends Composer<_$AppDatabase, $TokensTable> {
  $$TokensTableOrderingComposer({
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

  ColumnOrderings<String> get tokenType => $composableBuilder(
    column: $table.tokenType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawValue => $composableBuilder(
    column: $table.rawValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedValue => $composableBuilder(
    column: $table.resolvedValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TokensTableAnnotationComposer
    extends Composer<_$AppDatabase, $TokensTable> {
  $$TokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tokenType =>
      $composableBuilder(column: $table.tokenType, builder: (column) => column);

  GeneratedColumn<String> get rawValue =>
      $composableBuilder(column: $table.rawValue, builder: (column) => column);

  GeneratedColumn<String> get resolvedValue => $composableBuilder(
    column: $table.resolvedValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TokensTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TokensTable,
          Token,
          $$TokensTableFilterComposer,
          $$TokensTableOrderingComposer,
          $$TokensTableAnnotationComposer,
          $$TokensTableCreateCompanionBuilder,
          $$TokensTableUpdateCompanionBuilder,
          (Token, $$TokensTableReferences),
          Token,
          PrefetchHooks Function({bool itemId})
        > {
  $$TokensTableTableManager(_$AppDatabase db, $TokensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TokensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TokensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> tokenType = const Value.absent(),
                Value<String> rawValue = const Value.absent(),
                Value<String?> resolvedValue = const Value.absent(),
                Value<int> parserVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TokensCompanion(
                id: id,
                itemId: itemId,
                tokenType: tokenType,
                rawValue: rawValue,
                resolvedValue: resolvedValue,
                parserVersion: parserVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String tokenType,
                required String rawValue,
                Value<String?> resolvedValue = const Value.absent(),
                required int parserVersion,
                Value<int> rowid = const Value.absent(),
              }) => TokensCompanion.insert(
                id: id,
                itemId: itemId,
                tokenType: tokenType,
                rawValue: rawValue,
                resolvedValue: resolvedValue,
                parserVersion: parserVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TokensTable, Token>(table),
                  $$TokensTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$TokensTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$TokensTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TokensTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TokensTable,
      Token,
      $$TokensTableFilterComposer,
      $$TokensTableOrderingComposer,
      $$TokensTableAnnotationComposer,
      $$TokensTableCreateCompanionBuilder,
      $$TokensTableUpdateCompanionBuilder,
      (Token, $$TokensTableReferences),
      Token,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ChangeLogTableCreateCompanionBuilder =
    ChangeLogCompanion Function({
      required String id,
      required String entity,
      required String entityId,
      required String hlc,
      required ChangeOperation operation,
      required String payload,
      required int formatVersion,
      Value<int> rowid,
    });
typedef $$ChangeLogTableUpdateCompanionBuilder =
    ChangeLogCompanion Function({
      Value<String> id,
      Value<String> entity,
      Value<String> entityId,
      Value<String> hlc,
      Value<ChangeOperation> operation,
      Value<String> payload,
      Value<int> formatVersion,
      Value<int> rowid,
    });

class $$ChangeLogTableFilterComposer
    extends Composer<_$AppDatabase, $ChangeLogTable> {
  $$ChangeLogTableFilterComposer({
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

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ChangeOperation, ChangeOperation, String>
  get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChangeLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ChangeLogTable> {
  $$ChangeLogTableOrderingComposer({
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

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChangeLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChangeLogTable> {
  $$ChangeLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChangeOperation, String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => column,
  );
}

class $$ChangeLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChangeLogTable,
          ChangeLogData,
          $$ChangeLogTableFilterComposer,
          $$ChangeLogTableOrderingComposer,
          $$ChangeLogTableAnnotationComposer,
          $$ChangeLogTableCreateCompanionBuilder,
          $$ChangeLogTableUpdateCompanionBuilder,
          (
            ChangeLogData,
            BaseReferences<_$AppDatabase, $ChangeLogTable, ChangeLogData>,
          ),
          ChangeLogData,
          PrefetchHooks Function()
        > {
  $$ChangeLogTableTableManager(_$AppDatabase db, $ChangeLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChangeLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChangeLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChangeLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<ChangeOperation> operation = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> formatVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChangeLogCompanion(
                id: id,
                entity: entity,
                entityId: entityId,
                hlc: hlc,
                operation: operation,
                payload: payload,
                formatVersion: formatVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entity,
                required String entityId,
                required String hlc,
                required ChangeOperation operation,
                required String payload,
                required int formatVersion,
                Value<int> rowid = const Value.absent(),
              }) => ChangeLogCompanion.insert(
                id: id,
                entity: entity,
                entityId: entityId,
                hlc: hlc,
                operation: operation,
                payload: payload,
                formatVersion: formatVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChangeLogTable, ChangeLogData>(table),
                  BaseReferences<_$AppDatabase, $ChangeLogTable, ChangeLogData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChangeLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChangeLogTable,
      ChangeLogData,
      $$ChangeLogTableFilterComposer,
      $$ChangeLogTableOrderingComposer,
      $$ChangeLogTableAnnotationComposer,
      $$ChangeLogTableCreateCompanionBuilder,
      $$ChangeLogTableUpdateCompanionBuilder,
      (
        ChangeLogData,
        BaseReferences<_$AppDatabase, $ChangeLogTable, ChangeLogData>,
      ),
      ChangeLogData,
      PrefetchHooks Function()
    >;
typedef $$LocalStateTableCreateCompanionBuilder =
    LocalStateCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalStateTableUpdateCompanionBuilder =
    LocalStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalStateTableFilterComposer
    extends Composer<_$AppDatabase, $LocalStateTable> {
  $$LocalStateTableFilterComposer({
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

class $$LocalStateTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalStateTable> {
  $$LocalStateTableOrderingComposer({
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

class $$LocalStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalStateTable> {
  $$LocalStateTableAnnotationComposer({
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

class $$LocalStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalStateTable,
          LocalStateData,
          $$LocalStateTableFilterComposer,
          $$LocalStateTableOrderingComposer,
          $$LocalStateTableAnnotationComposer,
          $$LocalStateTableCreateCompanionBuilder,
          $$LocalStateTableUpdateCompanionBuilder,
          (
            LocalStateData,
            BaseReferences<_$AppDatabase, $LocalStateTable, LocalStateData>,
          ),
          LocalStateData,
          PrefetchHooks Function()
        > {
  $$LocalStateTableTableManager(_$AppDatabase db, $LocalStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalStateCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalStateTable, LocalStateData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalStateTable,
                    LocalStateData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalStateTable,
      LocalStateData,
      $$LocalStateTableFilterComposer,
      $$LocalStateTableOrderingComposer,
      $$LocalStateTableAnnotationComposer,
      $$LocalStateTableCreateCompanionBuilder,
      $$LocalStateTableUpdateCompanionBuilder,
      (
        LocalStateData,
        BaseReferences<_$AppDatabase, $LocalStateTable, LocalStateData>,
      ),
      LocalStateData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $SearchIndexTableManager get searchIndex =>
      $SearchIndexTableManager(_db, _db.searchIndex);
  $SearchMapTableManager get searchMap =>
      $SearchMapTableManager(_db, _db.searchMap);
  $SearchPendingTableManager get searchPending =>
      $SearchPendingTableManager(_db, _db.searchPending);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$ContextsTableTableManager get contexts =>
      $$ContextsTableTableManager(_db, _db.contexts);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$PersonAliasesTableTableManager get personAliases =>
      $$PersonAliasesTableTableManager(_db, _db.personAliases);
  $$ContactDetailsTableTableManager get contactDetails =>
      $$ContactDetailsTableTableManager(_db, _db.contactDetails);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ItemLinksTableTableManager get itemLinks =>
      $$ItemLinksTableTableManager(_db, _db.itemLinks);
  $$ItemCompletionsTableTableManager get itemCompletions =>
      $$ItemCompletionsTableTableManager(_db, _db.itemCompletions);
  $$DuplicateDismissalsTableTableManager get duplicateDismissals =>
      $$DuplicateDismissalsTableTableManager(_db, _db.duplicateDismissals);
  $$SnapshotsTableTableManager get snapshots =>
      $$SnapshotsTableTableManager(_db, _db.snapshots);
  $$TokensTableTableManager get tokens =>
      $$TokensTableTableManager(_db, _db.tokens);
  $$ChangeLogTableTableManager get changeLog =>
      $$ChangeLogTableTableManager(_db, _db.changeLog);
  $$LocalStateTableTableManager get localState =>
      $$LocalStateTableTableManager(_db, _db.localState);
}
