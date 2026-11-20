// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AnimeRecordsTable extends AnimeRecords
    with TableInfo<$AnimeRecordsTable, AnimeRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimeRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _malIdMeta = const VerificationMeta('malId');
  @override
  late final GeneratedColumn<int> malId = GeneratedColumn<int>(
    'mal_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _romajiTitleMeta = const VerificationMeta(
    'romajiTitle',
  );
  @override
  late final GeneratedColumn<String> romajiTitle = GeneratedColumn<String>(
    'romaji_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _englishTitleMeta = const VerificationMeta(
    'englishTitle',
  );
  @override
  late final GeneratedColumn<String> englishTitle = GeneratedColumn<String>(
    'english_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bannerUrlMeta = const VerificationMeta(
    'bannerUrl',
  );
  @override
  late final GeneratedColumn<String> bannerUrl = GeneratedColumn<String>(
    'banner_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverColorMeta = const VerificationMeta(
    'coverColor',
  );
  @override
  late final GeneratedColumn<int> coverColor = GeneratedColumn<int>(
    'cover_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalEpisodesMeta = const VerificationMeta(
    'totalEpisodes',
  );
  @override
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
    'total_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _averageScoreMeta = const VerificationMeta(
    'averageScore',
  );
  @override
  late final GeneratedColumn<int> averageScore = GeneratedColumn<int>(
    'average_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    malId,
    title,
    romajiTitle,
    englishTitle,
    coverUrl,
    bannerUrl,
    coverColor,
    format,
    status,
    totalEpisodes,
    averageScore,
    genres,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('mal_id')) {
      context.handle(
        _malIdMeta,
        malId.isAcceptableOrUnknown(data['mal_id']!, _malIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('romaji_title')) {
      context.handle(
        _romajiTitleMeta,
        romajiTitle.isAcceptableOrUnknown(
          data['romaji_title']!,
          _romajiTitleMeta,
        ),
      );
    }
    if (data.containsKey('english_title')) {
      context.handle(
        _englishTitleMeta,
        englishTitle.isAcceptableOrUnknown(
          data['english_title']!,
          _englishTitleMeta,
        ),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('banner_url')) {
      context.handle(
        _bannerUrlMeta,
        bannerUrl.isAcceptableOrUnknown(data['banner_url']!, _bannerUrlMeta),
      );
    }
    if (data.containsKey('cover_color')) {
      context.handle(
        _coverColorMeta,
        coverColor.isAcceptableOrUnknown(data['cover_color']!, _coverColorMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
        _totalEpisodesMeta,
        totalEpisodes.isAcceptableOrUnknown(
          data['total_episodes']!,
          _totalEpisodesMeta,
        ),
      );
    }
    if (data.containsKey('average_score')) {
      context.handle(
        _averageScoreMeta,
        averageScore.isAcceptableOrUnknown(
          data['average_score']!,
          _averageScoreMeta,
        ),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnimeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      malId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mal_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      romajiTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}romaji_title'],
      ),
      englishTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_title'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      bannerUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}banner_url'],
      ),
      coverColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_color'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      totalEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_episodes'],
      ),
      averageScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}average_score'],
      ),
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AnimeRecordsTable createAlias(String alias) {
    return $AnimeRecordsTable(attachedDatabase, alias);
  }
}

