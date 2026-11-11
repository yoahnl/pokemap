import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  for (final method in ['friendship', 'friendship_day', 'friendship_night']) {
    test('package validation enforces the time evolution capability for $method', () {
      final project = ProjectManifest(name: 'Evolution', maps: [], tilesets: [],
        pokemon: const ProjectPokemonConfig(enabled: true, ruleset: PokemonRulesetProfile.standardV1));
      final publication = PortableCatalogPublication.encodeProject(project);
      final files = <String, List<int>>{
        'project/project.json': utf8.encode(jsonEncode(publication.descriptor)),
        for (final entry in publication.storage.objects.entries)
          'project/catalog/objects/${entry.key}.json': entry.value,
        'project/data/pokemon/evolutions/riolu.json': utf8.encode(jsonEncode(
          PokemonEvolutionFile(speciesId: 'riolu', evolutions: [
            PokemonEvolutionEntry(targetSpeciesId: 'lucario', method: method, minFriendship: 220),
          ]).toJson(),
        )),
      };
      GamePackageManifest manifest(bool declared) {
        final json = spatialManifest(capabilities: [
          'map@1', 'catalog.partitioned@2',
          if (declared) PokemonEvolutionTimeCapabilities.capabilityId,
        ]).toJson();
        (json['compatibility'] as Map).addAll(<String, Object?>{
          'projectFormat': 'v8', 'minHubVersion': '0.1.0',
          'saveFormat': SaveEnvelopeCodec.currentSaveFormat,
        });
        return const GamePackageManifestCodec().decodeJson(json);
      }

      if (method != 'friendship') {
        expect(() => const GamePackageBuilder().build(manifest: manifest(false), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
      }
      final result = const GamePackageBuilder().build(
        manifest: manifest(method != 'friendship'), payloadFiles: files);
      expect(GamePackageInspector(hostCompatibility: AveluneRuntimeCompatibility.host())
        .inspect(result.packageBytes).compatibility!.decision, GamePackageCompatibilityDecision.accept);
    });
  }
}
