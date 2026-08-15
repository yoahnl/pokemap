import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Pokemon catalog authoring', () {
    test('generic catalog edits canonicalize the document envelope', () {
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

      expect(updated.toJson().containsKey('vendorExtension'), isFalse);
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

    test('shared codecs reject future schemas for every document family', () {
      final futureSchema = currentPokemonDataSchemaVersion + 1;
      final documents = <PokemonDocumentKind, Map<String, dynamic>>{
        PokemonDocumentKind.catalog: <String, dynamic>{
          'schemaVersion': futureSchema,
          'catalog': 'moves',
          'entries': <Object?>[],
        },
        PokemonDocumentKind.species: <String, dynamic>{
          'schemaVersion': futureSchema,
          'id': 'sproutle',
        },
        PokemonDocumentKind.learnset: <String, dynamic>{
          'schemaVersion': futureSchema,
          'speciesId': 'sproutle',
        },
        PokemonDocumentKind.evolution: <String, dynamic>{
          'schemaVersion': futureSchema,
          'speciesId': 'sproutle',
        },
        PokemonDocumentKind.media: <String, dynamic>{
          'schemaVersion': futureSchema,
          'speciesId': 'sproutle',
        },
      };

      for (final entry in documents.entries) {
        expect(
          () => PokemonJsonDocument.fromJson(entry.key, entry.value),
          throwsFormatException,
        );
      }
    });

    test('batch validation reports broken evolution and media references', () {
      final species = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.species,
        {
          'schemaVersion': currentPokemonDataSchemaVersion,
          'id': 'sproutle',
          'forms': {'entries': []}
        },
      );
      final evolution = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.evolution,
        {
          'schemaVersion': currentPokemonDataSchemaVersion,
          'speciesId': 'sproutle',
          'evolutions': [
            {'targetSpeciesId': 'missing', 'method': 'level'},
          ],
        },
      );
      final media = PokemonJsonDocument.fromJson(
        PokemonDocumentKind.media,
        {
          'schemaVersion': currentPokemonDataSchemaVersion,
          'speciesId': 'sproutle',
          'defaultFormId': 'base',
          'variants': <String, Object?>{},
        },
      );

      final report = const PokemonDataBatchValidator().validate(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        species: [species],
        evolutions: [evolution],
        media: [media],
      );

      expect(report.canPublish, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        containsAll({
          'evolution.target_species_missing',
          'media.default_form_missing',
        }),
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
