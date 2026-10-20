import 'dart:convert';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_routed_door_program.dart';
import 'package:test/test.dart';

import '../tool/lot6_routed_door_patterns.dart';
import 'source_routed_door_profile_test.dart' as doors;
import 'support/literal_tile_fixture.dart';

void main() {
  test('derives reusable declared patterns from exact source pages and atlas',
      () async {
    final fixture =
        await doors.routedDoorFixture('CopperGate', declared: false);
    final result = await deriveLot6RoutedDoorPatterns(
        snapshot: fixture.snapshot,
        files: fixture.files,
        profile: fixture.source.interpretationProfile!);
    final binding =
        result.profile.presentationBindings!.routedDoorPatterns.single;
    expect(binding.charset, 'CopperGate');
    expect(binding.departurePattern, 3);
    expect(binding.arrivalPattern, 1);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        includeEventSystem: true,
        interpretationProfile: result.profile);
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    expect(sourceRoutedDoorPrograms(source: source, analysis: analysis),
        hasLength(1));
    expect(result.evidence['sourceProgramsQualified'], false);
    expect(result.evidence['nativePresentationAdaptation'],
        'nativeStableDepartureDoorSkin');
    expect(
        SourceInterpretationProfile.fromJson(result.profile.toJson())
            .canonicalHash,
        result.profile.canonicalHash);
  });

  test('a visual declaration never admits an unknown arrival program',
      () async {
    final fixture = await doors.routedDoorFixture('CopperGate',
        declared: false, unknownArrivalScript: true);
    final result = await deriveLot6RoutedDoorPatterns(
        snapshot: fixture.snapshot,
        files: fixture.files,
        profile: fixture.source.interpretationProfile!);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: fixture.snapshot,
        files: fixture.files,
        includeEventSystem: true,
        interpretationProfile: result.profile);
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    expect(
        sourceRoutedDoorPrograms(source: source, analysis: analysis), isEmpty);
    expect(analysis.eventAt(7, 3)!.isQuarantined, true);
  });

  test('refuses an unqualified source profile', () async {
    final fixture =
        await doors.routedDoorFixture('Unqualified', declared: false);
    final profile = SourceInterpretationProfile.fromJson({
      ...fixture.source.interpretationProfile!.toJson(),
      'capabilities': ['walking']
    });
    expect(
        deriveLot6RoutedDoorPatterns(
            snapshot: fixture.snapshot, files: fixture.files, profile: profile),
        throwsA(isA<ContractError>()));
  });

  for (final encoding in ['E', 'X']) {
    test(
        'literal charset metadata $encoding is checked without dropping unknown ivars',
        () async {
      final fixture =
          await doors.routedDoorFixture('CopperGate', declared: false);
      const path = 'Data/Map007.rxdata';
      final original = fixture.sourceBytes[path]!;
      final name = utf8.encode('CopperGate');
      final needle = [0x22, name.length + 5, ...name];
      final changed = <int>[];
      for (var index = 0; index < original.length;) {
        if (index + needle.length <= original.length &&
            List.generate(needle.length, (offset) => original[index + offset])
                    .toString() ==
                needle.toString()) {
          changed.addAll(
              [0x49, ...needle, 6, 0x3a, 6, encoding.codeUnitAt(0), 0x54]);
          index += needle.length;
        } else {
          changed.add(original[index++]);
        }
      }
      final snapshot = SourceSnapshot(
          logicalProjectNamespace: fixture.snapshot.logicalProjectNamespace,
          policyHash: fixture.snapshot.policyHash,
          diagnostics: fixture.snapshot.diagnostics,
          excludedPaths: fixture.snapshot.excludedPaths,
          profileEvidence: fixture.snapshot.profileEvidence,
          state: fixture.snapshot.state,
          entries: [
            for (final entry in fixture.snapshot.entries)
              if (entry.relativePath != path)
                entry
              else
                SourceFileEntry(
                    fileId: entry.fileId,
                    relativePath: path,
                    kind: entry.kind,
                    byteLength: changed.length,
                    sha256: literalFixtureHash(changed),
                    format: entry.format,
                    family: entry.family)
          ]);
      final result = await deriveLot6RoutedDoorPatterns(
          snapshot: snapshot,
          files: LiteralFixtureFiles(
              snapshot, {...fixture.sourceBytes, path: changed}),
          profile: fixture.source.interpretationProfile!);
      expect(result.profile.presentationBindings?.routedDoorPatterns ?? [],
          hasLength(encoding == 'E' ? 1 : 0));
    });
  }

  test('keeps existing exact declaration without adding a duplicate', () async {
    final fixture = await doors.routedDoorFixture('CrystalPortal');
    final result = await deriveLot6RoutedDoorPatterns(
        snapshot: fixture.snapshot,
        files: fixture.files,
        profile: fixture.source.interpretationProfile!);
    expect(
        result.profile.presentationBindings!.routedDoorPatterns, hasLength(1));
    expect(result.profile.canonicalHash,
        fixture.source.interpretationProfile!.canonicalHash);
  });

  test('does not overwrite a conflicting existing atlas declaration', () async {
    final fixture = await doors.routedDoorFixture('Changed', wrongPin: true);
    expect(
        deriveLot6RoutedDoorPatterns(
            snapshot: fixture.snapshot,
            files: fixture.files,
            profile: fixture.source.interpretationProfile!),
        throwsA(isA<ContractError>()));
  });

  test('refuses bytes changed after the exact inventory', () async {
    final fixture = await doors.routedDoorFixture('Changed', declared: false);
    expect(
        deriveLot6RoutedDoorPatterns(
            snapshot: fixture.snapshot,
            files: _ChangedFiles(fixture.files),
            profile: fixture.source.interpretationProfile!),
        throwsA(isA<ContractError>()));
  });
}

final class _ChangedFiles implements SourceFilePort {
  _ChangedFiles(this.inner);
  final SourceFilePort inner;
  @override
  Future<List<int>> read(ConverterId id) async => [...await inner.read(id), 0];
}
