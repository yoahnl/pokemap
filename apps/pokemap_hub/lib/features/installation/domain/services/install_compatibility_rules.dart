import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

/// Pure installation rules, extracted from the installer so they can be read
/// and tested without a filesystem. Nothing here touches the filesystem.

/// Projects package branding onto the library's own branding entity.
InstalledGameBranding? installedBrandingOf(GamePackageBranding? branding) =>
    branding == null
        ? null
        : InstalledGameBranding(
            icon: branding.icon,
            cover: branding.cover,
            hero: branding.hero,
            accentColor: branding.accentColor,
            titleMusic: branding.titleMusic,
            layoutVariant: branding.layoutVariant,
          );
