import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  for (final portable in [false, true]) {
    for (final feature in ['legacy', 'bitter', 'oran_berry', 'pecha_berry']) {
      final bitter = feature == 'bitter';
      final extended = feature != 'legacy';
      final capability = bitter ? ItemFriendshipCapabilities.capabilityId : ItemHeldBerryCapabilities.capabilityId;
      test('medicine package gates extended semantics portable=$portable feature=$feature', () {
        final project = ProjectManifest(name: 'Medicine', maps: [], tilesets: [],
          pokemon: const ProjectPokemonConfig(enabled: false, ruleset: PokemonRulesetProfile.standardV1));
        final publication = PortableCatalogPublication.encodeProject(project);
        final catalog = ProjectItemCatalog(schemaVersion: 1, entries: [ProjectItemDefinition(
          id: 'medicine', displayName: 'Medicine', pocketId: 'medicine', heldEffectId: feature.endsWith('_berry') ? feature : null, uses: [ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.overworld, ProjectItemUseContext.battle}, target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            friendshipLoss: bitter ? const ProjectItemFriendshipLoss(low: 5, medium: 5, high: 10) : null,
            effect: const ProjectItemEffectDefinition.healHp(mode: ProjectItemAmountMode.flat, amount: 50),
          )],
        )]);
        final files = <String, List<int>>{
          'project/project.json': utf8.encode(jsonEncode(portable ? publication.descriptor : project.toJson())),
          if (portable) for (final entry in publication.storage.objects.entries) 'project/catalog/objects/${entry.key}.json': entry.value,
          'project/data/pokemon/catalogs/items.json': utf8.encode(jsonEncode(encodeProjectItemCatalog(catalog))),
        };
        final originals = {for (final entry in files.entries) entry.key: List<int>.of(entry.value)};
        GamePackageManifest manifest(bool declared) {
          final json = spatialManifest(capabilities: ['map@1', if (portable) 'catalog.partitioned@2',
            if (declared) capability]).toJson();
          (json['compatibility'] as Map).addAll(<String, Object?>{'projectFormat': 'v8', 'minHubVersion': '0.1.0', 'saveFormat': SaveEnvelopeCodec.currentSaveFormat});
          return const GamePackageManifestCodec().decodeJson(json);
        }
        if (extended) {
          expect(() => const GamePackageBuilder().build(manifest: manifest(false), payloadFiles: files), throwsA(isA<GamePackageFormatException>()));
        }
        final built = const GamePackageBuilder().build(manifest: manifest(extended), payloadFiles: files);
        final host = AveluneRuntimeCompatibility.host();
        final old = GamePackageHostCompatibility(hubVersion: host.hubVersion, runtimeApiVersion: host.runtimeApiVersion,
          supportedRuntimeApiVersions: host.supportedRuntimeApiVersions, capabilities: host.capabilities.difference({capability}),
          supportedProjectFormats: host.supportedProjectFormats, currentProjectFormat: host.currentProjectFormat,
          currentProjectFormats: host.currentProjectFormats, supportedSaveFormats: host.supportedSaveFormats);
        expect(GamePackageInspector(hostCompatibility: host).inspect(built.packageBytes).compatibility!.decision, GamePackageCompatibilityDecision.accept);
        if (extended) {
          expect(() => GamePackageInspector(hostCompatibility: old).inspect(built.packageBytes), throwsA(isA<GamePackageFormatException>()));
        } else {
          expect(GamePackageInspector(hostCompatibility: old).inspect(built.packageBytes).compatibility!.decision, GamePackageCompatibilityDecision.accept);
        }
        expect(files, originals);
      });
    }
  }
}
