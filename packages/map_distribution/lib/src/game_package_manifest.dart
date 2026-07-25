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
    this.branding,
    required this.content,
    this.signature,
  });

  final int packageFormat;
  final String gameId;
  final Version gameVersion;
  final String title;
  final String? description;
  final GamePackageParty author;
  final GamePackageParty? publisher;
  final GamePackageCompatibility compatibility;
  final GamePackageLocales locales;
  final GamePackageBranding? branding;
  final GamePackageContent content;
  final GamePackageSignature? signature;

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
        branding: branding,
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
        if (branding != null) 'branding': branding!.toJson(),
        'content': content.toJson(),
        if (signature != null) 'signature': signature!.toJson(),
      };
}
