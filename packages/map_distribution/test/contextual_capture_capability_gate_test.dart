import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  for (final contextual in [false, true]) {
    test('contextual item admission and capability contextual=$contextual', () {
      final project = ProjectManifest(
        name: 'Contextual admission',
        maps: [],
        tilesets: [],
        pokemon: ProjectPokemonConfig(
          enabled: false,
          ruleset: contextual ? PokemonRulesetProfile.contextualV1 : PokemonRulesetProfile.standardV1,
        ),
      );
      final publication = PortableCatalogPublication.encodeProject(project);
      final payload = <String, List<int>>{
        'project/project.json': utf8.encode(jsonEncode(publication.descriptor)),
        for (final entry in publication.storage.objects.entries)
          'project/catalog/objects/${entry.key}.json': entry.value,
        'project/data/pokemon/catalogs/items.json': utf8.encode(jsonEncode({
          'schemaVersion': 1,
          'entries': [{
            'id': 'eighth-synthetic-orb', 'displayName': 'Eighth', 'pocketId': 'balls',
            'capture': {'rateNumerator': 1, 'rateDenominator': 1,
              'allowedEncounterKinds': ['walk'],
              'contextualPolicy': ProjectContextualCapturePolicy().toJson()},
          }],
        })),
      };
      final original = {for (final entry in payload.entries) entry.key: List<int>.of(entry.value)};
      final manifestJson = spatialManifest(capabilities: ['map@1', 'catalog.partitioned@2']).toJson();
      (manifestJson['compatibility'] as Map).addAll(<String, Object?>{
        'projectFormat': 'v8', 'minHubVersion': '0.1.0',
        'saveFormat': SaveEnvelopeCodec.currentSaveFormat,
      });
      final missing = const GamePackageManifestCodec().decodeJson(manifestJson);
      expect(() => const GamePackageBuilder().build(manifest: missing, payloadFiles: payload),
        throwsA(isA<GamePackageFormatException>()));
      (manifestJson['compatibility'] as Map)['requiredCapabilities'] = [
        'map@1', 'catalog.partitioned@2', PokemonRulesetProfile.contextualCaptureCapabilityId,
      ];
      final admitted = const GamePackageManifestCodec().decodeJson(manifestJson);
      if (contextual) {
        final built = const GamePackageBuilder().build(manifest: admitted, payloadFiles: payload);
        final inspection = GamePackageInspector().inspect(built.packageBytes);
        expect(inspection.receipt.pokemonRuleset.profileId, PokemonRulesetProfile.contextualProfileId);
        final host = AveluneRuntimeCompatibility.host();
        expect(host.capabilities, contains(PokemonRulesetProfile.contextualCaptureCapabilityId));
        final oldHost = GamePackageHostCompatibility(
          hubVersion: host.hubVersion, runtimeApiVersion: host.runtimeApiVersion,
          supportedRuntimeApiVersions: host.supportedRuntimeApiVersions,
          capabilities: host.capabilities.difference({PokemonRulesetProfile.contextualCaptureCapabilityId}),
          supportedProjectFormats: host.supportedProjectFormats,
          currentProjectFormat: host.currentProjectFormat, currentProjectFormats: host.currentProjectFormats,
          supportedSaveFormats: host.supportedSaveFormats);
        final bytes = List<int>.of(built.packageBytes);
        expect(() => GamePackageInspector(hostCompatibility: oldHost).inspect(built.packageBytes),
            throwsA(isA<GamePackageFormatException>()));
        expect(built.packageBytes, bytes);
        expect(GamePackageInspector(hostCompatibility: host).inspect(built.packageBytes).compatibility!.decision,
            GamePackageCompatibilityDecision.accept);
      } else {
        expect(() => const GamePackageBuilder().build(manifest: admitted, payloadFiles: payload),
          throwsA(isA<GamePackageFormatException>()));
      }
      expect(payload, original);
    });
  }
}
