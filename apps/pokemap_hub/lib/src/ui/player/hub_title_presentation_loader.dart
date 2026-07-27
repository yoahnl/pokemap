import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';

typedef HubPresentationFileResolver = Future<File> Function(String packagePath);

final class HubLoadedTitlePresentation {
  HubLoadedTitlePresentation({
    required this.title,
    required this.titleMusicPath,
    required List<String> unavailableAssets,
  }) : unavailableAssets = List<String>.unmodifiable(unavailableAssets);

  final RuntimePlayerTitlePresentation title;
  final String? titleMusicPath;
  final List<String> unavailableAssets;
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
      unavailableAssets: unavailable,
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
