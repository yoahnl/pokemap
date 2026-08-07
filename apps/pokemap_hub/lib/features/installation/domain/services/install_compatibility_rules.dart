import 'package:map_distribution/map_distribution.dart';

import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';

/// Pure installation rules, extracted from the installer so they can be read
/// and tested without a filesystem. Nothing here touches the filesystem.

/// Whether two inspection receipts describe the exact same package bytes.
///
/// Guards against a source package being swapped between inspection and
/// staging: every identity, digest and size field must match.
bool sameInspection(
  GamePackageInspectionReceipt left,
  GamePackageInspectionReceipt right,
) =>
    left.gameId == right.gameId &&
    left.gameVersion == right.gameVersion &&
    left.treeSha256 == right.treeSha256 &&
    left.manifestSha256 == right.manifestSha256 &&
    left.packageSha256 == right.packageSha256 &&
    left.archiveBytes == right.archiveBytes &&
    left.payloadBytes == right.payloadBytes &&
    left.fileCount == right.fileCount;

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
