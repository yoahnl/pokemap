import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/use_cases/gameplay_zone_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/gameplay_zone_properties_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

const _zone = MapGameplayZone(
  id: 'ice',
  name: 'Patinoire',
  kind: GameplayZoneKind.movementEffect,
  area: MapRect(pos: GridPos(x: 1, y: 1), size: GridSize(width: 3, height: 3)),
  movementEffect: MovementEffectZonePayload(movementCost: 3),
);
final _map = MapData(
  id: 'cave',
  name: 'Cave',
  size: const GridSize(width: 8, height: 8),
  gameplayZones: const [_zone],
  layers: [MapLayer.tile(id: 'art', name: 'Décors', cells: List.filled(64, 0))],
);
const _project = ProjectManifest(
  name: 'Glissade',
  tilesets: [],
  maps: [ProjectMapEntry(id: 'cave', name: 'Cave', relativePath: 'cave.json')],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('editing a slide keeps the existing trimmed zone ID behavior', () {
    final updated = UpdateGameplayZoneOnMapUseCase().execute(
      _map,
      manifest: _project,
      zoneId: 'ice',
      id: '  ice-renamed  ',
      movementEffect: _zone.movementEffect,
    );
    expect(updated.gameplayZones.single.id, 'ice-renamed');
    expect(updated.gameplayZones.single.movementEffect, _zone.movementEffect);
    expect(updated.layers, _map.layers);
  });

  test(
    'editor adapter plans, applies and cold reopens the typed slide action',
    () async {
      final root = await Directory.systemTemp.createTemp('slide-editor-');
      addTearDown(() => root.delete(recursive: true));
      final initial = _map.copyWith(gameplayZones: []);
      final file = File('${root.path}/cave.json');
      await file.writeAsString(jsonEncode(initial.toJson()));
      await File(
        '${root.path}/project.json',
      ).writeAsString(jsonEncode(_project.toJson()));
      const reader = LocalProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: _RootLocator(root.path),
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);
      var revision = (await queries.open(root.path)).snapshotRevision;
      for (final (action, parameters) in [
        (
          'gameplay_zone.create',
          <String, Object?>{
            'mapId': 'cave',
            'zone': _zone
                .copyWith(
                  movementEffect: const MovementEffectZonePayload(
                    effectKind: MovementEffectZoneKind.movementCost,
                    movementCost: 3,
                  ),
                )
                .toJson(),
          },
        ),
        (
          'gameplay_zone.set_movement_effect_payload',
          <String, Object?>{
            'mapId': 'cave',
            'zoneId': 'ice',
            'payload': _zone.movementEffect!.toJson(),
          },
        ),
      ]) {
        final before = await file.readAsBytes();
        final plan = await mutations.plan(
          root.path,
          actionId: action,
          parameters: Map<String, Object?>.from(
            jsonDecode(jsonEncode(parameters)) as Map,
          ),
          idempotencyKey: action,
          requestId: action,
          expectedRevision: revision,
        );
        expect(await file.readAsBytes(), before);
        final applied = await mutations.apply(plan, operationId: action);
        expect(applied.receipt.status, AuthoringReceiptStatus.applied);
        revision = applied.snapshotRevision!;
      }
      final beforeFailure = await file.readAsBytes();
      await expectLater(
        mutations.plan(
          root.path,
          actionId: 'gameplay_zone.set_movement_effect_payload',
          parameters: {
            'mapId': 'cave',
            'zoneId': 'ice',
            'payload': {
              'effectKind': 'slide',
              'movementCost': 3,
              'direction': 'north',
            },
          },
          idempotencyKey: 'invalid',
          requestId: 'invalid',
          expectedRevision: revision,
        ),
        throwsA(isA<Exception>()),
      );
      expect(await file.readAsBytes(), beforeFailure);
      await mutations.closeAll();
      await queries.closeAll();
      final coldQueries = AuthoringQueryAdapter(fileReader: reader);
      addTearDown(coldQueries.closeAll);
      final cold = await coldQueries.open(root.path);
      final queried = cold.query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: ['cave'],
        ),
      );
      expect(
        MapData.fromJson(
          Map<String, dynamic>.from((queried['items'] as List).single as Map),
        ),
        _map,
      );
    },
  );

  testWidgets('editor slide hides cost and preserves the typed zone at save', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/tmp/slide-panel',
      project: _project,
      activeMap: _map,
      selectedGameplayZoneId: 'ice',
    );
    await _pump(tester, container);
    expect(find.textContaining('direction d’entrée'), findsOneWidget);
    expect(find.text('Movement Cost'), findsNothing);
    await tester.ensureVisible(find.text('Save Zone'));
    await tester.tap(find.text('Save Zone'));
    await tester.pump();
    expect(container.read(editorNotifierProvider).activeMap, _map);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor movement cost keeps the existing cost field', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/tmp/slide-panel',
      project: _project,
      activeMap: _map.copyWith(
        gameplayZones: [
          _zone.copyWith(
            movementEffect: const MovementEffectZonePayload(
              effectKind: MovementEffectZoneKind.movementCost,
              movementCost: 3,
            ),
          ),
        ],
      ),
      selectedGameplayZoneId: 'ice',
    );
    await _pump(tester, container);
    expect(find.text('Movement Cost'), findsOneWidget);
    expect(find.textContaining('direction d’entrée'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 2400);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: MaterialApp(
          home: Material(
            child: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 2200,
                child: GameplayZonePropertiesPanel(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _RootLocator implements EditorProjectRootLocator {
  const _RootLocator(this.root);
  final String root;

  @override
  Future<String> locateForResource(String resourcePath) async => root;
}
