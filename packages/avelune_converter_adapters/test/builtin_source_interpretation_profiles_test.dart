import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/literal_tile_fixture.dart';

const _knownHash =
    '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';

SourceFileEntry _scripts(
        {String path = 'Data/Scripts.rxdata',
        String hash = _knownHash,
        SourceNodeKind kind = SourceNodeKind.file}) =>
    SourceFileEntry(
        fileId: ConverterId('scripts-${path.hashCode.abs()}'),
        relativePath: path,
        kind: kind,
        byteLength: 100,
        sha256: Sha256Hash(hash),
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
  test('known complete exact archive selects the closed reusable profile', () {
    final profile = detectBuiltinSourceInterpretationProfile(_snapshot())!;
    expect(profile.profileId.value, 'essentials-static-walking-events-items');
    expect(profile.scriptsArchiveHash.value, _knownHash);
    expect(profile.supports('events'), isTrue);
    expect(profile.supports('walking'), isTrue);
    expect(profile.sections['events.Audio_Play']!['index'], 93);
    expect(profile.declaredPrograms, isEmpty);
    final presentation = profile.toJson()['presentationBindings'] as Map;
    expect(presentation.containsKey('characterSubstitutions'), isFalse);
    expect(presentation.containsKey('routedDoorPatterns'), isFalse);
  });

  for (final state
      in SourceScanState.values.where((s) => s != SourceScanState.complete)) {
    test('incomplete inventory $state never selects a profile', () {
      expect(detectBuiltinSourceInterpretationProfile(_snapshot(state: state)),
          isNull);
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

  test('archive bytes still require the existing strict SHA verification',
      () async {
    final snapshot = _snapshot();
    final profile = detectBuiltinSourceInterpretationProfile(snapshot)!;
    final files = LiteralFixtureFiles(snapshot, {
      'Data/Scripts.rxdata': [4, 8]
    });
    await expectLater(profile.verifySource(snapshot: snapshot, files: files),
        throwsA(isA<ContractError>()));
  });
}
