import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_intro_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  final enabled = root != null && snapshot != null && profile != null;
  test(
      'selected Pallet and lab obtain an attested text type without importing Intro',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: const {6, 9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final witnesses = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(), null);
    final bindings = await const SourceIntroBindingResolver().readTextVariables(
        source: fixture.source,
        files: witnesses,
        referencedVariableIds: {28, 29});
    expect(bindings.keys, [28]);
    expect(bindings[28]!.presetValues, ['Blue', 'Gary', 'Michael']);
    expect(bindings[28]!.sourceSnapshotHash,
        fixture.source.snapshot.canonicalHash);
    expect(fixture.source.selectedSourceMapIds.toSet(), {6, 9});
    expect(
        fixture.source.maps.map((map) => map.map.sourceMapId).toSet(), {6, 9});
    expect(
        witnesses.evidence
            .any((file) => file['relativePath'] == 'Data/Map001.rxdata'),
        isTrue);
    final analysis = SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze();
    expect(
        () => const SourceEventProjector().characterImportCandidates(
            source: fixture.source,
            analysis: analysis,
            nativeMaps: const {},
            textVariablePrograms: {29: bindings[28]!}),
        throwsA(isA<NativeWriteException>()
            .having((e) => e.code, 'code', 'events.text_variable.binding')));
  },
      skip: enabled
          ? false
          : 'Requires immutable original source and interpretation profile.');
  test('unreferenced source variables cause no auxiliary source reads',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: const {6, 9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final witnesses = SourceSemanticWitnessFiles(fixture.source.snapshot,
        fixture.files, const NativeWriteLimits(), null);
    expect(
        await const SourceIntroBindingResolver().readTextVariables(
            source: fixture.source,
            files: witnesses,
            referencedVariableIds: {}),
        isEmpty);
    expect(witnesses.evidence, isEmpty);
  },
      skip: enabled
          ? false
          : 'Requires immutable original source and interpretation profile.');
}
