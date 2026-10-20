import 'dart:async';
import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/cinematic_adapter_fixture.dart';
import '../support/m2_ui_fixture.dart' show WidgetResourcePort, pumpIo;
import '../support/widget_resource_journey_map_port.dart';

void main() {
  testWidgets('all existing engine condition sources have guided choices', (
    tester,
  ) async {
    final changes = <SceneConditionSource>[];
    await _pump(tester, changes: changes);
    expect(
      _select(tester, 'Source de la condition').options.keys,
      containsAll([
        'badge',
        'inventoryItem',
        'playerAtEntityAnchor',
        'factLikeStoryFlag',
        'mapEventInstanceBoolean',
      ]),
    );
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    (SceneConditionSourceKind.badge, 'badge-a', 'Premier badge'),
    (SceneConditionSourceKind.factLikeStoryFlag, 'DOOR_OPEN', 'Porte ouverte'),
    (SceneConditionSourceKind.factLikeStoryFlag, 'gate-open', 'Passage ouvert'),
  ]) {
    testWidgets(
      '${entry.$1.name} edits both expectations through guided choices',
      (tester) async {
        final changes = <SceneConditionSource>[];
        final source = SceneConditionSource(
          sourceKind: entry.$1,
          sourceId: entry.$2,
          operator: SceneConditionOperator.isFalse,
          debugTechnicalLabel: 'existing-debug',
        );
        await _pump(tester, source: source, changes: changes);
        expect(
          find.textContaining('Condition avancée conservée'),
          findsNothing,
        );
        expect(_select(tester, 'Référence').options[entry.$2], entry.$3);
        expect(_booleanSelect(tester).value, 'false');
        expect(find.byType(TextField), findsNothing);
        expect(changes, isEmpty);
        for (final expected in [true, false]) {
          await _choose(tester, _booleanSelect(tester).label, '$expected');
          expect(changes, hasLength(expected ? 0 : 1));
          await _apply(tester);
          expect(changes.last.sourceKind, entry.$1);
          expect(changes.last.sourceId, entry.$2);
          expect(
            changes.last.operator,
            expected
                ? SceneConditionOperator.isTrue
                : SceneConditionOperator.isFalse,
          );
          expect(changes.last.field, isNull);
          expect(changes.last.value, isNull);
          expect(changes.last.debugTechnicalLabel, 'existing-debug');
          final reopened = SceneConditionSource.fromJson(changes.last.toJson());
          await _pump(tester, source: reopened, changes: changes);
          expect(_select(tester, 'Référence').value, entry.$2);
          expect(_booleanSelect(tester).value, '$expected');
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'missing and ambiguous badges or story flags preserve the source',
    (tester) async {
      for (final project in [
        _project(badges: []),
        _project(
          badges: [
            const BadgeDefinition(id: 'badge-a', label: 'Premier badge'),
            const BadgeDefinition(id: 'badge-a', label: 'Doublon'),
          ],
        ),
      ]) {
        final changes = <SceneConditionSource>[];
        await _pump(
          tester,
          project: project,
          changes: changes,
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.badge,
            sourceId: 'badge-a',
            operator: SceneConditionOperator.isFalse,
          ),
        );
        expect(
          _select(tester, 'Référence').options,
          isNot(contains('badge-a')),
        );
        expect(_applyButton(tester).onPressed, isNull);
        expect(changes, isEmpty);
      }
      for (final facts in [
        <NarrativeFactDefinition>[],
        [
          NarrativeFactDefinition(
            id: 'first',
            label: 'Un',
            legacyFlagName: 'DOOR_OPEN',
          ),
          NarrativeFactDefinition(
            id: 'second',
            label: 'Deux',
            legacyFlagName: 'DOOR_OPEN',
          ),
        ],
        [
          NarrativeFactDefinition(
            id: 'first',
            label: 'Un',
            legacyFlagName: 'DOOR_OPEN',
          ),
          NarrativeFactDefinition(id: 'DOOR_OPEN', label: 'Deux'),
        ],
        [
          NarrativeFactDefinition(
            id: 'duplicate',
            label: 'Un',
            legacyFlagName: 'DOOR_OPEN',
          ),
          NarrativeFactDefinition(
            id: 'duplicate',
            label: 'Deux',
            legacyFlagName: 'OTHER',
          ),
        ],
      ]) {
        final changes = <SceneConditionSource>[];
        await _pump(
          tester,
          project: _project(facts: facts),
          changes: changes,
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
            sourceId: 'DOOR_OPEN',
            operator: SceneConditionOperator.isFalse,
          ),
        );
        expect(
          _select(tester, 'Référence').options,
          isNot(contains('DOOR_OPEN')),
        );
        expect(_applyButton(tester).onPressed, isNull);
        expect(changes, isEmpty);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'blank item labels preserve the source without a build exception',
    (tester) async {
      for (final label in ['', '  ']) {
        final changes = <SceneConditionSource>[];
        await _pump(
          tester,
          changes: changes,
          source: _inventory('3'),
          loadItems: () async => {'tonic': label},
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_applyButton(tester).onPressed, isNull);
        expect(changes, isEmpty);
      }
    },
  );

  testWidgets(
    'malformed badge references cannot become applicable conditions',
    (tester) async {
      for (final badge in [
        const BadgeDefinition(id: 'badge-a', label: ''),
        const BadgeDefinition(id: 'badge-a', label: '  '),
        const BadgeDefinition(id: ' badge-a ', label: 'Premier badge'),
      ]) {
        final changes = <SceneConditionSource>[];
        await _pump(
          tester,
          changes: changes,
          project: _project(badges: [badge]),
          source: SceneConditionSource(
            sourceKind: SceneConditionSourceKind.badge,
            sourceId: badge.id,
            operator: SceneConditionOperator.isFalse,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(_select(tester, 'Référence').options, isEmpty);
        expect(_applyButton(tester).onPressed, isNull);
        expect(changes, isEmpty);
      }
    },
  );

  testWidgets('inventory keeps exact minimum quantity and both comparisons', (
    tester,
  ) async {
    final changes = <SceneConditionSource>[];
    await _pump(
      tester,
      changes: changes,
      source: _inventory('3', expected: false),
      loadItems: () async => {'tonic': 'Potion', 'ether': 'Éther'},
    );
    await tester.pumpAndSettle();
    expect(_select(tester, 'Référence').value, 'tonic');
    expect(_booleanSelect(tester).value, 'false');
    expect(_draft(tester, 'Quantité minimale').value, '3');
    expect(changes, isEmpty);
    await _enter(tester, 'Quantité minimale', '70000');
    await _choose(tester, 'Référence', 'ether');
    await _enter(tester, 'Quantité minimale', '70000');
    expect(changes, isEmpty);
    for (final expected in [false, true]) {
      await _choose(tester, _booleanSelect(tester).label, '$expected');
      await _apply(tester);
      final applied = changes.last;
      expect(applied.sourceKind, SceneConditionSourceKind.inventoryItem);
      expect(applied.sourceId, 'ether');
      expect(applied.field, 'minimumQuantity');
      expect(applied.value, '70000');
      expect(applied.inventoryQuantityThreshold, 70000);
      expect(
        applied.operator,
        expected
            ? SceneConditionOperator.isTrue
            : SceneConditionOperator.isFalse,
      );
      await _pump(
        tester,
        changes: changes,
        source: SceneConditionSource.fromJson(applied.toJson()),
        loadItems: () async => {'tonic': 'Potion', 'ether': 'Éther'},
      );
      await tester.pumpAndSettle();
      expect(_draft(tester, 'Quantité minimale').value, '70000');
      expect(_booleanSelect(tester).value, '$expected');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'inventory rejects noncanonical quantities without implicit apply',
    (tester) async {
      final changes = <SceneConditionSource>[];
      await _pump(
        tester,
        changes: changes,
        source: _inventory('1'),
        loadItems: () async => {'tonic': 'Potion'},
      );
      await tester.pumpAndSettle();
      for (final invalid in ['', '0', '-1', '1.5', '01', ' 2 ']) {
        await _enter(tester, 'Quantité minimale', invalid);
        expect(_applyButton(tester).onPressed, isNull, reason: invalid);
        expect(changes, isEmpty);
      }
      await _enter(tester, 'Quantité minimale', '2');
      expect(_applyButton(tester).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(changes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inventory missing or unavailable catalogues keep the saved item',
    (tester) async {
      for (final loader in <Future<Map<String, String>> Function()>[
        () async => {},
        () async => {'other': 'Autre objet'},
        () async => throw StateError('Ambiguous item catalogue'),
      ]) {
        final changes = <SceneConditionSource>[];
        await _pump(
          tester,
          changes: changes,
          source: _inventory('3'),
          loadItems: loader,
        );
        await tester.pumpAndSettle();
        expect(_select(tester, 'Référence').options, isNot(contains('tonic')));
        expect(_applyButton(tester).onPressed, isNull);
        expect(changes, isEmpty);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('stale inventory loads and disposed drafts cannot apply', (
    tester,
  ) async {
    final pending = Completer<Map<String, String>>();
    final changes = <SceneConditionSource>[];
    await _pump(
      tester,
      changes: changes,
      source: _inventory('3'),
      loadItems: () => pending.future,
    );
    await _pump(
      tester,
      changes: changes,
      project: _project(name: 'Other project'),
      source: _inventory('3'),
      loadItems: () async => {},
    );
    await tester.pumpAndSettle();
    pending.complete({'tonic': 'Objet périmé'});
    await tester.pumpAndSettle();
    expect(_select(tester, 'Référence').options, isEmpty);
    expect(_applyButton(tester).onPressed, isNull);
    final disposed = Completer<Map<String, String>>();
    await _pump(
      tester,
      changes: changes,
      source: _inventory('3'),
      loadItems: () => disposed.future,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    disposed.complete({'tonic': 'Objet après fermeture'});
    await tester.pump();
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map and entity pickers author an exact anchor and negation', (
    tester,
  ) async {
    final changes = <SceneConditionSource>[];
    await _pump(
      tester,
      changes: changes,
      source: SceneConditionSource.playerAtEntityAnchor(
        mapId: 'workshop',
        entityId: 'door',
        expected: false,
      ),
      loadMap: (id) async => _map(id),
    );
    await tester.pumpAndSettle();
    expect(_select(tester, 'Carte').value, 'workshop');
    expect(_select(tester, 'Référence').value, 'door');
    expect(find.byType(TextField), findsNothing);
    expect(_booleanSelect(tester).value, 'false');
    await _choose(tester, 'Carte', 'garden');
    await tester.pumpAndSettle();
    expect(_applyButton(tester).onPressed, isNull);
    await _choose(tester, 'Référence', 'guide');
    await _choose(tester, _booleanSelect(tester).label, 'true');
    expect(changes, isEmpty);
    await _apply(tester);
    expect(changes.single.mapId, 'garden');
    expect(changes.single.sourceId, 'guide');
    expect(changes.single.operator, SceneConditionOperator.isTrue);
    expect(
      changes.single.sourceKind,
      SceneConditionSourceKind.playerAtEntityAnchor,
    );
    await _pump(
      tester,
      changes: changes,
      source: SceneConditionSource.fromJson(changes.single.toJson()),
      loadMap: (id) async => _map(id),
    );
    await tester.pumpAndSettle();
    expect(_select(tester, 'Carte').value, 'garden');
    expect(_select(tester, 'Référence').value, 'guide');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'local booleans use concrete entity ownership and canonical keys',
    (tester) async {
      final changes = <SceneConditionSource>[];
      await _pump(
        tester,
        changes: changes,
        source: SceneConditionSource.mapEventInstanceBoolean(
          mapId: 'workshop',
          eventId: 'door',
          key: 'A',
          expected: false,
          debugTechnicalLabel: 'existing-debug',
        ),
        loadMap: (id) async => _map(id),
      );
      await tester.pumpAndSettle();
      expect(_select(tester, 'Référence').value, 'door');
      expect(_draft(tester, 'Nom de l’état local').value, 'A');
      expect(_booleanSelect(tester).value, 'false');
      await _apply(tester);
      expect(changes.single.debugTechnicalLabel, 'existing-debug');
      for (final invalid in ['', ' ', ' A ']) {
        await _enter(tester, 'Nom de l’état local', invalid);
        expect(_applyButton(tester).onPressed, isNull);
      }
      await _enter(tester, 'Nom de l’état local', 'gate-open');
      await _choose(tester, _booleanSelect(tester).label, 'true');
      expect(changes, hasLength(1));
      await _apply(tester);
      expect(
        changes.last.sourceKind,
        SceneConditionSourceKind.mapEventInstanceBoolean,
      );
      expect(changes.last.mapId, 'workshop');
      expect(changes.last.sourceId, 'door');
      expect(changes.last.key, 'gate-open');
      expect(changes.last.operator, SceneConditionOperator.isTrue);
      expect(changes.last.debugTechnicalLabel, isNull);
      await _pump(
        tester,
        changes: changes,
        source: SceneConditionSource.fromJson(changes.last.toJson()),
        loadMap: (id) async => _map(id),
      );
      await tester.pumpAndSettle();
      expect(_draft(tester, 'Nom de l’état local').value, 'gate-open');
      expect(_booleanSelect(tester).value, 'true');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing ambiguous and out of bounds map owners cannot be applied',
    (tester) async {
      for (final map in [
        _map('workshop', entities: []),
        _map(
          'workshop',
          entities: [
            const MapEntity(
              id: 'door',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 1, y: 1),
            ),
            const MapEntity(
              id: 'door',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 2, y: 1),
            ),
          ],
        ),
        _map(
          'workshop',
          entities: [
            const MapEntity(
              id: 'door',
              kind: MapEntityKind.sign,
              pos: GridPos(x: 9, y: 1),
            ),
          ],
        ),
      ]) {
        final changes = <SceneConditionSource>[];
        await _pump(
          tester,
          changes: changes,
          source: SceneConditionSource.playerAtEntityAnchor(
            mapId: 'workshop',
            entityId: 'door',
          ),
          loadMap: (_) async => map,
        );
        await tester.pumpAndSettle();
        expect(_select(tester, 'Référence').options, isNot(contains('door')));
        expect(_applyButton(tester).onPressed, isNull);
        expect(changes, isEmpty);
      }
      final changes = <SceneConditionSource>[];
      await _pump(
        tester,
        changes: changes,
        source: SceneConditionSource.mapEventInstanceBoolean(
          mapId: 'workshop',
          eventId: 'door',
          key: 'A',
        ),
        loadMap: (_) async => _map('workshop', entities: []),
      );
      await tester.pumpAndSettle();
      expect(_applyButton(tester).onPressed, isNull);
      expect(changes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stale map responses and cancellation cannot replace a map owner',
    (tester) async {
      final pending = Completer<MapData>();
      final changes = <SceneConditionSource>[];
      await _pump(
        tester,
        changes: changes,
        source: SceneConditionSource.playerAtEntityAnchor(
          mapId: 'workshop',
          entityId: 'door',
        ),
        loadMap: (_) => pending.future,
      );
      await _pump(
        tester,
        changes: changes,
        project: _project(name: 'Other project'),
        source: SceneConditionSource.playerAtEntityAnchor(
          mapId: 'garden',
          entityId: 'guide',
        ),
        loadMap: (id) async => _map(id),
      );
      await tester.pumpAndSettle();
      pending.complete(_map('workshop'));
      await tester.pumpAndSettle();
      expect(_select(tester, 'Carte').value, 'garden');
      expect(_select(tester, 'Référence').options, contains('guide'));
      expect(_select(tester, 'Référence').options, isNot(contains('door')));
      final disposed = Completer<MapData>();
      await _pump(
        tester,
        changes: changes,
        source: SceneConditionSource.playerAtEntityAnchor(
          mapId: 'workshop',
          entityId: 'door',
        ),
        loadMap: (_) => disposed.future,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      disposed.complete(_map('workshop'));
      await tester.pump();
      expect(changes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'missing or ambiguous map descriptors cannot trigger a map load',
    (tester) async {
      final original = _project();
      for (final maps in <List<ProjectMapEntry>>[
        [],
        [original.maps.first, original.maps.first],
      ]) {
        var loads = 0;
        final changes = <SceneConditionSource>[];
        await _pump(
          tester,
          changes: changes,
          project: original.copyWith(maps: maps),
          source: SceneConditionSource.playerAtEntityAnchor(
            mapId: 'workshop',
            entityId: 'door',
          ),
          loadMap: (id) async {
            loads++;
            return _map(id);
          },
        );
        await tester.pumpAndSettle();
        expect(_select(tester, 'Carte').options, isNot(contains('workshop')));
        expect(_applyButton(tester).onPressed, isNull);
        expect(loads, 0);
        expect(changes, isEmpty);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a map loader cannot silently replace the requested map identity',
    (tester) async {
      final changes = <SceneConditionSource>[];
      await _pump(
        tester,
        changes: changes,
        source: SceneConditionSource.playerAtEntityAnchor(
          mapId: 'workshop',
          entityId: 'door',
        ),
        loadMap: (_) async => _map('garden'),
      );
      await tester.pumpAndSettle();
      expect(_select(tester, 'Carte').value, 'workshop');
      expect(_select(tester, 'Référence').options, isEmpty);
      expect(_applyButton(tester).onPressed, isNull);
      expect(changes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('changing condition family invalidates a pending item load', (
    tester,
  ) async {
    final pending = Completer<Map<String, String>>();
    final changes = <SceneConditionSource>[];
    await _pump(
      tester,
      changes: changes,
      source: _inventory('3'),
      loadItems: () => pending.future,
    );
    await _choose(tester, 'Source de la condition', 'badge');
    await _choose(tester, 'Référence', 'badge-a');
    pending.complete({'tonic': 'Objet périmé'});
    await tester.pumpAndSettle();
    expect(_select(tester, 'Source de la condition').value, 'badge');
    expect(_select(tester, 'Référence').options, {'badge-a': 'Premier badge'});
    expect(changes, isEmpty);
    await _apply(tester);
    expect(changes.single.sourceKind, SceneConditionSourceKind.badge);
    expect(changes.single.sourceId, 'badge-a');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '3D keeps saved map conditions and exposes other guided families',
    (tester) async {
      final changes = <SceneConditionSource>[];
      var loads = 0;
      await _pump(
        tester,
        changes: changes,
        project: _project().copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        ),
        source: SceneConditionSource.playerAtEntityAnchor(
          mapId: 'workshop',
          entityId: 'door',
        ),
        loadMap: (id) async {
          loads++;
          return _map(id);
        },
      );
      final families = _select(tester, 'Source de la condition').options;
      expect(families, isNot(contains('playerAtEntityAnchor')));
      expect(families, isNot(contains('mapEventInstanceBoolean')));
      expect(
        families.keys,
        containsAll(['badge', 'inventoryItem', 'factLikeStoryFlag']),
      );
      expect(_applyButton(tester).onPressed, isNull);
      expect(changes, isEmpty);
      expect(loads, 0);
      expect(
        find.textContaining('Condition avancée conservée'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final initial in [
    SceneConditionSource(
      sourceKind: SceneConditionSourceKind.badge,
      sourceId: 'badge-a',
      operator: SceneConditionOperator.isTrue,
    ),
    _inventory('1'),
    SceneConditionSource(
      sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
      sourceId: 'gate-open',
      operator: SceneConditionOperator.isTrue,
    ),
    SceneConditionSource.playerAtEntityAnchor(
      mapId: 'workshop',
      entityId: 'door',
    ),
    SceneConditionSource.mapEventInstanceBoolean(
      mapId: 'workshop',
      eventId: 'door',
      key: 'A',
    ),
  ]) {
    testWidgets(
      'real scene page publishes ${initial.sourceKind.name} with undo redo and cold reopen',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final original = SceneAsset(
          id: 'conditions',
          name: 'Conditions',
          description: 'Condition guidée persistée',
          tags: ['condition-qa'],
          graph: _scene(initial).graph,
          layout: SceneGraphLayout(
            nodeLayouts: [
              SceneNodeLayout(nodeId: 'start', x: 40, y: 80),
              SceneNodeLayout(nodeId: 'check', x: 320, y: 80),
              SceneNodeLayout(nodeId: 'end', x: 600, y: 80),
            ],
            edgeLayouts: [
              SceneEdgeLayout(
                edgeId: 'yes',
                controlPoints: [SceneLayoutPoint(x: 560, y: 40)],
              ),
            ],
          ),
          metadata: {'fixture': 'condition-source-forms'},
        );
        final fixture = (await tester.runAsync(() async {
          final fixture = await CinematicAdapterFixture.create();
          final project = _project(name: 'Condition host');
          await fixture.writeManifest(
            project.copyWith(
              scenes: [original],
              pokemon: project.pokemon.copyWith(
                catalogFiles: {
                  ...project.pokemon.catalogFiles,
                  'items': 'data/items.json',
                },
              ),
            ),
          );
          for (final entry in project.maps) {
            final map = _map(
              entry.id,
              entities: [
                MapEntity(
                  id: 'door',
                  kind: MapEntityKind.sign,
                  pos: GridPos(x: entry.id == 'workshop' ? 1 : 2, y: 1),
                ),
              ],
            );
            final file = fixture.file(entry.relativePath);
            await file.parent.create(recursive: true);
            await file.writeAsString(jsonEncode(map.toJson()));
          }
          final items = fixture.file('data/items.json');
          await items.parent.create(recursive: true);
          await items.writeAsString(
            jsonEncode(
              encodeProjectItemCatalog(
                const ProjectItemCatalog(
                  schemaVersion: 1,
                  entries: [
                    ProjectItemDefinition(
                      id: 'tonic',
                      displayName: 'Potion',
                      pocketId: 'custom',
                    ),
                    ProjectItemDefinition(
                      id: 'ether',
                      displayName: 'Éther',
                      pocketId: 'custom',
                    ),
                  ],
                ),
              ),
            ),
          );
          return fixture;
        }))!;
        addTearDown(fixture.dispose);
        final baseline = (await tester.runAsync(fixture.readManifest))!;
        final projectBytes = (await tester.runAsync(
          () => fixture.file('project.json').readAsBytes(),
        ))!;
        final protectedBytes = (await tester.runAsync(
          () async => {
            for (final path in [
              ...baseline.maps.map((entry) => entry.relativePath),
              'data/items.json',
            ])
              path: await fixture.file(path).readAsBytes(),
          },
        ))!;
        final mapPort = WidgetResourceJourneyMapPort(fixture.maps, tester);
        final maps = MapWorkspaceController(fixture.session, mapPort);
        await tester.runAsync(maps.initialize);
        expect(maps.error, isNull);
        mapPort.active = true;
        addTearDown(maps.dispose);
        final port = _WidgetScenePort(
          LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
          tester,
        );
        final scenes = SceneWorkspaceController(maps, port, changed: () {});
        addTearDown(scenes.dispose);
        expect(scenes.open(original.id), isTrue);
        final edit = scenes.active!;
        final pokemon = LocalPokemonWorkspaceAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        );
        addTearDown(pokemon.dispose);
        var itemLoads = 0;
        final views = SceneBuilderViewStore();
        views.forScene(original.id).nodeId = 'check';
        addTearDown(views.dispose);
        Widget app(
          SceneWorkspaceController controller,
          SceneBuilderViewStore views,
          LocalPokemonWorkspaceAdapter pokemon,
        ) => MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SceneBuilderPage(
              controller: controller,
              views: views,
              onBack: () {},
              loadItems: () async {
                itemLoads++;
                final index = (await WidgetResourcePort.serial(
                  tester,
                  pokemon.loadIndex,
                ))!;
                expect(index.enabled, isTrue);
                expect(index.itemCatalog, isNotNull);
                return {
                  for (final item in index.itemCatalog!.entries)
                    item.id: item.displayName,
                };
              },
            ),
          ),
        );
        await tester.pumpWidget(app(scenes, views, pokemon));
        await pumpIo(tester);
        switch (initial.sourceKind) {
          case SceneConditionSourceKind.badge:
            await _choose(tester, 'Référence', 'badge-a');
          case SceneConditionSourceKind.inventoryItem:
            expect(_select(tester, 'Référence').options['ether'], 'Éther');
            expect(itemLoads, greaterThan(0));
            await _choose(tester, 'Référence', 'ether');
            for (final invalid in ['0', '01']) {
              await _enter(tester, 'Quantité minimale', invalid);
              expect(_applyButton(tester).onPressed, isNull);
              expect(edit.dirty, isFalse);
            }
            await _enter(tester, 'Quantité minimale', '3');
          case SceneConditionSourceKind.factLikeStoryFlag:
            expect(
              _select(tester, 'Référence').options['DOOR_OPEN'],
              'Porte ouverte',
            );
            expect(
              _select(tester, 'Référence').options,
              isNot(contains('door-fact')),
            );
            await _choose(tester, 'Référence', 'DOOR_OPEN');
          case SceneConditionSourceKind.playerAtEntityAnchor:
          case SceneConditionSourceKind.mapEventInstanceBoolean:
            await _choose(tester, 'Carte', 'garden');
            await pumpIo(tester);
            await _choose(tester, 'Référence', 'door');
            if (initial.sourceKind ==
                SceneConditionSourceKind.mapEventInstanceBoolean) {
              for (final invalid in ['', ' A ']) {
                await _enter(tester, 'Nom de l’état local', invalid);
                expect(_applyButton(tester).onPressed, isNull);
                expect(edit.dirty, isFalse);
              }
              await _enter(tester, 'Nom de l’état local', 'gate-open');
            }
          default:
            fail('Unsupported fixture condition family');
        }
        await _choose(tester, _booleanSelect(tester).label, 'false');
        expect(edit.current, original);
        expect(edit.dirty, isFalse);
        expect(port.writes, 0);
        expect(
          (await tester.runAsync(
            () => fixture.file('project.json').readAsBytes(),
          ))!,
          projectBytes,
        );
        await _apply(tester);
        await pumpIo(tester);
        expect(edit.undoCount, 1);
        expect(edit.dirty, isTrue);
        expect(port.writes, 0);
        expect(
          (await tester.runAsync(
            () => fixture.file('project.json').readAsBytes(),
          ))!,
          projectBytes,
        );
        final edited = edit.current;
        final expectedId = switch (initial.sourceKind) {
          SceneConditionSourceKind.badge => 'badge-a',
          SceneConditionSourceKind.inventoryItem => 'ether',
          SceneConditionSourceKind.factLikeStoryFlag => 'DOOR_OPEN',
          _ => 'door',
        };
        final source = _conditionSource(edited);
        expect(source.sourceKind, initial.sourceKind);
        expect(source.sourceId, expectedId);
        expect(source.operator, SceneConditionOperator.isFalse);
        expect(source.mapId, initial.mapId == null ? null : 'garden');
        expect(
          source.field,
          initial.sourceKind == SceneConditionSourceKind.inventoryItem
              ? 'minimumQuantity'
              : null,
        );
        expect(
          source.value,
          initial.sourceKind == SceneConditionSourceKind.inventoryItem
              ? '3'
              : null,
        );
        expect(
          source.key,
          initial.sourceKind == SceneConditionSourceKind.mapEventInstanceBoolean
              ? 'gate-open'
              : null,
        );
        expect(source.label, isNotEmpty);
        await tester.tap(find.byKey(const ValueKey('Annuler la scène')));
        await pumpIo(tester);
        expect(edit.current, original);
        expect(edit.dirty, isFalse);
        await tester.tap(find.byKey(const ValueKey('Rétablir la scène')));
        await pumpIo(tester);
        expect(edit.current, edited);
        expect(edit.dirty, isTrue);
        expect(port.writes, 0);
        expect(
          (await tester.runAsync(
            () => fixture.file('project.json').readAsBytes(),
          ))!,
          projectBytes,
        );
        await tester.tap(find.text('Enregistrer'));
        await pumpIo(tester);
        expect(port.writes, 1);
        expect(scenes.error, isNull);
        expect(edit.error, isNull);
        expect(edit.dirty, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        scenes.dispose();
        maps.dispose();
        final coldAdapter = LocalMapWorkspaceAdapter();
        final coldMapPort = WidgetResourceJourneyMapPort(coldAdapter, tester);
        final coldMaps = MapWorkspaceController(fixture.session, coldMapPort);
        addTearDown(coldMaps.dispose);
        await tester.runAsync(coldMaps.initialize);
        expect(coldMaps.error, isNull);
        coldMapPort.active = true;
        final coldScenes = SceneWorkspaceController(
          coldMaps,
          LocalSceneAdapter(session: fixture.session, mapAdapter: coldAdapter),
          changed: () {},
        );
        addTearDown(coldScenes.dispose);
        expect(coldScenes.open(original.id), isTrue);
        final reopened = coldScenes.active!.current;
        final coldPokemon = LocalPokemonWorkspaceAdapter(
          session: fixture.session,
          mapAdapter: coldAdapter,
        );
        addTearDown(coldPokemon.dispose);
        final coldViews = SceneBuilderViewStore();
        coldViews.forScene(original.id).nodeId = 'check';
        addTearDown(coldViews.dispose);
        await tester.pumpWidget(app(coldScenes, coldViews, coldPokemon));
        await pumpIo(tester);
        expect(_select(tester, 'Référence').value, expectedId);
        expect(_booleanSelect(tester).value, 'false');
        if (initial.mapId != null) {
          expect(_select(tester, 'Carte').value, 'garden');
        }
        if (initial.sourceKind == SceneConditionSourceKind.inventoryItem) {
          expect(_draft(tester, 'Quantité minimale').value, '3');
        }
        if (initial.sourceKind ==
            SceneConditionSourceKind.mapEventInstanceBoolean) {
          expect(_draft(tester, 'Nom de l’état local').value, 'gate-open');
        }
        expect(coldScenes.dirty, isFalse);
        expect(reopened, edited);
        expect(_conditionSource(reopened).toJson(), source.toJson());
        expect(reopened.metadata, original.metadata);
        expect(reopened.description, original.description);
        expect(reopened.tags, original.tags);
        expect(reopened.layout, original.layout);
        expect(reopened.graph.edges, original.graph.edges);
        expect(
          reopened.graph.nodes.where((node) => node.id != 'check'),
          original.graph.nodes.where((node) => node.id != 'check'),
        );
        expect(coldMaps.project, baseline.copyWith(scenes: [edited]));
        for (final entry in protectedBytes.entries) {
          expect(
            (await tester.runAsync(
              () => fixture.file(entry.key).readAsBytes(),
            ))!,
            entry.value,
            reason: entry.key,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  ProjectManifest? project,
  SceneConditionSource? source,
  required List<SceneConditionSource> changes,
  Future<MapData> Function(String)? loadMap,
  Future<Map<String, String>> Function()? loadItems,
}) => tester.pumpWidget(
  MaterialApp(
    theme: studioTheme(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: SceneConditionForm(
            project: project ?? _project(),
            current: SceneConditionPayload(conditionSource: source),
            loadMap: loadMap,
            loadItems: loadItems,
            onApply: changes.add,
          ),
        ),
      ),
    ),
  ),
);

StudioSelect _select(WidgetTester tester, String label) => tester
    .widgetList<StudioSelect>(find.byType(StudioSelect))
    .singleWhere((select) => select.label == label);
StudioSelect _booleanSelect(WidgetTester tester) => tester
    .widgetList<StudioSelect>(find.byType(StudioSelect))
    .singleWhere(
      (select) =>
          select.options.length == 2 &&
          select.options.containsKey('true') &&
          select.options.containsKey('false'),
    );
StudioButton _applyButton(WidgetTester tester) => tester
    .widgetList<StudioButton>(find.byType(StudioButton))
    .singleWhere((button) => button.label == 'Appliquer la condition');
StudioDraftField _draft(WidgetTester tester, String label) => tester
    .widgetList<StudioDraftField>(find.byType(StudioDraftField))
    .singleWhere((field) => field.label == label);

Future<void> _choose(WidgetTester tester, String label, String value) async {
  final select = _select(tester, label);
  final text = select.options[value];
  expect(text, isNotNull, reason: '$label / $value');
  final field = find.byWidgetPredicate(
    (widget) => widget is StudioSelect && widget.label == label,
  );
  await tester.ensureVisible(field);
  await tester.tap(
    find.descendant(
      of: field,
      matching: find.byType(DropdownButtonFormField<String>),
    ),
  );
  await tester.pumpAndSettle();
  final option = find.text(text!).last;
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String label, String value) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is StudioDraftField && widget.label == label,
  );
  await tester.ensureVisible(field);
  await tester.enterText(
    find.descendant(of: field, matching: find.byType(TextField)),
    value,
  );
  await tester.pump();
}

Future<void> _apply(WidgetTester tester) async {
  final button = find.text('Appliquer la condition');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

SceneConditionSource _inventory(String quantity, {bool expected = true}) =>
    SceneConditionSource(
      sourceKind: SceneConditionSourceKind.inventoryItem,
      sourceId: 'tonic',
      field: 'minimumQuantity',
      value: quantity,
      operator: expected
          ? SceneConditionOperator.isTrue
          : SceneConditionOperator.isFalse,
    );

ProjectManifest _project({
  String name = 'Guided conditions',
  List<BadgeDefinition>? badges,
  List<NarrativeFactDefinition>? facts,
}) => ProjectManifest(
  name: name,
  tilesets: [],
  maps: [
    const ProjectMapEntry(
      id: 'workshop',
      name: 'Atelier',
      relativePath: 'maps/workshop.json',
    ),
    const ProjectMapEntry(
      id: 'garden',
      name: 'Jardin',
      relativePath: 'maps/garden.json',
    ),
  ],
  badges:
      badges ?? [const BadgeDefinition(id: 'badge-a', label: 'Premier badge')],
  facts:
      facts ??
      [
        NarrativeFactDefinition(
          id: 'door-fact',
          label: 'Porte ouverte',
          legacyFlagName: 'DOOR_OPEN',
        ),
        NarrativeFactDefinition(id: 'gate-open', label: 'Passage ouvert'),
        NarrativeFactDefinition(
          id: 'count',
          label: 'Nombre',
          initialValue: NarrativeValue.integer(0),
        ),
      ],
);

MapData _map(String id, {List<MapEntity>? entities}) => MapData(
  id: id,
  name: id == 'workshop' ? 'Atelier' : 'Jardin',
  size: const GridSize(width: 6, height: 6),
  entities:
      entities ??
      [
        MapEntity(
          id: id == 'workshop' ? 'door' : 'guide',
          kind: MapEntityKind.sign,
          pos: const GridPos(x: 1, y: 1),
        ),
      ],
);

SceneAsset _scene(SceneConditionSource source) => SceneAsset(
  id: 'conditions',
  name: 'Conditions',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'check',
        kind: SceneNodeKind.condition,
        payload: SceneConditionPayload(conditionSource: source),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'check',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'yes',
        fromNodeId: 'check',
        fromPortId: 'true',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionTrue,
      ),
      SceneEdge(
        id: 'no',
        fromNodeId: 'check',
        fromPortId: 'false',
        toNodeId: 'end',
        kind: SceneEdgeKind.conditionFalse,
      ),
    ],
  ),
);

SceneConditionSource _conditionSource(SceneAsset scene) =>
    (scene.graph.nodes.singleWhere((node) => node.id == 'check').payload
            as SceneConditionPayload)
        .conditionSource!;

class _WidgetScenePort implements ScenePort {
  _WidgetScenePort(this.adapter, this.tester);

  final LocalSceneAdapter adapter;
  final WidgetTester tester;
  int writes = 0;

  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    writes++;
    return (await WidgetResourcePort.serial(
      tester,
      () => adapter.publishScene(base: base, current: current),
    ))!;
  }
}
