import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';

final class InstalledGamePointer {
  const InstalledGamePointer({
    required this.gameVersion,
    required this.treeSha256,
  });

  final Version gameVersion;
  final String treeSha256;

  Map<String, Object?> toJson() => <String, Object?>{
        'gameVersion': gameVersion.toString(),
        'treeSha256': treeSha256,
      };

  @override
  bool operator ==(Object other) =>
      other is InstalledGamePointer &&
      gameVersion == other.gameVersion &&
      treeSha256 == other.treeSha256;

  @override
  int get hashCode => Object.hash(gameVersion, treeSha256);
}

final class InstalledGameVersion {
  const InstalledGameVersion({
    required this.gameVersion,
    required this.treeSha256,
    required this.installedAt,
    required this.receiptFileName,
    required this.source,
    required this.signatureStatus,
  });

  final Version gameVersion;
  final String treeSha256;
  final DateTime installedAt;
  final String receiptFileName;
  final GamePackageInstallSource source;
  final PackageSignatureStatus signatureStatus;

  InstalledGamePointer get pointer => InstalledGamePointer(
        gameVersion: gameVersion,
        treeSha256: treeSha256,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'gameVersion': gameVersion.toString(),
        'treeSha256': treeSha256,
        'installedAt': installedAt.toUtc().toIso8601String(),
        'receiptFileName': receiptFileName,
        'source': source.name,
        'signatureStatus': signatureStatus.name,
      };
}

final class InstalledGameBranding {
  const InstalledGameBranding({
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

final class InstalledGame {
  InstalledGame({
    required this.gameId,
    required this.title,
    this.description,
    required this.authorName,
    this.publisherName,
    required this.defaultLocale,
    required List<String> supportedLocales,
    this.branding,
    required this.current,
    required List<InstalledGameVersion> versions,
  })  : supportedLocales = List.unmodifiable(supportedLocales),
        versions = List.unmodifiable(
          versions.toList()
            ..sort((left, right) {
              final byVersion = left.gameVersion.compareTo(right.gameVersion);
              return byVersion != 0
                  ? byVersion
                  : left.treeSha256.compareTo(right.treeSha256);
            }),
        );

  final String gameId;
  final String title;
  final String? description;
  final String authorName;
  final String? publisherName;
  final String defaultLocale;
  final List<String> supportedLocales;
  final InstalledGameBranding? branding;
  final InstalledGamePointer current;
  final List<InstalledGameVersion> versions;

  InstalledGameVersion get currentVersion => versions.singleWhere(
        (version) => version.pointer == current,
      );

  InstalledGame copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    String? authorName,
    String? publisherName,
    bool clearPublisherName = false,
    String? defaultLocale,
    List<String>? supportedLocales,
    InstalledGameBranding? branding,
    bool clearBranding = false,
    InstalledGamePointer? current,
    List<InstalledGameVersion>? versions,
  }) =>
      InstalledGame(
        gameId: gameId,
        title: title ?? this.title,
        description: clearDescription ? null : description ?? this.description,
        authorName: authorName ?? this.authorName,
        publisherName:
            clearPublisherName ? null : publisherName ?? this.publisherName,
        defaultLocale: defaultLocale ?? this.defaultLocale,
        supportedLocales: supportedLocales ?? this.supportedLocales,
        branding: clearBranding ? null : branding ?? this.branding,
        current: current ?? this.current,
        versions: versions ?? this.versions,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'gameId': gameId,
        'title': title,
        if (description != null) 'description': description,
        'authorName': authorName,
        if (publisherName != null) 'publisherName': publisherName,
        'defaultLocale': defaultLocale,
        'supportedLocales': supportedLocales,
        if (branding != null) 'branding': branding!.toJson(),
        'current': current.toJson(),
        'versions':
            versions.map((version) => version.toJson()).toList(growable: false),
      };
}

final class GameLibrary {
  GameLibrary({
    this.schemaVersion = 1,
    required this.revision,
    required this.updatedAt,
    required List<InstalledGame> games,
  }) : games = List.unmodifiable(
          games.toList()
            ..sort((left, right) => left.gameId.compareTo(right.gameId)),
        );

  factory GameLibrary.empty({DateTime? updatedAt}) => GameLibrary(
        revision: 0,
        updatedAt:
            (updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc(),
        games: const <InstalledGame>[],
      );

  final int schemaVersion;
  final int revision;
  final DateTime updatedAt;
  final List<InstalledGame> games;

  InstalledGame? game(String gameId) {
    for (final game in games) {
      if (game.gameId == gameId) return game;
    }
    return null;
  }

  GameLibrary replaceGame(InstalledGame game, {required DateTime updatedAt}) {
    final next = <InstalledGame>[
      for (final existing in games)
        if (existing.gameId != game.gameId) existing,
      game,
    ];
    return GameLibrary(
      revision: revision + 1,
      updatedAt: updatedAt.toUtc(),
      games: next,
    );
  }

  GameLibrary removeGame(String gameId, {required DateTime updatedAt}) =>
      GameLibrary(
        revision: revision + 1,
        updatedAt: updatedAt.toUtc(),
        games: games.where((game) => game.gameId != gameId).toList(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'revision': revision,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'games': games.map((game) => game.toJson()).toList(growable: false),
      };
}
