import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  for (final portable in [false, true]) {
    for (final allMoves in [false, true]) {
      test(
          'PP package preserves scope and gates old hosts portable=$portable all=$allMoves',
          () {
        final project = ProjectManifest(
            name: 'PP',
            maps: [],
            tilesets: [],
            pokemon: const ProjectPokemonConfig(
                enabled: false, ruleset: PokemonRulesetProfile.standardV1));
        final publication = PortableCatalogPublication.encodeProject(project);
        final catalog = ProjectItemCatalog(schemaVersion: 1, entries: [
          ProjectItemDefinition(
              id: 'pp-item',
              displayName: 'PP',
              pocketId: 'medicine',
              uses: [
                ProjectItemUseDefinition(
                    contexts: {
                      ProjectItemUseContext.overworld,
                      ProjectItemUseContext.battle
                    },
                    target: allMoves
                        ? ProjectItemTargetKind.partyMember
                        : ProjectItemTargetKind.partyMove,
                    consumption: ProjectItemConsumptionPolicy.onApplied,
                    effect: ProjectItemEffectDefinition.restorePp(
                        mode: ProjectItemAmountMode.flat,
                        amount: 10,
                        scope: allMoves
                            ? ProjectItemPpScope.allMoves
                            : ProjectItemPpScope.selectedMove)),
              ]),
        ]);
        final files = <String, List<int>>{
          'project/project.json': utf8.encode(
              jsonEncode(portable ? publication.descriptor : project.toJson())),
          if (portable)
            for (final entry in publication.storage.objects.entries)
              'project/catalog/objects/${entry.key}.json': entry.value,
          'project/data/pokemon/catalogs/items.json':
              utf8.encode(jsonEncode(encodeProjectItemCatalog(catalog))),
        };
        final originals = {
          for (final row in files.entries) row.key: List<int>.of(row.value)
        };
        final base = ['map@1', if (portable) 'catalog.partitioned@2'];
        GamePackageManifest manifest(bool declare) {
          final json = spatialManifest(capabilities: [
            ...base,
            if (declare) ItemPpRestoreCapabilities.allMovesCapabilityId
          ]).toJson();
          (json['compatibility'] as Map).addAll(<String, Object?>{
            'projectFormat': 'v8',
            'minHubVersion': '0.1.0',
            'saveFormat': SaveEnvelopeCodec.currentSaveFormat
          });
          return const GamePackageManifestCodec().decodeJson(json);
        }

        if (allMoves) {
          expect(
              () => const GamePackageBuilder()
                  .build(manifest: manifest(false), payloadFiles: files),
              throwsA(isA<GamePackageFormatException>().having(
                  (error) => error.message,
                  'capability',
                  contains(ItemPpRestoreCapabilities.allMovesCapabilityId))));
        }
        final built = const GamePackageBuilder()
            .build(manifest: manifest(allMoves), payloadFiles: files);
        final host = AveluneRuntimeCompatibility.host();
        final old = GamePackageHostCompatibility(
          hubVersion: host.hubVersion,
          runtimeApiVersion: host.runtimeApiVersion,
          supportedRuntimeApiVersions: host.supportedRuntimeApiVersions,
          capabilities: host.capabilities
              .difference({ItemPpRestoreCapabilities.allMovesCapabilityId}),
          supportedProjectFormats: host.supportedProjectFormats,
          currentProjectFormat: host.currentProjectFormat,
          currentProjectFormats: host.currentProjectFormats,
          supportedSaveFormats: host.supportedSaveFormats,
        );
        expect(
            GamePackageInspector(hostCompatibility: host)
                .inspect(built.packageBytes)
                .compatibility!
                .decision,
            GamePackageCompatibilityDecision.accept);
        final bytes = List<int>.of(built.packageBytes);
        if (allMoves) {
          expect(
              () => GamePackageInspector(hostCompatibility: old)
                  .inspect(built.packageBytes),
              throwsA(isA<GamePackageFormatException>().having(
                  (error) => error.code, 'reason', 'capabilityUnsupported')));
          expect(
              const GamePackageCompatibilityEvaluator()
                  .evaluate(built.manifest, old)
                  .missingCapabilities,
              [ItemPpRestoreCapabilities.allMovesCapabilityId]);
        } else {
          expect(
              GamePackageInspector(hostCompatibility: old)
                  .inspect(built.packageBytes)
                  .compatibility!
                  .decision,
              GamePackageCompatibilityDecision.accept);
        }
        expect(built.packageBytes, bytes);
        expect(files, originals);
        expect(
            decodeProjectItemCatalog(encodeProjectItemCatalog(catalog))
                .entries
                .single
                .uses
                .single
                .effect,
            catalog.entries.single.uses.single.effect);
      });
    }
  }
}
