import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/project_creation/project_creation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/project_creation_workspace_fixture.dart';

void main() {
  Future<ProjectCreationWorkspaceFixture> open(
    WidgetTester tester, {
    MapWorkspacePort Function(MapWorkspacePort)? mapPort,
    GlobalKey? captureKey,
  }) async {
    final parent = (await tester.runAsync(() async {
      await loadDesktopCaptureFonts();
      return Directory.systemTemp.createTemp('creation-draft-');
    }))!;
    final fixture = ProjectCreationWorkspaceFixture(
      tester,
      parent,
      File('${parent.path}/demo.avelunegame'),
    );
    addTearDown(() async {
      await fixture.dispose();
      await tester.runAsync(() => parent.delete(recursive: true));
    });
    await fixture.mount(mapPort: mapPort, captureKey: captureKey);
    await fixture.create(32, name: 'Projet A');
    return fixture;
  }

  Future<File> mapFile(ProjectCreationWorkspaceFixture fixture) async => File(
    '${fixture.session.state.project!.directoryPath}/'
    '${fixture.maps.project!.maps.first.relativePath}',
  );

  Future<void> goHome(WidgetTester tester) async {
    await tester.tap(find.text('Accueil'));
    await pumpIo(tester, frames: 12);
  }

  testWidgets('closing creator does not save the mounted project draft', (
    tester,
  ) async {
    final fixture = await open(tester);
    final owner = fixture.maps;
    final document = owner.active!;
    final session = fixture.session.state.project!;
    final file = await mapFile(fixture);
    final before = (await tester.runAsync(file.readAsBytes))!;
    document.commit(document.current.copyWith(name: 'Saisie non enregistrée'));
    document.stackPosition = const GridPos(x: 3, y: 4);
    owner.notify();
    await goHome(tester);
    await tester.tap(find.text('Nouveau projet'));
    await pumpIo(tester, frames: 4);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du projet'),
      'Projet jamais créé',
    );
    await tester.tap(find.byKey(const ValueKey('creation-close')));
    await pumpIo(tester, frames: 8);
    expect(find.byType(ProjectCreationDialog), findsNothing);
    expect(fixture.session.state.project, same(session));
    expect(fixture.maps, same(owner));
    expect(owner.active, same(document));
    expect(document.dirty, isTrue);
    expect(document.undoCount, 1);
    expect(document.stackPosition, const GridPos(x: 3, y: 4));
    expect(await tester.runAsync(file.readAsBytes), orderedEquals(before));
    expect(fixture.parent.listSync().whereType<Directory>().length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled switch retains A and created B can be reopened', (
    tester,
  ) async {
    final key = GlobalKey();
    final fixture = await open(tester, captureKey: key);
    final owner = fixture.maps;
    final document = owner.active!;
    final session = fixture.session.state.project!;
    final file = await mapFile(fixture);
    final before = (await tester.runAsync(file.readAsBytes))!;
    document.commit(document.current.copyWith(name: 'Brouillon A conservé'));
    document.stackPosition = const GridPos(x: 6, y: 5);
    owner.notify();
    await goHome(tester);
    await fixture.submitCreation(48, name: 'Projet B');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Annuler'),
      ),
    );
    await pumpIo(tester, frames: 12);
    expect(find.textContaining('basculement a été annulé'), findsOneWidget);
    await captureM3Widget(tester, key, 'creation-result-preserved-project');
    expect(fixture.session.state.project, same(session));
    expect(fixture.maps, same(owner));
    expect(owner.active, same(document));
    expect(owner.isDisposed, isFalse);
    expect(document.dirty, isTrue);
    expect(document.undoCount, 1);
    expect(document.stackPosition, const GridPos(x: 6, y: 5));
    expect(await tester.runAsync(file.readAsBytes), orderedEquals(before));
    final created = fixture.parent.listSync().whereType<Directory>().firstWhere(
      (directory) =>
          directory.resolveSymbolicLinksSync() != session.directoryPath,
    );
    final independentlyOpened = (await tester.runAsync(
      () => LocalProjectSessionAdapter().open(created.path),
    ))!;
    final independent = LocalMapWorkspaceAdapter();
    final manifest = (await tester.runAsync(
      () => independent.loadProject(independentlyOpened),
    ))!;
    expect(manifest.name, 'Projet B');
    expect(manifest.settings.tileWidth, 48);
    expect(
      (await tester.runAsync(
        () => independent.loadMap(independentlyOpened, manifest.maps.single),
      ))!.map.id,
      'first-map',
    );
    await LocalProjectSessionAdapter().close(independentlyOpened);
    owner.restore(redo: false);
    expect(document.dirty, isFalse);
    owner.restore(redo: true);
    expect(document.current.name, 'Brouillon A conservé');
    expect(document.dirty, isTrue);
    await tester.tap(find.text('Ouvrir le projet créé'));
    await pumpIo(tester, frames: 6);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Abandonner'));
    await pumpIo(tester, frames: 30);
    expect(find.byType(ProjectCreationDialog), findsNothing);
    expect(
      fixture.session.state.project!.directoryPath,
      created.resolveSymbolicLinksSync(),
    );
    expect(fixture.maps, isNot(same(owner)));
    expect(owner.isDisposed, isTrue);
    expect(fixture.maps.active!.dirty, isFalse);
    await captureM3Widget(tester, key, 'creation-opened-map');
    expect(await tester.runAsync(file.readAsBytes), orderedEquals(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed save from real creation guard keeps draft and B on disk',
    (tester) async {
      late _FailingSavePort port;
      final fixture = await open(
        tester,
        mapPort: (delegate) => port = _FailingSavePort(delegate),
      );
      final owner = fixture.maps;
      final document = owner.active!;
      final session = fixture.session.state.project!;
      final file = await mapFile(fixture);
      final before = (await tester.runAsync(file.readAsBytes))!;
      document.commit(document.current.copyWith(name: 'Brouillon après refus'));
      owner.notify();
      await goHome(tester);
      await fixture.submitCreation(16, name: 'Projet B');
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Enregistrer'),
        ),
      );
      await pumpIo(tester, frames: 12);
      expect(port.writes, 1);
      expect(fixture.session.state.project, same(session));
      expect(fixture.maps, same(owner));
      expect(owner.active, same(document));
      expect(document.current.name, 'Brouillon après refus');
      expect(document.dirty, isTrue);
      expect(document.canUndo, isTrue);
      expect(document.error, 'Écriture refusée pour la recette');
      expect(await tester.runAsync(file.readAsBytes), orderedEquals(before));
      expect(fixture.parent.listSync().whereType<Directory>().length, 2);
      expect(find.textContaining('Projet créé et conservé'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('creation-close')));
      await pumpIo(tester, frames: 8);
      expect(fixture.session.state.project, same(session));
      expect(document.dirty, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
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
