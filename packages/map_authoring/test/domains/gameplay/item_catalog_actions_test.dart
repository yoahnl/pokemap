import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ItemCatalogActions', () {
    test('registers only durable catalog mutations with full guarantees', () {
      final descriptors = ItemCatalogActions.descriptors;

      expect(
        descriptors.map((descriptor) => descriptor.id).toSet(),
        <String>{
          'item.create',
          'item.update',
          'item.clone',
          'item.delete_apply',
          'item.set_overworld_effect',
          'item.set_battle_effect',
          'item.set_held_effect',
          'item.set_capture_effect',
          'item.set_tm_hm_move',
        },
      );
      for (final descriptor in descriptors) {
        expect(
          descriptor.guarantees,
          containsAll(<AuthoringGuarantee>{
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.atomic,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable,
          }),
        );
      }
      final itemDefinition =
          AuthoringResourceKindRegistry.canonical().require('itemDefinition');
      expect(
        itemDefinition.extensions['queryActions'],
        <String>['item.delete_plan', 'item.simulate', 'item.validate'],
      );
    });

    test('plans deletion and simulates use through read-only query actions',
        () {
      final fixture = _fixture(withUsage: true);
      const service = ProjectQueryService();

      final deletion = service.query(
        fixture.snapshot,
        AuthoringQueryRequest(
          resourceKind: 'itemUsage',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          extensions: const <String, Object?>{
            'actionId': 'item.delete_plan',
            'parameters': <String, Object?>{'itemId': 'thread-charm'},
          },
        ),
      );
      final simulation = service.query(
        fixture.snapshot,
        AuthoringQueryRequest(
          resourceKind: 'itemDefinition',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['thread-charm'],
          view: AuthoringQueryView.detail,
          extensions: const <String, Object?>{
            'actionId': 'item.simulate',
            'parameters': <String, Object?>{
              'itemId': 'thread-charm',
              'context': 'overworld',
            },
          },
        ),
      );

      expect(deletion.totalAvailable, 1);
      expect(deletion.items.single['editablePath'],
          'newGame.initialBag[0].itemId');
      expect(simulation.items.single['simulation'], <String, Object?>{
        'status': 'passive',
        'context': 'overworld',
        'consumption': null,
        'target': null,
        'effect': null,
      });
    });

    test('creates one item through one atomic catalog replacement', () {
      final fixture = _fixture();
      final draft = const ItemCatalogActions().build(
        fixture.context(
          actionId: 'item.create',
          parameters: <String, Object?>{
            'definition': const ProjectItemDefinition(
              id: 'field-tonic',
              displayName: 'Field Tonic',
              pocketId: 'medicine',
              buyPrice: 300,
            ).toJson(),
          },
        ),
      );

      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.changeSet.changes.single.resource.kind, 'itemCatalog');
      expect(
        decodeProjectItemCatalog(
          jsonDecode(
            utf8.decode(draft.changeSet.changes.single.afterBytes!),
          ) as Map<String, dynamic>,
        ).entries.map((definition) => definition.id),
        <String>['thread-charm', 'field-tonic'],
      );
    });

    test('rejects deletion while editable blocking usages remain', () {
      final fixture = _fixture(withUsage: true);

      expect(
        () => const ItemCatalogActions().build(
          fixture.context(
            actionId: 'item.delete_apply',
            parameters: const <String, Object?>{'itemId': 'thread-charm'},
          ),
        ),
        throwsA(
          isA<ItemCatalogAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'item.delete_references_blocking',
              )
              .having(
                (error) => error.details['references'],
                'references',
                isNotEmpty,
              ),
        ),
      );
    });

    test('sets context effects without replacing another context', () {
      final fixture = _fixture(
        definition: const ProjectItemDefinition(
          id: 'thread-charm',
          displayName: 'Thread Charm',
          pocketId: 'custom',
          uses: <ProjectItemUseDefinition>[
            ProjectItemUseDefinition(
              contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
              target: ProjectItemTargetKind.partyMember,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.healHp(
                mode: ProjectItemAmountMode.flat,
                amount: 10,
              ),
            ),
          ],
        ),
      );
      final draft = const ItemCatalogActions().build(
        fixture.context(
          actionId: 'item.set_overworld_effect',
          parameters: <String, Object?>{
            'itemId': 'thread-charm',
            'use': const ProjectItemUseDefinition(
              contexts: <ProjectItemUseContext>{
                ProjectItemUseContext.overworld,
              },
              target: ProjectItemTargetKind.partyMember,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.healHp(
                mode: ProjectItemAmountMode.flat,
                amount: 20,
              ),
            ).toJson(),
          },
        ),
      );
      final catalog = decodeProjectItemCatalog(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>,
      );

      expect(catalog.entries.single.uses, hasLength(2));
      expect(
        catalog.entries.single.uses.expand((use) => use.contexts).toSet(),
        ProjectItemUseContext.values.toSet(),
      );
    });

    test('rejects capabilities that the runtime cannot execute', () {
      final fixture = _fixture();
      final scenarios = <(String, Map<String, Object?>)>[
        (
          'item.set_overworld_effect',
          <String, Object?>{
            'itemId': 'thread-charm',
            'use': const ProjectItemUseDefinition(
              contexts: <ProjectItemUseContext>{
                ProjectItemUseContext.overworld,
              },
              target: ProjectItemTargetKind.world,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.repel(steps: 100),
            ).toJson(),
          },
        ),
        (
          'item.set_battle_effect',
          <String, Object?>{
            'itemId': 'thread-charm',
            'use': const ProjectItemUseDefinition(
              contexts: <ProjectItemUseContext>{
                ProjectItemUseContext.battle,
              },
              target: ProjectItemTargetKind.partyMove,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.restorePp(
                mode: ProjectItemAmountMode.flat,
                amount: 10,
              ),
            ).toJson(),
          },
        ),
        (
          'item.set_held_effect',
          const <String, Object?>{
            'itemId': 'thread-charm',
            'heldEffectId': 'never_registered_effect',
          },
        ),
      ];

      for (final scenario in scenarios) {
        expect(
          () => const ItemCatalogActions().build(
            fixture.context(
              actionId: scenario.$1,
              parameters: scenario.$2,
            ),
          ),
          throwsA(
            isA<ItemCatalogAuthoringException>().having(
              (error) => error.code,
              'code',
              'item.catalog_invalid',
            ),
          ),
          reason: scenario.$1,
        );
      }
    });
  });
}

