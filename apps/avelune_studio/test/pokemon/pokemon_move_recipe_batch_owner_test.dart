import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/pokemon_move_recipe_batch_owner_fixture.dart';

void main() {
  PokemonWorkspaceController makeController(RecordingMoveRecipeBatchPort port) {
    final controller = PokemonWorkspaceController(port, changed: () {});
    controller.index = const PokemonWorkspaceIndex(
      enabled: true,
      entries: [],
      types: [],
      items: {},
      moves: PokemonMovesCatalogView(
        relativePath: 'moves',
        entries: [
          PokemonMoveSummary(id: 'tackle', name: 'Charge'),
          PokemonMoveSummary(id: 'surf', name: 'Surf'),
          PokemonMoveSummary(id: 'custom', name: 'Création', userCreated: true),
        ],
      ),
    );
    return controller;
  }

  test(
    'continues bounded slices with the same revision and keeps all results',
    () async {
      final port = RecordingMoveRecipeBatchPort();
      port.handler = (start, cancelled, progress) async {
        final entries = start == 0
            ? [
                const BattleMoveRecipeBatchEntry(
                  index: 0,
                  projectMoveId: 'tackle',
                  status: BattleMoveRecipeBatchStatus.imported,
                ),
              ]
            : [
                const BattleMoveRecipeBatchEntry(
                  index: 1,
                  projectMoveId: 'surf',
                  status: BattleMoveRecipeBatchStatus.missing,
                ),
                const BattleMoveRecipeBatchEntry(
                  index: 2,
                  projectMoveId: 'custom',
                  status: BattleMoveRecipeBatchStatus.custom,
                ),
              ];
        for (final entry in entries) {
          progress?.call(entry);
        }
        return BattleMoveRecipeBatchResult(
          total: 3,
          nextIndex: start + entries.length,
          results: entries,
          inventoryRevision: 'same-revision',
        );
      };
      final controller = makeController(port);
      await controller.importMoveRecipeBatch();
      expect(port.starts, [0, 1]);
      expect(port.revisions, [null, 'same-revision']);
      expect(controller.recipeBatchProcessed, 3);
      expect(controller.recipeBatchResults.map((e) => e.status), [
        BattleMoveRecipeBatchStatus.imported,
        BattleMoveRecipeBatchStatus.missing,
        BattleMoveRecipeBatchStatus.custom,
      ]);
      expect(controller.recipeBatchStopped, isNull);
      controller.dispose();
    },
  );

  test('cancels an active slice and keeps completed results', () async {
    final port = RecordingMoveRecipeBatchPort();
    bool Function()? cancelled;
    port.handler = (start, isCancelled, progress) {
      if (start == 0) {
        return Future.value(
          const BattleMoveRecipeBatchResult(
            total: 3,
            nextIndex: 1,
            results: [
              BattleMoveRecipeBatchEntry(
                index: 0,
                projectMoveId: 'tackle',
                status: BattleMoveRecipeBatchStatus.imported,
              ),
            ],
            inventoryRevision: 'rev',
          ),
        );
      }
      cancelled = isCancelled;
      return port.pending.future;
    };
    final controller = makeController(port);
    final run = controller.importMoveRecipeBatch();
    await Future<void>.delayed(Duration.zero);
    expect(port.starts, [0, 1]);
    controller.stopMoveRecipeBatch();
    expect(cancelled!(), isTrue);
    port.pending.complete(
      const BattleMoveRecipeBatchResult(
        total: 3,
        nextIndex: 1,
        results: [],
        inventoryRevision: 'rev',
        stopped: 'cancelled',
      ),
    );
    await run;
    expect(controller.recipeBatchStopped, 'cancelled');
    expect(
      controller.recipeBatchResults.single.status,
      BattleMoveRecipeBatchStatus.imported,
    );
    expect(controller.recipeBatchTotal! - controller.recipeBatchProcessed, 2);
    controller.dispose();
  });

  test(
    'stops on a network error and a retry starts from the beginning',
    () async {
      final port = RecordingMoveRecipeBatchPort();
      port.handler = (start, cancelled, progress) async => port.calls == 1
          ? const BattleMoveRecipeBatchResult(
              total: 1,
              nextIndex: 1,
              results: [
                BattleMoveRecipeBatchEntry(
                  index: 0,
                  projectMoveId: 'tackle',
                  status: BattleMoveRecipeBatchStatus.failed,
                  reason: 'network',
                ),
              ],
              inventoryRevision: 'rev',
              stopped: 'network',
            )
          : const BattleMoveRecipeBatchResult(
              total: 1,
              nextIndex: 1,
              results: [
                BattleMoveRecipeBatchEntry(
                  index: 0,
                  projectMoveId: 'tackle',
                  status: BattleMoveRecipeBatchStatus.alreadyPresent,
                ),
              ],
              inventoryRevision: 'rev',
            );
      final controller = makeController(port);
      await controller.importMoveRecipeBatch();
      expect(controller.recipeBatchStopped, 'network');
      await controller.importMoveRecipeBatch();
      expect(port.starts, [0, 0]);
      expect(controller.recipeBatchStopped, isNull);
      expect(
        controller.recipeBatchResults.single.status,
        BattleMoveRecipeBatchStatus.alreadyPresent,
      );
      controller.dispose();
    },
  );

  test('prepares an older project only when explicitly requested', () async {
    final port = RecordingMoveRecipeBatchPort();
    port.handler = (start, cancelled, progress) async =>
        const BattleMoveRecipeBatchResult(
          total: 3,
          nextIndex: 0,
          results: [],
          inventoryRevision: 'rev',
          stopped: 'preparationRequired',
        );
    final controller = makeController(port);
    await controller.importMoveRecipeBatch();
    expect(controller.recipeBatchStopped, 'preparationRequired');
    expect(port.preparations, 0);
    await controller.prepareMoveRecipeBatchProject();
    expect(port.preparations, 1);
    expect(controller.recipeBatchStopped, 'prepared');
    controller.dispose();
  });

  test(
    'a concurrent catalogue change keeps the earlier import and stops',
    () async {
      final port = RecordingMoveRecipeBatchPort();
      port.handler = (start, cancelled, progress) async {
        if (start > 0) {
          throw const CatalogStorageException(
            'catalog.revision_conflict',
            'changed',
          );
        }
        return const BattleMoveRecipeBatchResult(
          total: 3,
          nextIndex: 1,
          results: [
            BattleMoveRecipeBatchEntry(
              index: 0,
              projectMoveId: 'tackle',
              status: BattleMoveRecipeBatchStatus.imported,
            ),
          ],
          inventoryRevision: 'rev',
        );
      };
      final controller = makeController(port);
      await controller.importMoveRecipeBatch();
      expect(controller.recipeBatchStopped, 'projectChanged');
      expect(
        controller.recipeBatchResults.single.status,
        BattleMoveRecipeBatchStatus.imported,
      );
      expect(controller.recipeBatchTotal! - controller.recipeBatchProcessed, 2);
      controller.dispose();
    },
  );

  test('refuses a batch while a Pokémon draft has unsaved edits', () async {
    final port = RecordingMoveRecipeBatchPort();
    final controller = makeController(port);
    controller.index = PokemonWorkspaceIndex(
      enabled: true,
      types: const [],
      items: const {},
      moves: controller.index!.moves,
      entries: const [
        PokemonSpeciesSummary(
          id: 'test',
          name: 'Test',
          nationalDex: 1,
          generation: 1,
          types: [],
          formIds: [],
          mediaRelativePath: '',
          enabled: true,
          relativePath: 'species.json',
        ),
      ],
    );
    await controller.selectSpecies('test');
    controller.edit(
      PokemonDocumentFamily.species,
      (json) => json['name'] = 'Après',
    );
    expect(controller.hasPendingChanges, isTrue);
    await controller.importMoveRecipeBatch();
    expect(port.calls, 0);
    controller.dispose();
  });

  test(
    'refuses to start during another operation and stops on disposal',
    () async {
      final port = RecordingMoveRecipeBatchPort();
      bool Function()? cancelled;
      port.handler = (start, isCancelled, progress) {
        cancelled = isCancelled;
        return port.pending.future;
      };
      final controller = makeController(port);
      controller.syncing = true;
      await controller.importMoveRecipeBatch();
      expect(port.calls, 0);
      controller.syncing = false;
      final run = controller.importMoveRecipeBatch();
      controller.dispose();
      expect(cancelled!(), isTrue);
      port.pending.complete(
        const BattleMoveRecipeBatchResult(
          total: 3,
          nextIndex: 0,
          results: [],
          inventoryRevision: 'rev',
          stopped: 'cancelled',
        ),
      );
      await run;
      expect(port.calls, 1);
    },
  );
}
