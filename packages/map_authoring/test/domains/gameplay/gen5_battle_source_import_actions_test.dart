import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/gameplay/gen5_battle_source_import_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _speciesPath = 'data/pokemon/species/alternate-filename.json';
const _speciesId = 'local-mon';

void main() {
  test('plans exactly the binding and verified bundle for the selected species',
      () async {
    final fixture = await _Fixture.create();
    final draft = await fixture.plan();
    final changes = {
      for (final change in draft.changeSet.changes) change.storageKey: change
    };
    expect(changes.keys.toSet(),
        {fixture.binding.bindingPath, fixture.binding.bundlePath});
    expect(changes[fixture.binding.bindingPath]!.afterBytes,
        fixture.binding.encode());
    expect(
        changes[fixture.binding.bundlePath]!.afterBytes, fixture.bundleBytes);
    expect(
        changes.values.every((change) => change.beforeBytes == null), isTrue);
    expect(draft.preview['projectSpeciesId'], _speciesId);
  });

  test('rejects an identity mismatch and a species path mismatch', () async {
    final fixture = await _Fixture.create();
    await expectLater(fixture.plan(nationalDex: 26), throwsFormatException);
    await expectLater(
        fixture.plan(snapshotPath: 'data/pokemon/species/other.json'),
        throwsFormatException);
  });

  test('rejects a corrupted staged bundle before planning writes', () async {
    final fixture = await _Fixture.create(corrupt: true);
    await expectLater(fixture.plan(), throwsFormatException);
  });

  test('rejects a corrupted asset even when the bundle hash is recalculated',
      () async {
    final fixture = await _Fixture.create(forgeOuterDigest: true);
    await expectLater(fixture.plan(), throwsFormatException);
  });

  test('refuses existing different content and an unprepared storage scope',
      () async {
    final fixture = await _Fixture.create();
    await expectLater(fixture.plan(existingBinding: utf8.encode('{}')),
        throwsFormatException);
    await expectLater(
        fixture.plan(omitBundleScope: true), throwsFormatException);
    await expectLater(
        fixture.plan(
            existingBinding: fixture.binding.encode(), staleBindingScope: true),
        throwsFormatException);
  });

  test('reimporting identical bytes produces no changes', () async {
    final fixture = await _Fixture.create();
    final draft = await fixture.plan(
      existingBinding: fixture.binding.encode(),
      existingBundle: fixture.bundleBytes,
    );
    expect(draft.changeSet.changes, isEmpty);
    expect(draft.preview['idempotent'], isTrue);
  });
}

final class _Fixture {
  _Fixture(this.store, this.binding, this.bundleBytes, this.handle);

  static Future<_Fixture> create(
      {bool corrupt = false, bool forgeOuterDigest = false}) async {
    final bundle = Gen5BattleSourceBundle(
      species: 'syntheticmon',
      nationalDex: 25,
      release: 'synthetic-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/syntheticmon',
      reconstruction: 'a\u0300 verifier',
      redistributionStatus: 'unverified',
      assets: {
        for (var index = 0; index < gen5BattleBundleAssetNames.length; index++)
          gen5BattleBundleAssetNames[index]: Uint8List.fromList([index + 1]),
      },
    );
    var binding = Gen5BattleSourceBinding.fromBundle(
      projectSpeciesId: _speciesId,
      projectNationalDex: 25,
      bundle: bundle,
    );
    var bytes = bundle.encode();
    if (forgeOuterDigest) {
      final document = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final asset = (document['assets'] as Map<String, dynamic>)['front.png']
          as Map<String, dynamic>;
      asset['data'] = base64.encode([0]);
      bytes = Uint8List.fromList(utf8.encode(jsonEncode(document)));
      final raw =
          jsonDecode(utf8.decode(binding.encode())) as Map<String, dynamic>;
      raw['bundleSha256'] = sha256.convert(bytes).toString();
      final rawBytes = Uint8List.fromList(utf8.encode(jsonEncode(raw)));
      binding = Gen5BattleSourceBinding.decode(rawBytes,
          expectedSha256: sha256.convert(rawBytes).toString(),
          expectedProjectSpeciesId: _speciesId,
          expectedProjectNationalDex: 25);
    }
    final staged = Uint8List.fromList(bytes);
    if (corrupt) staged[staged.length - 2] ^= 1;
    final store = MemoryArtifactStore(maximumArtifactBytes: 20 * 1024 * 1024);
    final artifact =
        await store.put(staged, declaredMediaType: 'application/json');
    return _Fixture(store, binding, bytes, artifact.reference.handle);
  }

  final MemoryArtifactStore store;
  final Gen5BattleSourceBinding binding;
  final Uint8List bundleBytes;
  final String handle;

  Future<AuthoringMutationDraft> plan({
    int nationalDex = 25,
    String snapshotPath = _speciesPath,
    List<int>? existingBinding,
    List<int>? existingBundle,
    bool omitBundleScope = false,
    bool staleBindingScope = false,
  }) {
    final species = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'id': _speciesId,
      'nationalDex': nationalDex,
    }));
    final identity = pokemonSpeciesResourceIdentity(_speciesId);
    final documents = <String, List<int>>{
      identity: species,
      if (existingBinding != null)
        'gen5BattleSource:${binding.bindingPath}': existingBinding,
      if (existingBundle != null)
        'gen5BattleSource:${binding.bundlePath}': existingBundle,
    };
    final paths = <String, String>{
      identity: snapshotPath,
      if (existingBinding != null)
        'gen5BattleSource:${binding.bindingPath}': binding.bindingPath,
      if (existingBundle != null)
        'gen5BattleSource:${binding.bundlePath}': binding.bundlePath,
    };
    final revisions = <String, String>{
      for (final entry in documents.entries)
        entry.key: computeAuthoringBytesFingerprint(entry.value,
            logicalName: paths[entry.key]!),
    };
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('project'),
      revision: 'sha256:${'1' * 64}',
      manifest: const ProjectManifest(
          name: 'Synthetic',
          maps: [],
          tilesets: [],
          pokemon: ProjectPokemonConfig(
              enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1)),
      materializedCatalogProject: true,
      maps: const [],
      resourceFingerprints: revisions,
      resourceBytes: documents,
      resourceStorageKeys: paths,
      scopedStorageRevisions: {
        snapshotPath: revisions[identity],
        binding.bindingPath: staleBindingScope
            ? 'sha256:${'0' * 64}'
            : revisions['gen5BattleSource:${binding.bindingPath}'],
        if (!omitBundleScope)
          binding.bundlePath:
              revisions['gen5BattleSource:${binding.bundlePath}'],
      },
    );
    final request = AuthoringRequest(
      requestId: 'import',
      actionId: 'pokemon.gen5_battle_source.import',
      actionVersion: 1,
      workspaceHandle: 'workspace',
      parameters: {
        'binding': jsonDecode(utf8.decode(binding.encode())),
        'bundleHandle': handle,
        'speciesPath': _speciesPath,
      },
    );
    return Gen5BattleSourceImportActions(artifactStore: store).build(
      AuthoringPlanningContext(
          snapshot: snapshot, request: request, planId: 'plan', seed: 1),
    );
  }
}
