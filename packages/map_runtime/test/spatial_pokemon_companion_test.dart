import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/player/runtime_pokemon_overworld_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the lead Pokemon uses its own overworld media and follows changes',
      () async {
    final root = await Directory.systemTemp.createTemp('pokemon-follower-');
    addTearDown(() => root.delete(recursive: true));
    Future<void> writeJson(String path, Object value) async {
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(value));
    }

    Future<void> writeAtlas(String path, int cellSize) async {
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      final image = img.Image(width: cellSize * 4, height: cellSize * 4);
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          image.setPixelRgba(x, y, 30, 120, 220, 255);
        }
      }
      await file.writeAsBytes(img.encodePng(image));
    }

    await writeAtlas('hero.png', 8);
    await writeAtlas('pokemon/riolu.png', 16);
    await writeAtlas('pokemon/riolu-shiny.png', 24);
    await writeAtlas('pokemon/other.png', 20);
    await writeJson('data/pokemon/species/riolu.json', {
      'id': 'riolu',
      'forms': {'formId': 'base'},
      'refs': {'media': 'riolu-media'},
    });
    await writeJson('data/pokemon/media/riolu-media.json', {
      'schemaVersion': 2,
      'speciesId': 'riolu-media',
      'defaultFormId': 'base',
      'variants': {
        'base': {
          'overworld': 'pokemon/riolu.png',
          'overworldShiny': 'pokemon/riolu-shiny.png',
        },
        'other': {'overworld': 'pokemon/other.png'},
      },
    });
    final hero = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'unused',
      frameWidth: 1,
      frameHeight: 1,
      animations: [
        for (final facing in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: facing,
            sourceAssetId: 'hero',
            frames: const [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 8, height: 8),
                durationMs: 100,
              ),
            ],
          ),
      ],
    );
    final manifest = ProjectManifest(
      name: 'Pokemon follower',
      version: ProjectVersion.v9,
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
      ),
      maps: const [],
      tilesets: const [],
      characters: [hero],
      pokemon: const ProjectPokemonConfig(
        enabled: true,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      partyCompanion: const ProjectPartyCompanionConfig(enabled: true),
    );
    final bundle = RuntimeMapBundle(
      manifest: manifest,
      map: MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 12, height: 12),
        layers: const [],
        spatialScene: MapSpatialScene(
          width: 12,
          depth: 12,
          navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
        ),
      ),
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      characterAnimationAbsolutePathsByAssetId: {
        'hero': '${root.path}/hero.png',
      },
    );
    PlayerPokemon member(String form, {bool shiny = false}) => PlayerPokemon(
      individualId: 'one',
      speciesId: 'riolu',
      formId: form,
      natureId: 'hardy',
      abilityId: 'inner-focus',
      currentHp: 10,
      isShiny: shiny,
    );
    var state = GameState(
      saveId: 'save',
      currentMapId: 'map',
      party: PlayerParty(members: [member('base')]),
    );
    final session = await SpatialExplorationSession.load(
      bundle,
      presentationStateProvider: () => state,
    );
    addTearDown(session.dispose);

    Future<void> expectFollowerSize(int size) async {
      session.movement.setInput(x: 1, z: 0);
      for (var i = 0; i < 15; i++) {
        session.frames(.05);
      }
      for (var i = 0; i < 100; i++) {
        final frame = session.frames(0)['party-companion'];
        if (frame?.frame.width == size) {
          expect(frame!.frame.top, size * 2);
          expect(frame.contactShadowFootAnchor, isNotNull);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      fail('The $size-pixel Pokemon follower never appeared.');
    }

    await expectFollowerSize(16);
    state = state.copyWith(party: PlayerParty(members: [member('base', shiny: true)]));
    await expectFollowerSize(24);
    state = state.copyWith(party: PlayerParty(members: [member('other', shiny: true)]));
    await expectFollowerSize(20);
    state = state.copyWith(party: PlayerParty(members: [member('missing')]));
    await expectFollowerSize(16);
    state = state.copyWith(party: const PlayerParty());
    expect(session.frames(0), isNot(contains('party-companion')));
  });

  test('overworld paths cannot leave the game directory', () async {
    final root = await Directory.systemTemp.createTemp('pokemon-path-');
    addTearDown(() => root.delete(recursive: true));
    final outsideName = '${root.uri.pathSegments.where((part) => part.isNotEmpty).last}.png';
    final outside = File('${root.parent.path}/$outsideName');
    await outside.writeAsBytes([1, 2, 3]);
    addTearDown(() => outside.delete());
    final file = File('${root.path}/data/pokemon/media/riolu.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({
      'schemaVersion': 2,
      'speciesId': 'riolu',
      'defaultFormId': 'base',
      'variants': {
        'base': {'overworld': '../$outsideName'},
      },
    }));
    const pokemon = PlayerPokemon(
      speciesId: 'riolu',
      formId: 'base',
      natureId: 'hardy',
      abilityId: 'inner-focus',
    );
    final resolver = RuntimePokemonOverworldResolver(
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
    );
    expect(await resolver.resolve(pokemon), isNull);
  });
}
