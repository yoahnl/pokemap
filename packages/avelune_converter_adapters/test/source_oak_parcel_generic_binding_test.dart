import 'dart:io';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_item_bindings.dart';
import 'package:avelune_converter_adapters/src/source_oak_parcel_binding.dart';
import 'package:test/test.dart';
import 'support/oak_parcel_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  group('renamed parcel native binding', () {
    late ({
      NormalizedSourceProject source,
      ExternalOriginalFiles files
    }) original;
    setUpAll(() async {
      original = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {9},
          supplementalRoots:
              (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                      '')
                  .split('|')
                  .where((value) => value.isNotEmpty)
                  .toList());
    });
    for (final missingDex in [false, true]) {
      test(
          missingDex
              ? 'refuses the captured dex when its source row is empty'
              : 'binds captured items props rival through and dex without Kanto identities',
          () async {
        final changed = await renameBoundParcelSource(
            original.source, original.files,
            missingDex: missingDex);
        final source = changed.source;
        final analysis = SourceEventAnalyzer.forProject(source,
                profile: SourceEventProfile.forProject(source))
            .analyze();
        final event = analysis.eventAt(9, 41)!;
        final items = (await const SourceEventItemBindingResolver().read(
                snapshot: source.snapshot,
                files: changed.files,
                symbols: ['SEALEDLETTER', 'CAPSULE'],
                eventProfile: analysis.profile))
            .bindings;
        final binding = await const SourceOakParcelBindingResolver().read(
            source: source,
            analysis: analysis,
            event: event,
            files: changed.files,
            items: items);
        if (missingDex) {
          expect(binding, isNull);
          return;
        }
        expect(binding, isNotNull);
        expect(
            binding!.items.keys, unorderedEquals(['SEALEDLETTER', 'CAPSULE']));
        expect(binding.companionHashes.keys, unorderedEquals([61, 62, 63]));
        expect(
            binding.tileActors.values.map((value) => value.event.sourceEventId),
            unorderedEquals([61, 62]));
        expect(binding.inheritedThroughEvidence['sourceActorEventId'], 63);
        expect(binding.unlockedDexSourceFactId,
            endsWith(':player:pokedex:unlocked:3'));
        expect((binding.toJson()['regionalDex'] as Map)['index'], 3);
        expect(binding.dexSpecies, isNotEmpty);
        expect(binding.isBoundTo(source, analysis, event), isTrue);
      });
    }
  },
      skip: enabled
          ? false
          : 'Requires the immutable Kanto snapshot and explicitly admitted supplements.');
}