_ItemFixture _fixture({
  bool withUsage = false,
  ProjectItemDefinition definition = const ProjectItemDefinition(
    id: 'thread-charm',
    displayName: 'Thread Charm',
    pocketId: 'custom',
    buyPrice: 100,
  ),
}) {
  final catalog = ProjectItemCatalog(
    schemaVersion: 1,
    entries: <ProjectItemDefinition>[definition],
  ).normalized();
  final bytes = utf8.encode(jsonEncode(encodeProjectItemCatalog(catalog)));
  const path = 'data/pokemon/catalogs/items.json';
  final fingerprint = computeAuthoringBytesFingerprint(
    bytes,
    logicalName: path,
  );
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_items'),
    revision: 'sha256:${List<String>.filled(64, 'a').join()}',
    manifest: ProjectManifest(
      name: 'Items',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      newGame: withUsage
          ? const ProjectNewGameConfig(
              initialBag: <BagEntry>[
                BagEntry(itemId: 'thread-charm', quantity: 1),
              ],
            )
          : const ProjectNewGameConfig(),
    ),
    maps: const <MapData>[],
    itemCatalog: catalog,
    resourceFingerprints: <String, String>{
      'project': 'sha256:${List<String>.filled(64, 'b').join()}',
      itemCatalogResourceIdentity: fingerprint,
    },
    resourceBytes: <String, List<int>>{itemCatalogResourceIdentity: bytes},
    resourceStorageKeys: const <String, String>{
      itemCatalogResourceIdentity: path,
    },
  );
  return _ItemFixture(snapshot);
}

final class _ItemFixture {
  const _ItemFixture(this.snapshot);

  final ProjectSnapshot snapshot;

  AuthoringPlanningContext context({
    required String actionId,
    required Map<String, Object?> parameters,
  }) {
    return AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'req-$actionId',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'ws-items',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem-$actionId',
      ),
      planId: 'plan-items',
      seed: 17,
    );
  }
}
