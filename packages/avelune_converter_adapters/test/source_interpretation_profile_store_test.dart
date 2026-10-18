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
