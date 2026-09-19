import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

import 'project_fixture.dart';

void main() {
  late Directory sandbox;
  late _ObservedLocalReader reader;
  late LocalProjectSessionAdapter adapter;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('avelune_path_identity_');
    reader = _ObservedLocalReader();
    adapter = LocalProjectSessionAdapter(fileReader: reader);
  });

  tearDown(() async {
    await sandbox.delete(recursive: true);
  });

  Future<(Directory, Directory)> neighbors() async {
    final plain = await createProject(
      sandbox,
      'MonJeu',
      manifestName: 'Projet témoin sans espace',
    );
    final spaced = await createProject(
      sandbox,
      'MonJeu ',
      manifestName: 'Projet demandé avec espace final',
    );
    final names = await sandbox.list().map((e) => p.basename(e.path)).toList();
    expect(
      names,
      containsAll(['MonJeu', 'MonJeu ']),
      reason: 'Le filesystem doit représenter les deux noms U+0020 distincts.',
    );
    expect(
      await spaced.resolveSymbolicLinks(),
      isNot(await plain.resolveSymbolicLinks()),
      reason: 'Ces tests exigent deux vrais dossiers distincts.',
    );
    return (plain, spaced);
  }

  Future<void> refuseWithoutReads(String path) async {
    reader.reads.clear();
    reader.probes.clear();
    ProjectSession? unexpectedSession;
    Object? failure;
    try {
      unexpectedSession = await adapter.open(path);
    } catch (error) {
      failure = error;
    }
    if (unexpectedSession != null) await adapter.close(unexpectedSession);
    expect(
      unexpectedSession?.name,
      isNull,
      reason: 'Un chemin refusé ne doit retourner aucun projet voisin.',
    );
    expect(
      failure,
      isA<ProjectOpenFailure>().having(
        (failure) => failure.problem.name,
        'problem',
        'pathNotPreserved',
      ),
    );
    expect(reader.reads, isEmpty, reason: 'Aucun manifeste ne doit être lu.');
    expect(reader.probes, isEmpty, reason: 'Aucun manifeste voisin consulté.');
  }

  test(
    'real neighboring projects never substitute the trimmed target',
    () async {
      final (plain, spaced) = await neighbors();
      final before = await _snapshot(sandbox);
      final plainRoot = await plain.resolveSymbolicLinks();

      final session = await adapter.open(plain.path);
      expect(session.name, 'Projet témoin sans espace');
      expect(session.directoryPath, plainRoot);
      expect(reader.reads, [(root: plainRoot, relativePath: 'project.json')]);
      await adapter.close(session);

      await refuseWithoutReads(spaced.path);

      expect(await _snapshot(sandbox), before);
    },
  );

  test(
    'trailing space is refused even when no plain neighbor exists',
    () async {
      final spaced = await createProject(
        sandbox,
        'MonJeu ',
        manifestName: 'Projet demandé sans voisin',
      );
      expect(await Directory(p.join(sandbox.path, 'MonJeu')).exists(), isFalse);
      expect(p.basename(await spaced.resolveSymbolicLinks()), 'MonJeu ');
      final before = await _snapshot(sandbox);

      await refuseWithoutReads(spaced.path);

      expect(await _snapshot(sandbox), before);
    },
  );

  test('trailing separator cannot hide a risky canonical root', () async {
    final (_, spaced) = await neighbors();
    final submitted = '${spaced.path}${Platform.pathSeparator}';
    expect(submitted.trim(), submitted);
    final before = await _snapshot(sandbox);

    await refuseWithoutReads(submitted);

    expect(reader.canonicalRequests, contains(submitted));
    expect(await _snapshot(sandbox), before);
  });

  test(
    'ordinary symlink to risky root is refused before manifest access',
    () async {
      final (_, spaced) = await neighbors();
      final alias = await Link(
        p.join(sandbox.path, 'Alias'),
      ).create(spaced.path);
      final before = await _snapshot(sandbox);

      await refuseWithoutReads(alias.path);

      expect(reader.canonicalRequests, contains(alias.path));
      expect(await alias.target(), spaced.path);
      expect(await _snapshot(sandbox), before);
    },
  );

  test(
    'ordinary symlink to safe root accepts legitimate canonicalization',
    () async {
      final (plain, _) = await neighbors();
      final alias = await Link(
        p.join(sandbox.path, 'Alias sûr'),
      ).create(plain.path);
      final root = await plain.resolveSymbolicLinks();
      expect(alias.path, isNot(root));
      final before = await _snapshot(sandbox);

      final session = await adapter.open(alias.path);

      expect(session.name, 'Projet témoin sans espace');
      expect(session.directoryPath, root);
      expect(reader.reads, [(root: root, relativePath: 'project.json')]);
      await adapter.close(session);
      expect(await alias.target(), plain.path);
      expect(await _snapshot(sandbox), before);
    },
  );

  test('internal spaces and accents preserve the requested project', () async {
    final project = await createProject(
      sandbox,
      'Mon jeu été à vélo',
      manifestName: 'Identité réelle accentuée',
    );
    final root = await project.resolveSymbolicLinks();
    final before = await _snapshot(sandbox);

    final session = await adapter.open(project.path);

    expect(session.name, 'Identité réelle accentuée');
    expect(session.directoryPath, root);
    expect(reader.reads, [(root: root, relativePath: 'project.json')]);
    await adapter.close(session);
    expect(await _snapshot(sandbox), before);
  });

  test('surrounding whitespace never redirects a direct port call', () async {
    final (plain, _) = await neighbors();
    final before = await _snapshot(sandbox);

    await refuseWithoutReads(' ${plain.path} ');

    expect(await _snapshot(sandbox), before);
  });
}

Future<Map<String, Object>> _snapshot(Directory directory) async {
  final entries = await directory
      .list(recursive: true, followLinks: false)
      .toList();
  entries.sort((a, b) => a.path.compareTo(b.path));
  return {
    for (final entry in entries)
      p.relative(entry.path, from: directory.path): switch (entry) {
        File() => await entry.readAsBytes(),
        Link() => ('link', await entry.target()),
        _ => 'directory',
      },
  };
}

final class _ObservedLocalReader
    implements ProjectFileReader, ProjectResourceProbeReader {
  final delegate = const LocalProjectFileReader();
  final canonicalRequests = <String>[];
  final reads = <({String root, String relativePath})>[];
  final probes = <({String root, String relativePath})>[];

  @override
  Future<String> canonicalizeDirectory(String path) {
    canonicalRequests.add(path);
    return delegate.canonicalizeDirectory(path);
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    reads.add((root: projectRoot, relativePath: relativePath));
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    probes.add((root: projectRoot, relativePath: relativePath));
    return delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
