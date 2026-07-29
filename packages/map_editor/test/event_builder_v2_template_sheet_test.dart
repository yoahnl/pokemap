import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_template_catalog.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_template_sheet.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';

const _eventId = 'evt_019abcde-7000-7000-8000-000000000001';

void main() {
  testWidgets('guided template previews one Event and one Scene before apply',
      (tester) async {
    NarrativeTemplatePreview? applied;
    await _pump(
      tester,
      sources: [_npcSource()],
      onApply: (preview) async {
        applied = preview;
        return null;
      },
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('scene-action-submit')),
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(find.text('Prévisualisation prête'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-v2-template-apply')),
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-template-apply')),
    );
    await tester.pumpAndSettle();

    expect(applied!.event!.sceneId, 'scene.template.test');
    expect(applied!.after!.eventRegistry!.records, hasLength(1));
    expect(applied!.after!.scenes, hasLength(1));
  });

  testWidgets('missing physical source opens Map Editor with resumable draft',
      (tester) async {
    EventBuilderV2TemplateDraft? draft;
    await _pump(
      tester,
      sources: const [],
      onOpenMapEditor: (value) => draft = value,
    );

    await tester.tap(find.text('Ouvrir le Map Editor'));
    await tester.pumpAndSettle();

    expect(draft, isNotNull);
    expect(draft!.kind, NarrativeTemplateKind.simpleNpc);
    expect(draft!.name, 'PNJ simple');
  });

  testWidgets(
      'static encounter template creates the canonical distinct battle payload',
      (tester) async {
    NarrativeTemplatePreview? applied;
    await _pump(
      tester,
      project: _staticProject(),
      sources: [_npcSource()],
      initialDraft: const EventBuilderV2TemplateDraft(
        kind: NarrativeTemplateKind.staticEncounter,
        name: 'Gardien du phare',
        parameters: {},
        expectedValue: 'true',
      ),
      actionPickerOptions: const {
        NarrativeCommandParameterKind.staticEncounter: [
          SceneActionPickerOption(
            id: 'static:trainer_lighthouse_guardian',
            label: 'Gardien du phare',
            parameters: {
              'trainerId': 'trainer_lighthouse_guardian',
              'battleTemplateId': 'battle_lighthouse_pokemon',
            },
          ),
        ],
      },
      onApply: (preview) async {
        applied = preview;
        return null;
      },
    );

    expect(find.text('Gardien du phare'), findsWidgets);
    await tester.ensureVisible(
      find.byKey(const ValueKey('scene-action-submit')),
    );
    await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
    await tester.pump();

    expect(find.text('Prévisualisation prête'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-v2-template-apply')),
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-template-apply')),
    );
    await tester.pumpAndSettle();

    final payload = applied!.scene!.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneBattlePayload>()
        .single;
    expect(payload.battleKind, 'static');
    expect(payload.trainerId, 'trainer_lighthouse_guardian');
    expect(payload.battleTemplateId, 'battle_lighthouse_pokemon');
    expect(payload.declaredOutcomes, const ['victory', 'defeat']);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required List<NarrativeSpatialEventSourceOption> sources,
  ProjectManifest? project,
  EventBuilderV2TemplateDraft? initialDraft,
  Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>?
      actionPickerOptions,
  EventBuilderV2TemplateApply? onApply,
  ValueChanged<EventBuilderV2TemplateDraft>? onOpenMapEditor,
}) async {
  tester.view.physicalSize = const Size(640, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: EventBuilderV2TemplateSheet(
          project: project ?? _project(),
          eventId: _eventId,
          sceneId: 'scene.template.test',
          spatialSources: sources,
          actionPickerOptions: actionPickerOptions ??
              const {
                NarrativeCommandParameterKind.dialogue: [
                  SceneActionPickerOption(
                    id: 'dialogue.npc',
                    label: 'Dialogue PNJ',
                  ),
                ],
              },
          onApply: onApply ?? (_) async => null,
          onOpenMapEditor: onOpenMapEditor ?? (_) {},
          initialDraft: initialDraft,
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project() => ProjectManifest(
      name: 'Template sheet',
      maps: const [
        ProjectMapEntry(
          id: 'map.port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const [],
      dialogues: const [
        ProjectDialogueEntry(
          id: 'dialogue.npc',
          name: 'Dialogue PNJ',
          relativePath: 'dialogues/npc.yarn',
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const [],
        legacyClaims: const [],
      ),
    );

ProjectManifest _staticProject() => ProjectManifest(
      name: 'Static template sheet',
      maps: const [
        ProjectMapEntry(
          id: 'map.port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: const [],
      trainers: const [
        ProjectTrainerEntry(
          id: 'trainer_lighthouse_guardian',
          name: 'Gardien du phare',
          trainerClass: 'Rencontre',
          tags: ['static-encounter'],
        ),
      ],
      scenes: [
        SceneAsset(
          id: 'scene.static.contract',
          name: 'Static contract',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'battle',
                kind: SceneNodeKind.battle,
                payload: SceneBattlePayload(
                  battleKind: 'static',
                  trainerId: 'trainer_lighthouse_guardian',
                  battleTemplateId: 'battle_lighthouse_pokemon',
                  declaredOutcomes: const ['victory', 'defeat'],
                ),
              ),
            ],
            edges: const [],
          ),
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const [],
        legacyClaims: const [],
      ),
    );

NarrativeSpatialEventSourceOption _npcSource() =>
    NarrativeSpatialEventSourceOption(
      source: NarrativeEventSourceRef.entityInteract('map.port', 'npc.a'),
      humanLabel: 'PNJ A',
      humanDescription: 'PNJ déjà placé',
      mapId: 'map.port',
      mapLabel: 'Port',
      sourceTypeLabel: 'PNJ',
      availability: NarrativeSpatialEventSourceAvailability.selectable,
      origin: NarrativeSpatialEventSourceOrigin.canonical,
      debugTechnicalLabel: 'map.port:npc.a',
      geometry: const NarrativeSpatialSourceGeometrySummary.bounds(
        MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 1, height: 1),
        ),
      ),
      ownerKind: NarrativeSpatialEventSourceOwnerKind.entity,
      ownerId: 'npc.a',
    );
