import 'package:avelune_studio/features/verification/application/studio_failure_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'studio_spatial_gameplay_playtest_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(setUpSpatialPlaytest);

  tearDown(tearDownSpatialPlaytest);

  test('Studio prepares and opens a painted actor-occlusion map', () async {
    final material = const ProjectSmartTileMaterial(
      id: 'contact',
      name: 'Contact',
      connectionGroupId: 'contact',
      pathSurfaceKind: PathSurfaceKind.tallGrass,
    );
    final project = bundle.manifest.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: [material],
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'contact',
            name: 'Contact',
            tilesetId: 'hero-atlas',
            columns: 1,
            rows: 1,
          ),
        ],
        animations: [
          ProjectSmartTileAnimation(
            id: 'contact',
            name: 'Contact',
            loop: SmartTileAnimationLoop.once,
            frames: [
              for (var i = 0; i < 2; i++)
                const ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'contact',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 100,
                ),
            ],
          ),
        ],
        presets: [
          ProjectSmartTilePreset(
            id: 'contact',
            name: 'Contact',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: const SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: const SmartTileTransformPolicy(),
            defaultMaterialId: 'contact',
            allowedMaterialIds: ['contact'],
            rules: [
              SmartTileRule(
                id: 'contact',
                centerMatch: const SmartTileSlotMatch.material('contact'),
                candidates: const [
                  SmartTileCandidate(
                    id: 'contact',
                    parts: [
                      SmartTileVisualPart(
                        channel: SmartTileRenderChannel.actorOcclusion,
                        source: SmartTileVisualSource.animation(
                          animationId: 'contact',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    bundle = bundle.copyWith(
      manifest: project,
      map: bundle.map.copyWith(
        layers: [
          SmartTileLayer(
            id: 'contact',
            name: 'Contact',
            presetId: 'contact',
            usage: SmartTileUsage.path,
            animationActivation: SmartTileAnimationActivation.onEnter,
            materialPalette: const ['', 'contact'],
            field: SmartTileField.cell(
              semanticCells: [for (var i = 0; i < 64; i++) i == 36 ? 1 : 0],
            ),
          ),
        ],
      ),
    );
    expect(
      SpatialActorOcclusionCapabilities.requiresCapability(
        project,
        maps: [bundle.map],
      ),
      isTrue,
    );
    final host = await prepare();
    await host.runtime.load((_) {});
    expect(
      host.runtime.descriptor.grantedCapabilities,
      contains(SpatialActorOcclusionCapabilities.capabilityId),
    );
    host.runtime.session!.frames(0);
    expect(
      host.runtime.session!.actorOcclusionStateForCell(
        'field',
        'contact',
        4,
        4,
        5000,
      ),
      (active: true, elapsedMs: 200),
    );
  });

  for (final (defaultAvatar, allowedAvatars, expectedAvatar) in [
    ('second', ['hero', 'second'], 'second'),
    ('hero', ['second', 'third'], 'second'),
  ]) {
    test(
      'map preview resolves $defaultAvatar against $allowedAvatars and restores its saved actor',
      () async {
        final hero = bundle.manifest.characters.single;
        var project = bundle.manifest.copyWith(
          settings: bundle.manifest.settings.copyWith(
            defaultPlayerCharacterId: defaultAvatar,
          ),
          characters: [
            hero,
            hero.copyWith(id: 'second', name: 'Deuxième'),
            hero.copyWith(id: 'third', name: 'Troisième'),
          ],
          newGame: ProjectNewGameConfig(
            enabled: true,
            startMapId: 'field',
            playerName: 'Map preview',
            playerAvatarCharacterIds: allowedAvatars,
          ),
        );
        project = const SceneActions().createPreSessionScene(
          project,
          maps: [bundle.map],
          sceneId: 'identity',
          name: 'Identité interactive',
          templateId: 'identitySetup',
          setAsEntrypoint: true,
        );
        bundle = bundle.copyWith(manifest: project);
        final host = await prepare();
        await host.runtime.load((_) {});
        expect(
          host.runtime.gameStateSnapshot.trainerProfile.avatarCharacterId,
          expectedAvatar,
        );
        expect(
          host.runtime.gameStateSnapshot.trainerProfile.name,
          'Map preview',
        );
        expect(host.runtime.session!.character.id, expectedAvatar);
        await host.save();
        bundle = bundle.copyWith(
          manifest: bundle.manifest.copyWith(
            settings: bundle.manifest.settings.copyWith(
              defaultPlayerCharacterId: 'third',
            ),
          ),
        );
        final restored = await prepare(restore: true);
        await restored.runtime.load((_) {});
        expect(restored.runtime.session!.character.id, expectedAvatar);
        expect(
          restored.runtime.gameStateSnapshot.trainerProfile.avatarCharacterId,
          expectedAvatar,
        );
      },
    );
  }

  test('map preview keeps ambiguous starter selection blocked', () async {
    bundle = bundle.copyWith(
      manifest: bundle.manifest.copyWith(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'field',
          playerAvatarCharacterIds: ['hero'],
          starterOptions: [
            ProjectStarterOption(
              id: 'first',
              label: 'Premier',
              pokemon: PlayerPokemon(
                speciesId: 'first',
                natureId: 'hardy',
                abilityId: 'run_away',
              ),
            ),
            ProjectStarterOption(
              id: 'second',
              label: 'Deuxième',
              pokemon: PlayerPokemon(
                speciesId: 'second',
                natureId: 'hardy',
                abilityId: 'run_away',
              ),
            ),
          ],
        ),
      ),
    );
    await expectLater(
      prepare(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'diagnostic',
          contains('starter'),
        ),
      ),
    );
    expect(saves.hasSave, isFalse);
  });

  test('3D direct test rejects a missing authored New Game', () async {
    bundle = bundle.copyWith(
      manifest: bundle.manifest.copyWith(
        newGame: const ProjectNewGameConfig(enabled: false),
      ),
    );
    await expectLater(
      prepare(),
      throwsA(
        isA<StudioLaunchProblem>()
            .having(
              (error) => error.message,
              'diagnostic',
              contains('Configurez la nouvelle partie'),
            )
            .having((error) => error.owner, 'owner', StudioFailureOwner.map),
      ),
    );
    expect(saves.hasSave, isFalse);
  });
}
