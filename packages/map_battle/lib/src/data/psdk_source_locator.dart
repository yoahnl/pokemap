import 'dart:io';

const _movesPathFromContainer = 'pokémon_sdk_test_project/Data/Studio/moves';
const _battlePathFromContainer = 'pokemonsdk-development/scripts/5 Battle';

final class PsdkSourceDirectories {
  const PsdkSourceDirectories({
    required this.containerDirectory,
    required this.movesDirectory,
    required this.psdkBattleDirectory,
  });

  final Directory containerDirectory;
  final Directory movesDirectory;
  final Directory psdkBattleDirectory;
}

PsdkSourceDirectories resolvePsdkSourceDirectories({
  Directory? repositoryRoot,
}) {
  final root = repositoryRoot ?? _gitRepositoryRoot();
  if (root == null) {
    return _sourcesIn(Directory('../..'));
  }

  final repositorySources = _sourcesIn(root);
  if (_exists(repositorySources)) {
    return repositorySources;
  }

  final siblingContainers = root.parent
      .listSync(followLinks: false)
      .whereType<Directory>()
      .where((directory) => directory.absolute.path != root.absolute.path)
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  for (final container in siblingContainers) {
    final sources = _sourcesIn(container);
    if (_exists(sources)) {
      return sources;
    }
  }

  return repositorySources;
}

PsdkSourceDirectories _sourcesIn(Directory container) {
  return PsdkSourceDirectories(
    containerDirectory: container,
    movesDirectory: Directory.fromUri(
      container.uri.resolve(_movesPathFromContainer),
    ),
    psdkBattleDirectory: Directory.fromUri(
      container.uri.resolve(_battlePathFromContainer),
    ),
  );
}

bool _exists(PsdkSourceDirectories sources) {
  return sources.movesDirectory.existsSync() &&
      sources.psdkBattleDirectory.existsSync();
}

Directory? _gitRepositoryRoot() {
  final result = Process.runSync(
    'git',
    <String>['rev-parse', '--show-toplevel'],
  );
  if (result.exitCode != 0) {
    return null;
  }
  final path = '${result.stdout}'.trim();
  return path.isEmpty ? null : Directory(path);
}
