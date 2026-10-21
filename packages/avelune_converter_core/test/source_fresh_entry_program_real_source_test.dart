import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/interpretation_profile_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final enabled = root != null &&
      snapshot != null &&
      Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] != null;
  Future<NormalizedSourceProject> read(
      {Map<String, List<int>> overrides = const {},
      Set<int> selected = const {1, 2}}) async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: selected, overrideBytes: overrides);
    return const RmxpSourceNormalizer().normalize(
      snapshot: fixture.source.snapshot,
      files: _FreshFiles(fixture.files),
      selectedMapIds: selected,
      includeEventSystem: true,
      interpretationProfile: externalOracleInterpretationProfile(),
    );
  }

  group('attested fresh source entry', () {
    test(
        'binds System, dispatcher and introduction without creating native rewards',
        () async {
      final source = await read();
      final entry = sourceFreshEntryProgram(source);
      expect(entry, isNotNull);
      expect(entry!.isBoundTo(source), isTrue);
      expect((entry.startSourceMapId, entry.startX, entry.startY), (2, 0, 1));
      expect((
        entry.introSourceMapId,
        entry.introSourceEventId,
        entry.introX,
        entry.introY
      ), (
        1,
        1,
        0,
        0
      ));
      expect((entry.regionVariableId, entry.regionValue), (50, 1));
      expect(entry.sourceOutfit, 1);
      expect(entry.spriteLockSwitchId, 98);
      expect(entry.startingOverSwitchId, 1);
      expect(entry.completedSwitchId, 99);
      expect(entry.intro.targetMapId, 7);
      expect((entry.intro.targetX, entry.intro.targetY), (27, 8));
      final json = entry.toJson();
      expect(json['requiredNativeEntryState'],
          'freshGameWithEmptyPartyAndStorage');
      expect(json['otherDispatcherBranches'], 'preservedNotQualified');
      expect(json['nativeExecutionQualified'], isFalse);
      expect(json['sourceScriptsExecuted'], 0);
      expect(json['aiCalls'], 0);
      final effects = json['effects'] as List;
      expect((effects.first as Map)['sourceMapId'], 2);
      expect((effects.first as Map)['x'], 0);
      expect((effects.first as Map)['y'], 1);
      expect(effects.map((v) => (v as Map)['kind']), [
        'recordRecoveryPoint',
        'setIntegerVariable',
        'setPlayerOutfit',
        'disableFollowers',
        'transferToIntro'
      ]);
      expect(entry.dispatcherRawDataRef.locator!.file, 'Data/Map002.rxdata');
      expect(entry.intro.rawDataRef.locator!.file, 'Data/Map001.rxdata');
    });
    for (final row in [
      (
        'Data/Map002.rxdata',
        'FollowingPkmn.toggle_off',
        'FollowingPkmn.toggle_on'
      ),
      ('Data/Map002.rxdata', 'pbSetPokemonCenter', 'pbHealAll'),
      (
        'Data/Map002.rxdata',
        r'$player.outfit = pbGet(50)',
        r'$player.outfit = pbGet(49)'
      ),
      (
        'Data/Map002.rxdata',
        'change_disc(pbGet(50))',
        'change_disc(pbGet(49))'
      ),
      ('Data/Map001.rxdata', 'pbSet(28, "Gary")', 'pbSet(29, "Gary")'),
    ]) {
      test('rejects changed source semantics ${row.$2}', () async {
        final changed = await read(overrides: {
          row.$1: _replaceLiteral(
              await File('$root/${row.$1}').readAsBytes(), row.$2, row.$3)
        });
        expect(sourceFreshEntryProgram(changed), isNull);
      });
    }
    for (final field in ['@start_map_id', '@start_x', '@start_y']) {
      test('rejects a changed System entry $field', () async {
        final bytes = await File('$root/Data/System.rxdata').readAsBytes();
        final doc = const MarshalDecoder().decode(bytes);
        final pair = doc
            .node(doc.rootId)
            .instanceVariables
            .singleWhere((pair) => doc.node(pair.key).name == field);
        final value = doc.node(pair.value);
        expect(value.kind, MarshalKind.integer);
        final offset = value.location.byteOffset;
        expect(bytes[offset], 105);
        final next = [
          ...bytes.take(offset),
          105,
          value.integerValue!.toInt() + 6,
          ...bytes.skip(offset + 2)
        ];
        final changed = await read(overrides: {'Data/System.rxdata': next});
        expect(sourceFreshEntryProgram(changed), isNull);
      });
    }
    test('requires an attested interpretation profile', () async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: const {1, 2});
      expect(sourceFreshEntryProgram(fixture.source), isNull);
    });
    test('requires the dispatcher and intro in the same normalized source',
        () async {
      for (final selected in [
        const {1},
        const {2}
      ]) {
        expect(sourceFreshEntryProgram(await read(selected: selected)), isNull);
      }
    });
    test(
        'binds text changes to a new proof instead of reusing another snapshot',
        () async {
      final original = sourceFreshEntryProgram(await read())!;
      final path = 'Data/Map001.rxdata';
      final changed = await read(overrides: {
        path: _replaceLiteral(
            await File('$root/$path').readAsBytes(),
            r'\bHello, there! Glad to meet you!',
            r'\bHello, traveler! Welcome to Kanto!')
      });
      expect(original.isBoundTo(changed), isFalse);
      final rebound = sourceFreshEntryProgram(changed);
      expect(rebound, isNotNull);
      expect(rebound!.programHash, isNot(original.programHash));
    });
  },
      skip: enabled
          ? false
          : 'Requires explicit immutable original source and interpretation profile.');
}

List<int> _replaceLiteral(List<int> bytes, String before, String after) {
  final old = utf8.encode(before), next = utf8.encode(after);
  if (old.length >= 123 || next.length >= 123) {
    throw StateError('Fixture quota');
  }
  final pattern = [34, old.length + 5, ...old];
  for (var i = 0; i <= bytes.length - pattern.length; i++) {
    if (List.generate(pattern.length, (j) => bytes[i + j] == pattern[j])
        .every((v) => v)) {
      return [
        ...bytes.take(i),
        34,
        next.length + 5,
        ...next,
        ...bytes.skip(i + pattern.length)
      ];
    }
  }
  throw StateError('Missing source literal: $before');
}

final class _FreshFiles implements SourceFilePort {
  const _FreshFiles(this.primary);
  final ExternalOriginalFiles primary;
  @override
  Future<List<int>> read(ConverterId id) async {
    if (primary.overrideBytes.containsKey(primary.snapshot.entries
        .singleWhere((e) => e.fileId == id)
        .relativePath)) {
      return primary.read(id);
    }
    final entry = primary.snapshot.entries.singleWhere((e) => e.fileId == id);
    for (final root in [
      primary.root,
      ...(Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((v) => v.isNotEmpty)
    ]) {
      final file = File('$root/${entry.relativePath}');
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (bytes.length == entry.byteLength &&
          crypto.sha256.convert(bytes).toString() == entry.sha256?.value) {
        return bytes;
      }
    }
    return primary.read(id);
  }
}
