import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';

typedef HubPresentationFileResolver = Future<File> Function(String packagePath);

final class HubLoadedTitlePresentation {
  HubLoadedTitlePresentation({
    required this.title,
    required this.titleMusicPath,
    required this.intro,
    required this.typography,
    required List<String> unavailableAssets,
  }) : unavailableAssets = List<String>.unmodifiable(unavailableAssets);

  final RuntimePlayerTitlePresentation title;
  final String? titleMusicPath;
  final HubLoadedIntroVideo? intro;
  final HubLoadedTypography? typography;
  final List<String> unavailableAssets;
}

final class HubLoadedTypography {
  HubLoadedTypography({
    required Map<ProjectTypographyRole, HubLoadedFontRole> roles,
  }) : roles = Map.unmodifiable(roles);

  final Map<ProjectTypographyRole, HubLoadedFontRole> roles;
}

final class HubLoadedFontRole {
  HubLoadedFontRole({
    required this.file,
    required this.family,
    required List<String> fallbackFamilies,
  }) : fallbackFamilies = List.unmodifiable(fallbackFamilies);

  final File? file;
  final String? family;
  final List<String> fallbackFamilies;
}

final class HubLoadedIntroVideo {
  const HubLoadedIntroVideo({
    required this.videoPath,
    required this.poster,
    required this.captionsPath,
    required this.reducedMotionBehavior,
    required this.allowReplay,
  });

  final String videoPath;
  final ImageProvider? poster;
  final String? captionsPath;
  final String reducedMotionBehavior;
  final bool allowReplay;
}

/// Resolves optional installed presentation assets independently.
///
/// A missing logo, background, or music file degrades to the generic player
/// title instead of rejecting an otherwise verified game installation.
final class HubTitlePresentationLoader {
  const HubTitlePresentationLoader({
    required this.manifest,
    required this.resolveFile,
  });

  final GamePackageManifest manifest;
  final HubPresentationFileResolver resolveFile;

  Future<HubLoadedTitlePresentation> load({
    PlayerNewGameIdentityPresentation? newGameIdentity,
  }) async {
    final branding = manifest.branding;
    final unavailable = <String>[];
    final logo = await _image(
      branding?.icon,
      unavailable: unavailable,
    );
    final background = await _firstImage(
      <String?>[branding?.hero, branding?.cover],
      unavailable: unavailable,
    );
    final titleMusicPath = await _path(
      branding?.titleMusic,
      unavailable: unavailable,
    );
    final intro = await _intro(
      manifest.presentation?.intro,
      unavailable: unavailable,
    );
    final typography = await _typography(
      manifest.presentation?.typography,
      unavailable: unavailable,
    );
    return HubLoadedTitlePresentation(
      title: RuntimePlayerTitlePresentation(
        author: manifest.author.name,
        description: manifest.description,
        background: background,
        logo: logo,
        accentColor: _decodeAccentColor(branding?.accentColor),
        layoutVariant: PlayerTitleLayoutVariant.fromManifest(
          branding?.layoutVariant,
        ),
        newGameIdentity: newGameIdentity,
      ),
      titleMusicPath: titleMusicPath,
      intro: intro,
      typography: typography,
      unavailableAssets: unavailable,
    );
  }

  Future<HubLoadedTypography?> _typography(
    GamePackageTypography? source, {
    required List<String> unavailable,
  }) async {
    if (source == null) return null;
    final sources = <ProjectTypographyRole, GamePackageFontRole>{
      ProjectTypographyRole.display: source.display,
      ProjectTypographyRole.body: source.body,
      ProjectTypographyRole.dialogue: source.dialogue,
      ProjectTypographyRole.numbers: source.numbers,
    };
    final roles = <ProjectTypographyRole, HubLoadedFontRole>{};
    for (final entry in sources.entries) {
      final fontPath = entry.value.font;
      final resolvedPath = await _path(
        fontPath,
        unavailable: unavailable,
      );
      roles[entry.key] = HubLoadedFontRole(
        file: resolvedPath == null ? null : File(resolvedPath),
        family: entry.value.family,
        fallbackFamilies: entry.value.fallbackFamilies,
      );
    }
    return HubLoadedTypography(roles: roles);
  }

  Future<HubLoadedIntroVideo?> _intro(
    GamePackageIntroVideo? source, {
    required List<String> unavailable,
  }) async {
    if (source == null) return null;
    final videoPath = await _path(source.video, unavailable: unavailable);
    if (videoPath == null) return null;
    return HubLoadedIntroVideo(
      videoPath: videoPath,
      poster: await _image(source.poster, unavailable: unavailable),
      captionsPath: await _path(source.captions, unavailable: unavailable),
      reducedMotionBehavior: source.reducedMotionBehavior,
      allowReplay: source.allowReplay,
    );
  }

  Future<ImageProvider?> _firstImage(
    Iterable<String?> candidates, {
    required List<String> unavailable,
  }) async {
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final image = await _image(candidate, unavailable: unavailable);
      if (image != null) return image;
    }
    return null;
  }

  Future<ImageProvider?> _image(
    String? packagePath, {
    required List<String> unavailable,
  }) async {
    final filePath = await _path(
      packagePath,
      unavailable: unavailable,
    );
    return filePath == null ? null : FileImage(File(filePath));
  }

  Future<String?> _path(
    String? packagePath, {
    required List<String> unavailable,
  }) async {
    if (packagePath == null) return null;
    try {
      return (await resolveFile(packagePath)).path;
    } on Object {
      unavailable.add(packagePath);
      return null;
    }
  }
}

Color? _decodeAccentColor(String? source) {
  if (source == null || !source.startsWith('#')) return null;
  final hex = source.substring(1);
  try {
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    if (hex.length == 8) {
      final red = int.parse(hex.substring(0, 2), radix: 16);
      final green = int.parse(hex.substring(2, 4), radix: 16);
      final blue = int.parse(hex.substring(4, 6), radix: 16);
      final alpha = int.parse(hex.substring(6, 8), radix: 16);
      return Color.fromARGB(alpha, red, green, blue);
    }
  } on FormatException {
    return null;
  }
  return null;
}
