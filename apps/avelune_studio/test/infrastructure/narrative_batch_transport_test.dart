import 'dart:io';

import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../game_memory/game_memory_catalog_fixture.dart';
import '../support/transport_history.dart';

void main() {
  for (final catalog in [false, true]) {
    final storage = catalog ? 'working catalog' : 'manifest';
    test(
      'event template publishes map, pages and scenes atomically on $storage',
      () async {
        final session = await openGameMemoryCatalog(
          catalog: catalog,
          prepared: false,
          unrelated: 2,
          character: true,
          unrelatedDialogues: true,
        );
        final maps = LocalMapWorkspaceAdapter();
        final project = await maps.loadProject(session);
        final owner = project.maps.singleWhere(
          (map) => map.id == 'unused-map-0',
        );
        final base = await maps.loadMap(session, owner);
        final unrelated = File('${session.directoryPath}/maps/town.json');
        final untouched = await unrelated.readAsBytes();
        final events = LocalEventAdapter(session: session, mapAdapter: maps);
        final spec = StandardEventTemplateSpec(
          kind: StandardEventTemplateKind.conditionalNpc,
          mapId: owner.id,
          entityId: 'passer',
          name: 'Rencontre',
          parameters: const {
            'factId': 'fact_met',
            'characterId': 'leo',
            'dialogueId': 'unused_dialogue_0',
            'alternateDialogueId': 'unused_dialogue_1',
          },
        );
        final receipt = await events.publishTemplate(
          base: base,
          spec: spec,
          project: project,
          maps: [base.map],
        );
        expect(receipt.changedPaths, contains(owner.relativePath));
        await expectLater(
          events.publishTemplate(
            base: base,
            spec: spec,
            project: project,
            maps: [base.map],
          ),
          throwsA(isA<NarrativeFailure>()),
        );
        final cold = LocalMapWorkspaceAdapter();
        final reopened = await cold.loadProject(session);
        final map = await cold.loadMap(session, owner);
        final template = readStandardEventTemplate(
          project: reopened,
          map: map.map,
          entityId: 'passer',
        );
        expect(template?.toJson(), spec.toJson());
        final configured = reopened.eventRegistry!.records
            .where(
              (record) =>
                  record.definitionOrNull?.source ==
                  NarrativeEventSourceRef.entityInteract(owner.id, 'passer'),
            )
            .toList();
        expect(configured, hasLength(2));
        for (final record in configured) {
          expect(
            reopened.scenes.map((scene) => scene.id),
            contains(record.definitionOrNull!.sceneId),
          );
        }
        expect(await unrelated.readAsBytes(), untouched);
        expect(await transportActionHistory(session), [
          'event_v2.template.apply',
        ]);
      },
    );

    test(
      'world-rule batch persists a create and update and refuses a stale batch on $storage',
      () async {
        final session = await openGameMemoryCatalog(
          catalog: catalog,
          prepared: false,
        );
        final maps = LocalMapWorkspaceAdapter();
        final original = (await maps.loadProject(session)).worldRules.single;
        final updated = WorldRuleDefinition.fromJson({
          ...original.toJson(),
          'label': 'Rencontre terminée',
        });
        final added = WorldRuleDefinition.fromJson({
          ...original.toJson(),
          'id': 'world_rule_fermeture',
          'label': 'Fermeture',
          'source': {...original.source.toJson(), 'sourceId': 'fact_door'},
        });
        final uncommitted = WorldRuleDefinition.fromJson({
          ...added.toJson(),
          'id': 'world_rule_annulation',
          'label': 'Annulation',
        });
        final world = LocalWorldAdapter(session: session, mapAdapter: maps);
        final receipt = await world.publishRuleBatch(
          rules: [
            (base: original, current: updated),
            (base: null, current: added),
          ],
        );
        expect(receipt.revision, isNot(receipt.beforeRevision));
        await expectLater(
          world.publishRuleBatch(
            rules: [
              (base: null, current: uncommitted),
              (base: original, current: original),
            ],
          ),
          throwsA(isA<WorldFailure>()),
        );
        final reopened = await LocalMapWorkspaceAdapter().loadProject(session);
        expect(reopened.worldRules, unorderedEquals([updated, added]));
        expect(await transportActionHistory(session), [
          'world_rule.upsert_batch',
        ]);
      },
    );
  }
}
