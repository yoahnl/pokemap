import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/generated/native_psdk_trainer_bundle_data.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

void main() {
  test('embedded reference matches the rebuildable asset exactly', () async {
    final asset =
        await File('assets/native_psdk_trainer_bundle.json').readAsString();
    expect(asset, nativePsdkTrainerBundleJson);
    final builtin = NativePsdkTrainerBundle.builtin();
    final restored = NativePsdkTrainerBundle.fromJson(
        jsonDecode(jsonEncode(builtin.toJson())) as Map<String, dynamic>);
    expect(
        canonicalHashOf(builtin.toJson()), canonicalHashOf(restored.toJson()));
    final paths = (builtin.evidence['sources'] as List).cast<Map>();
    expect(paths, hasLength(559));
    expect(
        paths.every(
            (source) => !(source['relativePath'] as String).startsWith('/')),
        isTrue);
    expect(
        paths.every((source) => !source.containsKey('absolutePath')), isTrue);
  });

  test('rejects duplicate documents and incomplete type charts', () {
    final original = NativePsdkTrainerBundle.builtin().toJson();
    final duplicate = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    (duplicate['species'] as List).add((duplicate['species'] as List).first);
    expect(
        () => NativePsdkTrainerBundle.fromJson(duplicate),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_trainer.duplicate_species')));
    final missing = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    final types = (missing['catalogs'] as List)
        .cast<Map>()
        .singleWhere((catalog) => catalog['catalog'] == 'types');
    (types['entries'] as List).removeLast();
    expect(
        () => NativePsdkTrainerBundle.fromJson(missing),
        throwsA(isA<ContractError>().having(
            (error) => error.code, 'code', 'native_trainer.type_closure')));
  });

  final sourceRoot = Platform.environment['AVELUNE_NATIVE_PSDK_REFERENCE_ROOT'];
  test('rebuilds the same species, moves and charts from attested PSDK JSON',
      () async {
    final builtin = NativePsdkTrainerBundle.builtin();
    final files = <NativePsdkTrainerSourceFile>[];
    for (final raw in (builtin.evidence['sources'] as List).cast<Map>()) {
      final path = raw['relativePath'] as String;
      final bytes = await File('$sourceRoot/$path').readAsBytes();
      expect(crypto.sha256.convert(bytes).toString(), raw['sha256']);
      files.add(NativePsdkTrainerSourceFile(
          relativePath: path,
          sha256: Sha256Hash(raw['sha256'] as String),
          bytes: bytes));
    }
    final levels = (builtin.evidence['requestedLevels'] as Map).map(
        (key, value) =>
            MapEntry(key as String, (value as List).cast<int>().toSet()));
    final rebuilt = const NativePsdkTrainerBundleBuilder()
        .build(files: files, requestedLevels: levels);
    expect(rebuilt.toJson()['species'], builtin.toJson()['species']);
    expect(rebuilt.toJson()['sourceLearnsets'],
        builtin.toJson()['sourceLearnsets']);
    expect(rebuilt.toJson()['catalogs'], builtin.toJson()['catalogs']);
    expect(rebuilt.evidence['sources'], builtin.evidence['sources']);
  },
      skip: sourceRoot == null
          ? 'Requires the optional read-only PSDK reference root.'
          : false);
}
