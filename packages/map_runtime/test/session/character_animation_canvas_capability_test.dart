import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/catalog_storage/working_project_catalog.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (extended, granted) in [
    (true, false),
    (true, true),
    (false, false),
  ]) {
    test(
      '2D partitioned canvas admission without preload extended=$extended granted=$granted',
      () async {
        final root = await Directory.systemTemp.createTemp('canvas-session-');
        addTearDown(() => root.delete(recursive: true));
        final project = ProjectManifest(
          version: ProjectVersion.v8,
          name: 'Canvas session',
          settings: const ProjectSettings(defaultPlayerCharacterId: 'hero'),
          newGame: const ProjectNewGameConfig(
            enabled: true,
            startMapId: 'field',
          ),
          maps: const [
            ProjectMapEntry(
              id: 'field',
              name: 'Field',
              relativePath: 'field.json',
            ),
          ],
          tilesets: const [
            ProjectTilesetEntry(
              id: 'actors',
              name: 'Actors',
              relativePath: 'actors.png',
            ),
          ],
          characters: [
            ProjectCharacterEntry(
              id: 'hero',
              name: 'Hero',
              tilesetId: 'actors',
              animations: [
                CharacterAnimation(
                  state: CharacterAnimationState.idle,
                  direction: EntityFacing.south,
                  sourceAssetId: 'canvas',
                  presentationReferenceHeightPx: extended ? 32 : null,
                  frames: const [
                    CharacterAnimationFrame(
                      source: TilesetSourceRect(
                        x: 0,
                        y: 0,
                        width: 32,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        await WorkingProjectCatalog.create(
          store: store,
          projectId: 'canvas-session',
          project: project,
        );
        await File('${root.path}/field.json').writeAsString(
          jsonEncode(
            MapData(
              id: 'field',
              name: 'Field',
              size: const GridSize(width: 4, height: 4),
            ).toJson(),
          ),
        );
        final catalog = await RuntimeProjectCatalog.open(
          '${root.path}/project.json',
        );
        expect(catalog.projectMetadata.characters, isEmpty);
        catalog.dispose();
        var mounts = 0;
        final runtime = PlayableMapGameSessionRuntime(
          descriptor: GameSessionDescriptor(
            sessionId: 'canvas-session',
            sessionToken: 'canvas-token',
            identity: GameIdentity(
              gameId: 'org.example.canvas',
              gameVersion: '1.0.0',
              projectFormat: ProjectFormat.v8,
              saveFormat: SaveEnvelopeCodec.currentSaveFormat,
              compatibilityId: 'canvas-session',
            ),
            profileId: 'profile',
            slotId: 'slot',
            launchMode: GameSessionLaunchMode.newGame,
            installedVersionHandle: 'canvas-installed',
            runtimeApiVersion: '1.4.0',
            grantedCapabilities: {
              'map@1',
              if (granted) CharacterAnimationCanvasCapabilities.capabilityId,
            },
            locale: 'fr',
            accessibility: const GameSessionAccessibilityOptions(),
            initialGameState: const GameState(
              saveId: '019a3f70-0000-7000-8000-000000000702',
              currentMapId: 'field',
              playerPosition: GridPos(x: 1, y: 1),
              trainerProfile: TrainerProfile(
                name: 'Yoahn',
                avatarCharacterId: 'hero',
              ),
            ),
          ),
          projectFilePath: () async => '${root.path}/project.json',
          initialSave: () async => null,
          mountGame: (_) async => mounts++,
          unmountGame: (_) async {},
        );
        addTearDown(runtime.dispose);
        if (extended && !granted) {
          await expectLater(
            runtime.load((_) {}),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                contains(CharacterAnimationCanvasCapabilities.capabilityId),
              ),
            ),
          );
          expect(mounts, 0);
          expect(runtime.game, isNull);
        } else {
          await runtime.load((_) {});
          expect(mounts, 1);
          expect(runtime.game, isNotNull);
        }
      },
    );
  }
}
