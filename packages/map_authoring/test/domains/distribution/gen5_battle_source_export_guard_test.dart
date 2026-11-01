import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/distribution/gen5_battle_source_export_guard.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('preserves bound Unicode bytes and validates project identity', () {
    final source = _source();
    final binding = _binding(source);
    final bindingBytes = binding.encode();
    final bundleBytes = source.encode();
    final plan = Gen5BattleSourceExportPlan.fromBindingCandidates({
      binding.bindingPath: bindingBytes,
    });
    expect(plan.exactPaths, {binding.bindingPath, binding.bundlePath});
    final files = <String, List<int>>{
      binding.bindingPath: bindingBytes,
      binding.bundlePath: bundleBytes,
    };
    expect(
      () => plan.validate(files: files, projectSpecies: [
        (id: binding.projectSpeciesId, nationalDex: 25),
      ]),
      returnsNormally,
    );
    expect(files[binding.bindingPath], bindingBytes);
    expect(files[binding.bundlePath], bundleBytes);
    expect(utf8.decode(bundleBytes), contains('a\u0300 verifier'));
  });

  test('rejects a corrupted resource even with a recalculated bundle hash', () {
    final source = _source();
    final originalBinding = _binding(source);
    final document =
        jsonDecode(utf8.decode(source.encode())) as Map<String, dynamic>;
    final entries = document['assets'] as Map<String, dynamic>;
    final item = entries['front.png'] as Map<String, dynamic>;
    item['data'] = base64.encode([0, 0]);
    final damaged = Uint8List.fromList(utf8.encode(jsonEncode(document)));
    final bindingJson = jsonDecode(utf8.decode(originalBinding.encode()))
        as Map<String, dynamic>;
    bindingJson['bundleSha256'] = sha256.convert(damaged).toString();
    final forgedBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(bindingJson)));
    final forged = Gen5BattleSourceBinding.decode(forgedBytes,
        expectedSha256: sha256.convert(forgedBytes).toString(),
        expectedProjectSpeciesId: originalBinding.projectSpeciesId,
        expectedProjectNationalDex: 25);
    final plan = Gen5BattleSourceExportPlan.fromBindingCandidates({
      forged.bindingPath: forgedBytes,
    });
    expect(
      () => plan.validate(
          files: {forged.bindingPath: forgedBytes, forged.bundlePath: damaged},
          projectSpecies: [(id: forged.projectSpeciesId, nationalDex: 25)]),
      throwsA(isA<GamePackageExportException>().having(
          (error) => error.code, 'code', 'gen5_battle_source.invalid_bundle')),
    );
  });

  test('rejects missing, duplicated or mismatched project species', () {
    final source = _source();
    final binding = _binding(source);
    final plan = Gen5BattleSourceExportPlan.fromBindingCandidates({
      binding.bindingPath: binding.encode(),
    });
    final files = <String, List<int>>{
      binding.bindingPath: binding.encode(),
      binding.bundlePath: source.encode()
    };
    for (final species in <List<({String id, int nationalDex})>>[
      [],
      [(id: binding.projectSpeciesId, nationalDex: 26)],
      [
        (id: binding.projectSpeciesId, nationalDex: 25),
        (id: binding.projectSpeciesId, nationalDex: 25)
      ],
    ]) {
      expect(
          () => plan.validate(files: files, projectSpecies: species),
          throwsA(isA<GamePackageExportException>().having(
              (error) => error.code,
              'code',
              'gen5_battle_source.identity_mismatch')));
    }
  });

  test(
      'ignores unrelated legacy JSON and rejects misplaced recognized bindings',
      () {
    final source = _source();
    final binding = _binding(source);
    final path = 'data/pokemon/gen5_battle_sources/bindings/${'f' * 64}.json';
    final ignored = Gen5BattleSourceExportPlan.fromBindingCandidates({
      path: utf8.encode('{"kind":"another-extension","value":1}'),
    });
    expect(ignored.exactPaths, isEmpty);
    expect(
      () => Gen5BattleSourceExportPlan.fromBindingCandidates(
          {path: binding.encode()}),
      throwsA(isA<GamePackageExportException>().having(
          (error) => error.code, 'code', 'gen5_battle_source.invalid_binding')),
    );
  });
}

Gen5BattleSourceBundle _source() => Gen5BattleSourceBundle(
      species: 'syntheticmon',
      nationalDex: 25,
      release: 'synthetic-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/syntheticmon',
      reconstruction: 'a\u0300 verifier',
      redistributionStatus: 'unverified',
      assets: {
        for (var i = 0; i < gen5BattleBundleAssetNames.length; i++)
          gen5BattleBundleAssetNames[i]: Uint8List.fromList([i + 1, 255 - i]),
      },
    );

Gen5BattleSourceBinding _binding(Gen5BattleSourceBundle bundle) =>
    Gen5BattleSourceBinding.fromBundle(
        projectSpeciesId: 'local-e\u0301',
        projectNationalDex: 25,
        bundle: bundle);
