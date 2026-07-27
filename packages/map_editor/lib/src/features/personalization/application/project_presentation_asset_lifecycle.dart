import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

abstract interface class ProjectPresentationAssetCleaner {
  Future<ProjectPresentationAssetCleanupResult> cleanStaleAssets({
    required Directory projectRoot,
    required ProjectPresentationProfile previousProfile,
    required ProjectPresentationProfile currentProfile,
  });
}

final class ProjectPresentationAssetCleanupResult {
  ProjectPresentationAssetCleanupResult({
    Iterable<String> deletedPaths = const <String>[],
    Iterable<String> skippedPaths = const <String>[],
    Map<String, String> failures = const <String, String>{},
  })  : deletedPaths = Set<String>.unmodifiable(deletedPaths),
        skippedPaths = Set<String>.unmodifiable(skippedPaths),
        failures = Map<String, String>.unmodifiable(failures);

  factory ProjectPresentationAssetCleanupResult.failed(Object error) {
    return ProjectPresentationAssetCleanupResult(
      failures: <String, String>{'assetCleanup': error.toString()},
    );
  }

  final Set<String> deletedPaths;
  final Set<String> skippedPaths;
  final Map<String, String> failures;

  bool get hasFailures => failures.isNotEmpty;
}

/// Deletes project-owned presentation assets that became stale after a save.
///
/// Cleanup is deliberately reference-driven: it never scans a directory and
/// only removes regular files named by the previous intro or typography
/// profile. Unknown files, unsafe paths, missing files and symbolic links are
/// preserved.
final class ProjectPresentationAssetLifecycle
    implements ProjectPresentationAssetCleaner {
  const ProjectPresentationAssetLifecycle();

  @override
  Future<ProjectPresentationAssetCleanupResult> cleanStaleAssets({
    required Directory projectRoot,
    required ProjectPresentationProfile previousProfile,
    required ProjectPresentationProfile currentProfile,
  }) async {
    final deleted = <String>{};
    final skipped = <String>{};
    final failures = <String, String>{};
    final currentReferences = _allPresentationPaths(currentProfile).toSet();
    final stalePaths = _ownedAssetPaths(previousProfile)
        .where((path) => !currentReferences.contains(path))
        .toSet();

    for (final relativePath in stalePaths) {
      if (!_isManagedRelativePath(relativePath)) {
        skipped.add(relativePath);
        continue;
      }
      final segments = p.posix.split(relativePath);
      final target = File(
        p.joinAll(<String>[projectRoot.path, ...segments]),
      );
      try {
        if (!await _hasSafeDirectoryChain(projectRoot, segments)) {
          skipped.add(relativePath);
          continue;
        }
        final type = await FileSystemEntity.type(
          target.path,
          followLinks: false,
        );
        if (type != FileSystemEntityType.file) {
          skipped.add(relativePath);
          continue;
        }
        await target.delete();
        deleted.add(relativePath);
      } on Object catch (error) {
        failures[relativePath] = error.toString();
      }
    }

    return ProjectPresentationAssetCleanupResult(
      deletedPaths: deleted,
      skippedPaths: skipped,
      failures: failures,
    );
  }
}

Iterable<String> _ownedAssetPaths(ProjectPresentationProfile profile) sync* {
  final branding = profile.branding;
  for (final path in <String?>[
    branding.iconPath,
    branding.coverPath,
    branding.heroPath,
    branding.titleMusicPath,
  ]) {
    if (path != null) yield path;
  }
  final intro = profile.intro;
  if (intro != null) {
    yield intro.videoPath;
    if (intro.posterPath case final path?) yield path;
    if (intro.captionsPath case final path?) yield path;
  }
  final typography = profile.typography;
  if (typography == null) return;
  for (final role in <ProjectTypographyRoleProfile>[
    typography.display,
    typography.body,
    typography.dialogue,
    typography.numbers,
  ]) {
    if (role.fontPath case final path?) yield path;
    if (role.licensePath case final path?) yield path;
  }
}

Iterable<String> _allPresentationPaths(
  ProjectPresentationProfile profile,
) sync* {
  yield* _ownedAssetPaths(profile);
}

bool _isManagedRelativePath(String path) {
  if (path.isEmpty || p.posix.isAbsolute(path)) return false;
  if (p.posix.normalize(path) != path) return false;
  return path.startsWith('assets/presentation/intro/') ||
      path.startsWith('assets/presentation/fonts/') ||
      path.startsWith('assets/presentation/branding/');
}

Future<bool> _hasSafeDirectoryChain(
  Directory projectRoot,
  List<String> relativeSegments,
) async {
  if (await FileSystemEntity.type(
        projectRoot.path,
        followLinks: false,
      ) !=
      FileSystemEntityType.directory) {
    return false;
  }
  var currentPath = projectRoot.path;
  for (final segment in relativeSegments.take(relativeSegments.length - 1)) {
    currentPath = p.join(currentPath, segment);
    if (await FileSystemEntity.type(
          currentPath,
          followLinks: false,
        ) !=
        FileSystemEntityType.directory) {
      return false;
    }
  }
  return true;
}
