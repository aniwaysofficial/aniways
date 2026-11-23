import 'dart:convert';
import 'package:aniways/core/network/extractor_service.dart';

/// Metadata describing a streaming extension.
class ExtensionManifest {
  const ExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.versionCode,
    this.author = 'Aniways Community',
    this.iconUrl,
    this.description,
    this.audio = const [StreamAudio.sub],
    this.lang = 'en',
    this.baseUrl,
    this.isEnabled = true,
    this.priorityIndex = 0,
    this.localScriptPath,
    this.repoUrl,
    this.installedAt,
    this.updatedAt,
    this.isAdult = false,
  });

  final String id;
  final String name;
  final String version;
  final int versionCode;
  final String author;
  final String? iconUrl;
  final String? description;
  final List<StreamAudio> audio;
  final String lang;
  final String? baseUrl;
  final bool isEnabled;
  final int priorityIndex;
  final String? localScriptPath;
  final String? repoUrl;
  final DateTime? installedAt;
  final DateTime? updatedAt;
  final bool isAdult;

  bool get hasSub => audio.contains(StreamAudio.sub);
  bool get hasDub => audio.contains(StreamAudio.dub);

  /// Convert to [ProviderInfo] consumed by [WatchProvider].
  ProviderInfo toProviderInfo() {
    return ProviderInfo(
      id: id,
      name: name,
      audio: audio,
      status: isEnabled ? 'online' : 'offline',
      iconUrl: iconUrl,
      isAdult: isAdult,
    );
  }

  ExtensionManifest copyWith({
    String? id,
    String? name,
    String? version,
    int? versionCode,
    String? author,
    String? iconUrl,
    String? description,
    List<StreamAudio>? audio,
    String? lang,
    String? baseUrl,
    bool? isEnabled,
    int? priorityIndex,
    String? localScriptPath,
    String? repoUrl,
    DateTime? installedAt,
    DateTime? updatedAt,
    bool? isAdult,
  }) {
    return ExtensionManifest(
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
      isAdult: isAdult ?? this.isAdult,
    );
  }

  factory ExtensionManifest.fromJson(Map<String, dynamic> json) {
    final rawAudio = json['audio'];
    final audioList = <StreamAudio>[];

    if (rawAudio is List) {
      for (final a in rawAudio) {
        if (a.toString().toLowerCase() == 'dub') {
          audioList.add(StreamAudio.dub);
        } else {
          audioList.add(StreamAudio.sub);
        }
      }
    } else if (rawAudio is String) {
      try {
        final decoded = jsonDecode(rawAudio);
        if (decoded is List) {
          for (final a in decoded) {
            audioList.add(
              a.toString().toLowerCase() == 'dub'
                  ? StreamAudio.dub
                  : StreamAudio.sub,
            );
          }
        }
      } catch (_) {
        audioList.add(StreamAudio.sub);
      }
    }

    if (audioList.isEmpty) {
      audioList.add(StreamAudio.sub);
    }

    return ExtensionManifest(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      version: (json['version'] as String?) ?? '1.0.0',
      versionCode: (json['versionCode'] as num?)?.toInt() ?? 1,
      author: (json['author'] as String?) ?? 'Aniways Community',
      iconUrl: json['iconUrl'] as String? ?? json['icon'] as String?,
      description: json['description'] as String?,
      audio: audioList,
      lang: (json['lang'] as String?) ?? 'en',
      baseUrl: json['baseUrl'] as String?,
      isEnabled: (json['isEnabled'] as bool?) ?? true,
      priorityIndex: (json['priorityIndex'] as num?)?.toInt() ?? 0,
      localScriptPath: json['localScriptPath'] as String?,
      repoUrl: json['repoUrl'] as String?,
      installedAt: json['installedAt'] != null
          ? DateTime.tryParse(json['installedAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      isAdult: (json['isAdult'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'versionCode': versionCode,
        'author': author,
        'iconUrl': iconUrl,
        'description': description,
        'audio': audio.map((a) => a.name).toList(),
        'lang': lang,
        'baseUrl': baseUrl,
        'isEnabled': isEnabled,
        'priorityIndex': priorityIndex,
        'localScriptPath': localScriptPath,
        'repoUrl': repoUrl,
        'installedAt': installedAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isAdult': isAdult,
      };
}

