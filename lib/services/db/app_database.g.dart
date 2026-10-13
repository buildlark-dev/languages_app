// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SchemaMetaTable extends SchemaMeta
    with TableInfo<$SchemaMetaTable, SchemaMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _migratedAtMeta = const VerificationMeta(
    'migratedAt',
  );
  @override
  late final GeneratedColumn<DateTime> migratedAt = GeneratedColumn<DateTime>(
    'migrated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, createdAt, migratedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schema_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemaMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('migrated_at')) {
      context.handle(
        _migratedAtMeta,
        migratedAt.isAcceptableOrUnknown(data['migrated_at']!, _migratedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchemaMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      migratedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}migrated_at'],
      ),
    );
  }

  @override
  $SchemaMetaTable createAlias(String alias) {
    return $SchemaMetaTable(attachedDatabase, alias);
  }
}

class SchemaMetaRow extends DataClass implements Insertable<SchemaMetaRow> {
  final int id;
  final int version;
  final DateTime createdAt;
  final DateTime? migratedAt;
  const SchemaMetaRow({
    required this.id,
    required this.version,
    required this.createdAt,
    this.migratedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || migratedAt != null) {
      map['migrated_at'] = Variable<DateTime>(migratedAt);
    }
    return map;
  }

  SchemaMetaCompanion toCompanion(bool nullToAbsent) {
    return SchemaMetaCompanion(
      id: Value(id),
      version: Value(version),
      createdAt: Value(createdAt),
      migratedAt: migratedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(migratedAt),
    );
  }

  factory SchemaMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaMetaRow(
      id: serializer.fromJson<int>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      migratedAt: serializer.fromJson<DateTime?>(json['migratedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'migratedAt': serializer.toJson<DateTime?>(migratedAt),
    };
  }

  SchemaMetaRow copyWith({
    int? id,
    int? version,
    DateTime? createdAt,
    Value<DateTime?> migratedAt = const Value.absent(),
  }) => SchemaMetaRow(
    id: id ?? this.id,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    migratedAt: migratedAt.present ? migratedAt.value : this.migratedAt,
  );
  SchemaMetaRow copyWithCompanion(SchemaMetaCompanion data) {
    return SchemaMetaRow(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      migratedAt: data.migratedAt.present
          ? data.migratedAt.value
          : this.migratedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMetaRow(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('migratedAt: $migratedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, createdAt, migratedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaMetaRow &&
          other.id == this.id &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.migratedAt == this.migratedAt);
}

class SchemaMetaCompanion extends UpdateCompanion<SchemaMetaRow> {
  final Value<int> id;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime?> migratedAt;
  const SchemaMetaCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.migratedAt = const Value.absent(),
  });
  SchemaMetaCompanion.insert({
    this.id = const Value.absent(),
    required int version,
    required DateTime createdAt,
    this.migratedAt = const Value.absent(),
  }) : version = Value(version),
       createdAt = Value(createdAt);
  static Insertable<SchemaMetaRow> custom({
    Expression<int>? id,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? migratedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (migratedAt != null) 'migrated_at': migratedAt,
    });
  }

  SchemaMetaCompanion copyWith({
    Value<int>? id,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<DateTime?>? migratedAt,
  }) {
    return SchemaMetaCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      migratedAt: migratedAt ?? this.migratedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (migratedAt.present) {
      map['migrated_at'] = Variable<DateTime>(migratedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMetaCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('migratedAt: $migratedAt')
          ..write(')'))
        .toString();
  }
}

class $StudentProfileTable extends StudentProfile
    with TableInfo<$StudentProfileTable, StudentProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudentProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentLevelIdMeta = const VerificationMeta(
    'currentLevelId',
  );
  @override
  late final GeneratedColumn<String> currentLevelId = GeneratedColumn<String>(
    'current_level_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  static const VerificationMeta _streakCountMeta = const VerificationMeta(
    'streakCount',
  );
  @override
  late final GeneratedColumn<int> streakCount = GeneratedColumn<int>(
    'streak_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  static const VerificationMeta _lastActivityDateMeta = const VerificationMeta(
    'lastActivityDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastActivityDate =
      GeneratedColumn<DateTime>(
        'last_activity_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    courseId,
    currentLevelId,
    xp,
    streakCount,
    lastActivityDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'student_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudentProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('current_level_id')) {
      context.handle(
        _currentLevelIdMeta,
        currentLevelId.isAcceptableOrUnknown(
          data['current_level_id']!,
          _currentLevelIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentLevelIdMeta);
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('streak_count')) {
      context.handle(
        _streakCountMeta,
        streakCount.isAcceptableOrUnknown(
          data['streak_count']!,
          _streakCountMeta,
        ),
      );
    }
    if (data.containsKey('last_activity_date')) {
      context.handle(
        _lastActivityDateMeta,
        lastActivityDate.isAcceptableOrUnknown(
          data['last_activity_date']!,
          _lastActivityDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, courseId};
  @override
  StudentProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudentProfileRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      currentLevelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_level_id'],
      )!,
      xp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp'],
      )!,
      streakCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_count'],
      )!,
      lastActivityDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_activity_date'],
      ),
    );
  }

  @override
  $StudentProfileTable createAlias(String alias) {
    return $StudentProfileTable(attachedDatabase, alias);
  }
}

