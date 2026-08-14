import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_item_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('loads the strict catalog through the shared codec', () async {
    final root = await Directory.systemTemp.createTemp('runtime-item-catalog-');
    addTearDown(() => root.delete(recursive: true));
    final expected = _catalog();
    await _writeJson(
      root,
      'custom/catalogs/items.json',
      encodeProjectItemCatalog(expected),
    );

    final loaded = await const RuntimeItemCatalogLoader().load(
      projectRootDirectory: root.path,
      pokemonConfig: _config,
    );

    expect(loaded, expected);
    expect(loaded?.entries.single.machine?.moveId, 'protect');
  });

  test('returns null when no item catalog is configured or present', () async {
    final root = await Directory.systemTemp.createTemp('runtime-item-missing-');
    addTearDown(() => root.delete(recursive: true));

    expect(
      await const RuntimeItemCatalogLoader().load(
        projectRootDirectory: root.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
      ),
      isNull,
    );
    expect(
      await const RuntimeItemCatalogLoader().load(
        projectRootDirectory: root.path,
        pokemonConfig: _config,
      ),
      isNull,
    );
  });

  test('rejects legacy catalogs and paths outside the project', () async {
    final root = await Directory.systemTemp.createTemp('runtime-item-invalid-');
    addTearDown(() => root.delete(recursive: true));
    await _writeJson(
      root,
      'custom/catalogs/items.json',
      {
        'catalog': 'items',
        'entries': <Object?>[],
      },
    );

    await expectLater(
      () => const RuntimeItemCatalogLoader().load(
        projectRootDirectory: root.path,
        pokemonConfig: _config,
      ),
      throwsA(isA<RuntimeBattleSetupException>()),
    );
    await expectLater(
      () => const RuntimeItemCatalogLoader().load(
        projectRootDirectory: root.path,
        pokemonConfig: const ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          catalogFiles: {'items': '../items.json'},
        ),
      ),
      throwsA(isA<RuntimeBattleSetupException>()),
    );
  });
}

const _config = ProjectPokemonConfig(
  ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  catalogFiles: {'items': 'custom/catalogs/items.json'},
);

ProjectItemCatalog _catalog() {
  return ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'tm-protect',
        displayName: 'TM Protect',
        pocketId: 'machines',
        machine: const ProjectMoveMachineItemDefinition(
          moveId: 'protect',
          kind: ProjectMoveMachineKind.tm,
          consumable: true,
        ),
      ),
    ],
  ).normalized();
}

Future<void> _writeJson(
  Directory root,
  String relativePath,
  Map<String, Object?> json,
) async {
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}
