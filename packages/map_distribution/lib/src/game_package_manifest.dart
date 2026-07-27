import 'package:pub_semver/pub_semver.dart';

final class GamePackageParty {
  const GamePackageParty({required this.name, this.url});

  final String name;
  final Uri? url;

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        if (url != null) 'url': url.toString(),
      };
}

final class GamePackageCompatibility {
  GamePackageCompatibility({
    required this.minHubVersion,
    required this.runtimeApiExpression,
    required this.projectFormat,
    required this.saveFormat,
    required this.compatibilityId,
    required List<String> requiredCapabilities,
  })  : runtimeApi = VersionConstraint.parse(runtimeApiExpression),
        requiredCapabilities = List.unmodifiable(requiredCapabilities);

  final Version minHubVersion;
  final String runtimeApiExpression;
  final VersionConstraint runtimeApi;
  final String projectFormat;
  final int saveFormat;
  final String compatibilityId;
  final List<String> requiredCapabilities;

  Map<String, Object?> toJson() => <String, Object?>{
        'minHubVersion': minHubVersion.toString(),
        'runtimeApi': runtimeApiExpression,
        'projectFormat': projectFormat,
        'saveFormat': saveFormat,
        'compatibilityId': compatibilityId,
        'requiredCapabilities': requiredCapabilities,
      };
}

final class GamePackageLocales {
  GamePackageLocales({
    required this.defaultLocale,
    required List<String> supported,
  }) : supported = List.unmodifiable(supported);

  final String defaultLocale;
  final List<String> supported;

  Map<String, Object?> toJson() => <String, Object?>{
        'default': defaultLocale,
        'supported': supported,
      };
}

final class GamePackageBranding {
  const GamePackageBranding({
    this.icon,
    this.cover,
    this.hero,
    this.accentColor,
    this.titleMusic,
    this.layoutVariant,
  });

  final String? icon;
  final String? cover;
  final String? hero;
  final String? accentColor;
  final String? titleMusic;
  final String? layoutVariant;

  Map<String, Object?> toJson() => <String, Object?>{
        if (icon != null) 'icon': icon,
        if (cover != null) 'cover': cover,
        if (hero != null) 'hero': hero,
        if (accentColor != null) 'accentColor': accentColor,
        if (titleMusic != null) 'titleMusic': titleMusic,
        if (layoutVariant != null) 'layoutVariant': layoutVariant,
      };
}

/// Runtime-facing projection of the project-owned presentation contract.
///
/// Package paths replace authoring paths here; the project manifest remains
/// the source of truth.
final class GamePackagePresentation {
  const GamePackagePresentation({
    this.schemaVersion = 1,
    this.branding = const GamePackageBranding(),
    this.intro,
  });

  final int schemaVersion;
  final GamePackageBranding branding;
  final GamePackageIntroVideo? intro;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'branding': branding.toJson(),
        if (intro != null) 'intro': intro!.toJson(),
      };
}

final class GamePackageIntroVideo {
  const GamePackageIntroVideo({
    required this.video,
    required this.poster,
    this.captions,
    required this.durationMilliseconds,
    required this.width,
    required this.height,
    required this.bitrateKbps,
    required this.sizeBytes,
    required this.videoCodec,
    required this.audioCodec,
    required this.reducedMotionBehavior,
    required this.allowReplay,
  });

  final String video;
  final String poster;
  final String? captions;
  final int durationMilliseconds;
  final int width;
  final int height;
  final int bitrateKbps;
  final int sizeBytes;
  final String videoCodec;
  final String audioCodec;
  final String reducedMotionBehavior;
  final bool allowReplay;

  Map<String, Object?> toJson() => <String, Object?>{
        'video': video,
        'poster': poster,
        if (captions != null) 'captions': captions,
        'durationMilliseconds': durationMilliseconds,
        'width': width,
        'height': height,
        'bitrateKbps': bitrateKbps,
        'sizeBytes': sizeBytes,
        'videoCodec': videoCodec,
        'audioCodec': audioCodec,
        'reducedMotionBehavior': reducedMotionBehavior,
        'allowReplay': allowReplay,
      };
}

final class GamePackageFileEntry {
  const GamePackageFileEntry({
    required this.path,
    required this.size,
    required this.sha256,
    this.mediaType,
  });

  final String path;
  final int size;
  final String sha256;
  final String? mediaType;

  Map<String, Object?> toJson() => <String, Object?>{
        'path': path,
        'size': size,
        'sha256': sha256,
        if (mediaType != null) 'mediaType': mediaType,
      };
}

final class GamePackageContent {
  GamePackageContent({
    required this.fileCount,
    required this.totalBytes,
    required this.treeSha256,
    required List<GamePackageFileEntry> files,
  }) : files = List.unmodifiable(files);

  final int fileCount;
  final int totalBytes;
  final String treeSha256;
  final List<GamePackageFileEntry> files;

  Map<String, Object?> toJson() => <String, Object?>{
        'fileCount': fileCount,
        'totalBytes': totalBytes,
        'treeSha256': treeSha256,
        'files': files.map((file) => file.toJson()).toList(growable: false),
      };
}

final class GamePackageSignature {
  const GamePackageSignature({
    required this.algorithm,
    required this.keyId,
    required this.value,
  });

  final String algorithm;
  final String keyId;
  final String value;

  Map<String, Object?> toJson() => <String, Object?>{
        'algorithm': algorithm,
        'keyId': keyId,
        'value': value,
      };
}

final class GamePackageManifest {
  const GamePackageManifest({
    required this.packageFormat,
    required this.gameId,
    required this.gameVersion,
    required this.title,
    this.description,
    required this.author,
    this.publisher,
    required this.compatibility,
    required this.locales,
    GamePackageBranding? branding,
    this.presentation,
    required this.content,
    this.signature,
  }) : _legacyBranding = branding;

  final int packageFormat;
  final String gameId;
  final Version gameVersion;
  final String title;
  final String? description;
  final GamePackageParty author;
  final GamePackageParty? publisher;
  final GamePackageCompatibility compatibility;
  final GamePackageLocales locales;
  final GamePackageBranding? _legacyBranding;
  final GamePackagePresentation? presentation;
  final GamePackageContent content;
  final GamePackageSignature? signature;

  /// Branding consumed by old and new clients during the manifest migration.
  GamePackageBranding? get branding =>
      presentation?.branding ?? _legacyBranding;

  bool get usesLegacyBranding =>
      presentation == null && _legacyBranding != null;

  GamePackageManifest copyWith({
    GamePackageContent? content,
    GamePackageSignature? signature,
    bool clearSignature = false,
  }) =>
      GamePackageManifest(
        packageFormat: packageFormat,
        gameId: gameId,
        gameVersion: gameVersion,
        title: title,
        description: description,
        author: author,
        publisher: publisher,
        compatibility: compatibility,
        locales: locales,
        branding: _legacyBranding,
        presentation: presentation,
        content: content ?? this.content,
        signature: clearSignature ? null : signature ?? this.signature,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'packageFormat': packageFormat,
        'gameId': gameId,
        'gameVersion': gameVersion.toString(),
        'title': title,
        if (description != null) 'description': description,
        'author': author.toJson(),
        if (publisher != null) 'publisher': publisher!.toJson(),
        'compatibility': compatibility.toJson(),
        'locales': locales.toJson(),
        if (_legacyBranding != null) 'branding': _legacyBranding.toJson(),
        if (presentation != null) 'presentation': presentation!.toJson(),
        'content': content.toJson(),
        if (signature != null) 'signature': signature!.toJson(),
      };
}
