import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:test/test.dart';

import 'support/native_catalog_quarantine_fixture.dart';

void main() {
  final sourceRoot =
      Platform.environment['AVELUNE_KANTO_NATIVE_TRAINER_SOURCE_ROOT'];
  test('all eleven native trainer declarations precede NPC and Scene consumers',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('native-trainer-order-');
    try {
      final composition = await composeNativeCatalogQuarantineFixture(
        sourceRoot: sourceRoot!,
        outputParentPath: temporary.path,
        includeNativeTrainerConsumers: true,
      );
      final mutations = composition.draft.mutations;
      final definitions = mutations
          .where((mutation) => mutation.actionId == 'campaign.trainer.upsert')
          .toList();
      final consumers = mutations
          .where((mutation) =>
              mutation.operationId.value.startsWith('native-consumer-'))
          .toList();
      expect(definitions, hasLength(11));
      expect(consumers, hasLength(22));
      final firstConsumer = mutations.indexOf(consumers.first);
      for (final definition in definitions) {
        expect(mutations.indexOf(definition), lessThan(firstConsumer));
      }
      expect(consumers.where((mutation) => mutation.actionId == 'scene.upsert'),
          hasLength(11));
      expect(
          consumers.where((mutation) => mutation.actionId == 'entity.upsert'),
          hasLength(11));
    } finally {
      await temporary.delete(recursive: true);
    }
  },
      timeout: const Timeout(Duration(minutes: 3)),
      skip: sourceRoot == null ? 'Requires exact source data.' : false);
  test('native catalog publication excludes all source-only runtime consumers',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('native-catalog-quarantine-');
    try {
      final composition = await composeNativeCatalogQuarantineFixture(
        sourceRoot: sourceRoot!,
        outputParentPath: temporary.path,
      );
      final projection = composition.projection;
      final bundle = NativePsdkTrainerBundle.builtin();
      final species = projection.documents
          .where(
              (document) => document.kind == SourceCatalogDocumentKind.species)
          .toList();
      expect(species.map((document) => document.document['id']).toSet(),
          bundle.speciesById.keys.toSet());
      expect(projection.trainers, hasLength(11));
      expect(
          projection.trainers
              .every((trainer) => trainer.tags.contains('native-roster-bound')),
          isTrue);
      expect(projection.encounterTables, isEmpty);
      for (final catalog in bundle.catalogs.values) {
        final document = projection.documents.singleWhere(
            (document) => document.document['catalog'] == catalog.catalog);
        expect(document.document, catalog.toJson());
      }
      final sourceOnly = projection.evidence['sourceOnlyData'] as Map;
      expect(
          (sourceOnly['documents'] as List)
              .where((document) => (document as Map)['kind'] == 'species'),
          isNotEmpty);
      expect(
          (sourceOnly['trainers'] as List)
              .cast<Map>()
              .where((trainer) => const {'Dana', 'Lenny', 'Lucas', 'Oliver'}
                  .contains(trainer['name']))
              .map((trainer) => trainer['name'])
              .toSet(),
          {'Dana', 'Lenny', 'Lucas', 'Oliver'});
      expect(sourceOnly['encounterTables'] as List, hasLength(2));
      final active = composition.draft.mutations;
      expect(
          active.where(
              (mutation) => mutation.actionId == 'campaign.trainer.upsert'),
          hasLength(11));
      expect(
          active.where((mutation) =>
              mutation.actionId == 'campaign.encounter_table.upsert'),
          isEmpty);
      final documents = active
          .where((mutation) => mutation.actionId == 'pokemon.documents.write')
          .expand((mutation) => mutation.parameters['documents'] as List)
          .cast<Map>();
      expect(
          documents.where(
              (document) => document['actionId'] == 'pokemon.species.write'),
          hasLength(68));
      expect(jsonEncode(documents.toList()), isNot(contains('source-pbs-')));
      final output =
          Platform.environment['AVELUNE_NATIVE_CATALOG_QUARANTINE_OUTPUT'];
      if (output != null) {
        final directory = Directory(output);
        await directory.create(recursive: true);
        await File('$output/mutations.json').writeAsString(jsonEncode(
            [for (var i = 0; i < active.length; i++) active[i].toJson(i)]));
        await File('$output/projection.json')
            .writeAsString(jsonEncode(projection.toJson()));
        await File('$output/composition-evidence.json')
            .writeAsString(jsonEncode(composition.draft.compositionEvidence));
      }
    } finally {
      await temporary.delete(recursive: true);
    }
  },
      timeout: const Timeout(Duration(minutes: 3)),
      skip: sourceRoot == null ? 'Requires exact source data.' : false);
}
