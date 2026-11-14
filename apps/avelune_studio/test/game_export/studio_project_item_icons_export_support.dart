import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

Future<GamePackageExportArtifact> buildItemIconsPackage(
  Directory root,
  GamePackageExportProfile profile,
  GamePackageExportMode mode,
) =>
    CanonicalGamePackageExportService(pokemonValidator: acceptPokemonProjection)
        .build(projectRoot: root, profile: profile, mode: mode);

Future<void> enableItems(Directory root) async {
  final projectFile = File(p.join(root.path, 'project.json'));
  final project = ProjectManifest.fromJson(
    jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
  );
  await projectFile.writeAsString(
    jsonEncode(
      project
          .copyWith(
            pokemon: const ProjectPokemonConfig(
              enabled: true,
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            ),
          )
          .toJson(),
    ),
  );
  final catalog = File(p.join(root.path, 'data/pokemon/catalogs/items.json'));
  await catalog.parent.create(recursive: true);
  await catalog.writeAsString(
    jsonEncode(
      encodeProjectItemCatalog(
        ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'potion',
              displayName: 'Potion',
              pocketId: 'medicine',
            ),
          ],
        ),
      ),
    ),
  );
  await File(p.join(root.path, 'data/pokemon/catalogs/moves.json'))
      .writeAsString(jsonEncode({'entries': []}));
}

Future<PokemonCatalogCoherenceReport> acceptPokemonProjection({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectManifest manifest,
}) async => PokemonCatalogCoherenceReport(const <PokemonCatalogDiagnostic>[]);

final class ItemIconBundle extends CachingAssetBundle {
  ItemIconBundle(this.assets);

  final Map<String, List<int>> assets;
  final requests = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requests.add(key);
    final bytes = assets[key];
    if (bytes == null) throw StateError('Unexpected asset request: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
