import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final scenario in [
    (custom: false, pokemon: false),
    (custom: true, pokemon: false),
    (custom: false, pokemon: true),
  ]) {
    final custom = scenario.custom;
    testWidgets(
      custom
          ? '3D world-only playtest still awaits explicit asset preparation'
          : scenario.pokemon
          ? '3D Pokemon playtest keeps provisioning resource validation'
          : '3D world-only playtest skips default Pokemon provisioning',
      (tester) async {
        late Directory root;
        late ProjectSession session;
        late ProjectMapEntry entry;
        late String revision;
        final port = LocalMapWorkspaceAdapter();
        await tester.runAsync(() async {
          root = await Directory.systemTemp.createTemp('studio-world-only-');
          addTearDown(() => root.delete(recursive: true));
          final map = MapData(
            version: ProjectVersion.v9,
            id: 'field',
            name: 'Terrain',
            size: const GridSize(width: 4, height: 4),
            spatialScene: MapSpatialScene(width: 4, depth: 4),
          );
          final project = ProjectManifest(
            version: ProjectVersion.v9,
            name: 'World only',
            newGame: const ProjectNewGameConfig(enabled: false),
            pokemon: ProjectPokemonConfig(
              enabled: scenario.pokemon,
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            ),
            settings: ProjectSettings(
              dimension: ProjectDimension.threeD,
              defaultPlayerCharacterId: 'hero',
              spatialCamera: SpatialCameraProfile(),
            ),
            maps: const [
              ProjectMapEntry(
                id: 'field',
                name: 'Terrain',
                relativePath: 'field.json',
              ),
              ProjectMapEntry(
                id: 'unrelated',
                name: 'Unrelated map',
                relativePath: 'not-needed-by-this-map.json',
              ),
            ],
            tilesets: const [
              ProjectTilesetEntry(
                id: 'hero-atlas',
                name: 'Hero',
                relativePath: 'hero.png',
              ),
            ],
            characters: [
              ProjectCharacterEntry(
                id: 'hero',
                name: 'Hero',
                tilesetId: 'hero-atlas',
                animations: [
                  for (final facing in EntityFacing.values)
                    CharacterAnimation(
                      state: CharacterAnimationState.walk,
                      direction: facing,
                      frames: const [
                        CharacterAnimationFrame(
                          source: TilesetSourceRect(
                            x: 0,
                            y: 0,
                            width: 32,
                            height: 32,
                          ),
                          durationMs: 100,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          );
          ProjectManifest.fromJson(project.toJson());
          MapData.fromJson(map.toJson());
          expect(project.pokemon.enabled, scenario.pokemon);
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
          await File('${root.path}/field.json')
              .writeAsString(jsonEncode(map.toJson()));
          await File(
            '${root.path}/hero.png',
          ).writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
          final assetCatalog = File('${root.path}/$assetCatalogStorageKey');
          await assetCatalog.parent.create(recursive: true);
          await assetCatalog.writeAsString(jsonEncode(AssetCatalog().toJson()));
          session = ProjectSession(
            sessionId: 'world-only',
            name: project.name,
            directoryPath: await root.resolveSymbolicLinks(),
          );
          await port.loadProject(session);
          entry = project.maps.first;
          revision = (await port.loadMap(session, entry)).revision;
        });
        var called = false;
        const customMessage = 'Explicit preparation observed';
        const newGameMessage = 'Configurez la nouvelle partie';
        final expected = custom
            ? customMessage
            : scenario.pokemon
            ? 'workspace.file_unavailable'
            : newGameMessage;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StudioPlaytestView(
                session: session,
                entry: entry,
                expectedRevision: revision,
                port: port,
                onClose: () {},
                prepareProjectAssets: custom
                    ? (_) async {
                        called = true;
                        throw StateError(customMessage);
                      }
                    : null,
              ),
            ),
          ),
        );
        for (var attempt = 0; attempt < 100; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
          if (find.textContaining(expected).evaluate().isNotEmpty) break;
        }
        expect(
          find.textContaining(expected),
          findsOneWidget,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((text) => text.data)
              .join('\n'),
        );
        expect(called, custom);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
