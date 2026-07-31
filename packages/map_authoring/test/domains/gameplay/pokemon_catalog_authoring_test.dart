import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('Pokemon catalog authoring', () {
    test('generic catalog edits preserve unknown JSON fields losslessly', () {
      final catalog = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.catalog,
        {
          'schemaVersion': 1,
          'kind': 'pokemon_catalog',
          'catalog': 'moves',
          'vendorExtension': {'kept': true},
          'entries': [
            {
              'id': 'tackle',
              'power': 40,
              'custom': ['legacy']
            },
          ],
        },
      );

      final updated = const PokemonCatalogAuthoringService().upsertEntry(
        catalog,
        {
          'id': 'ember',
          'power': 40,
          'custom': {'source': 'manual'}
        },
      );

      expect(updated.toJson()['vendorExtension'], {'kept': true});
      expect(
        (updated.toJson()['entries'] as List).first,
        {
          'id': 'tackle',
          'power': 40,
          'custom': ['legacy']
        },
      );
      expect(jsonDecode(jsonEncode(updated.toJson())), updated.toJson());
    });

    test('batch validation reports broken evolution and media references', () {
      final species = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.species,
        {
          'id': 'sproutle',
          'forms': {'entries': []}
        },
      );
      final evolution = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.evolution,
        {
          'speciesId': 'sproutle',
          'evolutions': [
            {'targetSpeciesId': 'missing', 'method': 'level'},
          ],
        },
      );
      final media = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.media,
        {
          'speciesId': 'sproutle',
          'defaultFormId': 'base',
          'variants': <String, Object?>{},
        },
      );

      final report = const PokemonDataBatchValidator().validate(
        species: [species],
        evolutions: [evolution],
        media: [media],
      );

      expect(report.canPublish, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        containsAll({'evolution.target_missing', 'media.default_form_missing'}),
      );
    });

    test('network import remains blocked without an explicit opt-in', () {
      final blocked = const PokemonImportPlanner().preview(
        sourceId: 'pokeapi',
        requiresNetwork: true,
        allowNetwork: false,
        documents: const [],
      );
      final ready = const PokemonImportPlanner().preview(
        sourceId: 'pokeapi',
        requiresNetwork: true,
        allowNetwork: true,
        documents: const [],
      );

      expect(blocked.canApply, isFalse);
      expect(blocked.sideEffectsApplied, isFalse);
      expect(ready.canApply, isTrue);
      expect(ready.networkAuthorized, isTrue);
    });

    test('registered document actions cover all Pokemon file families', () {
      final actionIds = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        actionIds,
        containsAll({
          'pokemon.catalog.write',
          'pokemon.species.write',
          'pokemon.species.delete',
          'pokemon.learnset.write',
          'pokemon.evolution.write',
          'pokemon.media.write',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        contains('pokemonDocument'),
      );
    });
  });
}
