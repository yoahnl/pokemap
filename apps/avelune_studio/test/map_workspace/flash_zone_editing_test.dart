import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_zone_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const area = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 4, height: 3),
);

void main() {
  test('the native zone canvas offers darkness as a typed gameplay kind', () {
    expect(
      studioGameplayZoneKinds.map((kind) => kind.name),
      contains('fieldAction'),
    );
  });
  test('Studio darkness create, edit, save and cold reopen preserve the native zone', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'studio-flash-editing-',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    final project = workspaceProject.copyWith(maps: [workspaceEntries.first]);
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${root.path}/a.json')
        .writeAsString(jsonEncode(workspaceMap('a').toJson()));
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Flash',
      directoryPath: root.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final loadedProject = await adapter.loadProject(session);
    final base = await adapter.loadMap(session, loadedProject.maps.single);
    final document = EditableMapDocument(base);
    final commands = GameplayZoneEditingCommands(document, loadedProject);
    final zone = commands.place(GameplayZoneKind.fieldAction, area);
    expect(zone.fieldAction!.darkness.opacity, .7);
    commands.updateDarkness(zone.id, opacity: .85);
    final edited = document.current;
    document.restore(redo: false);
    expect(
      document.current.gameplayZones.single.fieldAction!.darkness.opacity,
      .7,
    );
    document.restore(redo: true);
    expect(document.current, edited);
    final revision = await adapter.saveMap(session, base, document.current);
    document.acceptSave(document.current, revision);
    final cold = LocalMapWorkspaceAdapter();
    final coldProject = await cold.loadProject(session);
    final reopened = await cold.loadMap(session, coldProject.maps.single);
    expect(reopened.map, edited);
    final second = EditableMapDocument(reopened);
    final secondCommands = GameplayZoneEditingCommands(second, coldProject);
    secondCommands.retype(zone.id, GameplayZoneKind.hazard);
    expect(second.current.gameplayZones.single.fieldAction, isNull);
    second.restore(redo: false);
    expect(second.current, edited);
    expect(
      () => commands.updateDarkness(zone.id, opacity: 1),
      throwsA(isA<Exception>()),
    );
    expect(document.current, edited);
  });
  testWidgets(
    'an automatic terrain zone explains why Flash needs an independent rectangle',
    (tester) async {
      const generated = MapGameplayZone(
        id: 'generated',
        kind: GameplayZoneKind.encounter,
        area: area,
        encounter: EncounterZonePayload(),
        smartTileProvenance: SmartTileGameplayZoneProvenance(
          smartTileLayerId: 'grass',
          smartTilePresetId: 'forest',
          materialId: 'grass',
          behaviorKey: 'encounter.walk',
        ),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a').copyWith(gameplayZones: [generated]),
          revision: 'initial',
          mapId: 'a',
        ),
      );
      final before = document.current;
      final commands = GameplayZoneEditingCommands(document, workspaceProject);
      expect(
        commands.availableKindsFor(generated),
        isNot(contains(GameplayZoneKind.fieldAction)),
      );
      expect(
        () => commands.retype(generated.id, GameplayZoneKind.fieldAction),
        throwsA(isA<ValidationException>()),
      );
      expect(document.current, before);
      expect(
        document.current.gameplayZones.single.smartTileProvenance,
        generated.smartTileProvenance,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapZoneInspector(
                document: document,
                project: workspaceProject,
                zone: generated,
                onChanged: () {},
                onDeleted: () {},
              ),
            ),
          ),
        ),
      );
      expect(
        find.text(
          'Cette zone suit un terrain automatique. Dessinez une zone indépendante pour utiliser Flash.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<GameplayZoneKind>));
      await tester.pumpAndSettle();
      expect(find.text('Zone sombre (Flash · 2D)'), findsNothing);
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(document.current, before);
      expect(document.dirty, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'the real inspector lets an author choose Flash and edit darkness without JSON',
    (tester) async {
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'initial',
          mapId: 'a',
        ),
      );
      final commands = GameplayZoneEditingCommands(document, workspaceProject);
      final zone = commands.place(GameplayZoneKind.encounter, area);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => MapZoneInspector(
                  document: document,
                  project: workspaceProject,
                  zone: commands.selected(zone.id)!,
                  onChanged: () => setState(() {}),
                  onDeleted: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DropdownButtonFormField<GameplayZoneKind>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zone sombre (Flash · 2D)').last);
      await tester.pumpAndSettle();
      expect(
        document.current.gameplayZones.single.kind,
        GameplayZoneKind.fieldAction,
      );
      expect(find.textContaining('L’éclairage dure'), findsOneWidget);
      expect(find.textContaining('Le voile le plus sombre'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('85 %').last);
      await tester.pumpAndSettle();
      expect(
        document.current.gameplayZones.single.fieldAction!.darkness.opacity,
        .85,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
