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

final class GamePackageMenuLabels {
  const GamePackageMenuLabels({
    this.pauseTitle,
    this.resume,
    this.party,
    this.bag,
    this.pokedex,
    this.map,
    this.save,
    this.options,
    this.returnToTitle,
  });

  final String? pauseTitle;
  final String? resume;
  final String? party;
  final String? bag;
  final String? pokedex;
  final String? map;
  final String? save;
  final String? options;
  final String? returnToTitle;

  Map<String, Object?> toJson() => <String, Object?>{
        if (pauseTitle != null) 'pauseTitle': pauseTitle,
        if (resume != null) 'resume': resume,
        if (party != null) 'party': party,
        if (bag != null) 'bag': bag,
        if (pokedex != null) 'pokedex': pokedex,
        if (map != null) 'map': map,
        if (save != null) 'save': save,
        if (options != null) 'options': options,
        if (returnToTitle != null) 'returnToTitle': returnToTitle,
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
    this.titleMotion,
    this.typography,
    this.theme,
    this.menuLabels,
  });

  final int schemaVersion;
  final GamePackageBranding branding;
  final GamePackageIntroVideo? intro;
  final GamePackageTitleMotion? titleMotion;
  final GamePackageTypography? typography;
  final GamePackageSemanticTheme? theme;
  final GamePackageMenuLabels? menuLabels;

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'branding': branding.toJson(),
        if (intro != null) 'intro': intro!.toJson(legacy: schemaVersion == 1),
        if (schemaVersion >= 2 && titleMotion != null)
          'titleMotion': titleMotion!.toJson(),
        if (typography != null) 'typography': typography!.toJson(),
        if (theme != null) 'theme': theme!.toJson(),
        if (menuLabels != null) 'menuLabels': menuLabels!.toJson(),
      };
}

final class GamePackageIntroVideo {
  const GamePackageIntroVideo({
    this.media,
    String? video,
    String? poster,
    String? captions,
    int? durationMilliseconds,
    int? width,
    int? height,
    int? bitrateKbps,
    int? sizeBytes,
    String? videoCodec,
    String? audioCodec,
    required this.reducedMotionBehavior,
    required this.allowReplay,
  })  : _legacyVideo = video,
        _legacyPoster = poster,
        _legacyCaptions = captions,
        _legacyDurationMilliseconds = durationMilliseconds,
        _legacyWidth = width,
        _legacyHeight = height,
        _legacyBitrateKbps = bitrateKbps,
        _legacySizeBytes = sizeBytes,
        _legacyVideoCodec = videoCodec,
        _legacyAudioCodec = audioCodec,
        assert(
          media != null ||
              (video != null &&
                  poster != null &&
                  durationMilliseconds != null &&
                  width != null &&
                  height != null &&
                  bitrateKbps != null &&
                  sizeBytes != null &&
                  videoCodec != null &&
                  audioCodec != null),
        );

  final GamePackageResponsiveVideo? media;
  final String? _legacyVideo;
  final String? _legacyPoster;
  final String? _legacyCaptions;
  final int? _legacyDurationMilliseconds;
  final int? _legacyWidth;
  final int? _legacyHeight;
  final int? _legacyBitrateKbps;
  final int? _legacySizeBytes;
  final String? _legacyVideoCodec;
  final String? _legacyAudioCodec;
  final String reducedMotionBehavior;
  final bool allowReplay;

  GamePackageVideoVariant get landscape =>
      media?.landscape ??
      GamePackageVideoVariant(
        video: _legacyVideo!,
        poster: _legacyPoster!,
        captions: _legacyCaptions,
        durationMilliseconds: _legacyDurationMilliseconds!,
        width: _legacyWidth!,
        height: _legacyHeight!,
        bitrateKbps: _legacyBitrateKbps!,
        sizeBytes: _legacySizeBytes!,
        videoCodec: _legacyVideoCodec!,
        audioCodec: _legacyAudioCodec!,
      );

  String get video => landscape.video;
  String get poster => landscape.poster;
  String? get captions => landscape.captions;
  int get durationMilliseconds => landscape.durationMilliseconds;
  int get width => landscape.width;
  int get height => landscape.height;
  int get bitrateKbps => landscape.bitrateKbps;
  int get sizeBytes => landscape.sizeBytes;
  String get videoCodec => landscape.videoCodec;
  String get audioCodec => landscape.audioCodec;

