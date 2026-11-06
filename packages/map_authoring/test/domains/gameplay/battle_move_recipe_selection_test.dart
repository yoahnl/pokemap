import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

final class _Transport implements PokemonBoundedExternalHttpTransport {
  _Transport(this.entries, {this.status = 200});

  final List<Map<String, Object?>> entries;
  final int status;
  final requests = <Uri>[];

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    requests.add(uri);
    final body = jsonEncode(entries);
    return PokemonExternalHttpResponse(
        statusCode: status,
        headers: const {},
        body: body,
        bodyBytes: Uint8List.fromList(utf8.encode(body)));
  }
}

Map<String, Object?> _entry(String id, String style,
        {String move = 'tackle', Object? variant = 'Tackle'}) =>
    {
      'id': id,
      'sha256': 'a' * 64,
      'contentType': 'application/vnd.avelune.battle-recipe+json',
      'usage': 'battle',
      'representation': 'recipe',
      'style': style,
      'metadata': {
        'recipeId': id,
        'moveSourceId': move,
        'variant': variant,
        'revision': '1',
        'bindings': <String, String>{},
      }
    };

BattleRecipeProjectBinding _binding(BattleMoveRecipeCandidate candidate,
        {String? release}) =>
    BattleRecipeProjectBinding(
      binding: BattleMoveRecipeBinding.fromJson({
        ...candidate.binding.toJson(),
        if (release != null) 'catalogReleaseId': release,
      }),
      catalogMoveId: candidate.catalogMoveId,
      recipeMediaId: candidate.mediaId,
    );

