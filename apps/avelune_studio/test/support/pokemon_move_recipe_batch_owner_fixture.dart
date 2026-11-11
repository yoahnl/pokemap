import 'dart:async';

import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_choice.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_move_recipe_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:map_authoring/map_authoring.dart';

final class RecordingMoveRecipeBatchPort
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