class AnimeRecord extends DataClass implements Insertable<AnimeRecord> {
  final int id;
  final int? malId;
  final String title;
  final String? romajiTitle;
  final String? englishTitle;
  final String? coverUrl;
  final String? bannerUrl;
  final int? coverColor;
  final String? format;
  final String? status;
  final int? totalEpisodes;
  final int? averageScore;
  final String genres;
  final DateTime updatedAt;
  const AnimeRecord({
    required this.id,
    this.malId,
    required this.title,
    this.romajiTitle,
    this.englishTitle,
    this.coverUrl,
    this.bannerUrl,
    this.coverColor,
    this.format,
    this.status,
    this.totalEpisodes,
    this.averageScore,
    required this.genres,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || malId != null) {
      map['mal_id'] = Variable<int>(malId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || romajiTitle != null) {
      map['romaji_title'] = Variable<String>(romajiTitle);
    }
    if (!nullToAbsent || englishTitle != null) {
      map['english_title'] = Variable<String>(englishTitle);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || bannerUrl != null) {
      map['banner_url'] = Variable<String>(bannerUrl);
    }
    if (!nullToAbsent || coverColor != null) {
      map['cover_color'] = Variable<int>(coverColor);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || totalEpisodes != null) {
      map['total_episodes'] = Variable<int>(totalEpisodes);
    }
    if (!nullToAbsent || averageScore != null) {
      map['average_score'] = Variable<int>(averageScore);
    }
    map['genres'] = Variable<String>(genres);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AnimeRecordsCompanion toCompanion(bool nullToAbsent) {
    return AnimeRecordsCompanion(
      id: Value(id),
      malId: malId == null && nullToAbsent
          ? const Value.absent()
          : Value(malId),
      title: Value(title),
      romajiTitle: romajiTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(romajiTitle),
      englishTitle: englishTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(englishTitle),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      bannerUrl: bannerUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(bannerUrl),
      coverColor: coverColor == null && nullToAbsent
          ? const Value.absent()
          : Value(coverColor),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      totalEpisodes: totalEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalEpisodes),
      averageScore: averageScore == null && nullToAbsent
          ? const Value.absent()
          : Value(averageScore),
      genres: Value(genres),
      updatedAt: Value(updatedAt),
    );
  }

  factory AnimeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimeRecord(
      id: serializer.fromJson<int>(json['id']),
      malId: serializer.fromJson<int?>(json['malId']),
      title: serializer.fromJson<String>(json['title']),
      romajiTitle: serializer.fromJson<String?>(json['romajiTitle']),
      englishTitle: serializer.fromJson<String?>(json['englishTitle']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      bannerUrl: serializer.fromJson<String?>(json['bannerUrl']),
      coverColor: serializer.fromJson<int?>(json['coverColor']),
      format: serializer.fromJson<String?>(json['format']),
      status: serializer.fromJson<String?>(json['status']),
      totalEpisodes: serializer.fromJson<int?>(json['totalEpisodes']),
      averageScore: serializer.fromJson<int?>(json['averageScore']),
      genres: serializer.fromJson<String>(json['genres']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'malId': serializer.toJson<int?>(malId),
      'title': serializer.toJson<String>(title),
      'romajiTitle': serializer.toJson<String?>(romajiTitle),
      'englishTitle': serializer.toJson<String?>(englishTitle),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'bannerUrl': serializer.toJson<String?>(bannerUrl),
      'coverColor': serializer.toJson<int?>(coverColor),
      'format': serializer.toJson<String?>(format),
      'status': serializer.toJson<String?>(status),
      'totalEpisodes': serializer.toJson<int?>(totalEpisodes),
      'averageScore': serializer.toJson<int?>(averageScore),
      'genres': serializer.toJson<String>(genres),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AnimeRecord copyWith({
    int? id,
    Value<int?> malId = const Value.absent(),
    String? title,
    Value<String?> romajiTitle = const Value.absent(),
    Value<String?> englishTitle = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> bannerUrl = const Value.absent(),
    Value<int?> coverColor = const Value.absent(),
    Value<String?> format = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<int?> totalEpisodes = const Value.absent(),
    Value<int?> averageScore = const Value.absent(),
    String? genres,
    DateTime? updatedAt,
  }) => AnimeRecord(
    id: id ?? this.id,
    malId: malId.present ? malId.value : this.malId,
    title: title ?? this.title,
    romajiTitle: romajiTitle.present ? romajiTitle.value : this.romajiTitle,
    englishTitle: englishTitle.present ? englishTitle.value : this.englishTitle,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    bannerUrl: bannerUrl.present ? bannerUrl.value : this.bannerUrl,
    coverColor: coverColor.present ? coverColor.value : this.coverColor,
    format: format.present ? format.value : this.format,
    status: status.present ? status.value : this.status,
    totalEpisodes: totalEpisodes.present
        ? totalEpisodes.value
        : this.totalEpisodes,
    averageScore: averageScore.present ? averageScore.value : this.averageScore,
    genres: genres ?? this.genres,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AnimeRecord copyWithCompanion(AnimeRecordsCompanion data) {
    return AnimeRecord(
      id: data.id.present ? data.id.value : this.id,
      malId: data.malId.present ? data.malId.value : this.malId,
      title: data.title.present ? data.title.value : this.title,
      romajiTitle: data.romajiTitle.present
          ? data.romajiTitle.value
          : this.romajiTitle,
      englishTitle: data.englishTitle.present
          ? data.englishTitle.value
          : this.englishTitle,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      bannerUrl: data.bannerUrl.present ? data.bannerUrl.value : this.bannerUrl,
      coverColor: data.coverColor.present
          ? data.coverColor.value
          : this.coverColor,
      format: data.format.present ? data.format.value : this.format,
      status: data.status.present ? data.status.value : this.status,
      totalEpisodes: data.totalEpisodes.present
          ? data.totalEpisodes.value
          : this.totalEpisodes,
      averageScore: data.averageScore.present
          ? data.averageScore.value
          : this.averageScore,
      genres: data.genres.present ? data.genres.value : this.genres,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimeRecord(')
          ..write('id: $id, ')
          ..write('malId: $malId, ')
          ..write('title: $title, ')
          ..write('romajiTitle: $romajiTitle, ')
          ..write('englishTitle: $englishTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('coverColor: $coverColor, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('averageScore: $averageScore, ')
          ..write('genres: $genres, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    malId,
    title,
    romajiTitle,
    englishTitle,
    coverUrl,
    bannerUrl,
    coverColor,
    format,
    status,
    totalEpisodes,
    averageScore,
    genres,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimeRecord &&
          other.id == this.id &&
          other.malId == this.malId &&
          other.title == this.title &&
          other.romajiTitle == this.romajiTitle &&
          other.englishTitle == this.englishTitle &&
          other.coverUrl == this.coverUrl &&
          other.bannerUrl == this.bannerUrl &&
          other.coverColor == this.coverColor &&
          other.format == this.format &&
          other.status == this.status &&
          other.totalEpisodes == this.totalEpisodes &&
          other.averageScore == this.averageScore &&
          other.genres == this.genres &&
          other.updatedAt == this.updatedAt);
}

class AnimeRecordsCompanion extends UpdateCompanion<AnimeRecord> {
  final Value<int> id;
  final Value<int?> malId;
  final Value<String> title;
  final Value<String?> romajiTitle;
  final Value<String?> englishTitle;
  final Value<String?> coverUrl;
  final Value<String?> bannerUrl;
  final Value<int?> coverColor;
  final Value<String?> format;
  final Value<String?> status;
  final Value<int?> totalEpisodes;
  final Value<int?> averageScore;
  final Value<String> genres;
  final Value<DateTime> updatedAt;
  const AnimeRecordsCompanion({
    this.id = const Value.absent(),
    this.malId = const Value.absent(),
    this.title = const Value.absent(),
    this.romajiTitle = const Value.absent(),
    this.englishTitle = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.format = const Value.absent(),
    this.status = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.averageScore = const Value.absent(),
    this.genres = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AnimeRecordsCompanion.insert({
    this.id = const Value.absent(),
    this.malId = const Value.absent(),
    required String title,
    this.romajiTitle = const Value.absent(),
    this.englishTitle = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.bannerUrl = const Value.absent(),
    this.coverColor = const Value.absent(),
    this.format = const Value.absent(),
    this.status = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.averageScore = const Value.absent(),
    this.genres = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<AnimeRecord> custom({
    Expression<int>? id,
    Expression<int>? malId,
    Expression<String>? title,
    Expression<String>? romajiTitle,
    Expression<String>? englishTitle,
    Expression<String>? coverUrl,
    Expression<String>? bannerUrl,
    Expression<int>? coverColor,
    Expression<String>? format,
    Expression<String>? status,
    Expression<int>? totalEpisodes,
    Expression<int>? averageScore,
    Expression<String>? genres,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (malId != null) 'mal_id': malId,
      if (title != null) 'title': title,
      if (romajiTitle != null) 'romaji_title': romajiTitle,
      if (englishTitle != null) 'english_title': englishTitle,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (bannerUrl != null) 'banner_url': bannerUrl,
      if (coverColor != null) 'cover_color': coverColor,
      if (format != null) 'format': format,
      if (status != null) 'status': status,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (averageScore != null) 'average_score': averageScore,
      if (genres != null) 'genres': genres,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AnimeRecordsCompanion copyWith({
    Value<int>? id,
    Value<int?>? malId,
    Value<String>? title,
    Value<String?>? romajiTitle,
    Value<String?>? englishTitle,
    Value<String?>? coverUrl,
    Value<String?>? bannerUrl,
    Value<int?>? coverColor,
    Value<String?>? format,
    Value<String?>? status,
    Value<int?>? totalEpisodes,
    Value<int?>? averageScore,
    Value<String>? genres,
    Value<DateTime>? updatedAt,
  }) {
    return AnimeRecordsCompanion(
      id: id ?? this.id,
      malId: malId ?? this.malId,
      title: title ?? this.title,
      romajiTitle: romajiTitle ?? this.romajiTitle,
      englishTitle: englishTitle ?? this.englishTitle,
      coverUrl: coverUrl ?? this.coverUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      coverColor: coverColor ?? this.coverColor,
      format: format ?? this.format,
      status: status ?? this.status,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      averageScore: averageScore ?? this.averageScore,
      genres: genres ?? this.genres,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (malId.present) {
      map['mal_id'] = Variable<int>(malId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (romajiTitle.present) {
      map['romaji_title'] = Variable<String>(romajiTitle.value);
    }
    if (englishTitle.present) {
      map['english_title'] = Variable<String>(englishTitle.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (bannerUrl.present) {
      map['banner_url'] = Variable<String>(bannerUrl.value);
    }
    if (coverColor.present) {
      map['cover_color'] = Variable<int>(coverColor.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (averageScore.present) {
      map['average_score'] = Variable<int>(averageScore.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimeRecordsCompanion(')
          ..write('id: $id, ')
          ..write('malId: $malId, ')
          ..write('title: $title, ')
          ..write('romajiTitle: $romajiTitle, ')
          ..write('englishTitle: $englishTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('bannerUrl: $bannerUrl, ')
          ..write('coverColor: $coverColor, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('averageScore: $averageScore, ')
          ..write('genres: $genres, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WatchHistoryTable extends WatchHistory
    with TableInfo<$WatchHistoryTable, WatchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<int> animeId = GeneratedColumn<int>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_records (id)',
    ),
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeTitleMeta = const VerificationMeta(
    'episodeTitle',
  );
  @override
  late final GeneratedColumn<String> episodeTitle = GeneratedColumn<String>(
    'episode_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeThumbnailMeta = const VerificationMeta(
    'episodeThumbnail',
  );
  @override
  late final GeneratedColumn<String> episodeThumbnail = GeneratedColumn<String>(
    'episode_thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<double> progressPercent = GeneratedColumn<double>(
    'progress_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioMeta = const VerificationMeta('audio');
  @override
  late final GeneratedColumn<String> audio = GeneratedColumn<String>(
    'audio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sub'),
  );
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
    'server',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastWatchedAtMeta = const VerificationMeta(
    'lastWatchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastWatchedAt =
      GeneratedColumn<DateTime>(
        'last_watched_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  @override
  List<GeneratedColumn> get $columns => [
    animeId,
    episodeNumber,
    episodeTitle,
    episodeThumbnail,
    positionMs,
    durationMs,
    progressPercent,
    isCompleted,
    providerId,
    audio,
    server,
    lastWatchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('episode_title')) {
      context.handle(
        _episodeTitleMeta,
        episodeTitle.isAcceptableOrUnknown(
          data['episode_title']!,
          _episodeTitleMeta,
        ),
      );
    }
    if (data.containsKey('episode_thumbnail')) {
      context.handle(
        _episodeThumbnailMeta,
        episodeThumbnail.isAcceptableOrUnknown(
          data['episode_thumbnail']!,
          _episodeThumbnailMeta,
        ),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    }
    if (data.containsKey('audio')) {
      context.handle(
        _audioMeta,
        audio.isAcceptableOrUnknown(data['audio']!, _audioMeta),
      );
    }
    if (data.containsKey('server')) {
      context.handle(
        _serverMeta,
        server.isAcceptableOrUnknown(data['server']!, _serverMeta),
      );
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
        _lastWatchedAtMeta,
        lastWatchedAt.isAcceptableOrUnknown(
          data['last_watched_at']!,
          _lastWatchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {animeId};
  @override
  WatchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchHistoryData(
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anime_id'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      episodeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_title'],
      ),
      episodeThumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_thumbnail'],
      ),
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_percent'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      ),
      audio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio'],
      )!,
      server: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server'],
      ),
      lastWatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched_at'],
      )!,
    );
  }

  @override
  $WatchHistoryTable createAlias(String alias) {
    return $WatchHistoryTable(attachedDatabase, alias);
  }
}

class WatchHistoryData extends DataClass
    implements Insertable<WatchHistoryData> {
  final int animeId;
  final int episodeNumber;
  final String? episodeTitle;
  final String? episodeThumbnail;
  final int positionMs;
  final int durationMs;
  final double progressPercent;
  final bool isCompleted;
  final String? providerId;
  final String audio;
  final String? server;
  final DateTime lastWatchedAt;
  const WatchHistoryData({
    required this.animeId,
    required this.episodeNumber,
    this.episodeTitle,
    this.episodeThumbnail,
    required this.positionMs,
    required this.durationMs,
    required this.progressPercent,
    required this.isCompleted,
    this.providerId,
    required this.audio,
    this.server,
    required this.lastWatchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anime_id'] = Variable<int>(animeId);
    map['episode_number'] = Variable<int>(episodeNumber);
    if (!nullToAbsent || episodeTitle != null) {
      map['episode_title'] = Variable<String>(episodeTitle);
    }
    if (!nullToAbsent || episodeThumbnail != null) {
      map['episode_thumbnail'] = Variable<String>(episodeThumbnail);
    }
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['progress_percent'] = Variable<double>(progressPercent);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || providerId != null) {
      map['provider_id'] = Variable<String>(providerId);
    }
    map['audio'] = Variable<String>(audio);
    if (!nullToAbsent || server != null) {
      map['server'] = Variable<String>(server);
    }
    map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    return map;
  }

  WatchHistoryCompanion toCompanion(bool nullToAbsent) {
    return WatchHistoryCompanion(
      animeId: Value(animeId),
      episodeNumber: Value(episodeNumber),
      episodeTitle: episodeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeTitle),
      episodeThumbnail: episodeThumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeThumbnail),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      progressPercent: Value(progressPercent),
      isCompleted: Value(isCompleted),
      providerId: providerId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerId),
      audio: Value(audio),
      server: server == null && nullToAbsent
          ? const Value.absent()
          : Value(server),
      lastWatchedAt: Value(lastWatchedAt),
    );
  }

  factory WatchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchHistoryData(
      animeId: serializer.fromJson<int>(json['animeId']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      episodeTitle: serializer.fromJson<String?>(json['episodeTitle']),
      episodeThumbnail: serializer.fromJson<String?>(json['episodeThumbnail']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      progressPercent: serializer.fromJson<double>(json['progressPercent']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      providerId: serializer.fromJson<String?>(json['providerId']),
      audio: serializer.fromJson<String>(json['audio']),
      server: serializer.fromJson<String?>(json['server']),
      lastWatchedAt: serializer.fromJson<DateTime>(json['lastWatchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'animeId': serializer.toJson<int>(animeId),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'episodeTitle': serializer.toJson<String?>(episodeTitle),
      'episodeThumbnail': serializer.toJson<String?>(episodeThumbnail),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'progressPercent': serializer.toJson<double>(progressPercent),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'providerId': serializer.toJson<String?>(providerId),
      'audio': serializer.toJson<String>(audio),
      'server': serializer.toJson<String?>(server),
      'lastWatchedAt': serializer.toJson<DateTime>(lastWatchedAt),
    };
  }

  WatchHistoryData copyWith({
    int? animeId,
    int? episodeNumber,
    Value<String?> episodeTitle = const Value.absent(),
    Value<String?> episodeThumbnail = const Value.absent(),
    int? positionMs,
    int? durationMs,
    double? progressPercent,
    bool? isCompleted,
    Value<String?> providerId = const Value.absent(),
    String? audio,
    Value<String?> server = const Value.absent(),
    DateTime? lastWatchedAt,
  }) => WatchHistoryData(
    animeId: animeId ?? this.animeId,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    episodeTitle: episodeTitle.present ? episodeTitle.value : this.episodeTitle,
    episodeThumbnail: episodeThumbnail.present
        ? episodeThumbnail.value
        : this.episodeThumbnail,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    progressPercent: progressPercent ?? this.progressPercent,
    isCompleted: isCompleted ?? this.isCompleted,
    providerId: providerId.present ? providerId.value : this.providerId,
    audio: audio ?? this.audio,
    server: server.present ? server.value : this.server,
    lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
  );
  WatchHistoryData copyWithCompanion(WatchHistoryCompanion data) {
    return WatchHistoryData(
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      episodeTitle: data.episodeTitle.present
          ? data.episodeTitle.value
          : this.episodeTitle,
      episodeThumbnail: data.episodeThumbnail.present
          ? data.episodeThumbnail.value
          : this.episodeThumbnail,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      audio: data.audio.present ? data.audio.value : this.audio,
      server: data.server.present ? data.server.value : this.server,
      lastWatchedAt: data.lastWatchedAt.present
          ? data.lastWatchedAt.value
          : this.lastWatchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryData(')
          ..write('animeId: $animeId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('episodeThumbnail: $episodeThumbnail, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('providerId: $providerId, ')
          ..write('audio: $audio, ')
          ..write('server: $server, ')
          ..write('lastWatchedAt: $lastWatchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    animeId,
    episodeNumber,
    episodeTitle,
    episodeThumbnail,
    positionMs,
    durationMs,
    progressPercent,
    isCompleted,
    providerId,
    audio,
    server,
    lastWatchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchHistoryData &&
          other.animeId == this.animeId &&
          other.episodeNumber == this.episodeNumber &&
          other.episodeTitle == this.episodeTitle &&
          other.episodeThumbnail == this.episodeThumbnail &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.progressPercent == this.progressPercent &&
          other.isCompleted == this.isCompleted &&
          other.providerId == this.providerId &&
          other.audio == this.audio &&
          other.server == this.server &&
          other.lastWatchedAt == this.lastWatchedAt);
}

class WatchHistoryCompanion extends UpdateCompanion<WatchHistoryData> {
  final Value<int> animeId;
  final Value<int> episodeNumber;
  final Value<String?> episodeTitle;
  final Value<String?> episodeThumbnail;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<double> progressPercent;
  final Value<bool> isCompleted;
  final Value<String?> providerId;
  final Value<String> audio;
  final Value<String?> server;
  final Value<DateTime> lastWatchedAt;
  const WatchHistoryCompanion({
    this.animeId = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.episodeThumbnail = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.providerId = const Value.absent(),
    this.audio = const Value.absent(),
    this.server = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
  });
  WatchHistoryCompanion.insert({
    this.animeId = const Value.absent(),
    required int episodeNumber,
    this.episodeTitle = const Value.absent(),
    this.episodeThumbnail = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.providerId = const Value.absent(),
    this.audio = const Value.absent(),
    this.server = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
  }) : episodeNumber = Value(episodeNumber);
  static Insertable<WatchHistoryData> custom({
    Expression<int>? animeId,
    Expression<int>? episodeNumber,
    Expression<String>? episodeTitle,
    Expression<String>? episodeThumbnail,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<double>? progressPercent,
    Expression<bool>? isCompleted,
    Expression<String>? providerId,
    Expression<String>? audio,
    Expression<String>? server,
    Expression<DateTime>? lastWatchedAt,
  }) {
    return RawValuesInsertable({
      if (animeId != null) 'anime_id': animeId,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (episodeTitle != null) 'episode_title': episodeTitle,
      if (episodeThumbnail != null) 'episode_thumbnail': episodeThumbnail,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (providerId != null) 'provider_id': providerId,
      if (audio != null) 'audio': audio,
      if (server != null) 'server': server,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
    });
  }

  WatchHistoryCompanion copyWith({
    Value<int>? animeId,
    Value<int>? episodeNumber,
    Value<String?>? episodeTitle,
    Value<String?>? episodeThumbnail,
    Value<int>? positionMs,
    Value<int>? durationMs,
    Value<double>? progressPercent,
    Value<bool>? isCompleted,
    Value<String?>? providerId,
    Value<String>? audio,
    Value<String?>? server,
    Value<DateTime>? lastWatchedAt,
  }) {
    return WatchHistoryCompanion(
      animeId: animeId ?? this.animeId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      episodeThumbnail: episodeThumbnail ?? this.episodeThumbnail,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      progressPercent: progressPercent ?? this.progressPercent,
      isCompleted: isCompleted ?? this.isCompleted,
      providerId: providerId ?? this.providerId,
      audio: audio ?? this.audio,
      server: server ?? this.server,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (animeId.present) {
      map['anime_id'] = Variable<int>(animeId.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (episodeTitle.present) {
      map['episode_title'] = Variable<String>(episodeTitle.value);
    }
    if (episodeThumbnail.present) {
      map['episode_thumbnail'] = Variable<String>(episodeThumbnail.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<double>(progressPercent.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (audio.present) {
      map['audio'] = Variable<String>(audio.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchHistoryCompanion(')
          ..write('animeId: $animeId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('episodeThumbnail: $episodeThumbnail, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('providerId: $providerId, ')
          ..write('audio: $audio, ')
          ..write('server: $server, ')
          ..write('lastWatchedAt: $lastWatchedAt')
          ..write(')'))
        .toString();
  }
}

class $EpisodeProgressTable extends EpisodeProgress
    with TableInfo<$EpisodeProgressTable, EpisodeProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodeProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<int> animeId = GeneratedColumn<int>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_records (id)',
    ),
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _progressPercentMeta = const VerificationMeta(
    'progressPercent',
  );
  @override
  late final GeneratedColumn<double> progressPercent = GeneratedColumn<double>(
    'progress_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    animeId,
    episodeNumber,
    positionMs,
    durationMs,
    progressPercent,
    isCompleted,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episode_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_animeIdMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('progress_percent')) {
      context.handle(
        _progressPercentMeta,
        progressPercent.isAcceptableOrUnknown(
          data['progress_percent']!,
          _progressPercentMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {animeId, episodeNumber};
  @override
  EpisodeProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeProgressData(
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anime_id'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      progressPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_percent'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EpisodeProgressTable createAlias(String alias) {
    return $EpisodeProgressTable(attachedDatabase, alias);
  }
}

class EpisodeProgressData extends DataClass
    implements Insertable<EpisodeProgressData> {
  final int animeId;
  final int episodeNumber;
  final int positionMs;
  final int durationMs;
  final double progressPercent;
  final bool isCompleted;
  final DateTime updatedAt;
  const EpisodeProgressData({
    required this.animeId,
    required this.episodeNumber,
    required this.positionMs,
    required this.durationMs,
    required this.progressPercent,
    required this.isCompleted,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anime_id'] = Variable<int>(animeId);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['progress_percent'] = Variable<double>(progressPercent);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EpisodeProgressCompanion toCompanion(bool nullToAbsent) {
    return EpisodeProgressCompanion(
      animeId: Value(animeId),
      episodeNumber: Value(episodeNumber),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      progressPercent: Value(progressPercent),
      isCompleted: Value(isCompleted),
      updatedAt: Value(updatedAt),
    );
  }

  factory EpisodeProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeProgressData(
      animeId: serializer.fromJson<int>(json['animeId']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      progressPercent: serializer.fromJson<double>(json['progressPercent']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'animeId': serializer.toJson<int>(animeId),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'progressPercent': serializer.toJson<double>(progressPercent),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EpisodeProgressData copyWith({
    int? animeId,
    int? episodeNumber,
    int? positionMs,
    int? durationMs,
    double? progressPercent,
    bool? isCompleted,
    DateTime? updatedAt,
  }) => EpisodeProgressData(
    animeId: animeId ?? this.animeId,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    progressPercent: progressPercent ?? this.progressPercent,
    isCompleted: isCompleted ?? this.isCompleted,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EpisodeProgressData copyWithCompanion(EpisodeProgressCompanion data) {
    return EpisodeProgressData(
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      progressPercent: data.progressPercent.present
          ? data.progressPercent.value
          : this.progressPercent,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeProgressData(')
          ..write('animeId: $animeId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    animeId,
    episodeNumber,
    positionMs,
    durationMs,
    progressPercent,
    isCompleted,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeProgressData &&
          other.animeId == this.animeId &&
          other.episodeNumber == this.episodeNumber &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.progressPercent == this.progressPercent &&
          other.isCompleted == this.isCompleted &&
          other.updatedAt == this.updatedAt);
}

class EpisodeProgressCompanion extends UpdateCompanion<EpisodeProgressData> {
  final Value<int> animeId;
  final Value<int> episodeNumber;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<double> progressPercent;
  final Value<bool> isCompleted;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EpisodeProgressCompanion({
    this.animeId = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodeProgressCompanion.insert({
    required int animeId,
    required int episodeNumber,
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.progressPercent = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : animeId = Value(animeId),
       episodeNumber = Value(episodeNumber);
  static Insertable<EpisodeProgressData> custom({
    Expression<int>? animeId,
    Expression<int>? episodeNumber,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<double>? progressPercent,
    Expression<bool>? isCompleted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (animeId != null) 'anime_id': animeId,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (progressPercent != null) 'progress_percent': progressPercent,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodeProgressCompanion copyWith({
    Value<int>? animeId,
    Value<int>? episodeNumber,
    Value<int>? positionMs,
    Value<int>? durationMs,
    Value<double>? progressPercent,
    Value<bool>? isCompleted,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EpisodeProgressCompanion(
      animeId: animeId ?? this.animeId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      progressPercent: progressPercent ?? this.progressPercent,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (animeId.present) {
      map['anime_id'] = Variable<int>(animeId.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (progressPercent.present) {
      map['progress_percent'] = Variable<double>(progressPercent.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeProgressCompanion(')
          ..write('animeId: $animeId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('progressPercent: $progressPercent, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
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
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    isSystem,
    iconName,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final String? iconName;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Collection({
    required this.id,
    required this.name,
    this.description,
    required this.isSystem,
    this.iconName,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_system'] = Variable<bool>(isSystem);
    if (!nullToAbsent || iconName != null) {
      map['icon_name'] = Variable<String>(iconName);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isSystem: Value(isSystem),
      iconName: iconName == null && nullToAbsent
          ? const Value.absent()
          : Value(iconName),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      iconName: serializer.fromJson<String?>(json['iconName']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isSystem': serializer.toJson<bool>(isSystem),
      'iconName': serializer.toJson<String?>(iconName),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Collection copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? isSystem,
    Value<String?> iconName = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Collection(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    isSystem: isSystem ?? this.isSystem,
    iconName: iconName.present ? iconName.value : this.iconName,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    isSystem,
    iconName,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.isSystem == this.isSystem &&
          other.iconName == this.iconName &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isSystem;
  final Value<String?> iconName;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.iconName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.iconName = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Collection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isSystem,
    Expression<String>? iconName,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isSystem != null) 'is_system': isSystem,
      if (iconName != null) 'icon_name': iconName,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? isSystem,
    Value<String?>? iconName,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSystem: isSystem ?? this.isSystem,
      iconName: iconName ?? this.iconName,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isSystem: $isSystem, ')
          ..write('iconName: $iconName, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionEntriesTable extends CollectionEntries
    with TableInfo<$CollectionEntriesTable, CollectionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collections (id)',
    ),
  );
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<int> animeId = GeneratedColumn<int>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_records (id)',
    ),
  );
  static const VerificationMeta _userScoreMeta = const VerificationMeta(
    'userScore',
  );
  @override
  late final GeneratedColumn<double> userScore = GeneratedColumn<double>(
    'user_score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userNotesMeta = const VerificationMeta(
    'userNotes',
  );
  @override
  late final GeneratedColumn<String> userNotes = GeneratedColumn<String>(
    'user_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    collectionId,
    animeId,
    userScore,
    userNotes,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_animeIdMeta);
    }
    if (data.containsKey('user_score')) {
      context.handle(
        _userScoreMeta,
        userScore.isAcceptableOrUnknown(data['user_score']!, _userScoreMeta),
      );
    }
    if (data.containsKey('user_notes')) {
      context.handle(
        _userNotesMeta,
        userNotes.isAcceptableOrUnknown(data['user_notes']!, _userNotesMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, animeId};
  @override
  CollectionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionEntry(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anime_id'],
      )!,
      userScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}user_score'],
      ),
      userNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_notes'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $CollectionEntriesTable createAlias(String alias) {
    return $CollectionEntriesTable(attachedDatabase, alias);
  }
}

class CollectionEntry extends DataClass implements Insertable<CollectionEntry> {
  final String collectionId;
  final int animeId;
  final double? userScore;
  final String? userNotes;
  final DateTime addedAt;
  const CollectionEntry({
    required this.collectionId,
    required this.animeId,
    this.userScore,
    this.userNotes,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['anime_id'] = Variable<int>(animeId);
    if (!nullToAbsent || userScore != null) {
      map['user_score'] = Variable<double>(userScore);
    }
    if (!nullToAbsent || userNotes != null) {
      map['user_notes'] = Variable<String>(userNotes);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  CollectionEntriesCompanion toCompanion(bool nullToAbsent) {
    return CollectionEntriesCompanion(
      collectionId: Value(collectionId),
      animeId: Value(animeId),
      userScore: userScore == null && nullToAbsent
          ? const Value.absent()
          : Value(userScore),
      userNotes: userNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(userNotes),
      addedAt: Value(addedAt),
    );
  }

  factory CollectionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionEntry(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      animeId: serializer.fromJson<int>(json['animeId']),
      userScore: serializer.fromJson<double?>(json['userScore']),
      userNotes: serializer.fromJson<String?>(json['userNotes']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'animeId': serializer.toJson<int>(animeId),
      'userScore': serializer.toJson<double?>(userScore),
      'userNotes': serializer.toJson<String?>(userNotes),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  CollectionEntry copyWith({
    String? collectionId,
    int? animeId,
    Value<double?> userScore = const Value.absent(),
    Value<String?> userNotes = const Value.absent(),
    DateTime? addedAt,
  }) => CollectionEntry(
    collectionId: collectionId ?? this.collectionId,
    animeId: animeId ?? this.animeId,
    userScore: userScore.present ? userScore.value : this.userScore,
    userNotes: userNotes.present ? userNotes.value : this.userNotes,
    addedAt: addedAt ?? this.addedAt,
  );
  CollectionEntry copyWithCompanion(CollectionEntriesCompanion data) {
    return CollectionEntry(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      userScore: data.userScore.present ? data.userScore.value : this.userScore,
      userNotes: data.userNotes.present ? data.userNotes.value : this.userNotes,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionEntry(')
          ..write('collectionId: $collectionId, ')
          ..write('animeId: $animeId, ')
          ..write('userScore: $userScore, ')
          ..write('userNotes: $userNotes, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(collectionId, animeId, userScore, userNotes, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionEntry &&
          other.collectionId == this.collectionId &&
          other.animeId == this.animeId &&
          other.userScore == this.userScore &&
          other.userNotes == this.userNotes &&
          other.addedAt == this.addedAt);
}

class CollectionEntriesCompanion extends UpdateCompanion<CollectionEntry> {
  final Value<String> collectionId;
  final Value<int> animeId;
  final Value<double?> userScore;
  final Value<String?> userNotes;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const CollectionEntriesCompanion({
    this.collectionId = const Value.absent(),
    this.animeId = const Value.absent(),
    this.userScore = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionEntriesCompanion.insert({
    required String collectionId,
    required int animeId,
    this.userScore = const Value.absent(),
    this.userNotes = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       animeId = Value(animeId);
  static Insertable<CollectionEntry> custom({
    Expression<String>? collectionId,
    Expression<int>? animeId,
    Expression<double>? userScore,
    Expression<String>? userNotes,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (animeId != null) 'anime_id': animeId,
      if (userScore != null) 'user_score': userScore,
      if (userNotes != null) 'user_notes': userNotes,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionEntriesCompanion copyWith({
    Value<String>? collectionId,
    Value<int>? animeId,
    Value<double?>? userScore,
    Value<String?>? userNotes,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return CollectionEntriesCompanion(
      collectionId: collectionId ?? this.collectionId,
      animeId: animeId ?? this.animeId,
      userScore: userScore ?? this.userScore,
      userNotes: userNotes ?? this.userNotes,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (animeId.present) {
      map['anime_id'] = Variable<int>(animeId.value);
    }
    if (userScore.present) {
      map['user_score'] = Variable<double>(userScore.value);
    }
    if (userNotes.present) {
      map['user_notes'] = Variable<String>(userNotes.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionEntriesCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('animeId: $animeId, ')
          ..write('userScore: $userScore, ')
          ..write('userNotes: $userNotes, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnimePreferencesTable extends AnimePreferences
    with TableInfo<$AnimePreferencesTable, AnimePreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimePreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<int> animeId = GeneratedColumn<int>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES anime_records (id)',
    ),
  );
  static const VerificationMeta _preferredProviderMeta = const VerificationMeta(
    'preferredProvider',
  );
  @override
  late final GeneratedColumn<String> preferredProvider =
      GeneratedColumn<String>(
        'preferred_provider',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _preferredAudioMeta = const VerificationMeta(
    'preferredAudio',
  );
  @override
  late final GeneratedColumn<String> preferredAudio = GeneratedColumn<String>(
    'preferred_audio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredServerMeta = const VerificationMeta(
    'preferredServer',
  );
  @override
  late final GeneratedColumn<String> preferredServer = GeneratedColumn<String>(
    'preferred_server',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredSubtitleTrackMeta =
      const VerificationMeta('preferredSubtitleTrack');
  @override
  late final GeneratedColumn<String> preferredSubtitleTrack =
      GeneratedColumn<String>(
        'preferred_subtitle_track',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _customPlaybackSpeedMeta =
      const VerificationMeta('customPlaybackSpeed');
  @override
  late final GeneratedColumn<double> customPlaybackSpeed =
      GeneratedColumn<double>(
        'custom_playback_speed',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _preferredQualityMeta = const VerificationMeta(
    'preferredQuality',
  );
  @override
  late final GeneratedColumn<String> preferredQuality = GeneratedColumn<String>(
    'preferred_quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    animeId,
    preferredProvider,
    preferredAudio,
    preferredServer,
    preferredSubtitleTrack,
    customPlaybackSpeed,
    preferredQuality,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'anime_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnimePreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    }
    if (data.containsKey('preferred_provider')) {
      context.handle(
        _preferredProviderMeta,
        preferredProvider.isAcceptableOrUnknown(
          data['preferred_provider']!,
          _preferredProviderMeta,
        ),
      );
    }
    if (data.containsKey('preferred_audio')) {
      context.handle(
        _preferredAudioMeta,
        preferredAudio.isAcceptableOrUnknown(
          data['preferred_audio']!,
          _preferredAudioMeta,
        ),
      );
    }
    if (data.containsKey('preferred_server')) {
      context.handle(
        _preferredServerMeta,
        preferredServer.isAcceptableOrUnknown(
          data['preferred_server']!,
          _preferredServerMeta,
        ),
      );
    }
    if (data.containsKey('preferred_subtitle_track')) {
      context.handle(
        _preferredSubtitleTrackMeta,
        preferredSubtitleTrack.isAcceptableOrUnknown(
          data['preferred_subtitle_track']!,
          _preferredSubtitleTrackMeta,
        ),
      );
    }
    if (data.containsKey('custom_playback_speed')) {
      context.handle(
        _customPlaybackSpeedMeta,
        customPlaybackSpeed.isAcceptableOrUnknown(
          data['custom_playback_speed']!,
          _customPlaybackSpeedMeta,
        ),
      );
    }
    if (data.containsKey('preferred_quality')) {
      context.handle(
        _preferredQualityMeta,
        preferredQuality.isAcceptableOrUnknown(
          data['preferred_quality']!,
          _preferredQualityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {animeId};
  @override
  AnimePreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimePreference(
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anime_id'],
      )!,
      preferredProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_provider'],
      ),
      preferredAudio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_audio'],
      ),
      preferredServer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_server'],
      ),
      preferredSubtitleTrack: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_subtitle_track'],
      ),
      customPlaybackSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}custom_playback_speed'],
      ),
      preferredQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_quality'],
      ),
    );
  }

  @override
  $AnimePreferencesTable createAlias(String alias) {
    return $AnimePreferencesTable(attachedDatabase, alias);
  }
}

class AnimePreference extends DataClass implements Insertable<AnimePreference> {
  final int animeId;
  final String? preferredProvider;
  final String? preferredAudio;
  final String? preferredServer;
  final String? preferredSubtitleTrack;
  final double? customPlaybackSpeed;
  final String? preferredQuality;
  const AnimePreference({
    required this.animeId,
    this.preferredProvider,
    this.preferredAudio,
    this.preferredServer,
    this.preferredSubtitleTrack,
    this.customPlaybackSpeed,
    this.preferredQuality,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anime_id'] = Variable<int>(animeId);
    if (!nullToAbsent || preferredProvider != null) {
      map['preferred_provider'] = Variable<String>(preferredProvider);
    }
    if (!nullToAbsent || preferredAudio != null) {
      map['preferred_audio'] = Variable<String>(preferredAudio);
    }
    if (!nullToAbsent || preferredServer != null) {
      map['preferred_server'] = Variable<String>(preferredServer);
    }
    if (!nullToAbsent || preferredSubtitleTrack != null) {
      map['preferred_subtitle_track'] = Variable<String>(
        preferredSubtitleTrack,
      );
    }
    if (!nullToAbsent || customPlaybackSpeed != null) {
      map['custom_playback_speed'] = Variable<double>(customPlaybackSpeed);
    }
    if (!nullToAbsent || preferredQuality != null) {
      map['preferred_quality'] = Variable<String>(preferredQuality);
    }
    return map;
  }

  AnimePreferencesCompanion toCompanion(bool nullToAbsent) {
    return AnimePreferencesCompanion(
      animeId: Value(animeId),
      preferredProvider: preferredProvider == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredProvider),
      preferredAudio: preferredAudio == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredAudio),
      preferredServer: preferredServer == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredServer),
      preferredSubtitleTrack: preferredSubtitleTrack == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredSubtitleTrack),
      customPlaybackSpeed: customPlaybackSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(customPlaybackSpeed),
      preferredQuality: preferredQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredQuality),
    );
  }

  factory AnimePreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimePreference(
      animeId: serializer.fromJson<int>(json['animeId']),
      preferredProvider: serializer.fromJson<String?>(
        json['preferredProvider'],
      ),
      preferredAudio: serializer.fromJson<String?>(json['preferredAudio']),
      preferredServer: serializer.fromJson<String?>(json['preferredServer']),
      preferredSubtitleTrack: serializer.fromJson<String?>(
        json['preferredSubtitleTrack'],
      ),
      customPlaybackSpeed: serializer.fromJson<double?>(
        json['customPlaybackSpeed'],
      ),
      preferredQuality: serializer.fromJson<String?>(json['preferredQuality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'animeId': serializer.toJson<int>(animeId),
      'preferredProvider': serializer.toJson<String?>(preferredProvider),
      'preferredAudio': serializer.toJson<String?>(preferredAudio),
      'preferredServer': serializer.toJson<String?>(preferredServer),
      'preferredSubtitleTrack': serializer.toJson<String?>(
        preferredSubtitleTrack,
      ),
      'customPlaybackSpeed': serializer.toJson<double?>(customPlaybackSpeed),
      'preferredQuality': serializer.toJson<String?>(preferredQuality),
    };
  }

  AnimePreference copyWith({
    int? animeId,
    Value<String?> preferredProvider = const Value.absent(),
    Value<String?> preferredAudio = const Value.absent(),
    Value<String?> preferredServer = const Value.absent(),
    Value<String?> preferredSubtitleTrack = const Value.absent(),
    Value<double?> customPlaybackSpeed = const Value.absent(),
    Value<String?> preferredQuality = const Value.absent(),
  }) => AnimePreference(
    animeId: animeId ?? this.animeId,
    preferredProvider: preferredProvider.present
        ? preferredProvider.value
        : this.preferredProvider,
    preferredAudio: preferredAudio.present
        ? preferredAudio.value
        : this.preferredAudio,
    preferredServer: preferredServer.present
        ? preferredServer.value
        : this.preferredServer,
    preferredSubtitleTrack: preferredSubtitleTrack.present
        ? preferredSubtitleTrack.value
        : this.preferredSubtitleTrack,
    customPlaybackSpeed: customPlaybackSpeed.present
        ? customPlaybackSpeed.value
        : this.customPlaybackSpeed,
    preferredQuality: preferredQuality.present
        ? preferredQuality.value
        : this.preferredQuality,
  );
  AnimePreference copyWithCompanion(AnimePreferencesCompanion data) {
    return AnimePreference(
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      preferredProvider: data.preferredProvider.present
          ? data.preferredProvider.value
          : this.preferredProvider,
      preferredAudio: data.preferredAudio.present
          ? data.preferredAudio.value
          : this.preferredAudio,
      preferredServer: data.preferredServer.present
          ? data.preferredServer.value
          : this.preferredServer,
      preferredSubtitleTrack: data.preferredSubtitleTrack.present
          ? data.preferredSubtitleTrack.value
          : this.preferredSubtitleTrack,
      customPlaybackSpeed: data.customPlaybackSpeed.present
          ? data.customPlaybackSpeed.value
          : this.customPlaybackSpeed,
      preferredQuality: data.preferredQuality.present
          ? data.preferredQuality.value
          : this.preferredQuality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimePreference(')
          ..write('animeId: $animeId, ')
          ..write('preferredProvider: $preferredProvider, ')
          ..write('preferredAudio: $preferredAudio, ')
          ..write('preferredServer: $preferredServer, ')
          ..write('preferredSubtitleTrack: $preferredSubtitleTrack, ')
          ..write('customPlaybackSpeed: $customPlaybackSpeed, ')
          ..write('preferredQuality: $preferredQuality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    animeId,
    preferredProvider,
    preferredAudio,
    preferredServer,
    preferredSubtitleTrack,
    customPlaybackSpeed,
    preferredQuality,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimePreference &&
          other.animeId == this.animeId &&
          other.preferredProvider == this.preferredProvider &&
          other.preferredAudio == this.preferredAudio &&
          other.preferredServer == this.preferredServer &&
          other.preferredSubtitleTrack == this.preferredSubtitleTrack &&
          other.customPlaybackSpeed == this.customPlaybackSpeed &&
          other.preferredQuality == this.preferredQuality);
}

class AnimePreferencesCompanion extends UpdateCompanion<AnimePreference> {
  final Value<int> animeId;
  final Value<String?> preferredProvider;
  final Value<String?> preferredAudio;
  final Value<String?> preferredServer;
  final Value<String?> preferredSubtitleTrack;
  final Value<double?> customPlaybackSpeed;
  final Value<String?> preferredQuality;
  const AnimePreferencesCompanion({
    this.animeId = const Value.absent(),
    this.preferredProvider = const Value.absent(),
    this.preferredAudio = const Value.absent(),
    this.preferredServer = const Value.absent(),
    this.preferredSubtitleTrack = const Value.absent(),
    this.customPlaybackSpeed = const Value.absent(),
    this.preferredQuality = const Value.absent(),
  });
  AnimePreferencesCompanion.insert({
    this.animeId = const Value.absent(),
    this.preferredProvider = const Value.absent(),
    this.preferredAudio = const Value.absent(),
    this.preferredServer = const Value.absent(),
    this.preferredSubtitleTrack = const Value.absent(),
    this.customPlaybackSpeed = const Value.absent(),
    this.preferredQuality = const Value.absent(),
  });
  static Insertable<AnimePreference> custom({
    Expression<int>? animeId,
    Expression<String>? preferredProvider,
    Expression<String>? preferredAudio,
    Expression<String>? preferredServer,
    Expression<String>? preferredSubtitleTrack,
    Expression<double>? customPlaybackSpeed,
    Expression<String>? preferredQuality,
  }) {
    return RawValuesInsertable({
      if (animeId != null) 'anime_id': animeId,
      if (preferredProvider != null) 'preferred_provider': preferredProvider,
      if (preferredAudio != null) 'preferred_audio': preferredAudio,
      if (preferredServer != null) 'preferred_server': preferredServer,
      if (preferredSubtitleTrack != null)
        'preferred_subtitle_track': preferredSubtitleTrack,
      if (customPlaybackSpeed != null)
        'custom_playback_speed': customPlaybackSpeed,
      if (preferredQuality != null) 'preferred_quality': preferredQuality,
    });
  }

  AnimePreferencesCompanion copyWith({
    Value<int>? animeId,
    Value<String?>? preferredProvider,
    Value<String?>? preferredAudio,
    Value<String?>? preferredServer,
    Value<String?>? preferredSubtitleTrack,
    Value<double?>? customPlaybackSpeed,
    Value<String?>? preferredQuality,
  }) {
    return AnimePreferencesCompanion(
      animeId: animeId ?? this.animeId,
      preferredProvider: preferredProvider ?? this.preferredProvider,
      preferredAudio: preferredAudio ?? this.preferredAudio,
      preferredServer: preferredServer ?? this.preferredServer,
      preferredSubtitleTrack:
          preferredSubtitleTrack ?? this.preferredSubtitleTrack,
      customPlaybackSpeed: customPlaybackSpeed ?? this.customPlaybackSpeed,
      preferredQuality: preferredQuality ?? this.preferredQuality,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (animeId.present) {
      map['anime_id'] = Variable<int>(animeId.value);
    }
    if (preferredProvider.present) {
      map['preferred_provider'] = Variable<String>(preferredProvider.value);
    }
    if (preferredAudio.present) {
      map['preferred_audio'] = Variable<String>(preferredAudio.value);
    }
    if (preferredServer.present) {
      map['preferred_server'] = Variable<String>(preferredServer.value);
    }
    if (preferredSubtitleTrack.present) {
      map['preferred_subtitle_track'] = Variable<String>(
        preferredSubtitleTrack.value,
      );
    }
    if (customPlaybackSpeed.present) {
      map['custom_playback_speed'] = Variable<double>(
        customPlaybackSpeed.value,
      );
    }
    if (preferredQuality.present) {
      map['preferred_quality'] = Variable<String>(preferredQuality.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimePreferencesCompanion(')
          ..write('animeId: $animeId, ')
          ..write('preferredProvider: $preferredProvider, ')
          ..write('preferredAudio: $preferredAudio, ')
          ..write('preferredServer: $preferredServer, ')
          ..write('preferredSubtitleTrack: $preferredSubtitleTrack, ')
          ..write('customPlaybackSpeed: $customPlaybackSpeed, ')
          ..write('preferredQuality: $preferredQuality')
          ..write(')'))
        .toString();
  }
}

class $EpisodeSubscriptionsTable extends EpisodeSubscriptions
    with TableInfo<$EpisodeSubscriptionsTable, EpisodeSubscription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodeSubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _animeIdMeta = const VerificationMeta(
    'animeId',
  );
  @override
  late final GeneratedColumn<int> animeId = GeneratedColumn<int>(
    'anime_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _animeTitleMeta = const VerificationMeta(
    'animeTitle',
  );
  @override
  late final GeneratedColumn<String> animeTitle = GeneratedColumn<String>(
    'anime_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextEpisodeNumberMeta = const VerificationMeta(
    'nextEpisodeNumber',
  );
  @override
  late final GeneratedColumn<int> nextEpisodeNumber = GeneratedColumn<int>(
    'next_episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextAiringAtMeta = const VerificationMeta(
    'nextAiringAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAiringAt = GeneratedColumn<DateTime>(
    'next_airing_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNotifiedEpisodeMeta =
      const VerificationMeta('lastNotifiedEpisode');
  @override
  late final GeneratedColumn<int> lastNotifiedEpisode = GeneratedColumn<int>(
    'last_notified_episode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSubscribedMeta = const VerificationMeta(
    'isSubscribed',
  );
  @override
  late final GeneratedColumn<bool> isSubscribed = GeneratedColumn<bool>(
    'is_subscribed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_subscribed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastCheckedAtMeta = const VerificationMeta(
    'lastCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCheckedAt =
      GeneratedColumn<DateTime>(
        'last_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    animeId,
    animeTitle,
    coverUrl,
    nextEpisodeNumber,
    nextAiringAt,
    lastNotifiedEpisode,
    isSubscribed,
    lastCheckedAt,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episode_subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeSubscription> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anime_id')) {
      context.handle(
        _animeIdMeta,
        animeId.isAcceptableOrUnknown(data['anime_id']!, _animeIdMeta),
      );
    }
    if (data.containsKey('anime_title')) {
      context.handle(
        _animeTitleMeta,
        animeTitle.isAcceptableOrUnknown(data['anime_title']!, _animeTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_animeTitleMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('next_episode_number')) {
      context.handle(
        _nextEpisodeNumberMeta,
        nextEpisodeNumber.isAcceptableOrUnknown(
          data['next_episode_number']!,
          _nextEpisodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextEpisodeNumberMeta);
    }
    if (data.containsKey('next_airing_at')) {
      context.handle(
        _nextAiringAtMeta,
        nextAiringAt.isAcceptableOrUnknown(
          data['next_airing_at']!,
          _nextAiringAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAiringAtMeta);
    }
    if (data.containsKey('last_notified_episode')) {
      context.handle(
        _lastNotifiedEpisodeMeta,
        lastNotifiedEpisode.isAcceptableOrUnknown(
          data['last_notified_episode']!,
          _lastNotifiedEpisodeMeta,
        ),
      );
    }
    if (data.containsKey('is_subscribed')) {
      context.handle(
        _isSubscribedMeta,
        isSubscribed.isAcceptableOrUnknown(
          data['is_subscribed']!,
          _isSubscribedMeta,
        ),
      );
    }
    if (data.containsKey('last_checked_at')) {
      context.handle(
        _lastCheckedAtMeta,
        lastCheckedAt.isAcceptableOrUnknown(
          data['last_checked_at']!,
          _lastCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {animeId};
  @override
  EpisodeSubscription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeSubscription(
      animeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anime_id'],
      )!,
      animeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_title'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      nextEpisodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_episode_number'],
      )!,
      nextAiringAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_airing_at'],
      )!,
      lastNotifiedEpisode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_notified_episode'],
      )!,
      isSubscribed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_subscribed'],
      )!,
      lastCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_checked_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $EpisodeSubscriptionsTable createAlias(String alias) {
    return $EpisodeSubscriptionsTable(attachedDatabase, alias);
  }
}

class EpisodeSubscription extends DataClass
    implements Insertable<EpisodeSubscription> {
  /// AniList Media ID
  final int animeId;

  /// Preferred title for notification headers
  final String animeTitle;

  /// Artwork URL for notification icons
  final String? coverUrl;

  /// The next episode number scheduled to air
  final int nextEpisodeNumber;

  /// The broadcast timestamp from AniList (Japan TV broadcast)
  final DateTime nextAiringAt;

  /// The last episode number that was verified and notified
  final int lastNotifiedEpisode;

  /// Whether the user actively wants notifications for this anime
  final bool isSubscribed;

  /// The last time provider availability was checked
  final DateTime? lastCheckedAt;

  /// Number of retry checks performed since airingAt
  final int retryCount;
  const EpisodeSubscription({
    required this.animeId,
    required this.animeTitle,
    this.coverUrl,
    required this.nextEpisodeNumber,
    required this.nextAiringAt,
    required this.lastNotifiedEpisode,
    required this.isSubscribed,
    this.lastCheckedAt,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anime_id'] = Variable<int>(animeId);
    map['anime_title'] = Variable<String>(animeTitle);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    map['next_episode_number'] = Variable<int>(nextEpisodeNumber);
    map['next_airing_at'] = Variable<DateTime>(nextAiringAt);
    map['last_notified_episode'] = Variable<int>(lastNotifiedEpisode);
    map['is_subscribed'] = Variable<bool>(isSubscribed);
    if (!nullToAbsent || lastCheckedAt != null) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  EpisodeSubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return EpisodeSubscriptionsCompanion(
      animeId: Value(animeId),
      animeTitle: Value(animeTitle),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      nextEpisodeNumber: Value(nextEpisodeNumber),
      nextAiringAt: Value(nextAiringAt),
      lastNotifiedEpisode: Value(lastNotifiedEpisode),
      isSubscribed: Value(isSubscribed),
      lastCheckedAt: lastCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCheckedAt),
      retryCount: Value(retryCount),
    );
  }

  factory EpisodeSubscription.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeSubscription(
      animeId: serializer.fromJson<int>(json['animeId']),
      animeTitle: serializer.fromJson<String>(json['animeTitle']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      nextEpisodeNumber: serializer.fromJson<int>(json['nextEpisodeNumber']),
      nextAiringAt: serializer.fromJson<DateTime>(json['nextAiringAt']),
      lastNotifiedEpisode: serializer.fromJson<int>(
        json['lastNotifiedEpisode'],
      ),
      isSubscribed: serializer.fromJson<bool>(json['isSubscribed']),
      lastCheckedAt: serializer.fromJson<DateTime?>(json['lastCheckedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'animeId': serializer.toJson<int>(animeId),
      'animeTitle': serializer.toJson<String>(animeTitle),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'nextEpisodeNumber': serializer.toJson<int>(nextEpisodeNumber),
      'nextAiringAt': serializer.toJson<DateTime>(nextAiringAt),
      'lastNotifiedEpisode': serializer.toJson<int>(lastNotifiedEpisode),
      'isSubscribed': serializer.toJson<bool>(isSubscribed),
      'lastCheckedAt': serializer.toJson<DateTime?>(lastCheckedAt),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  EpisodeSubscription copyWith({
    int? animeId,
    String? animeTitle,
    Value<String?> coverUrl = const Value.absent(),
    int? nextEpisodeNumber,
    DateTime? nextAiringAt,
    int? lastNotifiedEpisode,
    bool? isSubscribed,
    Value<DateTime?> lastCheckedAt = const Value.absent(),
    int? retryCount,
  }) => EpisodeSubscription(
    animeId: animeId ?? this.animeId,
    animeTitle: animeTitle ?? this.animeTitle,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    nextEpisodeNumber: nextEpisodeNumber ?? this.nextEpisodeNumber,
    nextAiringAt: nextAiringAt ?? this.nextAiringAt,
    lastNotifiedEpisode: lastNotifiedEpisode ?? this.lastNotifiedEpisode,
    isSubscribed: isSubscribed ?? this.isSubscribed,
    lastCheckedAt: lastCheckedAt.present
        ? lastCheckedAt.value
        : this.lastCheckedAt,
    retryCount: retryCount ?? this.retryCount,
  );
  EpisodeSubscription copyWithCompanion(EpisodeSubscriptionsCompanion data) {
    return EpisodeSubscription(
      animeId: data.animeId.present ? data.animeId.value : this.animeId,
      animeTitle: data.animeTitle.present
          ? data.animeTitle.value
          : this.animeTitle,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      nextEpisodeNumber: data.nextEpisodeNumber.present
          ? data.nextEpisodeNumber.value
          : this.nextEpisodeNumber,
      nextAiringAt: data.nextAiringAt.present
          ? data.nextAiringAt.value
          : this.nextAiringAt,
      lastNotifiedEpisode: data.lastNotifiedEpisode.present
          ? data.lastNotifiedEpisode.value
          : this.lastNotifiedEpisode,
      isSubscribed: data.isSubscribed.present
          ? data.isSubscribed.value
          : this.isSubscribed,
      lastCheckedAt: data.lastCheckedAt.present
          ? data.lastCheckedAt.value
          : this.lastCheckedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeSubscription(')
          ..write('animeId: $animeId, ')
          ..write('animeTitle: $animeTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('nextEpisodeNumber: $nextEpisodeNumber, ')
          ..write('nextAiringAt: $nextAiringAt, ')
          ..write('lastNotifiedEpisode: $lastNotifiedEpisode, ')
          ..write('isSubscribed: $isSubscribed, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    animeId,
    animeTitle,
    coverUrl,
    nextEpisodeNumber,
    nextAiringAt,
    lastNotifiedEpisode,
    isSubscribed,
    lastCheckedAt,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeSubscription &&
          other.animeId == this.animeId &&
          other.animeTitle == this.animeTitle &&
          other.coverUrl == this.coverUrl &&
          other.nextEpisodeNumber == this.nextEpisodeNumber &&
          other.nextAiringAt == this.nextAiringAt &&
          other.lastNotifiedEpisode == this.lastNotifiedEpisode &&
          other.isSubscribed == this.isSubscribed &&
          other.lastCheckedAt == this.lastCheckedAt &&
          other.retryCount == this.retryCount);
}

class EpisodeSubscriptionsCompanion
    extends UpdateCompanion<EpisodeSubscription> {
  final Value<int> animeId;
  final Value<String> animeTitle;
  final Value<String?> coverUrl;
  final Value<int> nextEpisodeNumber;
  final Value<DateTime> nextAiringAt;
  final Value<int> lastNotifiedEpisode;
  final Value<bool> isSubscribed;
  final Value<DateTime?> lastCheckedAt;
  final Value<int> retryCount;
  const EpisodeSubscriptionsCompanion({
    this.animeId = const Value.absent(),
    this.animeTitle = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.nextEpisodeNumber = const Value.absent(),
    this.nextAiringAt = const Value.absent(),
    this.lastNotifiedEpisode = const Value.absent(),
    this.isSubscribed = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  EpisodeSubscriptionsCompanion.insert({
    this.animeId = const Value.absent(),
    required String animeTitle,
    this.coverUrl = const Value.absent(),
    required int nextEpisodeNumber,
    required DateTime nextAiringAt,
    this.lastNotifiedEpisode = const Value.absent(),
    this.isSubscribed = const Value.absent(),
    this.lastCheckedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
  }) : animeTitle = Value(animeTitle),
       nextEpisodeNumber = Value(nextEpisodeNumber),
       nextAiringAt = Value(nextAiringAt);
  static Insertable<EpisodeSubscription> custom({
    Expression<int>? animeId,
    Expression<String>? animeTitle,
    Expression<String>? coverUrl,
    Expression<int>? nextEpisodeNumber,
    Expression<DateTime>? nextAiringAt,
    Expression<int>? lastNotifiedEpisode,
    Expression<bool>? isSubscribed,
    Expression<DateTime>? lastCheckedAt,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (animeId != null) 'anime_id': animeId,
      if (animeTitle != null) 'anime_title': animeTitle,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (nextEpisodeNumber != null) 'next_episode_number': nextEpisodeNumber,
      if (nextAiringAt != null) 'next_airing_at': nextAiringAt,
      if (lastNotifiedEpisode != null)
        'last_notified_episode': lastNotifiedEpisode,
      if (isSubscribed != null) 'is_subscribed': isSubscribed,
      if (lastCheckedAt != null) 'last_checked_at': lastCheckedAt,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  EpisodeSubscriptionsCompanion copyWith({
    Value<int>? animeId,
    Value<String>? animeTitle,
    Value<String?>? coverUrl,
    Value<int>? nextEpisodeNumber,
    Value<DateTime>? nextAiringAt,
    Value<int>? lastNotifiedEpisode,
    Value<bool>? isSubscribed,
    Value<DateTime?>? lastCheckedAt,
    Value<int>? retryCount,
  }) {
    return EpisodeSubscriptionsCompanion(
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      coverUrl: coverUrl ?? this.coverUrl,
      nextEpisodeNumber: nextEpisodeNumber ?? this.nextEpisodeNumber,
      nextAiringAt: nextAiringAt ?? this.nextAiringAt,
      lastNotifiedEpisode: lastNotifiedEpisode ?? this.lastNotifiedEpisode,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (animeId.present) {
      map['anime_id'] = Variable<int>(animeId.value);
    }
    if (animeTitle.present) {
      map['anime_title'] = Variable<String>(animeTitle.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (nextEpisodeNumber.present) {
      map['next_episode_number'] = Variable<int>(nextEpisodeNumber.value);
    }
    if (nextAiringAt.present) {
      map['next_airing_at'] = Variable<DateTime>(nextAiringAt.value);
    }
    if (lastNotifiedEpisode.present) {
      map['last_notified_episode'] = Variable<int>(lastNotifiedEpisode.value);
    }
    if (isSubscribed.present) {
      map['is_subscribed'] = Variable<bool>(isSubscribed.value);
    }
    if (lastCheckedAt.present) {
      map['last_checked_at'] = Variable<DateTime>(lastCheckedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeSubscriptionsCompanion(')
          ..write('animeId: $animeId, ')
          ..write('animeTitle: $animeTitle, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('nextEpisodeNumber: $nextEpisodeNumber, ')
          ..write('nextAiringAt: $nextAiringAt, ')
          ..write('lastNotifiedEpisode: $lastNotifiedEpisode, ')
          ..write('isSubscribed: $isSubscribed, ')
          ..write('lastCheckedAt: $lastCheckedAt, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

class $InstalledExtensionsTable extends InstalledExtensions
    with TableInfo<$InstalledExtensionsTable, InstalledExtension> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalledExtensionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionCodeMeta = const VerificationMeta(
    'versionCode',
  );
  @override
  late final GeneratedColumn<int> versionCode = GeneratedColumn<int>(
    'version_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Aniways Community'),
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _audioMeta = const VerificationMeta('audio');
  @override
  late final GeneratedColumn<String> audio = GeneratedColumn<String>(
    'audio',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('["sub"]'),
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _priorityIndexMeta = const VerificationMeta(
    'priorityIndex',
  );
  @override
  late final GeneratedColumn<int> priorityIndex = GeneratedColumn<int>(
    'priority_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _localScriptPathMeta = const VerificationMeta(
    'localScriptPath',
  );
  @override
  late final GeneratedColumn<String> localScriptPath = GeneratedColumn<String>(
    'local_script_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repoUrlMeta = const VerificationMeta(
    'repoUrl',
  );
  @override
  late final GeneratedColumn<String> repoUrl = GeneratedColumn<String>(
    'repo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    version,
    versionCode,
    author,
    iconUrl,
    description,
    audio,
    lang,
    baseUrl,
    isEnabled,
    priorityIndex,
    localScriptPath,
    repoUrl,
    installedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installed_extensions';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstalledExtension> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('version_code')) {
      context.handle(
        _versionCodeMeta,
        versionCode.isAcceptableOrUnknown(
          data['version_code']!,
          _versionCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionCodeMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('audio')) {
      context.handle(
        _audioMeta,
        audio.isAcceptableOrUnknown(data['audio']!, _audioMeta),
      );
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('priority_index')) {
      context.handle(
        _priorityIndexMeta,
        priorityIndex.isAcceptableOrUnknown(
          data['priority_index']!,
          _priorityIndexMeta,
        ),
      );
    }
    if (data.containsKey('local_script_path')) {
      context.handle(
        _localScriptPathMeta,
        localScriptPath.isAcceptableOrUnknown(
          data['local_script_path']!,
          _localScriptPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localScriptPathMeta);
    }
    if (data.containsKey('repo_url')) {
      context.handle(
        _repoUrlMeta,
        repoUrl.isAcceptableOrUnknown(data['repo_url']!, _repoUrlMeta),
      );
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstalledExtension map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstalledExtension(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      versionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_code'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      audio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      priorityIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority_index'],
      )!,
      localScriptPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_script_path'],
      )!,
      repoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repo_url'],
      ),
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InstalledExtensionsTable createAlias(String alias) {
    return $InstalledExtensionsTable(attachedDatabase, alias);
  }
}

class InstalledExtension extends DataClass
    implements Insertable<InstalledExtension> {
  /// Unique identifier of the extension (e.g. "gogoanime", "anikoto")
  final String id;

  /// User-friendly display name (e.g. "Gogoanime")
  final String name;

  /// Semantic version string (e.g. "1.0.2")
  final String version;

  /// Integer version code for easy update comparison
  final int versionCode;

  /// Author or maintainer of the extension
  final String author;

  /// Remote URL or local asset path to extension icon
  final String? iconUrl;

  /// Short summary of the provider
  final String? description;

  /// JSON array of supported audio streams, e.g. '["sub", "dub"]'
  final String audio;

  /// Primary language code (e.g. "en")
  final String lang;

  /// Base web URL of the target streaming site
  final String? baseUrl;

  /// Whether the user has toggled this provider active for playback
  final bool isEnabled;

  /// Order preference for multi-provider fallback (lower = higher priority)
  final int priorityIndex;

  /// Absolute local file path where the .js bundle is saved
  final String localScriptPath;

  /// Remote repository URL from which this extension was installed
  final String? repoUrl;

  /// Timestamp when first installed
  final DateTime installedAt;

  /// Timestamp when last updated
  final DateTime updatedAt;
  const InstalledExtension({
    required this.id,
    required this.name,
    required this.version,
    required this.versionCode,
    required this.author,
    this.iconUrl,
    this.description,
    required this.audio,
    required this.lang,
    this.baseUrl,
    required this.isEnabled,
    required this.priorityIndex,
    required this.localScriptPath,
    this.repoUrl,
    required this.installedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['version'] = Variable<String>(version);
    map['version_code'] = Variable<int>(versionCode);
    map['author'] = Variable<String>(author);
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['audio'] = Variable<String>(audio);
    map['lang'] = Variable<String>(lang);
    if (!nullToAbsent || baseUrl != null) {
      map['base_url'] = Variable<String>(baseUrl);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['priority_index'] = Variable<int>(priorityIndex);
    map['local_script_path'] = Variable<String>(localScriptPath);
    if (!nullToAbsent || repoUrl != null) {
      map['repo_url'] = Variable<String>(repoUrl);
    }
    map['installed_at'] = Variable<DateTime>(installedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InstalledExtensionsCompanion toCompanion(bool nullToAbsent) {
    return InstalledExtensionsCompanion(
      id: Value(id),
      name: Value(name),
      version: Value(version),
      versionCode: Value(versionCode),
      author: Value(author),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      audio: Value(audio),
      lang: Value(lang),
      baseUrl: baseUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUrl),
      isEnabled: Value(isEnabled),
      priorityIndex: Value(priorityIndex),
      localScriptPath: Value(localScriptPath),
      repoUrl: repoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(repoUrl),
      installedAt: Value(installedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InstalledExtension.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstalledExtension(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<String>(json['version']),
      versionCode: serializer.fromJson<int>(json['versionCode']),
      author: serializer.fromJson<String>(json['author']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
      description: serializer.fromJson<String?>(json['description']),
      audio: serializer.fromJson<String>(json['audio']),
      lang: serializer.fromJson<String>(json['lang']),
      baseUrl: serializer.fromJson<String?>(json['baseUrl']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      priorityIndex: serializer.fromJson<int>(json['priorityIndex']),
      localScriptPath: serializer.fromJson<String>(json['localScriptPath']),
      repoUrl: serializer.fromJson<String?>(json['repoUrl']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<String>(version),
      'versionCode': serializer.toJson<int>(versionCode),
      'author': serializer.toJson<String>(author),
      'iconUrl': serializer.toJson<String?>(iconUrl),
      'description': serializer.toJson<String?>(description),
      'audio': serializer.toJson<String>(audio),
      'lang': serializer.toJson<String>(lang),
      'baseUrl': serializer.toJson<String?>(baseUrl),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'priorityIndex': serializer.toJson<int>(priorityIndex),
      'localScriptPath': serializer.toJson<String>(localScriptPath),
      'repoUrl': serializer.toJson<String?>(repoUrl),
      'installedAt': serializer.toJson<DateTime>(installedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InstalledExtension copyWith({
    String? id,
    String? name,
    String? version,
    int? versionCode,
    String? author,
    Value<String?> iconUrl = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? audio,
    String? lang,
    Value<String?> baseUrl = const Value.absent(),
    bool? isEnabled,
    int? priorityIndex,
    String? localScriptPath,
    Value<String?> repoUrl = const Value.absent(),
    DateTime? installedAt,
    DateTime? updatedAt,
  }) => InstalledExtension(
    id: id ?? this.id,
    name: name ?? this.name,
    version: version ?? this.version,
    versionCode: versionCode ?? this.versionCode,
    author: author ?? this.author,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
    description: description.present ? description.value : this.description,
    audio: audio ?? this.audio,
    lang: lang ?? this.lang,
    baseUrl: baseUrl.present ? baseUrl.value : this.baseUrl,
    isEnabled: isEnabled ?? this.isEnabled,
    priorityIndex: priorityIndex ?? this.priorityIndex,
    localScriptPath: localScriptPath ?? this.localScriptPath,
    repoUrl: repoUrl.present ? repoUrl.value : this.repoUrl,
    installedAt: installedAt ?? this.installedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InstalledExtension copyWithCompanion(InstalledExtensionsCompanion data) {
    return InstalledExtension(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      versionCode: data.versionCode.present
          ? data.versionCode.value
          : this.versionCode,
      author: data.author.present ? data.author.value : this.author,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      description: data.description.present
          ? data.description.value
          : this.description,
      audio: data.audio.present ? data.audio.value : this.audio,
      lang: data.lang.present ? data.lang.value : this.lang,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      priorityIndex: data.priorityIndex.present
          ? data.priorityIndex.value
          : this.priorityIndex,
      localScriptPath: data.localScriptPath.present
          ? data.localScriptPath.value
          : this.localScriptPath,
      repoUrl: data.repoUrl.present ? data.repoUrl.value : this.repoUrl,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstalledExtension(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('versionCode: $versionCode, ')
          ..write('author: $author, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('description: $description, ')
          ..write('audio: $audio, ')
          ..write('lang: $lang, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('priorityIndex: $priorityIndex, ')
          ..write('localScriptPath: $localScriptPath, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    version,
    versionCode,
    author,
    iconUrl,
    description,
    audio,
    lang,
    baseUrl,
    isEnabled,
    priorityIndex,
    localScriptPath,
    repoUrl,
    installedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstalledExtension &&
          other.id == this.id &&
          other.name == this.name &&
          other.version == this.version &&
          other.versionCode == this.versionCode &&
          other.author == this.author &&
          other.iconUrl == this.iconUrl &&
          other.description == this.description &&
          other.audio == this.audio &&
          other.lang == this.lang &&
          other.baseUrl == this.baseUrl &&
          other.isEnabled == this.isEnabled &&
          other.priorityIndex == this.priorityIndex &&
          other.localScriptPath == this.localScriptPath &&
          other.repoUrl == this.repoUrl &&
          other.installedAt == this.installedAt &&
          other.updatedAt == this.updatedAt);
}

class InstalledExtensionsCompanion extends UpdateCompanion<InstalledExtension> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> version;
  final Value<int> versionCode;
  final Value<String> author;
  final Value<String?> iconUrl;
  final Value<String?> description;
  final Value<String> audio;
  final Value<String> lang;
  final Value<String?> baseUrl;
  final Value<bool> isEnabled;
  final Value<int> priorityIndex;
  final Value<String> localScriptPath;
  final Value<String?> repoUrl;
  final Value<DateTime> installedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InstalledExtensionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.versionCode = const Value.absent(),
    this.author = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.audio = const Value.absent(),
    this.lang = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.priorityIndex = const Value.absent(),
    this.localScriptPath = const Value.absent(),
    this.repoUrl = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstalledExtensionsCompanion.insert({
    required String id,
    required String name,
    required String version,
    required int versionCode,
    this.author = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.description = const Value.absent(),
    this.audio = const Value.absent(),
    this.lang = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.priorityIndex = const Value.absent(),
    required String localScriptPath,
    this.repoUrl = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       version = Value(version),
       versionCode = Value(versionCode),
       localScriptPath = Value(localScriptPath);
  static Insertable<InstalledExtension> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? version,
    Expression<int>? versionCode,
    Expression<String>? author,
    Expression<String>? iconUrl,
    Expression<String>? description,
    Expression<String>? audio,
    Expression<String>? lang,
    Expression<String>? baseUrl,
    Expression<bool>? isEnabled,
    Expression<int>? priorityIndex,
    Expression<String>? localScriptPath,
    Expression<String>? repoUrl,
    Expression<DateTime>? installedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (versionCode != null) 'version_code': versionCode,
      if (author != null) 'author': author,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (description != null) 'description': description,
      if (audio != null) 'audio': audio,
      if (lang != null) 'lang': lang,
      if (baseUrl != null) 'base_url': baseUrl,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (priorityIndex != null) 'priority_index': priorityIndex,
      if (localScriptPath != null) 'local_script_path': localScriptPath,
      if (repoUrl != null) 'repo_url': repoUrl,
      if (installedAt != null) 'installed_at': installedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstalledExtensionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? version,
    Value<int>? versionCode,
    Value<String>? author,
    Value<String?>? iconUrl,
    Value<String?>? description,
    Value<String>? audio,
    Value<String>? lang,
    Value<String?>? baseUrl,
    Value<bool>? isEnabled,
    Value<int>? priorityIndex,
    Value<String>? localScriptPath,
    Value<String?>? repoUrl,
    Value<DateTime>? installedAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InstalledExtensionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      versionCode: versionCode ?? this.versionCode,
      author: author ?? this.author,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      audio: audio ?? this.audio,
      lang: lang ?? this.lang,
      baseUrl: baseUrl ?? this.baseUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      localScriptPath: localScriptPath ?? this.localScriptPath,
      repoUrl: repoUrl ?? this.repoUrl,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (versionCode.present) {
      map['version_code'] = Variable<int>(versionCode.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (audio.present) {
      map['audio'] = Variable<String>(audio.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (priorityIndex.present) {
      map['priority_index'] = Variable<int>(priorityIndex.value);
    }
    if (localScriptPath.present) {
      map['local_script_path'] = Variable<String>(localScriptPath.value);
    }
    if (repoUrl.present) {
      map['repo_url'] = Variable<String>(repoUrl.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalledExtensionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('versionCode: $versionCode, ')
          ..write('author: $author, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('description: $description, ')
          ..write('audio: $audio, ')
          ..write('lang: $lang, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('priorityIndex: $priorityIndex, ')
          ..write('localScriptPath: $localScriptPath, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtensionRepositoriesTable extends ExtensionRepositories
    with TableInfo<$ExtensionRepositoriesTable, ExtensionRepository> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtensionRepositoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    url,
    isEnabled,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extension_repositories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtensionRepository> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtensionRepository map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtensionRepository(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
    );
  }

  @override
  $ExtensionRepositoriesTable createAlias(String alias) {
    return $ExtensionRepositoriesTable(attachedDatabase, alias);
  }
}

class ExtensionRepository extends DataClass
    implements Insertable<ExtensionRepository> {
  /// Unique repository ID (e.g. "aniways-official")
  final String id;

  /// Repository display name
  final String name;

  /// HTTPS URL pointing to the repository's index.json
  final String url;

  /// Whether this repository is active for update checks & browsing
  final bool isEnabled;

  /// When the repository catalog was last fetched
  final DateTime? lastSyncedAt;
  const ExtensionRepository({
    required this.id,
    required this.name,
    required this.url,
    required this.isEnabled,
    this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    return map;
  }

  ExtensionRepositoriesCompanion toCompanion(bool nullToAbsent) {
    return ExtensionRepositoriesCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      isEnabled: Value(isEnabled),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
    );
  }

  factory ExtensionRepository.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtensionRepository(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
    };
  }

  ExtensionRepository copyWith({
    String? id,
    String? name,
    String? url,
    bool? isEnabled,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
  }) => ExtensionRepository(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    isEnabled: isEnabled ?? this.isEnabled,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
  );
  ExtensionRepository copyWithCompanion(ExtensionRepositoriesCompanion data) {
    return ExtensionRepository(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionRepository(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, url, isEnabled, lastSyncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtensionRepository &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.isEnabled == this.isEnabled &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class ExtensionRepositoriesCompanion
    extends UpdateCompanion<ExtensionRepository> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> url;
  final Value<bool> isEnabled;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> rowid;
  const ExtensionRepositoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtensionRepositoriesCompanion.insert({
    required String id,
    required String name,
    required String url,
    this.isEnabled = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       url = Value(url);
  static Insertable<ExtensionRepository> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<bool>? isEnabled,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtensionRepositoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? url,
    Value<bool>? isEnabled,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? rowid,
  }) {
    return ExtensionRepositoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      isEnabled: isEnabled ?? this.isEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionRepositoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AnimeRecordsTable animeRecords = $AnimeRecordsTable(this);
  late final $WatchHistoryTable watchHistory = $WatchHistoryTable(this);
  late final $EpisodeProgressTable episodeProgress = $EpisodeProgressTable(
    this,
  );
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $CollectionEntriesTable collectionEntries =
      $CollectionEntriesTable(this);
  late final $AnimePreferencesTable animePreferences = $AnimePreferencesTable(
    this,
  );
  late final $EpisodeSubscriptionsTable episodeSubscriptions =
      $EpisodeSubscriptionsTable(this);
  late final $InstalledExtensionsTable installedExtensions =
      $InstalledExtensionsTable(this);
  late final $ExtensionRepositoriesTable extensionRepositories =
      $ExtensionRepositoriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    animeRecords,
    watchHistory,
    episodeProgress,
    collections,
    collectionEntries,
    animePreferences,
    episodeSubscriptions,
    installedExtensions,
    extensionRepositories,
  ];
}

typedef $$AnimeRecordsTableCreateCompanionBuilder =
    AnimeRecordsCompanion Function({
      Value<int> id,
      Value<int?> malId,
      required String title,
      Value<String?> romajiTitle,
      Value<String?> englishTitle,
      Value<String?> coverUrl,
      Value<String?> bannerUrl,
      Value<int?> coverColor,
      Value<String?> format,
      Value<String?> status,
      Value<int?> totalEpisodes,
      Value<int?> averageScore,
      Value<String> genres,
      Value<DateTime> updatedAt,
    });
typedef $$AnimeRecordsTableUpdateCompanionBuilder =
    AnimeRecordsCompanion Function({
      Value<int> id,
      Value<int?> malId,
      Value<String> title,
      Value<String?> romajiTitle,
      Value<String?> englishTitle,
      Value<String?> coverUrl,
      Value<String?> bannerUrl,
      Value<int?> coverColor,
      Value<String?> format,
      Value<String?> status,
      Value<int?> totalEpisodes,
      Value<int?> averageScore,
      Value<String> genres,
      Value<DateTime> updatedAt,
    });

final class $$AnimeRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $AnimeRecordsTable, AnimeRecord> {
  $$AnimeRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WatchHistoryTable, List<WatchHistoryData>>
  _watchHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.watchHistory,
    aliasName: 'anime_records__id__watch_history__anime_id',
  );

  $$WatchHistoryTableProcessedTableManager get watchHistoryRefs {
    final manager = $$WatchHistoryTableTableManager(
      $_db,
      $_db.watchHistory,
    ).filter((f) => f.animeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_watchHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpisodeProgressTable, List<EpisodeProgressData>>
  _episodeProgressRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.episodeProgress,
    aliasName: 'anime_records__id__episode_progress__anime_id',
  );

  $$EpisodeProgressTableProcessedTableManager get episodeProgressRefs {
    final manager = $$EpisodeProgressTableTableManager(
      $_db,
      $_db.episodeProgress,
    ).filter((f) => f.animeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _episodeProgressRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CollectionEntriesTable, List<CollectionEntry>>
  _collectionEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectionEntries,
        aliasName: 'anime_records__id__collection_entries__anime_id',
      );

  $$CollectionEntriesTableProcessedTableManager get collectionEntriesRefs {
    final manager = $$CollectionEntriesTableTableManager(
      $_db,
      $_db.collectionEntries,
    ).filter((f) => f.animeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnimePreferencesTable, List<AnimePreference>>
  _animePreferencesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.animePreferences,
    aliasName: 'anime_records__id__anime_preferences__anime_id',
  );

  $$AnimePreferencesTableProcessedTableManager get animePreferencesRefs {
    final manager = $$AnimePreferencesTableTableManager(
      $_db,
      $_db.animePreferences,
    ).filter((f) => f.animeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _animePreferencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AnimeRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AnimeRecordsTable> {
  $$AnimeRecordsTableFilterComposer({
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

  ColumnFilters<int> get malId => $composableBuilder(
    column: $table.malId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get romajiTitle => $composableBuilder(
    column: $table.romajiTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishTitle => $composableBuilder(
    column: $table.englishTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> watchHistoryRefs(
    Expression<bool> Function($$WatchHistoryTableFilterComposer f) f,
  ) {
    final $$WatchHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchHistoryTableFilterComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> episodeProgressRefs(
    Expression<bool> Function($$EpisodeProgressTableFilterComposer f) f,
  ) {
    final $$EpisodeProgressTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodeProgress,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodeProgressTableFilterComposer(
            $db: $db,
            $table: $db.episodeProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectionEntriesRefs(
    Expression<bool> Function($$CollectionEntriesTableFilterComposer f) f,
  ) {
    final $$CollectionEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionEntries,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEntriesTableFilterComposer(
            $db: $db,
            $table: $db.collectionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> animePreferencesRefs(
    Expression<bool> Function($$AnimePreferencesTableFilterComposer f) f,
  ) {
    final $$AnimePreferencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.animePreferences,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimePreferencesTableFilterComposer(
            $db: $db,
            $table: $db.animePreferences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnimeRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnimeRecordsTable> {
  $$AnimeRecordsTableOrderingComposer({
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

  ColumnOrderings<int> get malId => $composableBuilder(
    column: $table.malId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get romajiTitle => $composableBuilder(
    column: $table.romajiTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishTitle => $composableBuilder(
    column: $table.englishTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bannerUrl => $composableBuilder(
    column: $table.bannerUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnimeRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnimeRecordsTable> {
  $$AnimeRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get malId =>
      $composableBuilder(column: $table.malId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get romajiTitle => $composableBuilder(
    column: $table.romajiTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishTitle => $composableBuilder(
    column: $table.englishTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get bannerUrl =>
      $composableBuilder(column: $table.bannerUrl, builder: (column) => column);

  GeneratedColumn<int> get coverColor => $composableBuilder(
    column: $table.coverColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get averageScore => $composableBuilder(
    column: $table.averageScore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> watchHistoryRefs<T extends Object>(
    Expression<T> Function($$WatchHistoryTableAnnotationComposer a) f,
  ) {
    final $$WatchHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.watchHistory,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.watchHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> episodeProgressRefs<T extends Object>(
    Expression<T> Function($$EpisodeProgressTableAnnotationComposer a) f,
  ) {
    final $$EpisodeProgressTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodeProgress,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodeProgressTableAnnotationComposer(
            $db: $db,
            $table: $db.episodeProgress,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> collectionEntriesRefs<T extends Object>(
    Expression<T> Function($$CollectionEntriesTableAnnotationComposer a) f,
  ) {
    final $$CollectionEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectionEntries,
          getReferencedColumn: (t) => t.animeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectionEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectionEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> animePreferencesRefs<T extends Object>(
    Expression<T> Function($$AnimePreferencesTableAnnotationComposer a) f,
  ) {
    final $$AnimePreferencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.animePreferences,
      getReferencedColumn: (t) => t.animeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimePreferencesTableAnnotationComposer(
            $db: $db,
            $table: $db.animePreferences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnimeRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnimeRecordsTable,
          AnimeRecord,
          $$AnimeRecordsTableFilterComposer,
          $$AnimeRecordsTableOrderingComposer,
          $$AnimeRecordsTableAnnotationComposer,
          $$AnimeRecordsTableCreateCompanionBuilder,
          $$AnimeRecordsTableUpdateCompanionBuilder,
          (AnimeRecord, $$AnimeRecordsTableReferences),
          AnimeRecord,
          PrefetchHooks Function({
            bool watchHistoryRefs,
            bool episodeProgressRefs,
            bool collectionEntriesRefs,
            bool animePreferencesRefs,
          })
        > {
  $$AnimeRecordsTableTableManager(_$AppDatabase db, $AnimeRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimeRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnimeRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnimeRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> malId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> romajiTitle = const Value.absent(),
                Value<String?> englishTitle = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<int?> coverColor = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<int?> averageScore = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AnimeRecordsCompanion(
                id: id,
                malId: malId,
                title: title,
                romajiTitle: romajiTitle,
                englishTitle: englishTitle,
                coverUrl: coverUrl,
                bannerUrl: bannerUrl,
                coverColor: coverColor,
                format: format,
                status: status,
                totalEpisodes: totalEpisodes,
                averageScore: averageScore,
                genres: genres,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> malId = const Value.absent(),
                required String title,
                Value<String?> romajiTitle = const Value.absent(),
                Value<String?> englishTitle = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> bannerUrl = const Value.absent(),
                Value<int?> coverColor = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<int?> averageScore = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AnimeRecordsCompanion.insert(
                id: id,
                malId: malId,
                title: title,
                romajiTitle: romajiTitle,
                englishTitle: englishTitle,
                coverUrl: coverUrl,
                bannerUrl: bannerUrl,
                coverColor: coverColor,
                format: format,
                status: status,
                totalEpisodes: totalEpisodes,
                averageScore: averageScore,
                genres: genres,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnimeRecordsTable, AnimeRecord>(table),
                  $$AnimeRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                watchHistoryRefs = false,
                episodeProgressRefs = false,
                collectionEntriesRefs = false,
                animePreferencesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (watchHistoryRefs) db.watchHistory,
                    if (episodeProgressRefs) db.episodeProgress,
                    if (collectionEntriesRefs) db.collectionEntries,
                    if (animePreferencesRefs) db.animePreferences,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (watchHistoryRefs)
                        await $_getPrefetchedDataByColumns<
                          AnimeRecord,
                          $AnimeRecordsTable,
                          WatchHistoryData,
                          $WatchHistoryTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeRecordsTableReferences
                              ._watchHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).watchHistoryRefs,
                          currentColumn: 'id',
                          referencedColumn: 'anime_id',
                          typedResults: items,
                        ),
                      if (episodeProgressRefs)
                        await $_getPrefetchedDataByColumns<
                          AnimeRecord,
                          $AnimeRecordsTable,
                          EpisodeProgressData,
                          $EpisodeProgressTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeRecordsTableReferences
                              ._episodeProgressRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).episodeProgressRefs,
                          currentColumn: 'id',
                          referencedColumn: 'anime_id',
                          typedResults: items,
                        ),
                      if (collectionEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          AnimeRecord,
                          $AnimeRecordsTable,
                          CollectionEntry,
                          $CollectionEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeRecordsTableReferences
                              ._collectionEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'anime_id',
                          typedResults: items,
                        ),
                      if (animePreferencesRefs)
                        await $_getPrefetchedDataByColumns<
                          AnimeRecord,
                          $AnimeRecordsTable,
                          AnimePreference,
                          $AnimePreferencesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AnimeRecordsTableReferences
                              ._animePreferencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnimeRecordsTableReferences(
                                db,
                                table,
                                p0,
                              ).animePreferencesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'anime_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AnimeRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnimeRecordsTable,
      AnimeRecord,
      $$AnimeRecordsTableFilterComposer,
      $$AnimeRecordsTableOrderingComposer,
      $$AnimeRecordsTableAnnotationComposer,
      $$AnimeRecordsTableCreateCompanionBuilder,
      $$AnimeRecordsTableUpdateCompanionBuilder,
      (AnimeRecord, $$AnimeRecordsTableReferences),
      AnimeRecord,
      PrefetchHooks Function({
        bool watchHistoryRefs,
        bool episodeProgressRefs,
        bool collectionEntriesRefs,
        bool animePreferencesRefs,
      })
    >;
typedef $$WatchHistoryTableCreateCompanionBuilder =
    WatchHistoryCompanion Function({
      Value<int> animeId,
      required int episodeNumber,
      Value<String?> episodeTitle,
      Value<String?> episodeThumbnail,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<double> progressPercent,
      Value<bool> isCompleted,
      Value<String?> providerId,
      Value<String> audio,
      Value<String?> server,
      Value<DateTime> lastWatchedAt,
    });
typedef $$WatchHistoryTableUpdateCompanionBuilder =
    WatchHistoryCompanion Function({
      Value<int> animeId,
      Value<int> episodeNumber,
      Value<String?> episodeTitle,
      Value<String?> episodeThumbnail,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<double> progressPercent,
      Value<bool> isCompleted,
      Value<String?> providerId,
      Value<String> audio,
      Value<String?> server,
      Value<DateTime> lastWatchedAt,
    });

final class $$WatchHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $WatchHistoryTable, WatchHistoryData> {
  $$WatchHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AnimeRecordsTable _animeIdTable(_$AppDatabase db) =>
      db.animeRecords.createAlias('watch_history__anime_id__anime_records__id');

  $$AnimeRecordsTableProcessedTableManager get animeId {
    final $_column = $_itemColumn<int>('anime_id')!;

    final manager = $$AnimeRecordsTableTableManager(
      $_db,
      $_db.animeRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WatchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeThumbnail => $composableBuilder(
    column: $table.episodeThumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audio => $composableBuilder(
    column: $table.audio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeRecordsTableFilterComposer get animeId {
    final $$AnimeRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableFilterComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeThumbnail => $composableBuilder(
    column: $table.episodeThumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audio => $composableBuilder(
    column: $table.audio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeRecordsTableOrderingComposer get animeId {
    final $$AnimeRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchHistoryTable> {
  $$WatchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get episodeThumbnail => $composableBuilder(
    column: $table.episodeThumbnail,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audio =>
      $composableBuilder(column: $table.audio, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatchedAt => $composableBuilder(
    column: $table.lastWatchedAt,
    builder: (column) => column,
  );

  $$AnimeRecordsTableAnnotationComposer get animeId {
    final $$AnimeRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchHistoryTable,
          WatchHistoryData,
          $$WatchHistoryTableFilterComposer,
          $$WatchHistoryTableOrderingComposer,
          $$WatchHistoryTableAnnotationComposer,
          $$WatchHistoryTableCreateCompanionBuilder,
          $$WatchHistoryTableUpdateCompanionBuilder,
          (WatchHistoryData, $$WatchHistoryTableReferences),
          WatchHistoryData,
          PrefetchHooks Function({bool animeId})
        > {
  $$WatchHistoryTableTableManager(_$AppDatabase db, $WatchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> animeId = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<String?> episodeTitle = const Value.absent(),
                Value<String?> episodeThumbnail = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<String> audio = const Value.absent(),
                Value<String?> server = const Value.absent(),
                Value<DateTime> lastWatchedAt = const Value.absent(),
              }) => WatchHistoryCompanion(
                animeId: animeId,
                episodeNumber: episodeNumber,
                episodeTitle: episodeTitle,
                episodeThumbnail: episodeThumbnail,
                positionMs: positionMs,
                durationMs: durationMs,
                progressPercent: progressPercent,
                isCompleted: isCompleted,
                providerId: providerId,
                audio: audio,
                server: server,
                lastWatchedAt: lastWatchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> animeId = const Value.absent(),
                required int episodeNumber,
                Value<String?> episodeTitle = const Value.absent(),
                Value<String?> episodeThumbnail = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> providerId = const Value.absent(),
                Value<String> audio = const Value.absent(),
                Value<String?> server = const Value.absent(),
                Value<DateTime> lastWatchedAt = const Value.absent(),
              }) => WatchHistoryCompanion.insert(
                animeId: animeId,
                episodeNumber: episodeNumber,
                episodeTitle: episodeTitle,
                episodeThumbnail: episodeThumbnail,
                positionMs: positionMs,
                durationMs: durationMs,
                progressPercent: progressPercent,
                isCompleted: isCompleted,
                providerId: providerId,
                audio: audio,
                server: server,
                lastWatchedAt: lastWatchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WatchHistoryTable, WatchHistoryData>(table),
                  $$WatchHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeId = false}) {
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
                    if (animeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeId,
                        referencedTable: $$WatchHistoryTableReferences
                            ._animeIdTable(db),
                        referencedColumn: $$WatchHistoryTableReferences
                            ._animeIdTable(db)
                            .id,
                      ) as T;
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

typedef $$WatchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchHistoryTable,
      WatchHistoryData,
      $$WatchHistoryTableFilterComposer,
      $$WatchHistoryTableOrderingComposer,
      $$WatchHistoryTableAnnotationComposer,
      $$WatchHistoryTableCreateCompanionBuilder,
      $$WatchHistoryTableUpdateCompanionBuilder,
      (WatchHistoryData, $$WatchHistoryTableReferences),
      WatchHistoryData,
      PrefetchHooks Function({bool animeId})
    >;
typedef $$EpisodeProgressTableCreateCompanionBuilder =
    EpisodeProgressCompanion Function({
      required int animeId,
      required int episodeNumber,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<double> progressPercent,
      Value<bool> isCompleted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$EpisodeProgressTableUpdateCompanionBuilder =
    EpisodeProgressCompanion Function({
      Value<int> animeId,
      Value<int> episodeNumber,
      Value<int> positionMs,
      Value<int> durationMs,
      Value<double> progressPercent,
      Value<bool> isCompleted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$EpisodeProgressTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $EpisodeProgressTable,
          EpisodeProgressData
        > {
  $$EpisodeProgressTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeRecordsTable _animeIdTable(_$AppDatabase db) => db.animeRecords
      .createAlias('episode_progress__anime_id__anime_records__id');

  $$AnimeRecordsTableProcessedTableManager get animeId {
    final $_column = $_itemColumn<int>('anime_id')!;

    final manager = $$AnimeRecordsTableTableManager(
      $_db,
      $_db.animeRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpisodeProgressTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodeProgressTable> {
  $$EpisodeProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeRecordsTableFilterComposer get animeId {
    final $$AnimeRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableFilterComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodeProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodeProgressTable> {
  $$EpisodeProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeRecordsTableOrderingComposer get animeId {
    final $$AnimeRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodeProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodeProgressTable> {
  $$EpisodeProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressPercent => $composableBuilder(
    column: $table.progressPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AnimeRecordsTableAnnotationComposer get animeId {
    final $$AnimeRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodeProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodeProgressTable,
          EpisodeProgressData,
          $$EpisodeProgressTableFilterComposer,
          $$EpisodeProgressTableOrderingComposer,
          $$EpisodeProgressTableAnnotationComposer,
          $$EpisodeProgressTableCreateCompanionBuilder,
          $$EpisodeProgressTableUpdateCompanionBuilder,
          (EpisodeProgressData, $$EpisodeProgressTableReferences),
          EpisodeProgressData,
          PrefetchHooks Function({bool animeId})
        > {
  $$EpisodeProgressTableTableManager(
    _$AppDatabase db,
    $EpisodeProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodeProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodeProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodeProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> animeId = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodeProgressCompanion(
                animeId: animeId,
                episodeNumber: episodeNumber,
                positionMs: positionMs,
                durationMs: durationMs,
                progressPercent: progressPercent,
                isCompleted: isCompleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int animeId,
                required int episodeNumber,
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<double> progressPercent = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodeProgressCompanion.insert(
                animeId: animeId,
                episodeNumber: episodeNumber,
                positionMs: positionMs,
                durationMs: durationMs,
                progressPercent: progressPercent,
                isCompleted: isCompleted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpisodeProgressTable, EpisodeProgressData>(
                    table,
                  ),
                  $$EpisodeProgressTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeId = false}) {
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
                    if (animeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeId,
                        referencedTable: $$EpisodeProgressTableReferences
                            ._animeIdTable(db),
                        referencedColumn: $$EpisodeProgressTableReferences
                            ._animeIdTable(db)
                            .id,
                      ) as T;
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

typedef $$EpisodeProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodeProgressTable,
      EpisodeProgressData,
      $$EpisodeProgressTableFilterComposer,
      $$EpisodeProgressTableOrderingComposer,
      $$EpisodeProgressTableAnnotationComposer,
      $$EpisodeProgressTableCreateCompanionBuilder,
      $$EpisodeProgressTableUpdateCompanionBuilder,
      (EpisodeProgressData, $$EpisodeProgressTableReferences),
      EpisodeProgressData,
      PrefetchHooks Function({bool animeId})
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<bool> isSystem,
      Value<String?> iconName,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<bool> isSystem,
      Value<String?> iconName,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CollectionsTableReferences
    extends BaseReferences<_$AppDatabase, $CollectionsTable, Collection> {
  $$CollectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CollectionEntriesTable, List<CollectionEntry>>
  _collectionEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectionEntries,
        aliasName: 'collections__id__collection_entries__collection_id',
      );

  $$CollectionEntriesTableProcessedTableManager get collectionEntriesRefs {
    final manager = $$CollectionEntriesTableTableManager(
      $_db,
      $_db.collectionEntries,
    ).filter((f) => f.collectionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> collectionEntriesRefs(
    Expression<bool> Function($$CollectionEntriesTableFilterComposer f) f,
  ) {
    final $$CollectionEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionEntries,
      getReferencedColumn: (t) => t.collectionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionEntriesTableFilterComposer(
            $db: $db,
            $table: $db.collectionEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> collectionEntriesRefs<T extends Object>(
    Expression<T> Function($$CollectionEntriesTableAnnotationComposer a) f,
  ) {
    final $$CollectionEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectionEntries,
          getReferencedColumn: (t) => t.collectionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectionEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.collectionEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (Collection, $$CollectionsTableReferences),
          Collection,
          PrefetchHooks Function({bool collectionEntriesRefs})
        > {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<String?> iconName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                name: name,
                description: description,
                isSystem: isSystem,
                iconName: iconName,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<String?> iconName = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion.insert(
                id: id,
                name: name,
                description: description,
                isSystem: isSystem,
                iconName: iconName,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionsTable, Collection>(table),
                  $$CollectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (collectionEntriesRefs) db.collectionEntries,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (collectionEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      Collection,
                      $CollectionsTable,
                      CollectionEntry,
                      $CollectionEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionsTableReferences
                          ._collectionEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionsTableReferences(
                            db,
                            table,
                            p0,
                          ).collectionEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'collection_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (Collection, $$CollectionsTableReferences),
      Collection,
      PrefetchHooks Function({bool collectionEntriesRefs})
    >;
typedef $$CollectionEntriesTableCreateCompanionBuilder =
    CollectionEntriesCompanion Function({
      required String collectionId,
      required int animeId,
      Value<double?> userScore,
      Value<String?> userNotes,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$CollectionEntriesTableUpdateCompanionBuilder =
    CollectionEntriesCompanion Function({
      Value<String> collectionId,
      Value<int> animeId,
      Value<double?> userScore,
      Value<String?> userNotes,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$CollectionEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectionEntriesTable,
          CollectionEntry
        > {
  $$CollectionEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CollectionsTable _collectionIdTable(_$AppDatabase db) => db
      .collections
      .createAlias('collection_entries__collection_id__collections__id');

  $$CollectionsTableProcessedTableManager get collectionId {
    final $_column = $_itemColumn<String>('collection_id')!;

    final manager = $$CollectionsTableTableManager(
      $_db,
      $_db.collections,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_collectionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AnimeRecordsTable _animeIdTable(_$AppDatabase db) => db.animeRecords
      .createAlias('collection_entries__anime_id__anime_records__id');

  $$AnimeRecordsTableProcessedTableManager get animeId {
    final $_column = $_itemColumn<int>('anime_id')!;

    final manager = $$AnimeRecordsTableTableManager(
      $_db,
      $_db.animeRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectionEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionEntriesTable> {
  $$CollectionEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get userScore => $composableBuilder(
    column: $table.userScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userNotes => $composableBuilder(
    column: $table.userNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectionsTableFilterComposer get collectionId {
    final $$CollectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableFilterComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnimeRecordsTableFilterComposer get animeId {
    final $$AnimeRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableFilterComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionEntriesTable> {
  $$CollectionEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get userScore => $composableBuilder(
    column: $table.userScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userNotes => $composableBuilder(
    column: $table.userNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectionsTableOrderingComposer get collectionId {
    final $$CollectionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableOrderingComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnimeRecordsTableOrderingComposer get animeId {
    final $$AnimeRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionEntriesTable> {
  $$CollectionEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get userScore =>
      $composableBuilder(column: $table.userScore, builder: (column) => column);

  GeneratedColumn<String> get userNotes =>
      $composableBuilder(column: $table.userNotes, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$CollectionsTableAnnotationComposer get collectionId {
    final $$CollectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.collectionId,
      referencedTable: $db.collections,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.collections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AnimeRecordsTableAnnotationComposer get animeId {
    final $$AnimeRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionEntriesTable,
          CollectionEntry,
          $$CollectionEntriesTableFilterComposer,
          $$CollectionEntriesTableOrderingComposer,
          $$CollectionEntriesTableAnnotationComposer,
          $$CollectionEntriesTableCreateCompanionBuilder,
          $$CollectionEntriesTableUpdateCompanionBuilder,
          (CollectionEntry, $$CollectionEntriesTableReferences),
          CollectionEntry,
          PrefetchHooks Function({bool collectionId, bool animeId})
        > {
  $$CollectionEntriesTableTableManager(
    _$AppDatabase db,
    $CollectionEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<int> animeId = const Value.absent(),
                Value<double?> userScore = const Value.absent(),
                Value<String?> userNotes = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionEntriesCompanion(
                collectionId: collectionId,
                animeId: animeId,
                userScore: userScore,
                userNotes: userNotes,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required int animeId,
                Value<double?> userScore = const Value.absent(),
                Value<String?> userNotes = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionEntriesCompanion.insert(
                collectionId: collectionId,
                animeId: animeId,
                userScore: userScore,
                userNotes: userNotes,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionEntriesTable, CollectionEntry>(table),
                  $$CollectionEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({collectionId = false, animeId = false}) {
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
                    if (collectionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.collectionId,
                        referencedTable: $$CollectionEntriesTableReferences
                            ._collectionIdTable(db),
                        referencedColumn: $$CollectionEntriesTableReferences
                            ._collectionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (animeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeId,
                        referencedTable: $$CollectionEntriesTableReferences
                            ._animeIdTable(db),
                        referencedColumn: $$CollectionEntriesTableReferences
                            ._animeIdTable(db)
                            .id,
                      ) as T;
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

typedef $$CollectionEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionEntriesTable,
      CollectionEntry,
      $$CollectionEntriesTableFilterComposer,
      $$CollectionEntriesTableOrderingComposer,
      $$CollectionEntriesTableAnnotationComposer,
      $$CollectionEntriesTableCreateCompanionBuilder,
      $$CollectionEntriesTableUpdateCompanionBuilder,
      (CollectionEntry, $$CollectionEntriesTableReferences),
      CollectionEntry,
      PrefetchHooks Function({bool collectionId, bool animeId})
    >;
typedef $$AnimePreferencesTableCreateCompanionBuilder =
    AnimePreferencesCompanion Function({
      Value<int> animeId,
      Value<String?> preferredProvider,
      Value<String?> preferredAudio,
      Value<String?> preferredServer,
      Value<String?> preferredSubtitleTrack,
      Value<double?> customPlaybackSpeed,
      Value<String?> preferredQuality,
    });
typedef $$AnimePreferencesTableUpdateCompanionBuilder =
    AnimePreferencesCompanion Function({
      Value<int> animeId,
      Value<String?> preferredProvider,
      Value<String?> preferredAudio,
      Value<String?> preferredServer,
      Value<String?> preferredSubtitleTrack,
      Value<double?> customPlaybackSpeed,
      Value<String?> preferredQuality,
    });

final class $$AnimePreferencesTableReferences
    extends
        BaseReferences<_$AppDatabase, $AnimePreferencesTable, AnimePreference> {
  $$AnimePreferencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnimeRecordsTable _animeIdTable(_$AppDatabase db) => db.animeRecords
      .createAlias('anime_preferences__anime_id__anime_records__id');

  $$AnimeRecordsTableProcessedTableManager get animeId {
    final $_column = $_itemColumn<int>('anime_id')!;

    final manager = $$AnimeRecordsTableTableManager(
      $_db,
      $_db.animeRecords,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_animeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnimePreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AnimePreferencesTable> {
  $$AnimePreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get preferredProvider => $composableBuilder(
    column: $table.preferredProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredAudio => $composableBuilder(
    column: $table.preferredAudio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredServer => $composableBuilder(
    column: $table.preferredServer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredSubtitleTrack => $composableBuilder(
    column: $table.preferredSubtitleTrack,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get customPlaybackSpeed => $composableBuilder(
    column: $table.customPlaybackSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredQuality => $composableBuilder(
    column: $table.preferredQuality,
    builder: (column) => ColumnFilters(column),
  );

  $$AnimeRecordsTableFilterComposer get animeId {
    final $$AnimeRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableFilterComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnimePreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AnimePreferencesTable> {
  $$AnimePreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get preferredProvider => $composableBuilder(
    column: $table.preferredProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredAudio => $composableBuilder(
    column: $table.preferredAudio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredServer => $composableBuilder(
    column: $table.preferredServer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredSubtitleTrack => $composableBuilder(
    column: $table.preferredSubtitleTrack,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get customPlaybackSpeed => $composableBuilder(
    column: $table.customPlaybackSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredQuality => $composableBuilder(
    column: $table.preferredQuality,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnimeRecordsTableOrderingComposer get animeId {
    final $$AnimeRecordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableOrderingComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnimePreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnimePreferencesTable> {
  $$AnimePreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get preferredProvider => $composableBuilder(
    column: $table.preferredProvider,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredAudio => $composableBuilder(
    column: $table.preferredAudio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredServer => $composableBuilder(
    column: $table.preferredServer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredSubtitleTrack => $composableBuilder(
    column: $table.preferredSubtitleTrack,
    builder: (column) => column,
  );

  GeneratedColumn<double> get customPlaybackSpeed => $composableBuilder(
    column: $table.customPlaybackSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredQuality => $composableBuilder(
    column: $table.preferredQuality,
    builder: (column) => column,
  );

  $$AnimeRecordsTableAnnotationComposer get animeId {
    final $$AnimeRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.animeId,
      referencedTable: $db.animeRecords,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnimeRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.animeRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnimePreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnimePreferencesTable,
          AnimePreference,
          $$AnimePreferencesTableFilterComposer,
          $$AnimePreferencesTableOrderingComposer,
          $$AnimePreferencesTableAnnotationComposer,
          $$AnimePreferencesTableCreateCompanionBuilder,
          $$AnimePreferencesTableUpdateCompanionBuilder,
          (AnimePreference, $$AnimePreferencesTableReferences),
          AnimePreference,
          PrefetchHooks Function({bool animeId})
        > {
  $$AnimePreferencesTableTableManager(
    _$AppDatabase db,
    $AnimePreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimePreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnimePreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnimePreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> animeId = const Value.absent(),
                Value<String?> preferredProvider = const Value.absent(),
                Value<String?> preferredAudio = const Value.absent(),
                Value<String?> preferredServer = const Value.absent(),
                Value<String?> preferredSubtitleTrack = const Value.absent(),
                Value<double?> customPlaybackSpeed = const Value.absent(),
                Value<String?> preferredQuality = const Value.absent(),
              }) => AnimePreferencesCompanion(
                animeId: animeId,
                preferredProvider: preferredProvider,
                preferredAudio: preferredAudio,
                preferredServer: preferredServer,
                preferredSubtitleTrack: preferredSubtitleTrack,
                customPlaybackSpeed: customPlaybackSpeed,
                preferredQuality: preferredQuality,
              ),
          createCompanionCallback:
              ({
                Value<int> animeId = const Value.absent(),
                Value<String?> preferredProvider = const Value.absent(),
                Value<String?> preferredAudio = const Value.absent(),
                Value<String?> preferredServer = const Value.absent(),
                Value<String?> preferredSubtitleTrack = const Value.absent(),
                Value<double?> customPlaybackSpeed = const Value.absent(),
                Value<String?> preferredQuality = const Value.absent(),
              }) => AnimePreferencesCompanion.insert(
                animeId: animeId,
                preferredProvider: preferredProvider,
                preferredAudio: preferredAudio,
                preferredServer: preferredServer,
                preferredSubtitleTrack: preferredSubtitleTrack,
                customPlaybackSpeed: customPlaybackSpeed,
                preferredQuality: preferredQuality,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AnimePreferencesTable, AnimePreference>(table),
                  $$AnimePreferencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({animeId = false}) {
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
                    if (animeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.animeId,
                        referencedTable: $$AnimePreferencesTableReferences
                            ._animeIdTable(db),
                        referencedColumn: $$AnimePreferencesTableReferences
                            ._animeIdTable(db)
                            .id,
                      ) as T;
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

typedef $$AnimePreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnimePreferencesTable,
      AnimePreference,
      $$AnimePreferencesTableFilterComposer,
      $$AnimePreferencesTableOrderingComposer,
      $$AnimePreferencesTableAnnotationComposer,
      $$AnimePreferencesTableCreateCompanionBuilder,
      $$AnimePreferencesTableUpdateCompanionBuilder,
      (AnimePreference, $$AnimePreferencesTableReferences),
      AnimePreference,
      PrefetchHooks Function({bool animeId})
    >;
typedef $$EpisodeSubscriptionsTableCreateCompanionBuilder =
    EpisodeSubscriptionsCompanion Function({
      Value<int> animeId,
      required String animeTitle,
      Value<String?> coverUrl,
      required int nextEpisodeNumber,
      required DateTime nextAiringAt,
      Value<int> lastNotifiedEpisode,
      Value<bool> isSubscribed,
      Value<DateTime?> lastCheckedAt,
      Value<int> retryCount,
    });
typedef $$EpisodeSubscriptionsTableUpdateCompanionBuilder =
    EpisodeSubscriptionsCompanion Function({
      Value<int> animeId,
      Value<String> animeTitle,
      Value<String?> coverUrl,
      Value<int> nextEpisodeNumber,
      Value<DateTime> nextAiringAt,
      Value<int> lastNotifiedEpisode,
      Value<bool> isSubscribed,
      Value<DateTime?> lastCheckedAt,
      Value<int> retryCount,
    });

class $$EpisodeSubscriptionsTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodeSubscriptionsTable> {
  $$EpisodeSubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get animeId => $composableBuilder(
    column: $table.animeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animeTitle => $composableBuilder(
    column: $table.animeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextEpisodeNumber => $composableBuilder(
    column: $table.nextEpisodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAiringAt => $composableBuilder(
    column: $table.nextAiringAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastNotifiedEpisode => $composableBuilder(
    column: $table.lastNotifiedEpisode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodeSubscriptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodeSubscriptionsTable> {
  $$EpisodeSubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get animeId => $composableBuilder(
    column: $table.animeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animeTitle => $composableBuilder(
    column: $table.animeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextEpisodeNumber => $composableBuilder(
    column: $table.nextEpisodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAiringAt => $composableBuilder(
    column: $table.nextAiringAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastNotifiedEpisode => $composableBuilder(
    column: $table.lastNotifiedEpisode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodeSubscriptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodeSubscriptionsTable> {
  $$EpisodeSubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get animeId =>
      $composableBuilder(column: $table.animeId, builder: (column) => column);

  GeneratedColumn<String> get animeTitle => $composableBuilder(
    column: $table.animeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<int> get nextEpisodeNumber => $composableBuilder(
    column: $table.nextEpisodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAiringAt => $composableBuilder(
    column: $table.nextAiringAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastNotifiedEpisode => $composableBuilder(
    column: $table.lastNotifiedEpisode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSubscribed => $composableBuilder(
    column: $table.isSubscribed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCheckedAt => $composableBuilder(
    column: $table.lastCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$EpisodeSubscriptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodeSubscriptionsTable,
          EpisodeSubscription,
          $$EpisodeSubscriptionsTableFilterComposer,
          $$EpisodeSubscriptionsTableOrderingComposer,
          $$EpisodeSubscriptionsTableAnnotationComposer,
          $$EpisodeSubscriptionsTableCreateCompanionBuilder,
          $$EpisodeSubscriptionsTableUpdateCompanionBuilder,
          (
            EpisodeSubscription,
            BaseReferences<
              _$AppDatabase,
              $EpisodeSubscriptionsTable,
              EpisodeSubscription
            >,
          ),
          EpisodeSubscription,
          PrefetchHooks Function()
        > {
  $$EpisodeSubscriptionsTableTableManager(
    _$AppDatabase db,
    $EpisodeSubscriptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodeSubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodeSubscriptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EpisodeSubscriptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> animeId = const Value.absent(),
                Value<String> animeTitle = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<int> nextEpisodeNumber = const Value.absent(),
                Value<DateTime> nextAiringAt = const Value.absent(),
                Value<int> lastNotifiedEpisode = const Value.absent(),
                Value<bool> isSubscribed = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => EpisodeSubscriptionsCompanion(
                animeId: animeId,
                animeTitle: animeTitle,
                coverUrl: coverUrl,
                nextEpisodeNumber: nextEpisodeNumber,
                nextAiringAt: nextAiringAt,
                lastNotifiedEpisode: lastNotifiedEpisode,
                isSubscribed: isSubscribed,
                lastCheckedAt: lastCheckedAt,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> animeId = const Value.absent(),
                required String animeTitle,
                Value<String?> coverUrl = const Value.absent(),
                required int nextEpisodeNumber,
                required DateTime nextAiringAt,
                Value<int> lastNotifiedEpisode = const Value.absent(),
                Value<bool> isSubscribed = const Value.absent(),
                Value<DateTime?> lastCheckedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => EpisodeSubscriptionsCompanion.insert(
                animeId: animeId,
                animeTitle: animeTitle,
                coverUrl: coverUrl,
                nextEpisodeNumber: nextEpisodeNumber,
                nextAiringAt: nextAiringAt,
                lastNotifiedEpisode: lastNotifiedEpisode,
                isSubscribed: isSubscribed,
                lastCheckedAt: lastCheckedAt,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpisodeSubscriptionsTable, EpisodeSubscription>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $EpisodeSubscriptionsTable,
                    EpisodeSubscription
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodeSubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodeSubscriptionsTable,
      EpisodeSubscription,
      $$EpisodeSubscriptionsTableFilterComposer,
      $$EpisodeSubscriptionsTableOrderingComposer,
      $$EpisodeSubscriptionsTableAnnotationComposer,
      $$EpisodeSubscriptionsTableCreateCompanionBuilder,
      $$EpisodeSubscriptionsTableUpdateCompanionBuilder,
      (
        EpisodeSubscription,
        BaseReferences<
          _$AppDatabase,
          $EpisodeSubscriptionsTable,
          EpisodeSubscription
        >,
      ),
      EpisodeSubscription,
      PrefetchHooks Function()
    >;
typedef $$InstalledExtensionsTableCreateCompanionBuilder =
    InstalledExtensionsCompanion Function({
      required String id,
      required String name,
      required String version,
      required int versionCode,
      Value<String> author,
      Value<String?> iconUrl,
      Value<String?> description,
      Value<String> audio,
      Value<String> lang,
      Value<String?> baseUrl,
      Value<bool> isEnabled,
      Value<int> priorityIndex,
      required String localScriptPath,
      Value<String?> repoUrl,
      Value<DateTime> installedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$InstalledExtensionsTableUpdateCompanionBuilder =
    InstalledExtensionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> version,
      Value<int> versionCode,
      Value<String> author,
      Value<String?> iconUrl,
      Value<String?> description,
      Value<String> audio,
      Value<String> lang,
      Value<String?> baseUrl,
      Value<bool> isEnabled,
      Value<int> priorityIndex,
      Value<String> localScriptPath,
      Value<String?> repoUrl,
      Value<DateTime> installedAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$InstalledExtensionsTableFilterComposer
    extends Composer<_$AppDatabase, $InstalledExtensionsTable> {
  $$InstalledExtensionsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionCode => $composableBuilder(
    column: $table.versionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audio => $composableBuilder(
    column: $table.audio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priorityIndex => $composableBuilder(
    column: $table.priorityIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localScriptPath => $composableBuilder(
    column: $table.localScriptPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstalledExtensionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstalledExtensionsTable> {
  $$InstalledExtensionsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionCode => $composableBuilder(
    column: $table.versionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audio => $composableBuilder(
    column: $table.audio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priorityIndex => $composableBuilder(
    column: $table.priorityIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localScriptPath => $composableBuilder(
    column: $table.localScriptPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstalledExtensionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstalledExtensionsTable> {
  $$InstalledExtensionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get versionCode => $composableBuilder(
    column: $table.versionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audio =>
      $composableBuilder(column: $table.audio, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<int> get priorityIndex => $composableBuilder(
    column: $table.priorityIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localScriptPath => $composableBuilder(
    column: $table.localScriptPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repoUrl =>
      $composableBuilder(column: $table.repoUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InstalledExtensionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstalledExtensionsTable,
          InstalledExtension,
          $$InstalledExtensionsTableFilterComposer,
          $$InstalledExtensionsTableOrderingComposer,
          $$InstalledExtensionsTableAnnotationComposer,
          $$InstalledExtensionsTableCreateCompanionBuilder,
          $$InstalledExtensionsTableUpdateCompanionBuilder,
          (
            InstalledExtension,
            BaseReferences<
              _$AppDatabase,
              $InstalledExtensionsTable,
              InstalledExtension
            >,
          ),
          InstalledExtension,
          PrefetchHooks Function()
        > {
  $$InstalledExtensionsTableTableManager(
    _$AppDatabase db,
    $InstalledExtensionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstalledExtensionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstalledExtensionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstalledExtensionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<int> versionCode = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> audio = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> priorityIndex = const Value.absent(),
                Value<String> localScriptPath = const Value.absent(),
                Value<String?> repoUrl = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalledExtensionsCompanion(
                id: id,
                name: name,
                version: version,
                versionCode: versionCode,
                author: author,
                iconUrl: iconUrl,
                description: description,
                audio: audio,
                lang: lang,
                baseUrl: baseUrl,
                isEnabled: isEnabled,
                priorityIndex: priorityIndex,
                localScriptPath: localScriptPath,
                repoUrl: repoUrl,
                installedAt: installedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String version,
                required int versionCode,
                Value<String> author = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> audio = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String?> baseUrl = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<int> priorityIndex = const Value.absent(),
                required String localScriptPath,
                Value<String?> repoUrl = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalledExtensionsCompanion.insert(
                id: id,
                name: name,
                version: version,
                versionCode: versionCode,
                author: author,
                iconUrl: iconUrl,
                description: description,
                audio: audio,
                lang: lang,
                baseUrl: baseUrl,
                isEnabled: isEnabled,
                priorityIndex: priorityIndex,
                localScriptPath: localScriptPath,
                repoUrl: repoUrl,
                installedAt: installedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstalledExtensionsTable, InstalledExtension>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $InstalledExtensionsTable,
                    InstalledExtension
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InstalledExtensionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstalledExtensionsTable,
      InstalledExtension,
      $$InstalledExtensionsTableFilterComposer,
      $$InstalledExtensionsTableOrderingComposer,
      $$InstalledExtensionsTableAnnotationComposer,
      $$InstalledExtensionsTableCreateCompanionBuilder,
      $$InstalledExtensionsTableUpdateCompanionBuilder,
      (
        InstalledExtension,
        BaseReferences<
          _$AppDatabase,
          $InstalledExtensionsTable,
          InstalledExtension
        >,
      ),
      InstalledExtension,
      PrefetchHooks Function()
    >;
typedef $$ExtensionRepositoriesTableCreateCompanionBuilder =
    ExtensionRepositoriesCompanion Function({
      required String id,
      required String name,
      required String url,
      Value<bool> isEnabled,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });
typedef $$ExtensionRepositoriesTableUpdateCompanionBuilder =
    ExtensionRepositoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> url,
      Value<bool> isEnabled,
      Value<DateTime?> lastSyncedAt,
      Value<int> rowid,
    });

class $$ExtensionRepositoriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExtensionRepositoriesTable> {
  $$ExtensionRepositoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExtensionRepositoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExtensionRepositoriesTable> {
  $$ExtensionRepositoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExtensionRepositoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExtensionRepositoriesTable> {
  $$ExtensionRepositoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );
}

class $$ExtensionRepositoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExtensionRepositoriesTable,
          ExtensionRepository,
          $$ExtensionRepositoriesTableFilterComposer,
          $$ExtensionRepositoriesTableOrderingComposer,
          $$ExtensionRepositoriesTableAnnotationComposer,
          $$ExtensionRepositoriesTableCreateCompanionBuilder,
          $$ExtensionRepositoriesTableUpdateCompanionBuilder,
          (
            ExtensionRepository,
            BaseReferences<
              _$AppDatabase,
              $ExtensionRepositoriesTable,
              ExtensionRepository
            >,
          ),
          ExtensionRepository,
          PrefetchHooks Function()
        > {
  $$ExtensionRepositoriesTableTableManager(
    _$AppDatabase db,
    $ExtensionRepositoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtensionRepositoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ExtensionRepositoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExtensionRepositoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtensionRepositoriesCompanion(
                id: id,
                name: name,
                url: url,
                isEnabled: isEnabled,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String url,
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtensionRepositoriesCompanion.insert(
                id: id,
                name: name,
                url: url,
                isEnabled: isEnabled,
                lastSyncedAt: lastSyncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExtensionRepositoriesTable, ExtensionRepository>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ExtensionRepositoriesTable,
                    ExtensionRepository
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExtensionRepositoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExtensionRepositoriesTable,
      ExtensionRepository,
      $$ExtensionRepositoriesTableFilterComposer,
      $$ExtensionRepositoriesTableOrderingComposer,
      $$ExtensionRepositoriesTableAnnotationComposer,
      $$ExtensionRepositoriesTableCreateCompanionBuilder,
      $$ExtensionRepositoriesTableUpdateCompanionBuilder,
      (
        ExtensionRepository,
        BaseReferences<
          _$AppDatabase,
          $ExtensionRepositoriesTable,
          ExtensionRepository
        >,
      ),
      ExtensionRepository,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AnimeRecordsTableTableManager get animeRecords =>
      $$AnimeRecordsTableTableManager(_db, _db.animeRecords);
  $$WatchHistoryTableTableManager get watchHistory =>
      $$WatchHistoryTableTableManager(_db, _db.watchHistory);
  $$EpisodeProgressTableTableManager get episodeProgress =>
      $$EpisodeProgressTableTableManager(_db, _db.episodeProgress);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$CollectionEntriesTableTableManager get collectionEntries =>
      $$CollectionEntriesTableTableManager(_db, _db.collectionEntries);
  $$AnimePreferencesTableTableManager get animePreferences =>
      $$AnimePreferencesTableTableManager(_db, _db.animePreferences);
  $$EpisodeSubscriptionsTableTableManager get episodeSubscriptions =>
      $$EpisodeSubscriptionsTableTableManager(_db, _db.episodeSubscriptions);
  $$InstalledExtensionsTableTableManager get installedExtensions =>
      $$InstalledExtensionsTableTableManager(_db, _db.installedExtensions);
  $$ExtensionRepositoriesTableTableManager get extensionRepositories =>
      $$ExtensionRepositoriesTableTableManager(_db, _db.extensionRepositories);
}
