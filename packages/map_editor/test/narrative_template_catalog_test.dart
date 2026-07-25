import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_template_catalog.dart';

void main() {
  group('NarrativeTemplateCatalog', () {
    test('exposes every MVP pattern with executable gameplay templates', () {
      final catalog = NarrativeTemplateCatalog.canonical();

      expect(catalog.schemaVersion, 1);
      expect(catalog.eventSceneTemplates, hasLength(10));
      expect(catalog.cinematicTemplates, hasLength(2));
      expect(catalog.worldRuleTemplates, hasLength(2));
      expect(catalog.templates, hasLength(14));
      expect(
        catalog.byKind(NarrativeTemplateKind.nurse).isPublishable,
        isTrue,
      );
      expect(
        catalog.byKind(NarrativeTemplateKind.nurse).command.id,
        NarrativeCommandIds.openHeal,
      );
      expect(
        catalog.byKind(NarrativeTemplateKind.badgeReward).isPublishable,
        isTrue,
      );
      expect(
        catalog.byKind(NarrativeTemplateKind.itemBall).isPublishable,
        isTrue,
      );
      expect(
        catalog.byKind(NarrativeTemplateKind.cinematicEstablishingShot).id,
        'cinematic.establishingShot',
      );
      expect(
        catalog
            .byKind(NarrativeTemplateKind.worldRuleFactVisibility)
            .parameterLabels,
        containsPair('factId', 'Fact source'),
      );
      expect(
        catalog.byKind(NarrativeTemplateKind.shop).authoringHint,
        contains('catalogue des boutiques'),
      );
    });

    test('canonical gameplay payloads create and round-trip without raw ids',
        () {
      final payloads = <SceneActionPayload>[
        buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.openHeal,
          parameters: const {'requiresConfirmation': 'false'},
        ) as SceneActionPayload,
        buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.healParty,
          parameters: const {},
        ) as SceneActionPayload,
        buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.awardBadge,
          parameters: const {'badgeId': 'badge_tide'},
        ) as SceneActionPayload,
        buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.unlockFieldAbility,
          parameters: const {'abilityId': 'surf'},
        ) as SceneActionPayload,
      ];

      expect(
        payloads[0].interactiveCommand,
        SceneInteractiveCommand.openHeal(requiresConfirmation: false),
      );
      expect(payloads[1].consequence, SceneConsequence.healParty());
      expect(
        payloads[2].consequence,
        SceneConsequence.awardBadge(badgeId: 'badge_tide'),
      );
      expect(
        payloads[3].consequence,
        SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
      );
      for (final payload in payloads) {
        expect(SceneNodePayload.fromJson(payload.toJson()), payload);
      }
    });

    test('legacy action remains readable but cannot masquerade as supported',
        () {
      final legacy = SceneNodePayload.fromJson(const {
        'kind': 'action',
        'actionKind': 'setNpcPresence',
        'parameters': {'entityId': 'npc_old'},
      });

      expect(legacy, isA<SceneActionPayload>());
      expect((legacy as SceneActionPayload).actionKind, 'setNpcPresence');
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.setNpcPresence,
          parameters: const {'entityId': 'npc_old'},
        ),
        throwsArgumentError,
      );
    });

    test('badge preview refuses a target removed from the project', () {
      final withBadge = _emptyProject().copyWith(
        badges: const [
          BadgeDefinition(id: 'badge_tide', label: 'Badge Marée'),
        ],
      );
      final request = NarrativeTemplateRequest(
        kind: NarrativeTemplateKind.badgeReward,
        eventId: _eventId,
        sceneId: _sceneId,
        name: 'Récompense du champion',
        source: NarrativeEventSourceRef.mapEnter('map_port'),
        physicalSource: null,
        parameters: const {'badgeId': 'badge_tide'},
      );

      final valid = previewNarrativeTemplate(
        project: withBadge,
        request: request,
      );
      final deleted = previewNarrativeTemplate(
        project: withBadge.copyWith(badges: const []),
        request: request,
      );

      expect(valid.canApply, isTrue);
      expect(
        ProjectManifest.fromJson(valid.after!.toJson()).toJson(),
        valid.after!.toJson(),
      );
      expect(deleted.canApply, isFalse);
      expect(deleted.diagnostics.join(' '), contains('badge_tide'));
    });

    test('item ball preview creates one Event pointing to one Scene action',
        () {
      final before = _emptyProject();
      final preview = previewNarrativeTemplate(
        project: before,
        request: _itemBallRequest(),
      );

      expect(preview.canApply, isTrue);
      expect(preview.diagnostics, isEmpty);
      expect(preview.event!.sceneId, _sceneId);
      expect(preview.after!.eventRegistry!.records, hasLength(1));
      expect(preview.after!.scenes, hasLength(1));

      final actionPayloads = preview.scene!.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .toList();
      expect(actionPayloads, hasLength(1));
      expect(
        actionPayloads.single.consequence,
        SceneConsequence.giveItem(itemId: 'potion', quantity: 2),
      );

      final reloaded = ProjectManifest.fromJson(preview.after!.toJson());
      expect(reloaded.toJson(), preview.after!.toJson());
    });

    test('every Cinematic template builds a valid non-empty timeline', () {
      final catalog = NarrativeTemplateCatalog.canonical();

      for (final template in catalog.cinematicTemplates) {
        final timeline = buildNarrativeCinematicTemplateTimeline(
          template.kind,
        );
        final mutation = NarrativeAssetMutation.createCinematic(
          _emptyProject(),
          title: template.label,
          timeline: timeline,
        );

        expect(timeline.steps, isNotEmpty, reason: template.id);
        expect(mutation, isA<NarrativeAssetCreated>(), reason: template.id);
      }
    });

    test('conditional NPC requires its Fact parameters before construction',
        () {
      final preview = previewNarrativeTemplate(
        project: _emptyProject(),
        request: NarrativeTemplateRequest(
          kind: NarrativeTemplateKind.conditionalNpc,
          eventId: _eventId,
          sceneId: _sceneId,
          name: 'PNJ conditionnel',
          source: NarrativeEventSourceRef.entityInteract('map_port', 'npc_a'),
          physicalSource: const NarrativeTemplatePhysicalSource(
            kind: NarrativeTemplatePhysicalSourceKind.entity,
            mapId: 'map_port',
            sourceId: 'npc_a',
            exists: true,
          ),
          parameters: const {'dialogueId': 'dialogue.a'},
        ),
      );

      expect(preview.canApply, isFalse);
      expect(preview.diagnostics.join(' '), contains('Fact'));
      expect(preview.after, isNull);
    });

    test('refuses ID collisions and a missing physical Map Editor source', () {
      final collision = previewNarrativeTemplate(
        project: _emptyProject().copyWith(
          scenes: [
            SceneAsset(
              id: _sceneId,
              name: 'Existing',
              graph: SceneGraph(
                startNodeId: 'existing.start',
                nodes: [
                  SceneNode(id: 'existing.start', kind: SceneNodeKind.start),
                ],
                edges: const [],
              ),
            ),
          ],
        ),
        request: _itemBallRequest(),
      );
      final missingSource = previewNarrativeTemplate(
        project: _emptyProject(),
        request: _itemBallRequest(sourceExists: false),
      );

      expect(collision.canApply, isFalse);
      expect(collision.diagnostics.join(' '), contains(_sceneId));
      expect(missingSource.canApply, isFalse);
      expect(missingSource.requiresMapEditor, isTrue);
      expect(missingSource.diagnostics.join(' '), contains('Map Editor'));
    });

    test('refuses a physical source that does not match the Event source', () {
      final preview = previewNarrativeTemplate(
        project: _emptyProject(),
        request: _itemBallRequest(physicalSourceId: 'object_other'),
      );

      expect(preview.canApply, isFalse);
      expect(preview.requiresMapEditor, isTrue);
      expect(preview.diagnostics.join(' '), contains('ne correspond pas'));
    });

    test('rejects an empty label and a non-boolean conditional value', () {
      final emptyName = previewNarrativeTemplate(
        project: _emptyProject(),
        request: NarrativeTemplateRequest(
          kind: NarrativeTemplateKind.itemBall,
          eventId: _eventId,
          sceneId: _sceneId,
          name: '   ',
          source: NarrativeEventSourceRef.entityInteract(
            'map_port',
            'object_potion',
          ),
          physicalSource: const NarrativeTemplatePhysicalSource(
            kind: NarrativeTemplatePhysicalSourceKind.object,
            mapId: 'map_port',
            sourceId: 'object_potion',
            exists: true,
          ),
          parameters: const {'itemId': 'potion', 'quantity': '2'},
        ),
      );
      final invalidBoolean = previewNarrativeTemplate(
        project: _emptyProject(),
        request: NarrativeTemplateRequest(
          kind: NarrativeTemplateKind.conditionalNpc,
          eventId: _eventId,
          sceneId: _sceneId,
          name: 'PNJ',
          source: NarrativeEventSourceRef.entityInteract('map_port', 'npc_a'),
          physicalSource: const NarrativeTemplatePhysicalSource(
            kind: NarrativeTemplatePhysicalSourceKind.entity,
            mapId: 'map_port',
            sourceId: 'npc_a',
            exists: true,
          ),
          parameters: const {
            'dialogueId': 'dialogue.a',
            'factId': 'fact.a',
            'expectedValue': 'peut-être',
          },
        ),
      );

      expect(emptyName.canApply, isFalse);
      expect(emptyName.diagnostics.join(' '), contains('nom'));
      expect(invalidBoolean.canApply, isFalse);
      expect(invalidBoolean.diagnostics.join(' '), contains('vrai ou faux'));
    });
  });
}

const _eventId = 'evt_00000000-0000-7000-8000-000000000001';
const _sceneId = 'scene.item.ball';

ProjectManifest _emptyProject() => const ProjectManifest(
      name: 'Template test',
      maps: [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port',
          relativePath: 'maps/port.json',
        ),
      ],
      tilesets: [],
    );

NarrativeTemplateRequest _itemBallRequest({
  bool sourceExists = true,
  String physicalSourceId = 'object_potion',
}) {
  return NarrativeTemplateRequest(
    kind: NarrativeTemplateKind.itemBall,
    eventId: _eventId,
    sceneId: _sceneId,
    name: 'Potion au sol',
    source: NarrativeEventSourceRef.entityInteract(
      'map_port',
      'object_potion',
    ),
    physicalSource: NarrativeTemplatePhysicalSource(
      kind: NarrativeTemplatePhysicalSourceKind.object,
      mapId: 'map_port',
      sourceId: physicalSourceId,
      exists: sourceExists,
    ),
    parameters: const {'itemId': 'potion', 'quantity': '2'},
  );
}
