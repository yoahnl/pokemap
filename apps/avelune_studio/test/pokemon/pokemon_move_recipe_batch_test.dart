import 'dart:async';

import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_choice.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:avelune_studio/presentation/features/pokemon/pokemon_moves_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

final class _Port
    implements
        PokemonWorkspacePort,
        PokemonMoveRecipePort,
        PokemonMoveRecipeBatchPort {
  final pending = Completer<BattleMoveRecipeBatchResult>();
  int calls = 0;
  int preparations = 0;
  final starts = <int>[];
  final revisions = <String?>[];
  Future<BattleMoveRecipeBatchResult> Function(
    int start,
    bool Function()? cancelled,
    void Function(BattleMoveRecipeBatchEntry)? progress,
  )?
  handler;

  @override
  bool get supportsMoveRecipes => true;
  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async =>
      const PokemonSpeciesBundle(
        species: PokemonDocumentSource(
          family: PokemonDocumentFamily.species,
          relativePath: 'species.json',
          bytes: null,
          document: {'id': 'test', 'name': 'Avant'},
        ),
        learnset: null,
        evolution: null,
        media: null,
      );
  @override
  Future<void> prepareMoveRecipes() async {}
  @override
  Future<List<PokemonMoveRecipeChoice>> listMoveRecipes(
    String projectMoveId,
  ) async => [];
  @override
  Future<bool> importMoveRecipe(
    String projectMoveId,
    PokemonMoveRecipeChoice choice, {
    bool Function()? isCurrent,
  }) async => true;
  @override
  Future<void> prepareMoveRecipeBatchProject() async {
    preparations++;
  }

  @override
  Future<BattleMoveRecipeBatchResult> importMoveRecipeBatch({
    required String operationId,
    int startIndex = 0,
    int limit = BattleMoveRecipeBatchImporter.maximumBatchSize,
    String? expectedInventoryRevision,
    bool Function()? isCancelled,
    void Function(BattleMoveRecipeBatchEntry entry)? onProgress,
  }) {
    calls++;
    starts.add(startIndex);
    revisions.add(expectedInventoryRevision);
    return handler?.call(startIndex, isCancelled, onProgress) ?? pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  PokemonWorkspaceController makeController(_Port port) {
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

  testWidgets('shows batch import and immediate analysis feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = _Port();
    void Function() changed = () {};
    final controller = PokemonWorkspaceController(
      port,
      changed: () => changed(),
    );
    controller.index = const PokemonWorkspaceIndex(
      enabled: true,
      entries: [],
      types: [],
      items: {},
      moves: PokemonMovesCatalogView(
        relativePath: 'moves',
        entries: [PokemonMoveSummary(id: 'tackle', name: 'Charge')],
      ),
    );
    await controller.prepareMoveRecipes();
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            changed = () => setState(() {});
            return Scaffold(body: PokemonMovesLibrary(controller: controller));
          },
        ),
      ),
    );
    await tester.tap(find.text('Importer les animations disponibles'));
    await tester.pump();
    expect(find.textContaining('Analyse des attaques'), findsOneWidget);
    expect(port.calls, 1);
    port.pending.complete(
      const BattleMoveRecipeBatchResult(
        total: 1,
        nextIndex: 1,
        results: [
          BattleMoveRecipeBatchEntry(
            index: 0,
            projectMoveId: 'tackle',
            status: BattleMoveRecipeBatchStatus.imported,
          ),
        ],
        inventoryRevision: 'revision',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 animation ajoutée'), findsOneWidget);
    controller.dispose();
  });

  test(
    'continues bounded slices with the same revision and keeps all results',
    () async {
      final port = _Port();
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
    final port = _Port();
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
      final port = _Port();
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
    final port = _Port();
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
      final port = _Port();
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
    final port = _Port();
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
      final port = _Port();
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

  testWidgets(
    'compact layout shows a partial summary and affected move names',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = _Port();
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
        return BattleMoveRecipeBatchResult(
          total: 3,
          nextIndex: start + entries.length,
          results: entries,
          inventoryRevision: 'rev',
        );
      };
      void Function() changed = () {};
      final fixture = makeController(port);
      final controller = PokemonWorkspaceController(
        port,
        changed: () => changed(),
      );
      controller.index = fixture.index;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              changed = () => setState(() {});
              return Scaffold(
                body: PokemonMovesLibrary(controller: controller),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Importer les animations disponibles'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 animation ajoutée'), findsOneWidget);
      expect(find.text('Voir les attaques non ajoutées'), findsOneWidget);
      await tester.tap(find.text('Voir les attaques non ajoutées'));
      await tester.pumpAndSettle();
      expect(find.text('Aucune animation disponible'), findsOneWidget);
      expect(find.text('Attaque personnalisée conservée'), findsOneWidget);
      expect(tester.takeException(), isNull);
      controller.dispose();
      fixture.dispose();
    },
  );

  testWidgets('the user can stop an import and retry it', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = _Port();
    port.handler = (start, cancelled, progress) {
      if (port.calls == 1) return port.pending.future;
      return Future.value(
        const BattleMoveRecipeBatchResult(
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
        ),
      );
    };
    void Function() changed = () {};
    final fixture = makeController(port);
    final controller = PokemonWorkspaceController(
      port,
      changed: () => changed(),
    );
    controller.index = fixture.index;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            changed = () => setState(() {});
            return Scaffold(body: PokemonMovesLibrary(controller: controller));
          },
        ),
      ),
    );
    await tester.tap(find.text('Importer les animations disponibles'));
    await tester.pump();
    await tester.tap(find.text('Arrêter l’import'));
    await tester.pump();
    expect(find.textContaining('Arrêt en cours'), findsOneWidget);
    port.pending.complete(
      const BattleMoveRecipeBatchResult(
        total: 1,
        nextIndex: 0,
        results: [],
        inventoryRevision: 'rev',
        stopped: 'cancelled',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Import arrêté'), findsOneWidget);
    expect(find.text('1 attaque(s) non traitée(s).'), findsOneWidget);
    await tester.tap(find.text('Importer les animations disponibles'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 déjà présente'), findsOneWidget);
    controller.dispose();
    fixture.dispose();
  });
}