class StudentProfileRow extends DataClass
    implements Insertable<StudentProfileRow> {
  final String uid;
  final String courseId;
  final String currentLevelId;
  final int xp;
  final int streakCount;
  final DateTime? lastActivityDate;
  const StudentProfileRow({
    required this.uid,
    required this.courseId,
    required this.currentLevelId,
    required this.xp,
    required this.streakCount,
    this.lastActivityDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['course_id'] = Variable<String>(courseId);
    map['current_level_id'] = Variable<String>(currentLevelId);
    map['xp'] = Variable<int>(xp);
    map['streak_count'] = Variable<int>(streakCount);
    if (!nullToAbsent || lastActivityDate != null) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate);
    }
    return map;
  }

  StudentProfileCompanion toCompanion(bool nullToAbsent) {
    return StudentProfileCompanion(
      uid: Value(uid),
      courseId: Value(courseId),
      currentLevelId: Value(currentLevelId),
      xp: Value(xp),
      streakCount: Value(streakCount),
      lastActivityDate: lastActivityDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActivityDate),
    );
  }

  factory StudentProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudentProfileRow(
      uid: serializer.fromJson<String>(json['uid']),
      courseId: serializer.fromJson<String>(json['courseId']),
      currentLevelId: serializer.fromJson<String>(json['currentLevelId']),
      xp: serializer.fromJson<int>(json['xp']),
      streakCount: serializer.fromJson<int>(json['streakCount']),
      lastActivityDate: serializer.fromJson<DateTime?>(
        json['lastActivityDate'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'courseId': serializer.toJson<String>(courseId),
      'currentLevelId': serializer.toJson<String>(currentLevelId),
      'xp': serializer.toJson<int>(xp),
      'streakCount': serializer.toJson<int>(streakCount),
      'lastActivityDate': serializer.toJson<DateTime?>(lastActivityDate),
    };
  }

  StudentProfileRow copyWith({
    String? uid,
    String? courseId,
    String? currentLevelId,
    int? xp,
    int? streakCount,
    Value<DateTime?> lastActivityDate = const Value.absent(),
  }) => StudentProfileRow(
    uid: uid ?? this.uid,
    courseId: courseId ?? this.courseId,
    currentLevelId: currentLevelId ?? this.currentLevelId,
    xp: xp ?? this.xp,
    streakCount: streakCount ?? this.streakCount,
    lastActivityDate: lastActivityDate.present
        ? lastActivityDate.value
        : this.lastActivityDate,
  );
  StudentProfileRow copyWithCompanion(StudentProfileCompanion data) {
    return StudentProfileRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      currentLevelId: data.currentLevelId.present
          ? data.currentLevelId.value
          : this.currentLevelId,
      xp: data.xp.present ? data.xp.value : this.xp,
      streakCount: data.streakCount.present
          ? data.streakCount.value
          : this.streakCount,
      lastActivityDate: data.lastActivityDate.present
          ? data.lastActivityDate.value
          : this.lastActivityDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudentProfileRow(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('currentLevelId: $currentLevelId, ')
          ..write('xp: $xp, ')
          ..write('streakCount: $streakCount, ')
          ..write('lastActivityDate: $lastActivityDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    courseId,
    currentLevelId,
    xp,
    streakCount,
    lastActivityDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentProfileRow &&
          other.uid == this.uid &&
          other.courseId == this.courseId &&
          other.currentLevelId == this.currentLevelId &&
          other.xp == this.xp &&
          other.streakCount == this.streakCount &&
          other.lastActivityDate == this.lastActivityDate);
}

class StudentProfileCompanion extends UpdateCompanion<StudentProfileRow> {
  final Value<String> uid;
  final Value<String> courseId;
  final Value<String> currentLevelId;
  final Value<int> xp;
  final Value<int> streakCount;
  final Value<DateTime?> lastActivityDate;
  final Value<int> rowid;
  const StudentProfileCompanion({
    this.uid = const Value.absent(),
    this.courseId = const Value.absent(),
    this.currentLevelId = const Value.absent(),
    this.xp = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudentProfileCompanion.insert({
    required String uid,
    required String courseId,
    required String currentLevelId,
    this.xp = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.lastActivityDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       courseId = Value(courseId),
       currentLevelId = Value(currentLevelId);
  static Insertable<StudentProfileRow> custom({
    Expression<String>? uid,
    Expression<String>? courseId,
    Expression<String>? currentLevelId,
    Expression<int>? xp,
    Expression<int>? streakCount,
    Expression<DateTime>? lastActivityDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (courseId != null) 'course_id': courseId,
      if (currentLevelId != null) 'current_level_id': currentLevelId,
      if (xp != null) 'xp': xp,
      if (streakCount != null) 'streak_count': streakCount,
      if (lastActivityDate != null) 'last_activity_date': lastActivityDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudentProfileCompanion copyWith({
    Value<String>? uid,
    Value<String>? courseId,
    Value<String>? currentLevelId,
    Value<int>? xp,
    Value<int>? streakCount,
    Value<DateTime?>? lastActivityDate,
    Value<int>? rowid,
  }) {
    return StudentProfileCompanion(
      uid: uid ?? this.uid,
      courseId: courseId ?? this.courseId,
      currentLevelId: currentLevelId ?? this.currentLevelId,
      xp: xp ?? this.xp,
      streakCount: streakCount ?? this.streakCount,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (currentLevelId.present) {
      map['current_level_id'] = Variable<String>(currentLevelId.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (streakCount.present) {
      map['streak_count'] = Variable<int>(streakCount.value);
    }
    if (lastActivityDate.present) {
      map['last_activity_date'] = Variable<DateTime>(lastActivityDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudentProfileCompanion(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('currentLevelId: $currentLevelId, ')
          ..write('xp: $xp, ')
          ..write('streakCount: $streakCount, ')
          ..write('lastActivityDate: $lastActivityDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LevelProgressTable extends LevelProgress
    with TableInfo<$LevelProgressTable, LevelProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LevelProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelIdMeta = const VerificationMeta(
    'levelId',
  );
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
    'level_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<int> state = GeneratedColumn<int>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [uid, courseId, levelId, state];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'level_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LevelProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('level_id')) {
      context.handle(
        _levelIdMeta,
        levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, courseId, levelId};
  @override
  LevelProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LevelProgressRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      levelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $LevelProgressTable createAlias(String alias) {
    return $LevelProgressTable(attachedDatabase, alias);
  }
}

class LevelProgressRow extends DataClass
    implements Insertable<LevelProgressRow> {
  final String uid;
  final String courseId;
  final String levelId;

  /// 0 bloqueado · 1 desbloqueado · 2 dominado · 3 superado.
  final int state;
  const LevelProgressRow({
    required this.uid,
    required this.courseId,
    required this.levelId,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['course_id'] = Variable<String>(courseId);
    map['level_id'] = Variable<String>(levelId);
    map['state'] = Variable<int>(state);
    return map;
  }

  LevelProgressCompanion toCompanion(bool nullToAbsent) {
    return LevelProgressCompanion(
      uid: Value(uid),
      courseId: Value(courseId),
      levelId: Value(levelId),
      state: Value(state),
    );
  }

  factory LevelProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LevelProgressRow(
      uid: serializer.fromJson<String>(json['uid']),
      courseId: serializer.fromJson<String>(json['courseId']),
      levelId: serializer.fromJson<String>(json['levelId']),
      state: serializer.fromJson<int>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'courseId': serializer.toJson<String>(courseId),
      'levelId': serializer.toJson<String>(levelId),
      'state': serializer.toJson<int>(state),
    };
  }

  LevelProgressRow copyWith({
    String? uid,
    String? courseId,
    String? levelId,
    int? state,
  }) => LevelProgressRow(
    uid: uid ?? this.uid,
    courseId: courseId ?? this.courseId,
    levelId: levelId ?? this.levelId,
    state: state ?? this.state,
  );
  LevelProgressRow copyWithCompanion(LevelProgressCompanion data) {
    return LevelProgressRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressRow(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('levelId: $levelId, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uid, courseId, levelId, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LevelProgressRow &&
          other.uid == this.uid &&
          other.courseId == this.courseId &&
          other.levelId == this.levelId &&
          other.state == this.state);
}

class LevelProgressCompanion extends UpdateCompanion<LevelProgressRow> {
  final Value<String> uid;
  final Value<String> courseId;
  final Value<String> levelId;
  final Value<int> state;
  final Value<int> rowid;
  const LevelProgressCompanion({
    this.uid = const Value.absent(),
    this.courseId = const Value.absent(),
    this.levelId = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LevelProgressCompanion.insert({
    required String uid,
    required String courseId,
    required String levelId,
    required int state,
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       courseId = Value(courseId),
       levelId = Value(levelId),
       state = Value(state);
  static Insertable<LevelProgressRow> custom({
    Expression<String>? uid,
    Expression<String>? courseId,
    Expression<String>? levelId,
    Expression<int>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (courseId != null) 'course_id': courseId,
      if (levelId != null) 'level_id': levelId,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LevelProgressCompanion copyWith({
    Value<String>? uid,
    Value<String>? courseId,
    Value<String>? levelId,
    Value<int>? state,
    Value<int>? rowid,
  }) {
    return LevelProgressCompanion(
      uid: uid ?? this.uid,
      courseId: courseId ?? this.courseId,
      levelId: levelId ?? this.levelId,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LevelProgressCompanion(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('levelId: $levelId, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityResultsTable extends ActivityResults
    with TableInfo<$ActivityResultsTable, ActivityResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityKindMeta = const VerificationMeta(
    'activityKind',
  );
  @override
  late final GeneratedColumn<int> activityKind = GeneratedColumn<int>(
    'activity_kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bestScoreMeta = const VerificationMeta(
    'bestScore',
  );
  @override
  late final GeneratedColumn<double> bestScore = GeneratedColumn<double>(
    'best_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(1),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    courseId,
    activityId,
    activityKind,
    bestScore,
    attempts,
    lastAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('activity_kind')) {
      context.handle(
        _activityKindMeta,
        activityKind.isAcceptableOrUnknown(
          data['activity_kind']!,
          _activityKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityKindMeta);
    }
    if (data.containsKey('best_score')) {
      context.handle(
        _bestScoreMeta,
        bestScore.isAcceptableOrUnknown(data['best_score']!, _bestScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_bestScoreMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAttemptAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, courseId, activityId};
  @override
  ActivityResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityResultRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      activityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activity_kind'],
      )!,
      bestScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}best_score'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      )!,
    );
  }

  @override
  $ActivityResultsTable createAlias(String alias) {
    return $ActivityResultsTable(attachedDatabase, alias);
  }
}

class ActivityResultRow extends DataClass
    implements Insertable<ActivityResultRow> {
  final String uid;
  final String courseId;

  /// Identificador de la lección o del examen.
  final String activityId;

  /// 0 lección · 1 examen de módulo · 2 examen de nivel.
  final int activityKind;

  /// Proporción de aciertos, de 0.0 a 1.0. Solo el mejor intento.
  final double bestScore;
  final int attempts;
  final DateTime lastAttemptAt;
  const ActivityResultRow({
    required this.uid,
    required this.courseId,
    required this.activityId,
    required this.activityKind,
    required this.bestScore,
    required this.attempts,
    required this.lastAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['course_id'] = Variable<String>(courseId);
    map['activity_id'] = Variable<String>(activityId);
    map['activity_kind'] = Variable<int>(activityKind);
    map['best_score'] = Variable<double>(bestScore);
    map['attempts'] = Variable<int>(attempts);
    map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    return map;
  }

  ActivityResultsCompanion toCompanion(bool nullToAbsent) {
    return ActivityResultsCompanion(
      uid: Value(uid),
      courseId: Value(courseId),
      activityId: Value(activityId),
      activityKind: Value(activityKind),
      bestScore: Value(bestScore),
      attempts: Value(attempts),
      lastAttemptAt: Value(lastAttemptAt),
    );
  }

  factory ActivityResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityResultRow(
      uid: serializer.fromJson<String>(json['uid']),
      courseId: serializer.fromJson<String>(json['courseId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      activityKind: serializer.fromJson<int>(json['activityKind']),
      bestScore: serializer.fromJson<double>(json['bestScore']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastAttemptAt: serializer.fromJson<DateTime>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'courseId': serializer.toJson<String>(courseId),
      'activityId': serializer.toJson<String>(activityId),
      'activityKind': serializer.toJson<int>(activityKind),
      'bestScore': serializer.toJson<double>(bestScore),
      'attempts': serializer.toJson<int>(attempts),
      'lastAttemptAt': serializer.toJson<DateTime>(lastAttemptAt),
    };
  }

  ActivityResultRow copyWith({
    String? uid,
    String? courseId,
    String? activityId,
    int? activityKind,
    double? bestScore,
    int? attempts,
    DateTime? lastAttemptAt,
  }) => ActivityResultRow(
    uid: uid ?? this.uid,
    courseId: courseId ?? this.courseId,
    activityId: activityId ?? this.activityId,
    activityKind: activityKind ?? this.activityKind,
    bestScore: bestScore ?? this.bestScore,
    attempts: attempts ?? this.attempts,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
  );
  ActivityResultRow copyWithCompanion(ActivityResultsCompanion data) {
    return ActivityResultRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      activityKind: data.activityKind.present
          ? data.activityKind.value
          : this.activityKind,
      bestScore: data.bestScore.present ? data.bestScore.value : this.bestScore,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityResultRow(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('activityId: $activityId, ')
          ..write('activityKind: $activityKind, ')
          ..write('bestScore: $bestScore, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    courseId,
    activityId,
    activityKind,
    bestScore,
    attempts,
    lastAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityResultRow &&
          other.uid == this.uid &&
          other.courseId == this.courseId &&
          other.activityId == this.activityId &&
          other.activityKind == this.activityKind &&
          other.bestScore == this.bestScore &&
          other.attempts == this.attempts &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class ActivityResultsCompanion extends UpdateCompanion<ActivityResultRow> {
  final Value<String> uid;
  final Value<String> courseId;
  final Value<String> activityId;
  final Value<int> activityKind;
  final Value<double> bestScore;
  final Value<int> attempts;
  final Value<DateTime> lastAttemptAt;
  final Value<int> rowid;
  const ActivityResultsCompanion({
    this.uid = const Value.absent(),
    this.courseId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.activityKind = const Value.absent(),
    this.bestScore = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityResultsCompanion.insert({
    required String uid,
    required String courseId,
    required String activityId,
    required int activityKind,
    required double bestScore,
    this.attempts = const Value.absent(),
    required DateTime lastAttemptAt,
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       courseId = Value(courseId),
       activityId = Value(activityId),
       activityKind = Value(activityKind),
       bestScore = Value(bestScore),
       lastAttemptAt = Value(lastAttemptAt);
  static Insertable<ActivityResultRow> custom({
    Expression<String>? uid,
    Expression<String>? courseId,
    Expression<String>? activityId,
    Expression<int>? activityKind,
    Expression<double>? bestScore,
    Expression<int>? attempts,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (courseId != null) 'course_id': courseId,
      if (activityId != null) 'activity_id': activityId,
      if (activityKind != null) 'activity_kind': activityKind,
      if (bestScore != null) 'best_score': bestScore,
      if (attempts != null) 'attempts': attempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityResultsCompanion copyWith({
    Value<String>? uid,
    Value<String>? courseId,
    Value<String>? activityId,
    Value<int>? activityKind,
    Value<double>? bestScore,
    Value<int>? attempts,
    Value<DateTime>? lastAttemptAt,
    Value<int>? rowid,
  }) {
    return ActivityResultsCompanion(
      uid: uid ?? this.uid,
      courseId: courseId ?? this.courseId,
      activityId: activityId ?? this.activityId,
      activityKind: activityKind ?? this.activityKind,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (activityKind.present) {
      map['activity_kind'] = Variable<int>(activityKind.value);
    }
    if (bestScore.present) {
      map['best_score'] = Variable<double>(bestScore.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityResultsCompanion(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('activityId: $activityId, ')
          ..write('activityKind: $activityKind, ')
          ..write('bestScore: $bestScore, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewCardsTable extends ReviewCards
    with TableInfo<$ReviewCardsTable, ReviewCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleIdMeta = const VerificationMeta(
    'moduleId',
  );
  @override
  late final GeneratedColumn<String> moduleId = GeneratedColumn<String>(
    'module_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalStepMeta = const VerificationMeta(
    'intervalStep',
  );
  @override
  late final GeneratedColumn<int> intervalStep = GeneratedColumn<int>(
    'interval_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant<int>(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    courseId,
    moduleId,
    term,
    translation,
    intervalStep,
    dueDate,
    lapses,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewCardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('module_id')) {
      context.handle(
        _moduleIdMeta,
        moduleId.isAcceptableOrUnknown(data['module_id']!, _moduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleIdMeta);
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('interval_step')) {
      context.handle(
        _intervalStepMeta,
        intervalStep.isAcceptableOrUnknown(
          data['interval_step']!,
          _intervalStepMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, courseId, moduleId, term};
  @override
  ReviewCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewCardRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      moduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      intervalStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_step'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
    );
  }

  @override
  $ReviewCardsTable createAlias(String alias) {
    return $ReviewCardsTable(attachedDatabase, alias);
  }
}

class ReviewCardRow extends DataClass implements Insertable<ReviewCardRow> {
  final String uid;
  final String courseId;
  final String moduleId;
  final String term;
  final String translation;

  /// Índice en los intervalos 1·3·7·16·35·90, de 0 a 5.
  final int intervalStep;
  final DateTime dueDate;
  final int lapses;
  const ReviewCardRow({
    required this.uid,
    required this.courseId,
    required this.moduleId,
    required this.term,
    required this.translation,
    required this.intervalStep,
    required this.dueDate,
    required this.lapses,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['course_id'] = Variable<String>(courseId);
    map['module_id'] = Variable<String>(moduleId);
    map['term'] = Variable<String>(term);
    map['translation'] = Variable<String>(translation);
    map['interval_step'] = Variable<int>(intervalStep);
    map['due_date'] = Variable<DateTime>(dueDate);
    map['lapses'] = Variable<int>(lapses);
    return map;
  }

  ReviewCardsCompanion toCompanion(bool nullToAbsent) {
    return ReviewCardsCompanion(
      uid: Value(uid),
      courseId: Value(courseId),
      moduleId: Value(moduleId),
      term: Value(term),
      translation: Value(translation),
      intervalStep: Value(intervalStep),
      dueDate: Value(dueDate),
      lapses: Value(lapses),
    );
  }

  factory ReviewCardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewCardRow(
      uid: serializer.fromJson<String>(json['uid']),
      courseId: serializer.fromJson<String>(json['courseId']),
      moduleId: serializer.fromJson<String>(json['moduleId']),
      term: serializer.fromJson<String>(json['term']),
      translation: serializer.fromJson<String>(json['translation']),
      intervalStep: serializer.fromJson<int>(json['intervalStep']),
      dueDate: serializer.fromJson<DateTime>(json['dueDate']),
      lapses: serializer.fromJson<int>(json['lapses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'courseId': serializer.toJson<String>(courseId),
      'moduleId': serializer.toJson<String>(moduleId),
      'term': serializer.toJson<String>(term),
      'translation': serializer.toJson<String>(translation),
      'intervalStep': serializer.toJson<int>(intervalStep),
      'dueDate': serializer.toJson<DateTime>(dueDate),
      'lapses': serializer.toJson<int>(lapses),
    };
  }

  ReviewCardRow copyWith({
    String? uid,
    String? courseId,
    String? moduleId,
    String? term,
    String? translation,
    int? intervalStep,
    DateTime? dueDate,
    int? lapses,
  }) => ReviewCardRow(
    uid: uid ?? this.uid,
    courseId: courseId ?? this.courseId,
    moduleId: moduleId ?? this.moduleId,
    term: term ?? this.term,
    translation: translation ?? this.translation,
    intervalStep: intervalStep ?? this.intervalStep,
    dueDate: dueDate ?? this.dueDate,
    lapses: lapses ?? this.lapses,
  );
  ReviewCardRow copyWithCompanion(ReviewCardsCompanion data) {
    return ReviewCardRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      moduleId: data.moduleId.present ? data.moduleId.value : this.moduleId,
      term: data.term.present ? data.term.value : this.term,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      intervalStep: data.intervalStep.present
          ? data.intervalStep.value
          : this.intervalStep,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCardRow(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('moduleId: $moduleId, ')
          ..write('term: $term, ')
          ..write('translation: $translation, ')
          ..write('intervalStep: $intervalStep, ')
          ..write('dueDate: $dueDate, ')
          ..write('lapses: $lapses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    courseId,
    moduleId,
    term,
    translation,
    intervalStep,
    dueDate,
    lapses,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewCardRow &&
          other.uid == this.uid &&
          other.courseId == this.courseId &&
          other.moduleId == this.moduleId &&
          other.term == this.term &&
          other.translation == this.translation &&
          other.intervalStep == this.intervalStep &&
          other.dueDate == this.dueDate &&
          other.lapses == this.lapses);
}

class ReviewCardsCompanion extends UpdateCompanion<ReviewCardRow> {
  final Value<String> uid;
  final Value<String> courseId;
  final Value<String> moduleId;
  final Value<String> term;
  final Value<String> translation;
  final Value<int> intervalStep;
  final Value<DateTime> dueDate;
  final Value<int> lapses;
  final Value<int> rowid;
  const ReviewCardsCompanion({
    this.uid = const Value.absent(),
    this.courseId = const Value.absent(),
    this.moduleId = const Value.absent(),
    this.term = const Value.absent(),
    this.translation = const Value.absent(),
    this.intervalStep = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.lapses = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewCardsCompanion.insert({
    required String uid,
    required String courseId,
    required String moduleId,
    required String term,
    required String translation,
    this.intervalStep = const Value.absent(),
    required DateTime dueDate,
    this.lapses = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       courseId = Value(courseId),
       moduleId = Value(moduleId),
       term = Value(term),
       translation = Value(translation),
       dueDate = Value(dueDate);
  static Insertable<ReviewCardRow> custom({
    Expression<String>? uid,
    Expression<String>? courseId,
    Expression<String>? moduleId,
    Expression<String>? term,
    Expression<String>? translation,
    Expression<int>? intervalStep,
    Expression<DateTime>? dueDate,
    Expression<int>? lapses,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (courseId != null) 'course_id': courseId,
      if (moduleId != null) 'module_id': moduleId,
      if (term != null) 'term': term,
      if (translation != null) 'translation': translation,
      if (intervalStep != null) 'interval_step': intervalStep,
      if (dueDate != null) 'due_date': dueDate,
      if (lapses != null) 'lapses': lapses,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewCardsCompanion copyWith({
    Value<String>? uid,
    Value<String>? courseId,
    Value<String>? moduleId,
    Value<String>? term,
    Value<String>? translation,
    Value<int>? intervalStep,
    Value<DateTime>? dueDate,
    Value<int>? lapses,
    Value<int>? rowid,
  }) {
    return ReviewCardsCompanion(
      uid: uid ?? this.uid,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      term: term ?? this.term,
      translation: translation ?? this.translation,
      intervalStep: intervalStep ?? this.intervalStep,
      dueDate: dueDate ?? this.dueDate,
      lapses: lapses ?? this.lapses,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (moduleId.present) {
      map['module_id'] = Variable<String>(moduleId.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (intervalStep.present) {
      map['interval_step'] = Variable<int>(intervalStep.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewCardsCompanion(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('moduleId: $moduleId, ')
          ..write('term: $term, ')
          ..write('translation: $translation, ')
          ..write('intervalStep: $intervalStep, ')
          ..write('dueDate: $dueDate, ')
          ..write('lapses: $lapses, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlacementResultsTable extends PlacementResults
    with TableInfo<$PlacementResultsTable, PlacementResultRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacementResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimatedLevelIdMeta = const VerificationMeta(
    'estimatedLevelId',
  );
  @override
  late final GeneratedColumn<String> estimatedLevelId = GeneratedColumn<String>(
    'estimated_level_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteredLevelIdsMeta = const VerificationMeta(
    'masteredLevelIds',
  );
  @override
  late final GeneratedColumn<String> masteredLevelIds = GeneratedColumn<String>(
    'mastered_level_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant<String>(''),
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
    defaultValue: const Constant<bool>(false),
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    courseId,
    estimatedLevelId,
    masteredLevelIds,
    skipped,
    takenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'placement_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlacementResultRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('estimated_level_id')) {
      context.handle(
        _estimatedLevelIdMeta,
        estimatedLevelId.isAcceptableOrUnknown(
          data['estimated_level_id']!,
          _estimatedLevelIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_estimatedLevelIdMeta);
    }
    if (data.containsKey('mastered_level_ids')) {
      context.handle(
        _masteredLevelIdsMeta,
        masteredLevelIds.isAcceptableOrUnknown(
          data['mastered_level_ids']!,
          _masteredLevelIdsMeta,
        ),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid, courseId};
  @override
  PlacementResultRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlacementResultRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      estimatedLevelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimated_level_id'],
      )!,
      masteredLevelIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mastered_level_ids'],
      )!,
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
    );
  }

  @override
  $PlacementResultsTable createAlias(String alias) {
    return $PlacementResultsTable(attachedDatabase, alias);
  }
}

class PlacementResultRow extends DataClass
    implements Insertable<PlacementResultRow> {
  final String uid;
  final String courseId;

  /// Cualquier nivel MCER, incluso uno sin contenido construido.
  final String estimatedLevelId;

  /// Lista separada por comas. Solo niveles con contenido.
  final String masteredLevelIds;
  final bool skipped;
  final DateTime takenAt;
  const PlacementResultRow({
    required this.uid,
    required this.courseId,
    required this.estimatedLevelId,
    required this.masteredLevelIds,
    required this.skipped,
    required this.takenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['course_id'] = Variable<String>(courseId);
    map['estimated_level_id'] = Variable<String>(estimatedLevelId);
    map['mastered_level_ids'] = Variable<String>(masteredLevelIds);
    map['skipped'] = Variable<bool>(skipped);
    map['taken_at'] = Variable<DateTime>(takenAt);
    return map;
  }

  PlacementResultsCompanion toCompanion(bool nullToAbsent) {
    return PlacementResultsCompanion(
      uid: Value(uid),
      courseId: Value(courseId),
      estimatedLevelId: Value(estimatedLevelId),
      masteredLevelIds: Value(masteredLevelIds),
      skipped: Value(skipped),
      takenAt: Value(takenAt),
    );
  }

  factory PlacementResultRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlacementResultRow(
      uid: serializer.fromJson<String>(json['uid']),
      courseId: serializer.fromJson<String>(json['courseId']),
      estimatedLevelId: serializer.fromJson<String>(json['estimatedLevelId']),
      masteredLevelIds: serializer.fromJson<String>(json['masteredLevelIds']),
      skipped: serializer.fromJson<bool>(json['skipped']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'courseId': serializer.toJson<String>(courseId),
      'estimatedLevelId': serializer.toJson<String>(estimatedLevelId),
      'masteredLevelIds': serializer.toJson<String>(masteredLevelIds),
      'skipped': serializer.toJson<bool>(skipped),
      'takenAt': serializer.toJson<DateTime>(takenAt),
    };
  }

  PlacementResultRow copyWith({
    String? uid,
    String? courseId,
    String? estimatedLevelId,
    String? masteredLevelIds,
    bool? skipped,
    DateTime? takenAt,
  }) => PlacementResultRow(
    uid: uid ?? this.uid,
    courseId: courseId ?? this.courseId,
    estimatedLevelId: estimatedLevelId ?? this.estimatedLevelId,
    masteredLevelIds: masteredLevelIds ?? this.masteredLevelIds,
    skipped: skipped ?? this.skipped,
    takenAt: takenAt ?? this.takenAt,
  );
  PlacementResultRow copyWithCompanion(PlacementResultsCompanion data) {
    return PlacementResultRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      estimatedLevelId: data.estimatedLevelId.present
          ? data.estimatedLevelId.value
          : this.estimatedLevelId,
      masteredLevelIds: data.masteredLevelIds.present
          ? data.masteredLevelIds.value
          : this.masteredLevelIds,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlacementResultRow(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('estimatedLevelId: $estimatedLevelId, ')
          ..write('masteredLevelIds: $masteredLevelIds, ')
          ..write('skipped: $skipped, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    courseId,
    estimatedLevelId,
    masteredLevelIds,
    skipped,
    takenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlacementResultRow &&
          other.uid == this.uid &&
          other.courseId == this.courseId &&
          other.estimatedLevelId == this.estimatedLevelId &&
          other.masteredLevelIds == this.masteredLevelIds &&
          other.skipped == this.skipped &&
          other.takenAt == this.takenAt);
}

class PlacementResultsCompanion extends UpdateCompanion<PlacementResultRow> {
  final Value<String> uid;
  final Value<String> courseId;
  final Value<String> estimatedLevelId;
  final Value<String> masteredLevelIds;
  final Value<bool> skipped;
  final Value<DateTime> takenAt;
  final Value<int> rowid;
  const PlacementResultsCompanion({
    this.uid = const Value.absent(),
    this.courseId = const Value.absent(),
    this.estimatedLevelId = const Value.absent(),
    this.masteredLevelIds = const Value.absent(),
    this.skipped = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlacementResultsCompanion.insert({
    required String uid,
    required String courseId,
    required String estimatedLevelId,
    this.masteredLevelIds = const Value.absent(),
    this.skipped = const Value.absent(),
    required DateTime takenAt,
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       courseId = Value(courseId),
       estimatedLevelId = Value(estimatedLevelId),
       takenAt = Value(takenAt);
  static Insertable<PlacementResultRow> custom({
    Expression<String>? uid,
    Expression<String>? courseId,
    Expression<String>? estimatedLevelId,
    Expression<String>? masteredLevelIds,
    Expression<bool>? skipped,
    Expression<DateTime>? takenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (courseId != null) 'course_id': courseId,
      if (estimatedLevelId != null) 'estimated_level_id': estimatedLevelId,
      if (masteredLevelIds != null) 'mastered_level_ids': masteredLevelIds,
      if (skipped != null) 'skipped': skipped,
      if (takenAt != null) 'taken_at': takenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlacementResultsCompanion copyWith({
    Value<String>? uid,
    Value<String>? courseId,
    Value<String>? estimatedLevelId,
    Value<String>? masteredLevelIds,
    Value<bool>? skipped,
    Value<DateTime>? takenAt,
    Value<int>? rowid,
  }) {
    return PlacementResultsCompanion(
      uid: uid ?? this.uid,
      courseId: courseId ?? this.courseId,
      estimatedLevelId: estimatedLevelId ?? this.estimatedLevelId,
      masteredLevelIds: masteredLevelIds ?? this.masteredLevelIds,
      skipped: skipped ?? this.skipped,
      takenAt: takenAt ?? this.takenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (estimatedLevelId.present) {
      map['estimated_level_id'] = Variable<String>(estimatedLevelId.value);
    }
    if (masteredLevelIds.present) {
      map['mastered_level_ids'] = Variable<String>(masteredLevelIds.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacementResultsCompanion(')
          ..write('uid: $uid, ')
          ..write('courseId: $courseId, ')
          ..write('estimatedLevelId: $estimatedLevelId, ')
          ..write('masteredLevelIds: $masteredLevelIds, ')
          ..write('skipped: $skipped, ')
          ..write('takenAt: $takenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasPendingChangesMeta = const VerificationMeta(
    'hasPendingChanges',
  );
  @override
  late final GeneratedColumn<bool> hasPendingChanges = GeneratedColumn<bool>(
    'has_pending_changes',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_pending_changes" IN (0, 1))',
    ),
    defaultValue: const Constant<bool>(false),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storageDegradedMeta = const VerificationMeta(
    'storageDegraded',
  );
  @override
  late final GeneratedColumn<bool> storageDegraded = GeneratedColumn<bool>(
    'storage_degraded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("storage_degraded" IN (0, 1))',
    ),
    defaultValue: const Constant<bool>(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uid,
    lastSyncedAt,
    hasPendingChanges,
    lastError,
    storageDegraded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('has_pending_changes')) {
      context.handle(
        _hasPendingChangesMeta,
        hasPendingChanges.isAcceptableOrUnknown(
          data['has_pending_changes']!,
          _hasPendingChangesMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('storage_degraded')) {
      context.handle(
        _storageDegradedMeta,
        storageDegraded.isAcceptableOrUnknown(
          data['storage_degraded']!,
          _storageDegradedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      hasPendingChanges: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_pending_changes'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      storageDegraded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}storage_degraded'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String uid;
  final DateTime? lastSyncedAt;
  final bool hasPendingChanges;
  final String? lastError;
  final bool storageDegraded;
  const SyncMetaRow({
    required this.uid,
    this.lastSyncedAt,
    required this.hasPendingChanges,
    this.lastError,
    required this.storageDegraded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['has_pending_changes'] = Variable<bool>(hasPendingChanges);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['storage_degraded'] = Variable<bool>(storageDegraded);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      uid: Value(uid),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      hasPendingChanges: Value(hasPendingChanges),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      storageDegraded: Value(storageDegraded),
    );
  }

  factory SyncMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
      uid: serializer.fromJson<String>(json['uid']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      hasPendingChanges: serializer.fromJson<bool>(json['hasPendingChanges']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      storageDegraded: serializer.fromJson<bool>(json['storageDegraded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'hasPendingChanges': serializer.toJson<bool>(hasPendingChanges),
      'lastError': serializer.toJson<String?>(lastError),
      'storageDegraded': serializer.toJson<bool>(storageDegraded),
    };
  }

  SyncMetaRow copyWith({
    String? uid,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    bool? hasPendingChanges,
    Value<String?> lastError = const Value.absent(),
    bool? storageDegraded,
  }) => SyncMetaRow(
    uid: uid ?? this.uid,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
    lastError: lastError.present ? lastError.value : this.lastError,
    storageDegraded: storageDegraded ?? this.storageDegraded,
  );
  SyncMetaRow copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaRow(
      uid: data.uid.present ? data.uid.value : this.uid,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      hasPendingChanges: data.hasPendingChanges.present
          ? data.hasPendingChanges.value
          : this.hasPendingChanges,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      storageDegraded: data.storageDegraded.present
          ? data.storageDegraded.value
          : this.storageDegraded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
          ..write('uid: $uid, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('hasPendingChanges: $hasPendingChanges, ')
          ..write('lastError: $lastError, ')
          ..write('storageDegraded: $storageDegraded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uid,
    lastSyncedAt,
    hasPendingChanges,
    lastError,
    storageDegraded,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaRow &&
          other.uid == this.uid &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.hasPendingChanges == this.hasPendingChanges &&
          other.lastError == this.lastError &&
          other.storageDegraded == this.storageDegraded);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> uid;
  final Value<DateTime?> lastSyncedAt;
  final Value<bool> hasPendingChanges;
  final Value<String?> lastError;
  final Value<bool> storageDegraded;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.uid = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.hasPendingChanges = const Value.absent(),
    this.lastError = const Value.absent(),
    this.storageDegraded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String uid,
    this.lastSyncedAt = const Value.absent(),
    this.hasPendingChanges = const Value.absent(),
    this.lastError = const Value.absent(),
    this.storageDegraded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uid = Value(uid);
  static Insertable<SyncMetaRow> custom({
    Expression<String>? uid,
    Expression<DateTime>? lastSyncedAt,
    Expression<bool>? hasPendingChanges,
    Expression<String>? lastError,
    Expression<bool>? storageDegraded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (hasPendingChanges != null) 'has_pending_changes': hasPendingChanges,
      if (lastError != null) 'last_error': lastError,
      if (storageDegraded != null) 'storage_degraded': storageDegraded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? uid,
    Value<DateTime?>? lastSyncedAt,
    Value<bool>? hasPendingChanges,
    Value<String?>? lastError,
    Value<bool>? storageDegraded,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      uid: uid ?? this.uid,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      lastError: lastError ?? this.lastError,
      storageDegraded: storageDegraded ?? this.storageDegraded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (hasPendingChanges.present) {
      map['has_pending_changes'] = Variable<bool>(hasPendingChanges.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (storageDegraded.present) {
      map['storage_degraded'] = Variable<bool>(storageDegraded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('uid: $uid, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('hasPendingChanges: $hasPendingChanges, ')
          ..write('lastError: $lastError, ')
          ..write('storageDegraded: $storageDegraded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SchemaMetaTable schemaMeta = $SchemaMetaTable(this);
  late final $StudentProfileTable studentProfile = $StudentProfileTable(this);
  late final $LevelProgressTable levelProgress = $LevelProgressTable(this);
  late final $ActivityResultsTable activityResults = $ActivityResultsTable(
    this,
  );
  late final $ReviewCardsTable reviewCards = $ReviewCardsTable(this);
  late final $PlacementResultsTable placementResults = $PlacementResultsTable(
    this,
  );
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final Index idxReviewDue = Index(
    'idx_review_due',
    'CREATE INDEX idx_review_due ON review_cards (uid, course_id, due_date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    schemaMeta,
    studentProfile,
    levelProgress,
    activityResults,
    reviewCards,
    placementResults,
    syncMeta,
    idxReviewDue,
  ];
}

typedef $$SchemaMetaTableCreateCompanionBuilder =
    SchemaMetaCompanion Function({
      Value<int> id,
      required int version,
      required DateTime createdAt,
      Value<DateTime?> migratedAt,
    });
typedef $$SchemaMetaTableUpdateCompanionBuilder =
    SchemaMetaCompanion Function({
      Value<int> id,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime?> migratedAt,
    });

class $$SchemaMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SchemaMetaTable> {
  $$SchemaMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get migratedAt => $composableBuilder(
    column: $table.migratedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemaMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemaMetaTable> {
  $$SchemaMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get migratedAt => $composableBuilder(
    column: $table.migratedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemaMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemaMetaTable> {
  $$SchemaMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get migratedAt => $composableBuilder(
    column: $table.migratedAt,
    builder: (column) => column,
  );
}

class $$SchemaMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemaMetaTable,
          SchemaMetaRow,
          $$SchemaMetaTableFilterComposer,
          $$SchemaMetaTableOrderingComposer,
          $$SchemaMetaTableAnnotationComposer,
          $$SchemaMetaTableCreateCompanionBuilder,
          $$SchemaMetaTableUpdateCompanionBuilder,
          (
            SchemaMetaRow,
            BaseReferences<_$AppDatabase, $SchemaMetaTable, SchemaMetaRow>,
          ),
          SchemaMetaRow,
          PrefetchHooks Function()
        > {
  $$SchemaMetaTableTableManager(_$AppDatabase db, $SchemaMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemaMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemaMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemaMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> migratedAt = const Value.absent(),
              }) => SchemaMetaCompanion(
                id: id,
                version: version,
                createdAt: createdAt,
                migratedAt: migratedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int version,
                required DateTime createdAt,
                Value<DateTime?> migratedAt = const Value.absent(),
              }) => SchemaMetaCompanion.insert(
                id: id,
                version: version,
                createdAt: createdAt,
                migratedAt: migratedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchemaMetaTable, SchemaMetaRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SchemaMetaTable,
                    SchemaMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemaMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemaMetaTable,
      SchemaMetaRow,
      $$SchemaMetaTableFilterComposer,
      $$SchemaMetaTableOrderingComposer,
      $$SchemaMetaTableAnnotationComposer,
      $$SchemaMetaTableCreateCompanionBuilder,
      $$SchemaMetaTableUpdateCompanionBuilder,
      (
        SchemaMetaRow,
        BaseReferences<_$AppDatabase, $SchemaMetaTable, SchemaMetaRow>,
      ),
      SchemaMetaRow,
      PrefetchHooks Function()
    >;
typedef $$StudentProfileTableCreateCompanionBuilder =
    StudentProfileCompanion Function({
      required String uid,
      required String courseId,
      required String currentLevelId,
      Value<int> xp,
      Value<int> streakCount,
      Value<DateTime?> lastActivityDate,
      Value<int> rowid,
    });
typedef $$StudentProfileTableUpdateCompanionBuilder =
    StudentProfileCompanion Function({
      Value<String> uid,
      Value<String> courseId,
      Value<String> currentLevelId,
      Value<int> xp,
      Value<int> streakCount,
      Value<DateTime?> lastActivityDate,
      Value<int> rowid,
    });

class $$StudentProfileTableFilterComposer
    extends Composer<_$AppDatabase, $StudentProfileTable> {
  $$StudentProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentLevelId => $composableBuilder(
    column: $table.currentLevelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActivityDate => $composableBuilder(
    column: $table.lastActivityDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudentProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $StudentProfileTable> {
  $$StudentProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentLevelId => $composableBuilder(
    column: $table.currentLevelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xp => $composableBuilder(
    column: $table.xp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActivityDate => $composableBuilder(
    column: $table.lastActivityDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudentProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudentProfileTable> {
  $$StudentProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get currentLevelId => $composableBuilder(
    column: $table.currentLevelId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xp =>
      $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastActivityDate => $composableBuilder(
    column: $table.lastActivityDate,
    builder: (column) => column,
  );
}

class $$StudentProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudentProfileTable,
          StudentProfileRow,
          $$StudentProfileTableFilterComposer,
          $$StudentProfileTableOrderingComposer,
          $$StudentProfileTableAnnotationComposer,
          $$StudentProfileTableCreateCompanionBuilder,
          $$StudentProfileTableUpdateCompanionBuilder,
          (
            StudentProfileRow,
            BaseReferences<
              _$AppDatabase,
              $StudentProfileTable,
              StudentProfileRow
            >,
          ),
          StudentProfileRow,
          PrefetchHooks Function()
        > {
  $$StudentProfileTableTableManager(
    _$AppDatabase db,
    $StudentProfileTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudentProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudentProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudentProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> currentLevelId = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<DateTime?> lastActivityDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentProfileCompanion(
                uid: uid,
                courseId: courseId,
                currentLevelId: currentLevelId,
                xp: xp,
                streakCount: streakCount,
                lastActivityDate: lastActivityDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String courseId,
                required String currentLevelId,
                Value<int> xp = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<DateTime?> lastActivityDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudentProfileCompanion.insert(
                uid: uid,
                courseId: courseId,
                currentLevelId: currentLevelId,
                xp: xp,
                streakCount: streakCount,
                lastActivityDate: lastActivityDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StudentProfileTable, StudentProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StudentProfileTable,
                    StudentProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudentProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudentProfileTable,
      StudentProfileRow,
      $$StudentProfileTableFilterComposer,
      $$StudentProfileTableOrderingComposer,
      $$StudentProfileTableAnnotationComposer,
      $$StudentProfileTableCreateCompanionBuilder,
      $$StudentProfileTableUpdateCompanionBuilder,
      (
        StudentProfileRow,
        BaseReferences<_$AppDatabase, $StudentProfileTable, StudentProfileRow>,
      ),
      StudentProfileRow,
      PrefetchHooks Function()
    >;
typedef $$LevelProgressTableCreateCompanionBuilder =
    LevelProgressCompanion Function({
      required String uid,
      required String courseId,
      required String levelId,
      required int state,
      Value<int> rowid,
    });
typedef $$LevelProgressTableUpdateCompanionBuilder =
    LevelProgressCompanion Function({
      Value<String> uid,
      Value<String> courseId,
      Value<String> levelId,
      Value<int> state,
      Value<int> rowid,
    });

class $$LevelProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LevelProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get levelId => $composableBuilder(
    column: $table.levelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LevelProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LevelProgressTable> {
  $$LevelProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);
}

class $$LevelProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LevelProgressTable,
          LevelProgressRow,
          $$LevelProgressTableFilterComposer,
          $$LevelProgressTableOrderingComposer,
          $$LevelProgressTableAnnotationComposer,
          $$LevelProgressTableCreateCompanionBuilder,
          $$LevelProgressTableUpdateCompanionBuilder,
          (
            LevelProgressRow,
            BaseReferences<
              _$AppDatabase,
              $LevelProgressTable,
              LevelProgressRow
            >,
          ),
          LevelProgressRow,
          PrefetchHooks Function()
        > {
  $$LevelProgressTableTableManager(_$AppDatabase db, $LevelProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LevelProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LevelProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LevelProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> levelId = const Value.absent(),
                Value<int> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion(
                uid: uid,
                courseId: courseId,
                levelId: levelId,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String courseId,
                required String levelId,
                required int state,
                Value<int> rowid = const Value.absent(),
              }) => LevelProgressCompanion.insert(
                uid: uid,
                courseId: courseId,
                levelId: levelId,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LevelProgressTable, LevelProgressRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LevelProgressTable,
                    LevelProgressRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LevelProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LevelProgressTable,
      LevelProgressRow,
      $$LevelProgressTableFilterComposer,
      $$LevelProgressTableOrderingComposer,
      $$LevelProgressTableAnnotationComposer,
      $$LevelProgressTableCreateCompanionBuilder,
      $$LevelProgressTableUpdateCompanionBuilder,
      (
        LevelProgressRow,
        BaseReferences<_$AppDatabase, $LevelProgressTable, LevelProgressRow>,
      ),
      LevelProgressRow,
      PrefetchHooks Function()
    >;
typedef $$ActivityResultsTableCreateCompanionBuilder =
    ActivityResultsCompanion Function({
      required String uid,
      required String courseId,
      required String activityId,
      required int activityKind,
      required double bestScore,
      Value<int> attempts,
      required DateTime lastAttemptAt,
      Value<int> rowid,
    });
typedef $$ActivityResultsTableUpdateCompanionBuilder =
    ActivityResultsCompanion Function({
      Value<String> uid,
      Value<String> courseId,
      Value<String> activityId,
      Value<int> activityKind,
      Value<double> bestScore,
      Value<int> attempts,
      Value<DateTime> lastAttemptAt,
      Value<int> rowid,
    });

class $$ActivityResultsTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityResultsTable> {
  $$ActivityResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activityKind => $composableBuilder(
    column: $table.activityKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityResultsTable> {
  $$ActivityResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activityKind => $composableBuilder(
    column: $table.activityKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bestScore => $composableBuilder(
    column: $table.bestScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityResultsTable> {
  $$ActivityResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activityKind => $composableBuilder(
    column: $table.activityKind,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bestScore =>
      $composableBuilder(column: $table.bestScore, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );
}

class $$ActivityResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityResultsTable,
          ActivityResultRow,
          $$ActivityResultsTableFilterComposer,
          $$ActivityResultsTableOrderingComposer,
          $$ActivityResultsTableAnnotationComposer,
          $$ActivityResultsTableCreateCompanionBuilder,
          $$ActivityResultsTableUpdateCompanionBuilder,
          (
            ActivityResultRow,
            BaseReferences<
              _$AppDatabase,
              $ActivityResultsTable,
              ActivityResultRow
            >,
          ),
          ActivityResultRow,
          PrefetchHooks Function()
        > {
  $$ActivityResultsTableTableManager(
    _$AppDatabase db,
    $ActivityResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<int> activityKind = const Value.absent(),
                Value<double> bestScore = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityResultsCompanion(
                uid: uid,
                courseId: courseId,
                activityId: activityId,
                activityKind: activityKind,
                bestScore: bestScore,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String courseId,
                required String activityId,
                required int activityKind,
                required double bestScore,
                Value<int> attempts = const Value.absent(),
                required DateTime lastAttemptAt,
                Value<int> rowid = const Value.absent(),
              }) => ActivityResultsCompanion.insert(
                uid: uid,
                courseId: courseId,
                activityId: activityId,
                activityKind: activityKind,
                bestScore: bestScore,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActivityResultsTable, ActivityResultRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ActivityResultsTable,
                    ActivityResultRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityResultsTable,
      ActivityResultRow,
      $$ActivityResultsTableFilterComposer,
      $$ActivityResultsTableOrderingComposer,
      $$ActivityResultsTableAnnotationComposer,
      $$ActivityResultsTableCreateCompanionBuilder,
      $$ActivityResultsTableUpdateCompanionBuilder,
      (
        ActivityResultRow,
        BaseReferences<_$AppDatabase, $ActivityResultsTable, ActivityResultRow>,
      ),
      ActivityResultRow,
      PrefetchHooks Function()
    >;
typedef $$ReviewCardsTableCreateCompanionBuilder =
    ReviewCardsCompanion Function({
      required String uid,
      required String courseId,
      required String moduleId,
      required String term,
      required String translation,
      Value<int> intervalStep,
      required DateTime dueDate,
      Value<int> lapses,
      Value<int> rowid,
    });
typedef $$ReviewCardsTableUpdateCompanionBuilder =
    ReviewCardsCompanion Function({
      Value<String> uid,
      Value<String> courseId,
      Value<String> moduleId,
      Value<String> term,
      Value<String> translation,
      Value<int> intervalStep,
      Value<DateTime> dueDate,
      Value<int> lapses,
      Value<int> rowid,
    });

class $$ReviewCardsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalStep => $composableBuilder(
    column: $table.intervalStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalStep => $composableBuilder(
    column: $table.intervalStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewCardsTable> {
  $$ReviewCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get moduleId =>
      $composableBuilder(column: $table.moduleId, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalStep => $composableBuilder(
    column: $table.intervalStep,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);
}

class $$ReviewCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewCardsTable,
          ReviewCardRow,
          $$ReviewCardsTableFilterComposer,
          $$ReviewCardsTableOrderingComposer,
          $$ReviewCardsTableAnnotationComposer,
          $$ReviewCardsTableCreateCompanionBuilder,
          $$ReviewCardsTableUpdateCompanionBuilder,
          (
            ReviewCardRow,
            BaseReferences<_$AppDatabase, $ReviewCardsTable, ReviewCardRow>,
          ),
          ReviewCardRow,
          PrefetchHooks Function()
        > {
  $$ReviewCardsTableTableManager(_$AppDatabase db, $ReviewCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> moduleId = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<int> intervalStep = const Value.absent(),
                Value<DateTime> dueDate = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewCardsCompanion(
                uid: uid,
                courseId: courseId,
                moduleId: moduleId,
                term: term,
                translation: translation,
                intervalStep: intervalStep,
                dueDate: dueDate,
                lapses: lapses,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String courseId,
                required String moduleId,
                required String term,
                required String translation,
                Value<int> intervalStep = const Value.absent(),
                required DateTime dueDate,
                Value<int> lapses = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewCardsCompanion.insert(
                uid: uid,
                courseId: courseId,
                moduleId: moduleId,
                term: term,
                translation: translation,
                intervalStep: intervalStep,
                dueDate: dueDate,
                lapses: lapses,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewCardsTable, ReviewCardRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReviewCardsTable,
                    ReviewCardRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewCardsTable,
      ReviewCardRow,
      $$ReviewCardsTableFilterComposer,
      $$ReviewCardsTableOrderingComposer,
      $$ReviewCardsTableAnnotationComposer,
      $$ReviewCardsTableCreateCompanionBuilder,
      $$ReviewCardsTableUpdateCompanionBuilder,
      (
        ReviewCardRow,
        BaseReferences<_$AppDatabase, $ReviewCardsTable, ReviewCardRow>,
      ),
      ReviewCardRow,
      PrefetchHooks Function()
    >;
typedef $$PlacementResultsTableCreateCompanionBuilder =
    PlacementResultsCompanion Function({
      required String uid,
      required String courseId,
      required String estimatedLevelId,
      Value<String> masteredLevelIds,
      Value<bool> skipped,
      required DateTime takenAt,
      Value<int> rowid,
    });
typedef $$PlacementResultsTableUpdateCompanionBuilder =
    PlacementResultsCompanion Function({
      Value<String> uid,
      Value<String> courseId,
      Value<String> estimatedLevelId,
      Value<String> masteredLevelIds,
      Value<bool> skipped,
      Value<DateTime> takenAt,
      Value<int> rowid,
    });

class $$PlacementResultsTableFilterComposer
    extends Composer<_$AppDatabase, $PlacementResultsTable> {
  $$PlacementResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estimatedLevelId => $composableBuilder(
    column: $table.estimatedLevelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get masteredLevelIds => $composableBuilder(
    column: $table.masteredLevelIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlacementResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacementResultsTable> {
  $$PlacementResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estimatedLevelId => $composableBuilder(
    column: $table.estimatedLevelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get masteredLevelIds => $composableBuilder(
    column: $table.masteredLevelIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlacementResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacementResultsTable> {
  $$PlacementResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get estimatedLevelId => $composableBuilder(
    column: $table.estimatedLevelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get masteredLevelIds => $composableBuilder(
    column: $table.masteredLevelIds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);
}

class $$PlacementResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlacementResultsTable,
          PlacementResultRow,
          $$PlacementResultsTableFilterComposer,
          $$PlacementResultsTableOrderingComposer,
          $$PlacementResultsTableAnnotationComposer,
          $$PlacementResultsTableCreateCompanionBuilder,
          $$PlacementResultsTableUpdateCompanionBuilder,
          (
            PlacementResultRow,
            BaseReferences<
              _$AppDatabase,
              $PlacementResultsTable,
              PlacementResultRow
            >,
          ),
          PlacementResultRow,
          PrefetchHooks Function()
        > {
  $$PlacementResultsTableTableManager(
    _$AppDatabase db,
    $PlacementResultsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacementResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacementResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacementResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> estimatedLevelId = const Value.absent(),
                Value<String> masteredLevelIds = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlacementResultsCompanion(
                uid: uid,
                courseId: courseId,
                estimatedLevelId: estimatedLevelId,
                masteredLevelIds: masteredLevelIds,
                skipped: skipped,
                takenAt: takenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String courseId,
                required String estimatedLevelId,
                Value<String> masteredLevelIds = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                required DateTime takenAt,
                Value<int> rowid = const Value.absent(),
              }) => PlacementResultsCompanion.insert(
                uid: uid,
                courseId: courseId,
                estimatedLevelId: estimatedLevelId,
                masteredLevelIds: masteredLevelIds,
                skipped: skipped,
                takenAt: takenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlacementResultsTable, PlacementResultRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PlacementResultsTable,
                    PlacementResultRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlacementResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlacementResultsTable,
      PlacementResultRow,
      $$PlacementResultsTableFilterComposer,
      $$PlacementResultsTableOrderingComposer,
      $$PlacementResultsTableAnnotationComposer,
      $$PlacementResultsTableCreateCompanionBuilder,
      $$PlacementResultsTableUpdateCompanionBuilder,
      (
        PlacementResultRow,
        BaseReferences<
          _$AppDatabase,
          $PlacementResultsTable,
          PlacementResultRow
        >,
      ),
      PlacementResultRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String uid,
      Value<DateTime?> lastSyncedAt,
      Value<bool> hasPendingChanges,
      Value<String?> lastError,
      Value<bool> storageDegraded,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> uid,
      Value<DateTime?> lastSyncedAt,
      Value<bool> hasPendingChanges,
      Value<String?> lastError,
      Value<bool> storageDegraded,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get storageDegraded => $composableBuilder(
    column: $table.storageDegraded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get storageDegraded => $composableBuilder(
    column: $table.storageDegraded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasPendingChanges => $composableBuilder(
    column: $table.hasPendingChanges,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<bool> get storageDegraded => $composableBuilder(
    column: $table.storageDegraded,
    builder: (column) => column,
  );
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaRow,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaRow,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>,
          ),
          SyncMetaRow,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> hasPendingChanges = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> storageDegraded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(
                uid: uid,
                lastSyncedAt: lastSyncedAt,
                hasPendingChanges: hasPendingChanges,
                lastError: lastError,
                storageDegraded: storageDegraded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<bool> hasPendingChanges = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> storageDegraded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                uid: uid,
                lastSyncedAt: lastSyncedAt,
                hasPendingChanges: hasPendingChanges,
                lastError: lastError,
                storageDegraded: storageDegraded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMetaTable, SyncMetaRow>(table),
                  BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>(
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

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaRow,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (SyncMetaRow, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>),
      SyncMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SchemaMetaTableTableManager get schemaMeta =>
      $$SchemaMetaTableTableManager(_db, _db.schemaMeta);
  $$StudentProfileTableTableManager get studentProfile =>
      $$StudentProfileTableTableManager(_db, _db.studentProfile);
  $$LevelProgressTableTableManager get levelProgress =>
      $$LevelProgressTableTableManager(_db, _db.levelProgress);
  $$ActivityResultsTableTableManager get activityResults =>
      $$ActivityResultsTableTableManager(_db, _db.activityResults);
  $$ReviewCardsTableTableManager get reviewCards =>
      $$ReviewCardsTableTableManager(_db, _db.reviewCards);
  $$PlacementResultsTableTableManager get placementResults =>
      $$PlacementResultsTableTableManager(_db, _db.placementResults);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}
