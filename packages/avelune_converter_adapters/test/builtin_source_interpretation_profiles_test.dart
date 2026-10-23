import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

const _knownHash =
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';

const _hoennHash =
    '8b03301e71b12ba8cc84efb128534d0a7f17d02cf56c770e40c16be37b730940';

SourceFileEntry _scripts(
        {String path = 'Data/Scripts.rxdata',
        String hash = _knownHash,
        int byteLength = 100,
        SourceNodeKind kind = SourceNodeKind.file}) =>
    SourceFileEntry(
        fileId: ConverterId('scripts-${path.hashCode.abs()}'),
        relativePath: path,
        kind: kind,
        byteLength: kind == SourceNodeKind.file ? byteLength : 0,
        sha256: kind == SourceNodeKind.file ? Sha256Hash(hash) : null,
        format: 'unknown',
        family: 'project');

SourceSnapshot _snapshot(
        {List<SourceFileEntry>? entries,
        SourceScanState state = SourceScanState.complete}) =>
    SourceSnapshot(
        logicalProjectNamespace: ConverterId('builtin-profile-test'),
        policyHash: Sha256Hash('1' * 64),
        entries: entries ?? [_scripts()],
        diagnostics: const [],
        excludedPaths: const [],
        profileEvidence: const [],
        state: state);

void main() {
  for (final hash in [_knownHash, _hoennHash]) {
    test('known complete exact archive $hash selects its pinned profile', () {
      final profile = detectBuiltinSourceInterpretationProfile(
          _snapshot(entries: [_scripts(hash: hash)]))!;
      expect(profile.profileId.value, 'essentials-static-walking-events-items');
      expect(profile.scriptsArchiveHash.value, hash);
      expect(profile.supports('events'), isTrue);
      expect(profile.supports('walking'), isTrue);
      expect(profile.sections['events.Audio_Play']!['index'], 93);
      expect(profile.sections, hasLength(20));
      expect(profile.sections.values.map((section) => section['index']),
          isNot(contains(114)));
      expect(profile.sections.values.map((section) => section['index']),
          isNot(contains(266)));
      expect(profile.declaredPrograms, isEmpty);
      final presentation = profile.toJson()['presentationBindings'] as Map;
      expect(presentation.containsKey('characterSubstitutions'), isFalse);
      expect(presentation.containsKey('routedDoorPatterns'), isFalse);
    });
  }

  test('the two admitted archives retain identical static semantics pins', () {
    final original = detectBuiltinSourceInterpretationProfile(_snapshot())!;
    final hoenn = detectBuiltinSourceInterpretationProfile(
        _snapshot(entries: [_scripts(hash: _hoennHash)]))!;
    expect(hoenn.sections, original.sections);
    expect(hoenn.capabilities, original.capabilities);
    expect(hoenn.canonicalHash, isNot(original.canonicalHash));
  });

  for (final state
      in SourceScanState.values.where((s) => s != SourceScanState.complete)) {
    test('incomplete inventory $state never selects a profile', () {
      for (final hash in [_knownHash, _hoennHash]) {
        expect(
            detectBuiltinSourceInterpretationProfile(
                _snapshot(state: state, entries: [_scripts(hash: hash)])),
            isNull);
      }
    });
  }

  test('unknown or missing archive remains literal', () {
    expect(detectBuiltinSourceInterpretationProfile(_snapshot(entries: [])),
        isNull);
    expect(
        detectBuiltinSourceInterpretationProfile(
            _snapshot(entries: [_scripts(hash: '2' * 64)])),
        isNull);
  });

  test('case aliases and collisions never select a known profile', () {
    expect(
        detectBuiltinSourceInterpretationProfile(
            _snapshot(entries: [_scripts(path: 'data/Scripts.rxdata')])),
        isNull);
    expect(
        () => _snapshot(
            entries: [_scripts(), _scripts(path: 'data/scripts.rxdata')]),
        throwsA(isA<ContractError>()));
  });

  for (final hash in [_knownHash, _hoennHash]) {
    test('forged archive bytes are rejected for $hash', () async {
      final snapshot = _snapshot(entries: [_scripts(hash: hash)]);
      final profile = detectBuiltinSourceInterpretationProfile(snapshot)!;
      final files = LiteralFixtureFiles(snapshot, {
        'Data/Scripts.rxdata': List<int>.filled(100, 0)
      });
      await expectLater(profile.verifySource(snapshot: snapshot, files: files),
          throwsA(isA<ContractError>()));
    });
  }

  test('complete inventories reject non-file archives before detection', () {
    for (final hash in [_knownHash, _hoennHash]) {
      expect(
          () => _snapshot(
              entries: [_scripts(hash: hash, kind: SourceNodeKind.link)]),
          throwsA(isA<ContractError>()));
    }
  });

  for (final archive in [
    (_knownHash, 'AVELUNE_BUILTIN_JOHTO_SCRIPTS'),
    (_hoennHash, 'AVELUNE_BUILTIN_HOENN_SCRIPTS'),
  ]) {
    final archivePath = Platform.environment[archive.$2];
    test('real archive ${archive.$2} verifies all pinned static sections',
        () async {
      final bytes = await File(archivePath!).readAsBytes();
      final hash = crypto.sha256.convert(bytes).toString();
      expect(hash, archive.$1);
      final snapshot =
          _snapshot(entries: [_scripts(hash: hash, byteLength: bytes.length)]);
      final profile = detectBuiltinSourceInterpretationProfile(snapshot)!;
      await profile.verifySource(
          snapshot: snapshot,
          files: LiteralFixtureFiles(snapshot, {'Data/Scripts.rxdata': bytes}));
    }, skip: archivePath == null ? '${archive.$2} is required' : false);
  }
}
