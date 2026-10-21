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
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final enabled = root != null && snapshot != null && profile != null;
  const sourcePath = 'Data/Map001.rxdata';
  Future<NormalizedSourceProject> read({String? before, String? after}) async {
    final overrides = <String, List<int>>{};
    if (before != null) {
      overrides[sourcePath] = _replaceLiteral(
        await File('$root/$sourcePath').readAsBytes(),
        before,
        after!,
      );
    }
    final fixture = await readExternalOriginalSource(
      root!,
      snapshot!,
      selectedMapIds: const {1},
      overrideBytes: overrides,
    );
    return const RmxpSourceNormalizer().normalize(
      snapshot: fixture.source.snapshot,
      files: _SupplementalFiles(fixture.files),
      selectedMapIds: const {1},
      includeEventSystem: true,
      interpretationProfile: externalOracleInterpretationProfile(),
    );
  }

  group('attested source introduction', () {
    test('preserves names, dialogue, empty-state requirement and destination',
        () async {
      final source = await read();
      final intro =
          sourceIntroProgram(source, sourceMapId: 1, sourceEventId: 1);
      expect(intro, isNotNull);
      expect(intro!.isBoundTo(source), isTrue);
      expect(intro.nameVariableId, 28);
      expect(intro.presetValues, ['Blue', 'Gary', 'Michael']);
      expect(intro.customChoiceLabel, 'Custom');
      expect(intro.customPrompt, "Enter \nRival's Name");
      expect(intro.opening, hasLength(8));
      expect(intro.opening.first.text, contains('Glad to meet you'));
      expect(intro.confirmed.text, contains(r'\v[28]'));
      expect(intro.closing, hasLength(3));
      expect(intro.completedSwitchId, 99);
      expect((intro.targetMapId, intro.targetX, intro.targetY), (7, 27, 8));
      expect(intro.toJson()['requiredNativeEntryState'],
          'freshGameWithEmptyPartyAndStorage');
      expect(intro.toJson()['nativeExecutionQualified'], isFalse);
      expect(intro.toJson()['sourceScriptsExecuted'], 0);
      expect(intro.rawDataRef.locator!.file, sourcePath);
    });
    for (final row in [
      (r'$player.party = pbGet(44)', r'$player.party = pbGet(45)'),
      ('pbSet(28, "Blue")', 'pbSet(29, "Blue")'),
      ('Rival\'s Name", 1, 7, "", ', 'Rival\'s Name", 1, 8, "", '),
      (
        'pbToneChangeAll(Tone.new(0,0,0,0),20)',
        'pbToneChangeAll(Tone.new(0,0,0,0),21)'
      ),
      ('pbSet(28, "Gary")', 'pbSet(28, "Gary"); arbitrary_call()'),
    ]) {
      test('refuses a changed effect or control expression ${row.$1}',
          () async {
        final changed = await read(before: row.$1, after: row.$2);
        expect(sourceIntroProgram(changed, sourceMapId: 1, sourceEventId: 1),
            isNull);
      });
    }
    test('keeps source text editable without reusing another snapshot proof',
        () async {
      final source = await read();
      final intro =
          sourceIntroProgram(source, sourceMapId: 1, sourceEventId: 1)!;
      final changed = await read(
        before: r'\bHello, there! Glad to meet you!',
        after: r'\bHello, traveler! Welcome to Kanto!',
      );
      final rebound =
          sourceIntroProgram(changed, sourceMapId: 1, sourceEventId: 1)!;
      expect(
          rebound.opening.first.text, r'\bHello, traveler! Welcome to Kanto!');
      expect(intro.isBoundTo(changed), isFalse);
      expect(rebound.programHash, isNot(intro.programHash));
    });
  },
      skip: enabled
          ? false
          : 'Requires an explicit immutable original source and interpretation profile.');
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

final class _SupplementalFiles implements SourceFilePort {
  const _SupplementalFiles(this.primary);
  final ExternalOriginalFiles primary;

  @override
  Future<List<int>> read(ConverterId id) async {
    final entry = primary.snapshot.entries.singleWhere((e) => e.fileId == id);
    if (primary.overrideBytes.containsKey(entry.relativePath)) {
      return primary.read(id);
    }
    for (final root in [
      primary.root,
      ...(Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ?? '')
          .split('|')
          .where((value) => value.isNotEmpty),
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