void main() {
  test('uses explicit identities and does not guess unknown names', () {
    expect(battleRecipeCatalogMoveId('tackle'), 'tackle');
    expect(battleRecipeCatalogMoveId('surf'), 'surf');
    expect(battleRecipeCatalogMoveId('smoke_screen'), 'smokescreen');
    expect(battleRecipeCatalogMoveId('faint_attack'), 'feint-attack');
    expect(battleRecipeCatalogMoveId('selfdestruct'), 'self-destruct');
    expect(battleRecipeCatalogMoveId('made_up_attack'), isNull);
    expect(battleRecipeCatalogMoveId('../tackle'), isNull);
  });

  test('looks up aliases on their real catalog identities', () async {
    for (final pair in {
      'smoke_screen': 'smokescreen',
      'faint_attack': 'feint-attack',
      'selfdestruct': 'self-destruct',
    }.entries) {
      final transport =
          _Transport([_entry('source', 'gen5-bw2', move: pair.value)]);
      final source = BattleMoveRecipeCatalogSource(
          AvelunePokemonMediaSource(client: transport, release: 'old-release'));
      final candidate = (await source.list(pair.key)).single;
      expect(candidate.catalogMoveId, pair.value);
      expect(candidate.binding.projectMoveId, pair.key);
      expect(transport.requests.single.path, endsWith('/${pair.value}'));
    }
  });

  test('keeps the existing explicit individual lookup for unknown identities',
      () async {
    final transport = _Transport([_entry('source', 'gen5', move: 'origin')]);
    final source = BattleMoveRecipeCatalogSource(
        AvelunePokemonMediaSource(client: transport, release: 'old-release'));
    await expectLater(source.list('made_up_attack'), throwsFormatException);
    final choice =
        (await source.list('made_up_attack', manualSelection: true)).single;
    expect(choice.catalogMoveId, 'made-up-attack');
    expect(choice.binding.sourceMoveId, 'origin');
  });

  test('inventory selection never looks up custom or uncertain moves',
      () async {
    BattleMoveRecipeInventoryEntry entry(
            String id,
            BattleMoveRecipeInventoryStatus status,
            BattleMoveRecipeInventoryReason reason) =>
        BattleMoveRecipeInventoryEntry(
            index: 0,
            projectMoveId: id,
            catalogMoveId: 'tackle',
            status: status,
            reason: reason,
            existing: null);
    final custom = entry('tackle', BattleMoveRecipeInventoryStatus.custom,
        BattleMoveRecipeInventoryReason.custom);
    final uncertain = entry('tackle', BattleMoveRecipeInventoryStatus.uncertain,
        BattleMoveRecipeInventoryReason.uncertainProvenance);
    final ready = entry('tackle', BattleMoveRecipeInventoryStatus.eligible,
        BattleMoveRecipeInventoryReason.ready);
    final inventory = BattleMoveRecipeInventory(
        catalogRelease: 'old-release', moves: [custom, uncertain, ready]);
    final transport = _Transport([_entry('source', 'gen5-bw2')]);
    final source = BattleMoveRecipeCatalogSource(
        AvelunePokemonMediaSource(client: transport, release: 'old-release'));
    expect((await inventory.select(custom, source)).status,
        BattleMoveRecipeSelectionStatus.custom);
    expect((await inventory.select(uncertain, source)).status,
        BattleMoveRecipeSelectionStatus.uncertain);
    expect(transport.requests, isEmpty);
    expect((await inventory.select(ready, source)).status,
        BattleMoveRecipeSelectionStatus.available);
    expect(transport.requests, hasLength(1));
    final wrongRelease = BattleMoveRecipeCatalogSource(
        AvelunePokemonMediaSource(client: transport, release: 'new-release'));
    await expectLater(inventory.select(ready, wrongRelease), throwsStateError);
    expect(transport.requests, hasLength(1));
  });

  test('prefers a single BW2 recipe and protects existing bindings', () async {
    final transport = _Transport([
      _entry('pilot', 'gen5-pilot', variant: 'default'),
      _entry('source', 'gen5-bw2'),
    ]);
    final source = BattleMoveRecipeCatalogSource(
        AvelunePokemonMediaSource(client: transport, release: 'old-release'));
    final choices = await source.list('tackle');
    final selected = selectBattleMoveRecipe(choices);
    expect(selected.status, BattleMoveRecipeSelectionStatus.available);
    expect(selected.candidate!.mediaId, 'source');
    expect(selected.isPilotFallback, isFalse);
    expect(
        selectBattleMoveRecipe(choices, existing: _binding(selected.candidate!))
            .status,
        BattleMoveRecipeSelectionStatus.alreadyPresent);
    expect(
        selectBattleMoveRecipe(choices,
                existing: _binding(selected.candidate!, release: 'another'))
            .status,
        BattleMoveRecipeSelectionStatus.preserved);
    expect(transport.requests.single.path, contains('/old-release/'));
  });

  test('flags ambiguity, absence and a single pilot fallback', () async {
    Future<List<BattleMoveRecipeCandidate>> list(
        List<Map<String, Object?>> entries) {
      return BattleMoveRecipeCatalogSource(AvelunePokemonMediaSource(
              client: _Transport(entries), release: 'old-release'))
          .list('tackle');
    }

    expect(
        selectBattleMoveRecipe(await list([
          _entry('a', 'gen5-bw2'),
          _entry('b', 'gen5-bw2'),
        ]))
            .status,
        BattleMoveRecipeSelectionStatus.ambiguous);
    expect(selectBattleMoveRecipe(await list([])).status,
        BattleMoveRecipeSelectionStatus.missing);
    final pilot = selectBattleMoveRecipe(
        await list([_entry('pilot', 'gen5-pilot', variant: 'default')]));
    expect(pilot.status, BattleMoveRecipeSelectionStatus.available);
    expect(pilot.isPilotFallback, isTrue);
  });

  test('rejects invalid metadata and a recipe for another move', () async {
    for (final entry in [
      _entry('bad', 'gen5-bw2', variant: ''),
      _entry('wrong', 'gen5-bw2', move: 'surf'),
      {..._entry('bad-bindings', 'gen5-bw2'), 'metadata': <String, Object?>{}},
      {..._entry('bad-type', 'gen5-bw2'), 'contentType': 'image/png'},
    ]) {
      final source = BattleMoveRecipeCatalogSource(AvelunePokemonMediaSource(
          client: _Transport([entry]), release: 'old-release'));
      await expectLater(source.list('tackle'), throwsFormatException);
    }
  });

  test('an unavailable release is an error, not an empty result', () async {
    final source = BattleMoveRecipeCatalogSource(AvelunePokemonMediaSource(
        client: _Transport([], status: 404), release: 'missing-release'));
    await expectLater(source.list('surf'), throwsA(isA<Exception>()));
  });
}
