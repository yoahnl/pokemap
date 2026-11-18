import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/verification/application/project_verification_controller.dart';
import 'package:avelune_studio/features/verification/application/verification_snapshot.dart';
import 'package:avelune_studio/features/verification/data/local_verification_adapter.dart';
import 'package:avelune_studio/features/verification/domain/verification_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

const _map = ProjectMapEntry(
  id: 'a',
  name: 'Bourg',
  relativePath: 'maps/a.json',
);
const _dialogue = ProjectDialogueEntry(
  id: 'greeting',
  name: 'Bonjour',
  relativePath: 'dialogues/greeting.yarn',
);

Future<({ProjectSession session, File map, File dialogue})> _fixture(
  bool catalog,
) async {
  final directory = await Directory.systemTemp.createTemp(
    'verification_freshness_',
  );
  final root = await directory.resolveSymbolicLinks();
  addTearDown(() => directory.delete(recursive: true));
  const project = ProjectManifest(
    name: 'Vérification',
    maps: [_map],
    tilesets: [],
    dialogues: [_dialogue],
  );
  if (catalog) {
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root),
      projectId: 'verification-freshness',
      project: project,
    );
  } else {
    await File('$root/project.json')
        .writeAsString(jsonEncode(project.toJson()));
  }
  final map = File('$root/${_map.relativePath}');
  await map.parent.create();
  await map.writeAsString(
    jsonEncode(
      MapData(
        id: _map.id,
        name: _map.name,
        size: const GridSize(width: 2, height: 2),
        layers: const [],
      ).toJson(),
    ),
  );
  final dialogue = File('$root/${_dialogue.relativePath}');
  await dialogue.parent.create();
  await dialogue.writeAsString('title: Start\n---\nBonjour.\n===\n');
  return (
    session: ProjectSession(
      sessionId: root,
      name: project.name,
      directoryPath: root,
      storage: catalog
          ? ProjectSessionStorage.workingCatalog
          : ProjectSessionStorage.manifest,
    ),
    map: map,
    dialogue: dialogue,
  );
}

ProjectVerificationController _controller(VerificationPort port) {
  final controller = ProjectVerificationController(port: port, changed: () {});
  addTearDown(controller.dispose);
  return controller;
}

class _ModifyAfterMapRead extends LocalVerificationAdapter {
  _ModifyAfterMapRead({required super.session, required this.file})
    : super(mapAdapter: LocalMapWorkspaceAdapter());

  final File file;

  @override
  Future<List<VerificationMapSource>> readMaps(
    List<ProjectMapEntry> entries, {
    void Function(int loaded, int total)? progress,
  }) async {
    final maps = await super.readMaps(entries, progress: progress);
    await file.writeAsString('carte devenue illisible');
    return maps;
  }
}

void main() {
  for (final catalog in [false, true]) {
    test(
      'a map changed on disk invalidates the saved report, catalog=$catalog',
      () async {
        final fixture = await _fixture(catalog);
        final port = LocalVerificationAdapter(
          session: fixture.session,
          mapAdapter: LocalMapWorkspaceAdapter(),
        );
        final verification = _controller(port);
        await verification.start();
        expect(
          verification.phase,
          ProjectVerificationPhase.done,
          reason: '${verification.failure}',
        );
        expect(verification.freshness, VerificationFreshness.current);
        expect(
          verification.problems.map((p) => p.code),
          isNot(contains(verificationUnreadableMap)),
        );
        final revision = await port.projectRevision();
        await verification.refreshRevision();
        expect(verification.freshness, VerificationFreshness.current);

        await fixture.map.writeAsString('carte devenue illisible');
        await verification.refreshRevision();

        expect(await port.projectRevision(), revision);
        expect(verification.freshness, VerificationFreshness.stale);
        await verification.start();
        expect(verification.snapshot!.complete, isFalse);
        expect(
          verification.problems.map((p) => p.code),
          contains(verificationUnreadableMap),
        );
      },
    );

    test(
      'a map changed after capture cannot certify the run, catalog=$catalog',
      () async {
        final fixture = await _fixture(catalog);
        final verification = _controller(
          _ModifyAfterMapRead(session: fixture.session, file: fixture.map),
        );

        await verification.start();

        expect(
          verification.phase,
          ProjectVerificationPhase.done,
          reason: '${verification.failure}',
        );
        expect(verification.freshness, VerificationFreshness.stale);
      },
    );
  }

  test('a saved Yarn change invalidates a report while the catalog revision stays fixed', () async {
    final fixture = await _fixture(true);
    final port = LocalVerificationAdapter(
      session: fixture.session,
      mapAdapter: LocalMapWorkspaceAdapter(),
    );
    final verification = _controller(port);
    await verification.start();
    expect(verification.freshness, VerificationFreshness.current);
    final revision = await port.projectRevision();

    await fixture.dialogue.writeAsBytes([0xff, 0xfe, 0x00]);
    await verification.refreshRevision();

    expect(await port.projectRevision(), revision);
    expect(verification.freshness, VerificationFreshness.stale);
    await verification.start();
    expect(verification.snapshot!.unreadableDialogues, [_dialogue]);
    expect(verification.snapshot!.complete, isFalse);
  });
}
