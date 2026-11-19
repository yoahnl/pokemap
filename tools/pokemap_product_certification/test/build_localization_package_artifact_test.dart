import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_project_smoke.dart';
import 'package:pokemap_hub/features/saves/data/repositories/game_save_update_preparation.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_product_certification/pokemap_product_certification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the installed localization recipe contains names, dialogues and a battle',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'avelune-localization-',
      );
      addTearDown(() => root.delete(recursive: true));
      final author = Directory(p.join(root.path, 'author'));
      final packageFile = File(
        p.join(root.path, 'recette-localisation.avelunegame'),
      );
      final artifact = await _buildRecipe(author);
      await packageFile.writeAsBytes(artifact.packageBytes, flush: true);

      final compatibility = aveluneHostCompatibility();
      final supportRoot = Directory(p.join(root.path, 'support'));
      final installer = GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: GamePackageInspector(hostCompatibility: compatibility),
        availableDiskBytes: (_) async => 1024 * 1024 * 1024,
        prepareSavesForUpdate: GameSaveUpdatePreparation(
          supportRoot: supportRoot,
        ).call,
        loadSmoke: loadInstalledProjectSmoke,
      );
      final installed = await installer.install(
        packageFile,
        source: GamePackageInstallSource.localExport,
      );
      await author.delete(recursive: true);
      final launch = await InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: compatibility,
      ).resolve(installed.game);
      final projectFile = await launch.assets.resolveReference(launch.project);
      expect(launch.manifest.locales.defaultLocale, 'fr');
      expect(
        launch.manifest.locales.supported,
        unorderedEquals(['fr', 'en', 'es']),
      );
      expect(
        launch.grantedCapabilities,
        contains(dialogueLocalizationCapability),
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFile.path,
        mapId: NeutralCertificationGameFixture.fixedMapId,
      );
      final project = bundle.manifest;
      final locales = ProjectLocalePolicy(
        supportedLocales: launch.manifest.locales.supported,
        fallbackLocale: launch.manifest.locales.defaultLocale,
      );
      Future<String> line(String id, String locale) async {
        final entry = project.dialogues.singleWhere(
          (dialogue) => dialogue.id == id,
        );
        final bytes = await File(
          p.join(bundle.projectRootDirectory, entry.relativePath),
        ).readAsBytes();
        final compiled = const RuntimeDialogueDocumentCodec().decodeUtf8(bytes);
        return runtimeDialogueTextScopes(
          resolveRuntimeDialogueLocalization(
            compiled,
            entry.localization!,
            preferredLocale: locale,
            locales: locales,
          ),
        ).single.text;
      }

      expect(await line('greeting', 'en'), 'Welcome to the UwU harbor.');
      expect(await line('greeting', 'es-MX'), 'Bienvenido al puerto UwU.');
      expect(await line('fallback', 'en'), 'Le phare est ouvert.');
      final species = await RuntimePokemonSpeciesLoader().loadSpeciesSnapshot(
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: project.pokemon,
      );
      expect(species['bulbasaur']!.displayName('fr'), 'Bulbizarre');
      expect(species['bulbasaur']!.displayName('en'), 'Bulbasaur');
      expect(species['ivysaur']!.displayName('fr'), 'Ivysaur');
      expect(project.newGame.initialParty.map((member) => member.nickname), [
        '',
        'UwU',
      ]);
      await _verifyBattle(bundle);

      const output = String.fromEnvironment('POKEMAP_CERTIFICATION_OUTPUT');
      if (output.isNotEmpty) {
        final file = File(output).absolute;
        expect(await file.exists(), isFalse);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(artifact.packageBytes, flush: true);
      }
      bundle.projectCatalog?.dispose();
    },
  );
}

