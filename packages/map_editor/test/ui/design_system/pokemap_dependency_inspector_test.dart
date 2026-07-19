import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/narrative/pokemap_dependency_inspector.dart';
import 'package:map_editor/src/ui/design_system/narrative/pokemap_narrative_reference_picker.dart';

void main() {
  const target = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.cinematic,
    'cinematic_intro',
  );
  const definitionIntent = NarrativeDependencyNavigationIntent(
    kind: NarrativeDependencyTargetKind.cinematic,
    assetId: 'cinematic_intro',
  );
  const firstConsumerIntent = NarrativeDependencyNavigationIntent(
    kind: NarrativeDependencyTargetKind.scene,
    assetId: 'scene_port',
    context: 'graph.nodes[cinematic_0]',
  );

  testWidgets(
    'shows target definitions consumers diagnostics and opens exact intents',
    (tester) async {
      final opened = <NarrativeDependencyNavigationIntent>[];
      final model = NarrativeDependencyInspectionReadModel(
        target: target,
        definitions: [
          NarrativeDependencyDefinition(
            key: target,
            label: 'Introduction du port',
            path: 'cinematics[cinematic_intro]',
            navigationIntent: definitionIntent,
          ),
        ],
        usages: const [
          NarrativeDependencyUsage(
            target: target,
            owner: NarrativeDependencyKey.scene('scene_port'),
            path:
                'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
            navigationIntent: firstConsumerIntent,
          ),
          NarrativeDependencyUsage(
            target: target,
            owner: NarrativeDependencyKey.scene('scene_market'),
            path:
                'scenes[scene_market].graph.nodes[cinematic_0].payload.cinematicId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          ),
        ],
        issues: const [
          NarrativeDependencyIssue(
            kind: NarrativeDependencyIssueKind.missingReference,
            target: target,
            owner: NarrativeDependencyKey.scene('scene_port'),
            path:
                'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
            message: 'La cinématique est requise par la scène du port.',
          ),
        ],
      );

      await _pumpInspector(
        tester,
        model: model,
        onOpen: opened.add,
      );

      expect(find.text('Introduction du port'), findsNWidgets(2));
      expect(find.text('cinematic_intro'), findsOneWidget);
      expect(find.text('1 définition'), findsOneWidget);
      expect(find.text('2 consommateurs'), findsOneWidget);
      expect(find.text('scene_port'), findsOneWidget);
      expect(find.text('scene_market'), findsOneWidget);
      expect(
        find.textContaining(
          'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
        ),
        findsOneWidget,
      );
      expect(find.text('Bloquant pour l’exécution'), findsWidgets);
      expect(find.text('Avertissement de création'), findsOneWidget);
      expect(
        find.text('La cinématique est requise par la scène du port.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-definition-open',
              target,
              'cinematics[cinematic_intro]',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-consumer-open',
              target,
              NarrativeDependencyKey.scene('scene_port'),
              'scenes[scene_port].graph.nodes[cinematic_0].payload.cinematicId',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(opened, [definitionIntent, firstConsumerIntent]);
      expect(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-consumer-open',
              target,
              NarrativeDependencyKey.scene('scene_market'),
              'scenes[scene_market].graph.nodes[cinematic_0].payload.cinematicId',
            ),
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders honest missing and ambiguous target states',
      (tester) async {
    final missing = NarrativeDependencyInspectionReadModel(
      target: const NarrativeDependencyKey.scene('scene_missing'),
      definitions: const [],
      usages: const [],
      issues: const [
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.missingReference,
          target: NarrativeDependencyKey.scene('scene_missing'),
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message: 'La scène ciblée n’existe pas.',
        ),
      ],
    );

    await _pumpInspector(tester, model: missing);

    expect(find.text('Référence introuvable'), findsWidgets);
    expect(find.text('scene_missing'), findsOneWidget);
    expect(find.text('La scène ciblée n’existe pas.'), findsOneWidget);

    final ambiguous = NarrativeDependencyInspectionReadModel(
      target: target,
      definitions: [
        NarrativeDependencyDefinition(
          key: target,
          label: 'Introduction du port',
          path: 'cinematics[0]',
        ),
        NarrativeDependencyDefinition(
          key: target,
          label: 'Introduction du phare',
          path: 'cinematics[1]',
        ),
      ],
      usages: const [],
      issues: const [
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.ambiguousReference,
          target: target,
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message: 'Deux cinématiques utilisent le même identifiant.',
        ),
      ],
    );

    await _pumpInspector(tester, model: ambiguous);

    expect(find.text('Référence ambiguë'), findsWidgets);
    expect(find.text('Introduction du port'), findsOneWidget);
    expect(find.text('Introduction du phare'), findsOneWidget);
    expect(find.text('cinematics[0]'), findsOneWidget);
    expect(find.text('cinematics[1]'), findsOneWidget);
    expect(
      find.text('Deux cinématiques utilisent le même identifiant.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'offers replace everywhere only for a genuine exactly-covered capability',
    (tester) async {
      final project = _referencedProject();
      final validation = NarrativeAssetMutation.validateCinematicReplacement(
        project,
        sourceId: 'cinematic_intro',
        replacementId: 'cinematic_replacement',
      );
      expect(validation, isA<NarrativeReferenceReplacementValidated>());
      final capability =
          (validation as NarrativeReferenceReplacementValidated).capability;
      final model = inspectNarrativeDependency(
        buildNarrativeDependencyIndex(project: project),
        capability.source,
      );
      NarrativeReferenceReplacementCapability? received;

      await _pumpInspector(tester, model: model);
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );

      await _pumpInspector(
        tester,
        model: model,
        replacementCapability: capability,
      );
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );

      await _pumpInspector(
        tester,
        model: model,
        replacementCapability: capability,
        onReplaceEverywhere: (value) => received = value,
      );
      final action =
          find.byKey(const ValueKey('dependency-inspector-replace-all'));
      expect(action, findsOneWidget);

      await tester.tap(action);
      await tester.pump();

      expect(received, same(capability));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hides replace everywhere for another target or incomplete coverage',
    (tester) async {
      final project = _referencedProject();
      final validation = NarrativeAssetMutation.validateCinematicReplacement(
        project,
        sourceId: 'cinematic_intro',
        replacementId: 'cinematic_replacement',
      ) as NarrativeReferenceReplacementValidated;
      final capability = validation.capability;
      final inspected = inspectNarrativeDependency(
        buildNarrativeDependencyIndex(project: project),
        capability.source,
      );
      final incomplete = NarrativeDependencyInspectionReadModel(
        target: inspected.target,
        definitions: inspected.definitions,
        usages: inspected.usages.take(1).toList(),
        issues: inspected.issues,
      );
      final otherKind = NarrativeDependencyInspectionReadModel(
        target: const NarrativeDependencyKey.scene('cinematic_intro'),
        definitions: const [],
        usages: const [],
        issues: const [],
      );

      await _pumpInspector(
        tester,
        model: incomplete,
        replacementCapability: capability,
        onReplaceEverywhere: (_) {},
      );
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );

      await _pumpInspector(
        tester,
        model: otherKind,
        replacementCapability: capability,
        onReplaceEverywhere: (_) {},
      );
      expect(
        find.byKey(const ValueKey('dependency-inspector-replace-all')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'picker and inspector preserve a complete map child identity and intent',
    (tester) async {
      const portMap = NarrativeDependencyKey.map('map_port');
      const forestMap = NarrativeDependencyKey.map('map_forest');
      const portGuide = NarrativeDependencyKey.mapSource(
        mapId: 'map_port',
        sourceKind: 'entity',
        sourceId: 'guide',
      );
      const forestGuide = NarrativeDependencyKey.mapSource(
        mapId: 'map_forest',
        sourceKind: 'entity',
        sourceId: 'guide',
      );
      const forestIntent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.sourceMap,
        assetId: 'guide',
        parentId: 'map_forest',
        scope: 'map',
        sourceKind: 'entity',
        mapId: 'map_forest',
      );
      final index = NarrativeDependencyIndex(
        definitions: [
          NarrativeDependencyDefinition(key: portMap, label: 'Port'),
          NarrativeDependencyDefinition(key: forestMap, label: 'Forêt'),
          NarrativeDependencyDefinition(
            key: portGuide,
            label: 'Guide',
            owner: portMap,
            navigationIntent:
                NarrativeDependencyNavigationIntent.fromKey(portGuide),
          ),
          NarrativeDependencyDefinition(
            key: forestGuide,
            label: 'Guide',
            owner: forestMap,
            navigationIntent: forestIntent,
          ),
        ],
      );
      final pickerModel = buildCanonicalNarrativeReferencePickerReadModel(
        index: index,
        allowedKinds: const {NarrativeDependencyTargetKind.sourceMap},
      );
      CanonicalNarrativeReferenceOption? selected;

      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 540,
              height: 760,
              child: PokeMapNarrativeReferencePicker(
                label: 'PNJ déclencheur',
                readModel: pickerModel,
                selectedKey: null,
                onSelected: (option) => selected = option,
              ),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey<NarrativeDependencyKey>(forestGuide),
        ),
      );
      await tester.pump();

      expect(selected?.key, forestGuide);
      expect(selected?.navigationIntent, forestIntent);
      expect(
        find.byKey(const ValueKey<NarrativeDependencyKey>(portGuide)),
        findsOneWidget,
      );
      expect(find.text('Créer'), findsNothing);

      final inspection = inspectNarrativeDependency(index, selected!.key);
      NarrativeDependencyNavigationIntent? opened;
      await _pumpInspector(
        tester,
        model: inspection,
        onOpen: (intent) => opened = intent,
      );
      await tester.tap(
        find.byKey(
          const ValueKey<Object>(
            (
              'dependency-inspector-definition-open',
              forestGuide,
              null,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(opened, forestIntent);
      expect(opened, selected!.navigationIntent);
      expect(find.text('Créer'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpInspector(
  WidgetTester tester, {
  required NarrativeDependencyInspectionReadModel model,
  ValueChanged<NarrativeDependencyNavigationIntent>? onOpen,
  NarrativeReferenceReplacementCapability? replacementCapability,
  ValueChanged<NarrativeReferenceReplacementCapability>? onReplaceEverywhere,
}) async {
  tester.view.physicalSize = const Size(1200, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 680,
            child: PokeMapDependencyInspector(
              model: model,
              onOpen: onOpen,
              replacementCapability: replacementCapability,
              onReplaceEverywhere: onReplaceEverywhere,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _referencedProject() {
  return ProjectManifest(
    name: 'Dependency inspector test',
    maps: const [],
    tilesets: const [],
    cinematics: [
      _cinematic('cinematic_intro', 'Introduction du port'),
      _cinematic('cinematic_replacement', 'Introduction alternative'),
    ],
    scenes: [
      _sceneWithCinematic('scene_port', 'cinematic_intro'),
      _sceneWithCinematic('scene_market', 'cinematic_intro'),
    ],
  );
}

CinematicAsset _cinematic(String id, String title) {
  return CinematicAsset(
    id: id,
    title: title,
    timeline: CinematicTimeline(),
  );
}

SceneAsset _sceneWithCinematic(String id, String cinematicId) {
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start, title: 'Début'),
        SceneNode(
          id: 'cinematic',
          kind: SceneNodeKind.cinematic,
          title: 'Cinématique',
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end, title: 'Fin'),
      ],
    ),
  );
}
