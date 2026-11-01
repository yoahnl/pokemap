import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/scenes/periodic_reward_picker.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final lateGet in [false, true]) {
    testWidgets(
      'Editor refresh removes stale nodes and ignores old canonical get late=$lateGet',
      (tester) async {
        final project = _pickerProject('source');
        final reader = _PickerReader(project);
        final query = AuthoringQueryAdapter(fileReader: reader);
        addTearDown(query.closeAll);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              editorNotifierProvider.overrideWith(
                () => _PickerEditorNotifier(
                  EditorState(project: project, projectRootPath: '/project'),
                ),
              ),
              authoringQueryAdapterProvider.overrideWith((ref) => query),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: EditorPeriodicRewardPicker(
                    initial: PeriodicRewardReference(
                      sceneId: 'source',
                      nodeId: 'claim',
                      rewardId: 'daily',
                    ),
                    onApply: (_, _) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await _pumpUntil(tester, () => !_pickerLoading(tester));
        PokeMapButton button(String label) => tester.widget<PokeMapButton>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(PokeMapButton),
              )
              .first,
        );
        expect(
          _pickerDropdown(tester, 'Action de récompense').items,
          hasLength(1),
        );
        Completer<void>? oldGet;
        if (lateGet) {
          oldGet = Completer<void>();
          reader.project = _pickerProject('other');
          reader.holdQuery = reader.queryCount + 2;
          reader.heldProject = project;
          reader.gate = oldGet;
          button('Actualiser les sources').onPressed!();
          await tester.pump();
          await _pumpUntil(
            tester,
            () => _pickerDropdown(
              tester,
              'Scène de la récompense',
            ).items.any((item) => item.value == 'other'),
          );
          _pickerDropdown(tester, 'Scène de la récompense').onChanged('other');
          await tester.pump();
          await _pumpUntil(tester, () => !_pickerLoading(tester));
          _pickerDropdown(tester, 'Action de récompense').onChanged('claim');
          await tester.pump();
          expect(
            button('Appliquer la condition quotidienne').onPressed,
            isNotNull,
          );
        }
        reader.project = project.copyWith(scenes: const []);
        button('Actualiser les sources').onPressed!();
        await tester.pump();
        await _pumpUntil(tester, () => !_pickerLoading(tester));
        expect(_pickerDropdown(tester, 'Scène de la récompense').value, isNull);
        expect(_pickerDropdown(tester, 'Action de récompense').items, isEmpty);
        expect(button('Appliquer la condition quotidienne').onPressed, isNull);
        if (oldGet != null) {
          oldGet.complete();
          await _pumpUntil(
            tester,
            () =>
                (reader.readCounts[reader.heldRoot] ?? 0) >=
                reader.readCounts.values.first,
          );
          await tester.pumpAndSettle();
          expect(
            _pickerDropdown(tester, 'Scène de la récompense').items,
            isEmpty,
          );
          expect(
            _pickerDropdown(tester, 'Action de récompense').items,
            isEmpty,
          );
          expect(
            button('Appliquer la condition quotidienne').onPressed,
            isNull,
          );
        }
        expect(
          find.textContaining('La référence existante reste conservée'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Editor daily picker keeps changed reward identity unresolved until explicit choice',
    (tester) async {
      final original = PeriodicRewardReference(
        sceneId: 'source',
        nodeId: 'claim',
        rewardId: 'previous',
      );
      final current = PeriodicRewardReference(
        sceneId: 'source',
        nodeId: 'claim',
        rewardId: 'daily',
      );
      final project = ProjectManifest(
        name: 'Picker',
        tilesets: const [],
        maps: const [],
        scenes: [
          SceneAsset(
            id: 'source',
            name: 'Verger',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'claim',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.claimPeriodicReward(
                      definition: PeriodicItemRewardDefinition(
                        rewardId: 'daily',
                        label: 'Fruit',
                        itemId: 'fruit',
                        quantity: 1,
                      ),
                    ),
                  ),
                ),
              ],
              edges: const [],
            ),
          ),
        ],
      );
      final query = AuthoringQueryAdapter(fileReader: _PickerReader(project));
      addTearDown(query.closeAll);
      final applied = <PeriodicRewardReference>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorNotifierProvider.overrideWith(
              () => _PickerEditorNotifier(
                EditorState(project: project, projectRootPath: '/project'),
              ),
            ),
            authoringQueryAdapterProvider.overrideWith((ref) => query),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditorPeriodicRewardPicker(
                  initial: original,
                  onApply: (reference, _) => applied.add(reference),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 100 &&
            find.text('Chargement des sources publiées…').evaluate().isNotEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      final picker = tester
          .widgetList<PokeMapDropdownField<String?>>(
            find.byType(PokeMapDropdownField<String?>),
          )
          .singleWhere((value) => value.label == 'Action de récompense');
      expect(picker.items, hasLength(1));
      expect(picker.value, isNull);
      expect(
        find.textContaining('La référence existante reste conservée'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.text('Appliquer la condition quotidienne'),
      );
      await tester.tap(
        find.text('Appliquer la condition quotidienne'),
        warnIfMissed: false,
      );
      expect(applied, isEmpty);
      picker.onChanged('claim');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer la condition quotidienne'));
      expect(applied, [current]);
      expect(tester.takeException(), isNull);
    },
  );
  for (final catalog in [false, true]) {
    test(
      'Editor condition gateways use published sources and targeted persistence catalog=$catalog',
      () async {
        final root = Directory(
          '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-authoring/fixture',
        );
        final reader = _Reader();
        final queries = AuthoringQueryAdapter(fileReader: reader);
        final mutations = AuthoringMutationAdapter(
          fileReader: reader,
          queries: queries,
          projectRoots: _Roots(root.path),
        );
        addTearDown(() async {
          await mutations.closeAll();
          await queries.closeAll();
          if (await root.exists()) await root.delete(recursive: true);
        });
        await root.create(recursive: true);
        final source = SceneAsset(
          id: 'source',
          name: 'Verger',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'claim',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.claimPeriodicReward(
                    definition: PeriodicItemRewardDefinition(
                      rewardId: 'daily',
                      label: 'Fruit',
                      itemId: 'fruit',
                      quantity: 1,
                    ),
                  ),
                ),
              ),
              SceneNode(
                id: 'talk',
                kind: SceneNodeKind.yarnDialogue,
                payload: SceneYarnDialoguePayload(dialogueId: 'foreign'),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: const [],
          ),
        );
        final consumer = SceneAsset(
          id: 'consumer',
          name: 'Consumer',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'gate',
                kind: SceneNodeKind.condition,
                payload: SceneConditionPayload(
                  conditionSource: SceneConditionSource.factValue(
                    factId: 'gate',
                    operator: NarrativeFactOperator.equals,
                    expectedValue: NarrativeValue.boolean(true),
                  ),
                ),
              ),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                id: 'enter',
                kind: SceneEdgeKind.defaultFlow,
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'gate',
              ),
              SceneEdge(
                id: 'yes',
                fromNodeId: 'gate',
                fromPortId: 'true',
                toNodeId: 'end',
                kind: SceneEdgeKind.conditionTrue,
              ),
              SceneEdge(
                id: 'no',
                fromNodeId: 'gate',
                fromPortId: 'false',
                toNodeId: 'end',
                kind: SceneEdgeKind.conditionFalse,
              ),
            ],
          ),
        );
        final project = ProjectManifest(
          name: 'Editor',
          tilesets: const [],
          maps: [
            const ProjectMapEntry(
              id: 'own',
              name: 'Own',
              relativePath: 'maps/own.json',
            ),
            for (var i = 0; i < 80; i++)
              ProjectMapEntry(
                id: 'foreign-$i',
                name: 'Foreign',
                relativePath: 'maps/foreign-$i.json',
              ),
          ],
          scenes: [consumer, source],
          facts: [
            NarrativeFactDefinition(
              id: 'gate',
              label: 'Gate',
              initialValue: NarrativeValue.boolean(true),
            ),
          ],
          dialogues: const [
            ProjectDialogueEntry(
              id: 'foreign',
              name: 'Foreign',
              relativePath: 'dialogues/must-not-read.yarn',
            ),
          ],
        );
        if (catalog) {
          final store = await CatalogStorageStore.open(projectRoot: root.path);
          await WorkingProjectCatalog.create(
            store: store,
            projectId: 'editor-periodic',
            project: project,
          );
        } else {
          await File(
            '${root.path}/project.json',
          ).writeAsString(jsonEncode(project.toJson()));
        }
        await Directory('${root.path}/maps').create();
        await File('${root.path}/maps/own.json').writeAsString(
          jsonEncode(
            MapData(
              id: 'own',
              name: 'Own',
              size: const GridSize(width: 4, height: 4),
              entities: [
                MapEntity(
                  id: 'anchor',
                  name: 'Anchor',
                  kind: MapEntityKind.custom,
                  pos: const GridPos(x: 1, y: 1),
                ),
              ],
            ).toJson(),
          ),
        );
        final choices = await queries.queryPeriodicRewardChoices(
          root.path,
          AuthoringQueryRequest(
            resourceKind: 'periodicRewardNode',
            operation: AuthoringQueryOperation.list,
            filters: const {'sceneId': 'source'},
          ),
        );
        final reference = PeriodicRewardNodeChoice.fromJson(
          Map<String, dynamic>.from(choices.items.single),
        ).reference;
        reader.paths.clear();
        final updated = await mutations.setSceneCondition(
          root.path,
          expectedScene: consumer,
          nodeId: 'gate',
          source: SceneConditionSource.periodicRewardAvailable(
            reference: reference,
            expectedValue: true,
          ),
        );
        expect(
          (updated.after.graph.nodes
                      .singleWhere((node) => node.id == 'gate')
                      .payload
                  as SceneConditionPayload)
              .conditionSource!
              .rewardReference,
          reference,
        );
        final rule = WorldRuleDefinition(
          id: 'world_rule_daily',
          label: 'Daily',
          source: WorldRuleSource.periodicRewardAvailable(
            reference: reference,
            expectedValue: true,
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'own',
            entityId: 'anchor',
          ),
          effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
        );
        final savedRule = await mutations.mutateConditionAction(
          root.path,
          actionId: 'world_rule.create',
          parameters: {'rule': rule.toJson()},
          validate: (_) {},
        );
        expect(savedRule.after.worldRules.single, rule);
        final event = NarrativeEventRecord.fromJson({
          'state': 'configured',
          'enabled': false,
          'definition': {
            'id': 'evt_019abcde-0000-7000-8000-000000000001',
            'name': 'Daily entrance',
            'source': {'kind': 'mapEnter', 'mapId': 'own'},
            'conditions': [
              NarrativeEventCondition.periodicRewardAvailable(
                reference: reference,
                expectedValue: true,
              ).toJson(),
            ],
            'sceneId': 'consumer',
            'reusePolicy': 'reusable',
            'priority': 0,
            'order': 0,
          },
        });
        final savedEvent = await mutations.mutateConditionAction(
          root.path,
          actionId: 'event_v2.record_upsert',
          parameters: {'record': event.toJson()},
          validate: (_) {},
        );
        expect(savedEvent.after.eventRegistry!.records.single, event);
        expect(
          reader.paths.where(
            (path) =>
                path.startsWith('maps/') && path != 'maps/own.json' ||
                path.startsWith('assets/') ||
                path.startsWith('dialogues/') ||
                path.endsWith('history.jsonl'),
          ),
          isEmpty,
        );
      },
    );
  }
}

