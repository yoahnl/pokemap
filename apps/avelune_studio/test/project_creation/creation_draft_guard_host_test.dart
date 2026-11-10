import 'dart:io';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/project_creation_workspace_fixture.dart';
import '../support/real_test_io.dart';

void main() {
  Future<ProjectCreationWorkspaceFixture> open(
    WidgetTester tester, {
    MapWorkspacePort Function(MapWorkspacePort)? mapPort,
  }) async {
    final parent = (await RealTestIo.run(
      tester,
      () => Directory.systemTemp.createTemp('creation-draft-'),
    ))!;
    final fixture = ProjectCreationWorkspaceFixture(
      tester,
      parent,
      File('${parent.path}/demo.avelunegame'),
    );
    addTearDown(() async {
      await fixture.dispose();
      await RealTestIo.run(tester, () => parent.delete(recursive: true));
    });
    await fixture.mount(mapPort: mapPort);
    await fixture.create(32, name: 'Projet A');
    return fixture;
  }

  File mapFile(ProjectCreationWorkspaceFixture fixture) => File(
    '${fixture.session.state.project!.directoryPath}/${fixture.maps.project!.maps.first.relativePath}',
  );

  testWidgets('closing creation leaves the mounted draft and bytes untouched', (
    tester,
  ) async {
    final fixture = await open(tester);
    final owner = fixture.maps;
    final document = owner.active!;
    final session = fixture.session.state.project!;
    final file = mapFile(fixture);
    final before = (await RealTestIo.run(tester, file.readAsBytes))!;
    document.commit(document.current.copyWith(name: 'Saisie non enregistrée'));
    document.stackPosition = const GridPos(x: 3, y: 4);
    owner.notify();
    await fixture.beginCreation(name: 'Projet jamais créé');
    expect(await fixture.closeCreation(), isTrue);
    expect(fixture.session.state.project, same(session));
    expect(fixture.maps, same(owner));
    expect(owner.active, same(document));
    expect(document.dirty, isTrue);
    expect(document.undoCount, 1);
    expect(document.stackPosition, const GridPos(x: 3, y: 4));
    expect(
      await RealTestIo.run(tester, file.readAsBytes),
      orderedEquals(before),
    );
    expect(fixture.parent.listSync().whereType<Directory>(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled switch keeps A and the created B can be reopened', (
    tester,
  ) async {
    final fixture = await open(tester);
    final owner = fixture.maps;
    final document = owner.active!;
    final session = fixture.session.state.project!;
    final file = mapFile(fixture);
    final before = (await RealTestIo.run(tester, file.readAsBytes))!;
    document.commit(document.current.copyWith(name: 'Brouillon A conservé'));
    document.stackPosition = const GridPos(x: 6, y: 5);
    owner.notify();
    fixture.closeChoice = WorkspaceCloseChoice.cancel;
    await fixture.submitCreation(32, name: 'Projet B');
    final createdReceipt = fixture.creator!.receipt!;
    expect(fixture.creator!.openError, contains('basculement a été annulé'));
    expect(fixture.session.state.project, same(session));
    expect(fixture.maps, same(owner));
    expect(owner.active, same(document));
    expect(owner.isDisposed, isFalse);
    expect(document.dirty, isTrue);
    expect(document.undoCount, 1);
    expect(document.stackPosition, const GridPos(x: 6, y: 5));
    expect(
      await RealTestIo.run(tester, file.readAsBytes),
      orderedEquals(before),
    );
    await RealTestIo.run(tester, () async {
      final access = LocalProjectSessionAdapter();
      final independentSession = await access.open(createdReceipt.projectPath);
      try {
        final independent = LocalMapWorkspaceAdapter();
        final manifest = await independent.loadProject(independentSession);
        expect(manifest.name, 'Projet B');
        expect(manifest.settings.tileWidth, 32);
        expect(
          (await independent.loadMap(
            independentSession,
            manifest.maps.first,
          )).map.id,
          'first-map',
        );
      } finally {
        await access.close(independentSession);
      }
    });
    owner.restore(redo: false);
    expect(document.dirty, isFalse);
    owner.restore(redo: true);
    expect(document.current.name, 'Brouillon A conservé');
    expect(document.dirty, isTrue);
    fixture.closeChoice = WorkspaceCloseChoice.discard;
    expect(await fixture.tryOpenCreated(), isTrue);
    expect(fixture.creator, isNull);
    expect(
      fixture.session.state.project!.directoryPath,
      createdReceipt.projectPath,
    );
    expect(fixture.maps, isNot(same(owner)));
    expect(owner.isDisposed, isTrue);
    expect(fixture.maps.active!.dirty, isFalse);
    expect(
      await RealTestIo.run(tester, file.readAsBytes),
      orderedEquals(before),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('real creation guard failed save retains draft and B on disk', (
    tester,
  ) async {
    late _FailingSavePort port;
    final fixture = await open(
      tester,
      mapPort: (delegate) => port = _FailingSavePort(delegate),
    );
    final owner = fixture.maps;
    final document = owner.active!;
    final session = fixture.session.state.project!;
    final file = mapFile(fixture);
    final before = (await RealTestIo.run(tester, file.readAsBytes))!;
    document.commit(document.current.copyWith(name: 'Brouillon après refus'));
    owner.notify();
    fixture.closeChoice = WorkspaceCloseChoice.save;
    await fixture.submitCreation(32, name: 'Projet B');
    expect(port.writes, 1);
    expect(fixture.session.state.project, same(session));
    expect(fixture.maps, same(owner));
    expect(owner.active, same(document));
    expect(document.current.name, 'Brouillon après refus');
    expect(document.dirty, isTrue);
    expect(document.canUndo, isTrue);
    expect(document.error, 'Écriture refusée pour la recette');
    expect(
      await RealTestIo.run(tester, file.readAsBytes),
      orderedEquals(before),
    );
    expect(fixture.parent.listSync().whereType<Directory>(), hasLength(2));
    expect(fixture.creator!.openError, contains('Projet créé et conservé'));
    expect(await fixture.closeCreation(), isTrue);
    expect(fixture.session.state.project, same(session));
    expect(document.dirty, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _FailingSavePort implements MapWorkspacePort {
  _FailingSavePort(this.delegate);
  final MapWorkspacePort delegate;
  int writes = 0;
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      delegate.loadProject(session);
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) => delegate.loadMap(session, entry);
  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    writes++;
    throw const MapWorkspaceFailure(
      MapWorkspaceProblem.writeFailed,
      'Écriture refusée pour la recette',
    );
  }
}
