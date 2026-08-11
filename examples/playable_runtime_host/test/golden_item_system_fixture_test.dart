import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ITM-070 fixture owns a strict and complete item-system project',
    () async {
      final root = p.join(Directory.current.path, 'golden_item_system');
      final projectPath = p.join(root, 'project.json');
      final projectJson =
          jsonDecode(await File(projectPath).readAsString())
              as Map<String, dynamic>;
      final project = ProjectManifest.fromJson(projectJson);

      ProjectValidator.validate(project);

      expect(project.version, ProjectVersion.v6);
      expect(project.maps, hasLength(1));
      expect(project.newGame.enabled, isTrue);
      expect(project.newGame.initialParty, hasLength(1));
      expect(project.newGame.initialBag, hasLength(8));
      expect(project.encounterTables, hasLength(1));
      expect(project.shops, hasLength(1));
      expect(
        project.trainers.single.rewardItemGrants,
        const <ProjectTrainerItemGrant>[
          ProjectTrainerItemGrant(itemId: 'revive', quantity: 1),
        ],
      );

      final rawInitialBag =
          (projectJson['newGame'] as Map<String, dynamic>)['initialBag']
              as List<dynamic>;
      expect(
        rawInitialBag.cast<Map<String, dynamic>>(),
        everyElement(
          predicate<Map<String, dynamic>>(
            (entry) =>
                entry.keys.toSet().difference({'itemId', 'quantity'}).isEmpty,
          ),
        ),
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: 'golden_item_lab',
      );
      MapValidator.validate(bundle.map, projectDialogueContext: project);
      expect(
        bundle.map.entities.map((entity) => entity.id),
        containsAll(<String>[
          'spawn_item_lab',
          'item_ether_pickup',
          'npc_item_shopkeeper',
          'npc_item_trainer',
        ]),
      );
      final pickup = bundle.map.entities.singleWhere(
        (entity) => entity.id == 'item_ether_pickup',
      );
      expect(pickup.kind, MapEntityKind.item);
      expect(pickup.item?.gameItemId, 'ether');
      expect(pickup.item?.quantity, 1);
      expect(project.scenarios, hasLength(1));
      expect(
        project.scenarios.single.nodes
            .where((node) => node.payload.actionKind == 'giveItem')
            .single
            .payload
            .params,
        const <String, String>{'itemId': 'ether', 'quantity': '1'},
      );

      final catalog = await const RuntimeItemCatalogLoader().load(
        projectRootDirectory: root,
        pokemonConfig: project.pokemon,
      );
      expect(catalog, isNotNull);
      expect(catalog!.schemaVersion, 1);
      expect(catalog.entries.map((entry) => entry.id).toSet(), <String>{
        'potion',
        'antidote',
        'revive',
        'ether',
        'poke-ball',
        'lab-key',
        'tm-protect',
        'leftovers',
        'lucky-charm',
      });
      expect(
        catalog.entries.singleWhere((entry) => entry.id == 'poke-ball').capture,
        isNotNull,
      );
      expect(
        catalog.entries
            .singleWhere((entry) => entry.id == 'tm-protect')
            .machine,
        isNotNull,
      );
      expect(
        catalog.entries
            .singleWhere((entry) => entry.id == 'leftovers')
            .heldEffectId,
        'leftovers',
      );
      expect(
        catalog.entries
            .singleWhere((entry) => entry.id == 'ether')
            .uses
            .single
            .contexts,
        const <ProjectItemUseContext>{ProjectItemUseContext.overworld},
      );
      expect(
        catalog.entries.singleWhere((entry) => entry.id == 'lucky-charm'),
        isA<ProjectItemDefinition>()
            .having((entry) => entry.uses, 'uses', isEmpty)
            .having((entry) => entry.capture, 'capture', isNull)
            .having((entry) => entry.machine, 'machine', isNull)
            .having((entry) => entry.heldEffectId, 'heldEffectId', isNull),
      );
      final validation = validateProjectItemCatalog(
        catalog,
        capabilityTruth: ItemCapabilityTruth(
          supportedUseContexts: ProjectItemUseContext.values.toSet(),
          supportedEffects: ProjectItemEffectCapability.values.toSet(),
          supportedHeldEffectIds: const <String>{'leftovers'},
          supportsCapture: true,
          supportsMoveMachines: true,
        ),
      );
      expect(validation.hasBlockingDiagnostics, isFalse);
      expect(
        validation.assessmentFor('lucky-charm')?.readiness,
        ItemCapabilityReadiness.passive,
      );
      final references = buildProjectItemReferenceIndex(
        project: project,
        maps: <MapData>[bundle.map],
        itemCatalog: catalog,
      ).referencesFor('ether');
      expect(
        references.map((reference) => reference.kind),
        containsAll(<ProjectItemReferenceKind>[
          ProjectItemReferenceKind.mapPickup,
          ProjectItemReferenceKind.scenarioGive,
        ]),
      );

      final walkthrough =
          jsonDecode(
                await File(p.join(root, 'walkthrough.json')).readAsString(),
              )
              as Map<String, dynamic>;
      expect(walkthrough['schemaVersion'], 1);
      expect(walkthrough['projectId'], 'golden_item_system');
      expect(
        (walkthrough['steps'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((step) => step['id']),
        orderedEquals(const <String>[
          'new_game',
          'initial_items',
          'pickup',
          'overworld_heal',
          'buy',
          'sell',
          'battle_item',
          'capture_attempt',
          'equip_held_item',
          'learn_move_tm',
          'battle_reward',
          'save_reload',
        ]),
      );
    },
  );
}
