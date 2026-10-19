import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

void main() {
  late Directory root;
  setUp(() async {
    final created =
        await Directory.systemTemp.createTemp('source-interpretation-');
    root = Directory(await created.resolveSymbolicLinks());
  });
  tearDown(() async => root.delete(recursive: true));
  test('selected complete declared corpus is read within the measured bounded file quota', () async {
    final template = fixtureSourceInterpretationProfile.declaredPrograms
        .singleWhere((binding) =>
            binding.family == SourceDeclaredProgramFamily.externalWarp)
        .toJson();
    final programs = [
      for (var index = 0; index < 171; index++)
        jsonDecode(jsonEncode(template)) as Map<String, dynamic>,
    ];
    for (final (index, program) in programs.indexed) {
      program['id'] = 'synthetic-quota-warp-$index';
      final commands =
          ((program['pages'] as Map)['program'] as Map)['list'] as List;
      final sound = commands.cast<Map>().singleWhere((command) =>
          command['code'] == 250)['parameters'] as List;
      (sound.single as Map)['name'] = 'synthetic_quota_effect_$index';
    }
    final profile = SourceInterpretationProfile.fromJson({
      ...fixtureSourceInterpretationProfile.toJson(),
      'declaredPrograms': programs,
    });
    final bytes = utf8.encode(canonicalJsonOf(profile.toJson(),
        limits: SourceInterpretationProfile.jsonLimits));
    expect(bytes.length, greaterThan(131072));
    expect(bytes.length, lessThan(SourceInterpretationProfile.maxEncodedBytes));
    final file = File('${root.path}/complete-profile.json');
    await file.writeAsBytes(bytes);
    final selected = await const LocalSourceInterpretationProfileStore().read(file.path);
    expect(selected.declaredPrograms, hasLength(171));
    expect(selected.declaredPrograms.map((binding) => binding.canonicalHash).toSet(),
        hasLength(171));
    expect(selected.canonicalHash, profile.canonicalHash);
    expect(selected.toJson(), profile.toJson());
    await file.writeAsBytes([
      ...bytes,
      ...List.filled(SourceInterpretationProfile.maxEncodedBytes - bytes.length, 32),
    ]);
    expect(await file.length(), SourceInterpretationProfile.maxEncodedBytes);
    final atLimit =
        await const LocalSourceInterpretationProfileStore().read(file.path);
    expect(atLimit.canonicalHash, profile.canonicalHash);
    expect(atLimit.toJson(), profile.toJson());
    await file.writeAsBytes([32], mode: FileMode.append);
    await expectLater(const LocalSourceInterpretationProfileStore().read(file.path), throwsA(isA<ContractError>().having((e) => e.code, 'code', 'interpretation_profile.quota')));
  });
  test('selected JSON profile has exact immutable canonical identity',
      () async {
    final file = File('${root.path}/profile.json');
    await file.writeAsString(
        jsonEncode(syntheticSourceInterpretationProfile.toJson()));
    final selected =
        await const LocalSourceInterpretationProfileStore().read(file.path);
    expect(selected.canonicalHash,
        syntheticSourceInterpretationProfile.canonicalHash);
    await file.writeAsString('{}');
    expect(selected.canonicalHash,
        syntheticSourceInterpretationProfile.canonicalHash);
  });
  test('profile picker rejects relative links oversized and malformed files',
      () async {
    final file = File('${root.path}/profile.json');
    await file.writeAsString(
        jsonEncode(syntheticSourceInterpretationProfile.toJson()));
    final link = Link('${root.path}/linked.json');
    await link.create(file.path);
    final oversized = File('${root.path}/oversized.json');
    await oversized.writeAsString(' ' * 131073);
    for (final selected in ['relative.json', link.path, oversized.path]) {
      await expectLater(
          const LocalSourceInterpretationProfileStore().read(selected),
          throwsA(isA<ContractError>()));
    }
    await file.writeAsString('{"unexpected":true}');
    await expectLater(
        const LocalSourceInterpretationProfileStore().read(file.path),
        throwsA(isA<ContractError>()));
    for (final bytes in [
      utf8.encode('{'),
      [255]
    ]) {
      await file.writeAsBytes(bytes);
      await expectLater(
          const LocalSourceInterpretationProfileStore().read(file.path),
          throwsA(isA<ContractError>()
              .having((e) => e.code, 'code', 'interpretation_profile.schema')));
    }
  });
  test('saved review settings retain the selected profile and fingerprint',
      () async {
    final source = await Directory('${root.path}/source').create();
    final output = await Directory('${root.path}/output').create();
    final selected = LocalReviewResumeSettings(
        sourceRootPath: source.path,
        destinationParentPath: output.path,
        projectName: 'Synthetic',
        folderName: 'native',
        interpretationProfile: syntheticSourceInterpretationProfile);
    final reopened = LocalReviewResumeSettings.fromJson(
        jsonDecode(jsonEncode(selected.toJson())));
    expect(reopened.interpretationProfile!.canonicalHash,
        syntheticSourceInterpretationProfile.canonicalHash);
    expect(reopened.toJson(), selected.toJson());
    final without = LocalReviewResumeSettings.fromJson(
        {...selected.toJson(), 'interpretationProfile': null});
    expect(canonicalHashOf(without.toJson()),
        isNot(canonicalHashOf(selected.toJson())));
  });
}
