import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_town_map_original_fixture.dart';

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('source Everstone passive held binding', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    setUpAll(() async {
      final fixture = await readOriginalTownMapSource(
          archivePath: archive!, sourceRoot: root!);
      source = fixture.$1;
      files = fixture.$2;
    });
    test(
        'the exact compiled symbol and attested oracle qualify the native passive policy',
        () async {
      final items = await const SourceEventItemBindingResolver().read(
          snapshot: source.snapshot,
          files: files,
          symbols: ['EVERSTONE', 'HARDSTONE'],
          eventProfile: SourceEventProfile.kantoForProject(source));
      final binding = items.bindings['EVERSTONE']!;
      expect(binding.definition.id, startsWith('source-item-'));
      expect(binding.definition.heldEffectId,
          PokemonPassiveHeldEffect.preventEvolution.id);
      expect(items.bindings['HARDSTONE']!.definition.heldEffectId, isNull);
      final evidence = binding.toJson()['passiveHeldEffect'] as Map;
      expect(evidence['physicalItemId'], binding.definition.id);
      expect(evidence['evolutionScope'], ['trade', 'levelUp', 'itemUse']);
      expect(evidence['nativeCombatPolicy'], 'explicitPassiveNeutral');
      expect(evidence['consumedByEvolutionPrevention'], false);
      expect(evidence['sourceScriptsExecuted'], 0);
      expect(binding.toJson()['fullUseParityQualified'], false);
    });
    test(
        'unknown script provenance is rejected before any capability is created',
        () async {
      await expectLater(
          const SourceEventItemBindingResolver().read(
              snapshot: source.snapshot,
              files: files,
              symbols: ['EVERSTONE'],
              eventProfile: SourceEventProfile.kantoForProject(source,
                  scriptsArchiveHash: Sha256Hash('0' * 64))),
          throwsA(isA<ContractError>()));
    });
    test(
        'absent script provenance preserves data without a native held capability',
        () async {
      final items = await const SourceEventItemBindingResolver().read(
          snapshot: source.snapshot, files: files, symbols: ['EVERSTONE']);
      expect(items.bindings['EVERSTONE']!.definition.heldEffectId, isNull);
      expect(
          items.bindings['EVERSTONE']!
              .toJson()
              .containsKey('passiveHeldEffect'),
          false);
    });
  },
      skip: archive == null || root == null
          ? 'Original source archive/root required.'
          : false);
}