class _PickerEditorNotifier extends EditorNotifier {
  _PickerEditorNotifier(this.initial);
  final EditorState initial;
  @override
  EditorState build() => initial;
}

class _PickerReader implements ProjectFileReader {
  _PickerReader(this.project);
  ProjectManifest project;
  int queryCount = 0;
  int? holdQuery;
  ProjectManifest? heldProject;
  Completer<void>? gate;
  String? heldRoot;
  final snapshots = <String, ProjectManifest>{};
  final gates = <String, Future<void>>{};
  final readCounts = <String, int>{};
  @override
  Future<String> canonicalizeDirectory(String path) async {
    if (path != '/project') return path;
    final root = '/project/query-${++queryCount}';
    final held = queryCount == holdQuery;
    snapshots[root] = held ? heldProject! : project;
    if (held) {
      heldRoot = root;
      gates[root] = gate!.future;
    }
    return root;
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    await gates[projectRoot];
    readCounts.update(projectRoot, (count) => count + 1, ifAbsent: () => 1);
    if (relativePath == 'project.json')
      return utf8.encode(
        jsonEncode((snapshots[projectRoot] ?? project).toJson()),
      );
    throw FileSystemException('Missing fixture resource', relativePath);
  }
}

bool _pickerLoading(WidgetTester tester) =>
    find.text('Chargement des sources publiées…').evaluate().isNotEmpty;

PokeMapDropdownField<String?> _pickerDropdown(
  WidgetTester tester,
  String label,
) => tester
    .widgetList<PokeMapDropdownField<String?>>(
      find.byType(PokeMapDropdownField<String?>),
    )
    .singleWhere((value) => value.label == label);

Future<void> _pumpUntil(WidgetTester tester, bool Function() complete) async {
  await tester.pump();
  for (var i = 0; i < 500 && !complete(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  expect(complete(), isTrue);
}

ProjectManifest _pickerProject(String sceneId) => ProjectManifest(
  name: 'Picker',
  tilesets: const [],
  maps: const [],
  scenes: [
    SceneAsset(
      id: sceneId,
      name: sceneId,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'claim',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.claimPeriodicReward(
                definition: PeriodicItemRewardDefinition(
                  rewardId: 'daily',
                  label: 'Fruit',
                  itemId: 'fruit',
                  quantity: 1,
                ),
              ),
            ),
          ),
        ],
        edges: const [],
      ),
    ),
  ],
);

final class _Roots implements EditorProjectRootLocator {
  const _Roots(this.root);
  final String root;
  @override
  Future<String> locateForResource(String resourcePath) async => root;
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
