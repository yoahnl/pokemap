import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

MapGameplayZone _fixture() => MapGameplayZone.fromJson(
  jsonDecode(
    File('../../packages/map_core/test/fixtures/whirlpool_field_zone.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>,
);

MapData _map(MapGameplayZone zone) => MapData(
  id: 'whirls',
  name: 'Tourbillon',
  size: const GridSize(width: 8, height: 8),
  layers: [MapLayer.tile(id: 'ground', name: 'Sol', cells: List.filled(64, 0))],
  gameplayZones: [
    const MapGameplayZone(
      id: 'water',
      kind: GameplayZoneKind.movement,
      area: MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 8, height: 8),
      ),
      movement: MovementZonePayload(requiredMode: MovementMode.surf),
    ),
    zone,
  ],
);

void main() {
  testWidgets(
    'Whirlpool configuration preserves route, mandatory Surf, undo and cold reopen',
    (tester) async {
      final parent = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
      )..createSync(recursive: true);
      final temporary = parent.createTempSync('studio-whirlpool-');
      final root = Directory(temporary.resolveSymbolicLinksSync());
      addTearDown(() => root.deleteSync(recursive: true));
      final fixture = _fixture();
      final seed = fixture.copyWith(
        fieldAction: const FieldActionZonePayload(
          actionKind: FieldActionZoneKind.darkness,
          darkness: DarknessZonePayload(opacity: .7),
        ),
      );
      final initial = _map(seed);
      const project = ProjectManifest(
        name: 'Tourbillon',
        tilesets: [],
        maps: [
          ProjectMapEntry(
            id: 'whirls',
            name: 'Tourbillon',
            relativePath: 'whirls.json',
          ),
        ],
        badges: [
          BadgeDefinition(
            id: 'badge.jet',
            label: 'Badge Jet',
            fieldAbilityUnlock: FieldAbility.whirlpool,
          ),
        ],
      );
      File('${root.path}/project.json')
          .writeAsStringSync(jsonEncode(project.toJson()));
      File('${root.path}/whirls.json')
          .writeAsStringSync(jsonEncode(initial.toJson()));
      final session = ProjectSession(
        sessionId: root.path,
        name: 'Tourbillon',
        directoryPath: root.path,
      );
      final adapter = LocalMapWorkspaceAdapter();
      final loaded = (await tester.runAsync(
        () => adapter.loadProject(session),
      ))!;
      final base = (await tester.runAsync(
        () => adapter.loadMap(session, loaded.maps.single),
      ))!;
      final document = EditableMapDocument(base);
      GameplayZoneEditingCommands(
        document,
        loaded,
      ).configureWhirlpool(fixture.id);
      expect(document.current.gameplayZones.last, fixture);
      final edited = document.current;
      expect(
        () => GameplayZoneEditingCommands(document, loaded).configureWhirlpool(
          fixture.id,
          direction: MapConnectionDirection.east,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(document.current, edited);
      document.restore(redo: false);
      expect(document.current, initial);
      document.restore(redo: true);
      expect(document.current, edited);
      final reopened = (await tester.runAsync(() async {
        await adapter.saveMap(session, base, edited);
        final cold = LocalMapWorkspaceAdapter();
        final coldProject = await cold.loadProject(session);
        return cold.loadMap(session, coldProject.maps.single);
      }))!;
      expect(reopened.map, edited);
      expect(
        reopened.map.gameplayZones.last.fieldAction!.toJson(),
        fixture.fieldAction!.toJson(),
      );
      await tester.runAsync(() async {
        final file = File('${root.path}/whirls.json');
        await file.writeAsString(
          jsonEncode(edited.copyWith(name: 'Externe').toJson()),
        );
        final external = await file.readAsBytes();
        await expectLater(
          adapter.saveMap(session, base, edited),
          throwsA(
            isA<MapWorkspaceFailure>().having(
              (error) => error.problem,
              'problem',
              MapWorkspaceProblem.conflict,
            ),
          ),
        );
        expect(await file.readAsBytes(), external);
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Studio paints Whirlpool entry path and exit using the canonical fixture',
    (tester) async {
      final zone = _fixture();
      final before = _map(
        zone.copyWith(
          fieldAction: const FieldActionZonePayload(
            actionKind: FieldActionZoneKind.darkness,
            darkness: DarknessZonePayload(opacity: .7),
          ),
        ),
      );
      Future<List<int>> pixels(MapData map) async {
        final recorder = ui.PictureRecorder();
        MapEditingOverlay(
          map: map,
          project: const ProjectManifest(
            name: 'Tourbillon',
            tilesets: [],
            maps: [],
          ),
          selected: null,
          cellWidth: 32,
          cellHeight: 32,
          grid: false,
          color: ThemeData().colorScheme.primary,
        ).paint(Canvas(recorder), const Size(256, 256));
        final picture = recorder.endRecording();
        final image = await picture.toImage(256, 256);
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        return data;
      }

      await tester.runAsync(
        () async =>
            expect(await pixels(_map(zone)), isNot(await pixels(before))),
      );
    },
  );
}