  GamePackageResponsiveVideo get responsiveMedia =>
      media ?? GamePackageResponsiveVideo(landscape: landscape);

  Map<String, Object?> toJson({bool legacy = false}) => <String, Object?>{
        if (legacy)
          ...landscape.toLegacyJson()
        else
          'media': responsiveMedia.toJson(),
        'reducedMotionBehavior': reducedMotionBehavior,
        'allowReplay': allowReplay,
      };
}

final class GamePackageVideoVariant {
  const GamePackageVideoVariant({
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
    this.focalX = .5,
    this.focalY = .5,
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
  final double focalX;
  final double focalY;

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
        'focalXPermille': (focalX * 1000).round(),
        'focalYPermille': (focalY * 1000).round(),
      };

  Map<String, Object?> toLegacyJson() => <String, Object?>{
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
      };
}

final class GamePackageResponsiveVideo {
  const GamePackageResponsiveVideo({
    required this.landscape,
    this.portrait,
  });

  final GamePackageVideoVariant landscape;
  final GamePackageVideoVariant? portrait;

  Iterable<GamePackageVideoVariant> get variants sync* {
    yield landscape;
    if (portrait case final portrait?) yield portrait;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'landscape': landscape.toJson(),
        if (portrait != null) 'portrait': portrait!.toJson(),
      };
}

final class GamePackageTitleMotion {
  const GamePackageTitleMotion({
    this.promptLoop,
    this.menuLoop,
  });

  final GamePackageResponsiveVideo? promptLoop;
  final GamePackageResponsiveVideo? menuLoop;

  Map<String, Object?> toJson() => <String, Object?>{
        if (promptLoop != null) 'promptLoop': promptLoop!.toJson(),
        if (menuLoop != null) 'menuLoop': menuLoop!.toJson(),
      };
}

final class GamePackageTypography {
  const GamePackageTypography({
    this.display = const GamePackageFontRole(),
    this.body = const GamePackageFontRole(),
    this.dialogue = const GamePackageFontRole(),
    this.numbers = const GamePackageFontRole(
      fallbackFamilies: <String>['monospace'],
    ),
  });

  final GamePackageFontRole display;
  final GamePackageFontRole body;
  final GamePackageFontRole dialogue;
  final GamePackageFontRole numbers;

  Map<String, Object?> toJson() => <String, Object?>{
        'display': display.toJson(),
        'body': body.toJson(),
        'dialogue': dialogue.toJson(),
        'numbers': numbers.toJson(),
      };
}

final class GamePackageFontRole {
  const GamePackageFontRole({
    this.font,
    this.family,
    this.license,
    this.fallbackFamilies = const <String>['sans-serif'],
  });

  final String? font;
  final String? family;
  final String? license;
  final List<String> fallbackFamilies;

  Map<String, Object?> toJson() => <String, Object?>{
        if (font != null) 'font': font,
        if (family != null) 'family': family,
        if (license != null) 'license': license,
        'fallbackFamilies': fallbackFamilies,
      };
}

final class GamePackageSemanticTheme {
  const GamePackageSemanticTheme({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.outline,
    required this.success,
    required this.warning,
    required this.danger,
    required this.titleSurface,
    required this.dialogueSurface,
    required this.menuSurface,
    required this.overworldHudSurface,
    required this.battleHudSurface,
  });

  final String primary;
  final String onPrimary;
  final String background;
  final String surface;
  final String surfaceElevated;
  final String textPrimary;
  final String textSecondary;
  final String outline;
  final String success;
  final String warning;
  final String danger;
  final String titleSurface;
  final String dialogueSurface;
  final String menuSurface;
  final String overworldHudSurface;
  final String battleHudSurface;

  Map<String, Object?> toJson() => <String, Object?>{
        'primary': primary,
        'onPrimary': onPrimary,
        'background': background,
        'surface': surface,
        'surfaceElevated': surfaceElevated,
        'textPrimary': textPrimary,
        'textSecondary': textSecondary,
        'outline': outline,
        'success': success,
        'warning': warning,
        'danger': danger,
        'titleSurface': titleSurface,
        'dialogueSurface': dialogueSurface,
        'menuSurface': menuSurface,
        'overworldHudSurface': overworldHudSurface,
        'battleHudSurface': battleHudSurface,
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
