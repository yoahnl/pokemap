import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project character studio models', () {
    test('defaults to an empty additive catalog on v6 projects', () {
      const manifest = ProjectManifest(
        name: 'Character Studio',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );

      expect(manifest.version, ProjectVersion.v6);
      expect(manifest.characterStudioCatalog.portraitStates, isEmpty);
      expect(
        manifest.characterStudioCatalog.customAnimationDefinitions,
        isEmpty,
      );
    });

    test('round-trips a complete character studio catalog and character', () {
      const manifest = ProjectManifest(
        name: 'Character Studio',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        characterStudioCatalog: ProjectCharacterStudioCatalog(
          portraitStates: <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'surprised',
              displayName: 'Surprise',
              sortOrder: 2,
            ),
          ],
          customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Saluer',
              mode: CharacterCustomAnimationMode.directional,
              sortOrder: 3,
            ),
          ],
        ),
        characters: <ProjectCharacterEntry>[
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'characters',
            portraits: <CharacterPortraitVariant>[
              CharacterPortraitVariant(
                portraitStateId: 'surprised',
                assetId: 'portrait_hero_surprised',
                fitMode: CharacterPortraitFitMode.cover,
              ),
            ],
            animations: <CharacterAnimation>[
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: EntityFacing.south,
                sourceAssetId: 'sprite_hero_base',
                loop: false,
                frames: <CharacterAnimationFrame>[
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
                    durationMs: 120,
                  ),
                ],
              ),
            ],
            customAnimations: <CharacterCustomAnimationClip>[
              CharacterCustomAnimationClip(
                definitionId: 'wave',
                direction: EntityFacing.east,
                sourceAssetId: 'sprite_hero_wave',
                loop: false,
                frames: <CharacterAnimationFrame>[
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 2),
                    durationMs: 180,
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final json = jsonDecode(jsonEncode(manifest.toJson()));
      final decoded = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
        Map<String, dynamic>.from(json as Map),
      );

      expect(decoded, manifest);
      expect(decoded.version, ProjectVersion.v6);
    });

    test('keeps a legacy system animation source implicit', () {
      final animation = CharacterAnimation.fromJson(<String, dynamic>{
        'state': 'walk',
        'direction': 'north',
        'frames': <Object?>[],
      });

      expect(animation.sourceAssetId, isNull);
      expect(animation.loop, isTrue);
      expect(animation.toJson()['sourceAssetId'], isNull);
      expect(animation.toJson(), isNot(contains('loop')));
      expect(animation.copyWith(loop: false).toJson()['loop'], isFalse);
    });

    test('supports single and directional custom clips', () {
      const single = CharacterCustomAnimationClip(
        definitionId: 'sleep',
        sourceAssetId: 'sprite_hero_sleep',
      );
      const directional = CharacterCustomAnimationClip(
        definitionId: 'wave',
        direction: EntityFacing.west,
        sourceAssetId: 'sprite_hero_wave',
      );

      expect(single.direction, isNull);
      expect(single.loop, isTrue);
      expect(single.toJson()['direction'], isNull);
      expect(directional.toJson()['direction'], 'west');
    });

    test('uses stable wire values for studio enums', () {
      expect(
        const CharacterPortraitVariant(
          portraitStateId: 'neutral',
          assetId: 'portrait_hero_neutral',
        ).toJson()['fitMode'],
        'contain',
      );
      expect(
        const CharacterCustomAnimationDefinition(
          id: 'sleep',
          displayName: 'Dormir',
          mode: CharacterCustomAnimationMode.single,
        ).toJson()['mode'],
        'single',
      );
      expect(
        const CharacterCustomAnimationDefinition(
          id: 'wave',
          displayName: 'Saluer',
          mode: CharacterCustomAnimationMode.directional,
        ).toJson()['mode'],
        'directional',
      );
    });
  });
}