Future<GamePackageExportArtifact> _buildRecipe(Directory author) async {
  const fixture = NeutralCertificationGameFixture(
    partySize: 2,
    encounterField: true,
  );
  await fixture.writeAuthorWorkspace(author);
  await File(
    p.join(author.path, 'data', 'pokemon', 'pokemon_data_manifest.json'),
  ).delete();
  final repositories = FileProjectRepository();
  final projectFile = p.join(author.path, 'project.json');
  final base = await repositories.loadProject(projectFile);
  final dialogues = [
    await _writeDialogue(
      author,
      'greeting',
      'Bienvenue au port UwU.',
      translations: {
        'en': 'Welcome to the UwU harbor.',
        'es': 'Bienvenido al puerto UwU.',
      },
    ),
    await _writeDialogue(author, 'fallback', 'Le phare est ouvert.'),
  ];
  final project = base.copyWith(
    dialogues: dialogues,
    scenes: [...base.scenes, _intro(dialogues)],
    newGame: ProjectNewGameConfig.fromJson({
      ...base.newGame.toJson(),
      'preSessionSceneId': 'localization_intro',
      'initialParty': [
        base.newGame.initialParty.first.toJson(),
        base.newGame.initialParty.last.copyWith(nickname: 'UwU').toJson(),
      ],
    }),
  );
  await repositories.saveProject(project, projectFile);
  final workspace = ProjectFileSystem(author.path);
  final writer = FilePokemonWriteRepository();
  for (final (file, names) in [
    ('0001-bulbasaur.json', {'fr': 'Bulbizarre', 'en': 'Bulbasaur'}),
    ('0002-ivysaur.json', {'en': 'Ivysaur'}),
  ]) {
    final relativePath = 'data/pokemon/species/$file';
    final base = jsonDecode(
      await File(p.join(author.path, relativePath)).readAsString(),
    ) as Map<String, dynamic>;
    await writer.saveSpeciesAtRelativePath(
      workspace,
      relativePath: relativePath,
      species: PokemonSpeciesFile.fromJson({...base, 'names': names}),
    );
  }
  try {
    return await const CanonicalGamePackageExportService().build(
      projectRoot: author,
      profile: fixture.exportProfile.copyWith(
        gameId: 'dev.avelune.qa.localization',
        title: 'Recette localisation UwU',
        defaultLocale: 'fr',
        supportedLocales: ['fr', 'en', 'es'],
      ),
      mode: GamePackageExportMode.localTest,
    );
  } on GamePackageExportException catch (error) {
    fail('$error (${error.path}): ${error.cause}');
  }
}

Future<ProjectDialogueEntry> _writeDialogue(
  Directory root,
  String id,
  String line, {
  Map<String, String> translations = const {},
}) async {
  final source = 'title: Start\n---\n$line\n===\n';
  final relativePath = 'dialogues/$id.yarn';
  final file = File(p.join(root.path, relativePath));
  await file.parent.create(recursive: true);
  await file.writeAsString(source);
  var localization = readLocalizedDialogue(
    source: source,
    sourceLocale: 'fr',
  ).localization;
  final unitId = localization.units.single.id;
  for (final translation in translations.entries) {
    localization = localization.translate(
      unitId,
      translation.key,
      translation.value,
    );
  }
  return ProjectDialogueEntry(
    id: id,
    name: id,
    relativePath: relativePath,
    localization: localization,
  );
}

SceneAsset _intro(List<ProjectDialogueEntry> dialogues) {
  final ids = ['start', ...dialogues.map((dialogue) => dialogue.id), 'end'];
  return SceneAsset(
    id: 'localization_intro',
    name: 'Localisation',
    executionProfile: SceneExecutionProfile.preSession,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (final dialogue in dialogues)
          SceneNode(
            id: dialogue.id,
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: dialogue.id),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        for (var index = 0; index < ids.length - 1; index++)
          SceneEdge(
            id: 'next_$index',
            fromNodeId: ids[index],
            fromPortId: 'completed',
            toNodeId: ids[index + 1],
            kind: SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
  );
}

Future<void> _verifyBattle(RuntimeMapBundle bundle) async {
  final project = bundle.manifest;
  final spawn = bundle.map.entities.singleWhere(
    (entity) => entity.id == NeutralCertificationGameFixture.fixedSpawnId,
  );
  final newGame = createNewGameStateFromProject(
    project: project,
    startMap: bundle.map,
    saveId: 'localization',
  );
  final catalogs = await loadRuntimePlayerPokemonProgressionCatalogs(
    gameState: newGame,
    projectRootDirectory: bundle.projectRootDirectory,
    pokemonConfig: project.pokemon,
  );
  final gameState = hydrateRuntimePlayerPokemonProgression(
    gameState: newGame,
    catalogs: catalogs,
    ruleset: project.pokemon.ruleset,
    defaultOrigin: PlayerPokemonHydrationOrigin.newGame,
  );
  final world = GameplayWorldState.initial(
    map: bundle.map,
    playerPos: gameState.playerPosition,
    playerFacing: Direction.south,
    project: project,
  );
  final moved = stepGameplayWorld(
    world,
    const MoveIntent(Direction.south),
  ).world;
  expect(moved.player.pos, NeutralCertificationGameFixture.encounterCell);
  final encounter = checkEncounterAtPlayerPosition(
    world: moved,
    project: project,
    encounterKind: EncounterKind.walk,
    random: Random(4),
    policy: const GameplayEncounterPolicy(chancePerStep: 1),
  ).encounter;
  expect(encounter, isNotNull);
  expect(gameState.playerPosition, spawn.pos);
  final mapper = RuntimeBattleSetupMapper();
  final request = await mapper.hydrateWildRequest(
    bundle: bundle,
    request: buildBattleStartRequestFromEncounter(
      encounter: encounter!,
      world: moved,
      createdAtEpochMs: 1,
    ),
  );
  final setup = await mapper.map(
    bundle: bundle,
    gameState: gameState,
    request: request,
  );
  expect(setup.playerPokemon.speciesId, 'bulbasaur');
  expect(setup.enemyPokemon.speciesId, 'ivysaur');
}
