import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project character legacy compatibility', () {
    test('decodes a v6 character without studio fields', () {
      final manifest = ProjectManifest.fromJsonPokeMapBetaV1ForTest(
        <String, dynamic>{
          'name': 'Legacy character project',
          'version': 'v6',
          'maps': <Object?>[],
          'tilesets': <Object?>[
            <String, Object?>{
              'id': 'characters',
              'name': 'Characters',
              'relativePath': 'assets/characters.png',
            },
          ],
          'characters': <Object?>[
            <String, Object?>{
              'id': 'hero',
              'name': 'Hero',
              'tilesetId': 'characters',
            },
          ],
          'settings': <String, Object?>{'playerCharacterId': 'hero'},
        },
      );

      expect(manifest.version, ProjectVersion.v6);
      expect(manifest.characters, hasLength(1));
      expect(
        manifest.characters.single,
        const ProjectCharacterEntry(
          id: 'hero',
          name: 'Hero',
          tilesetId: 'characters',
        ),
      );
      expect(manifest.settings.defaultPlayerCharacterId, 'hero');
      expect(() => ProjectValidator.validate(manifest), returnsNormally);
    });

    test('round-trips legacy animation keys and defaults', () {
      final character = ProjectCharacterEntry.fromJson(<String, dynamic>{
        'id': 'hero',
        'name': 'Hero',
        'tilesetId': 'characters',
        'animations': <Object?>[
          <String, Object?>{
            'state': 'idle',
            'direction': 'south',
            'frames': <Object?>[
              <String, Object?>{
                'source': <String, Object?>{
                  'x': 1,
                  'y': 2,
                  'width': 1,
                  'height': 2,
                },
              },
            ],
          },
        ],
      });

      expect(character.frameWidth, 1);
      expect(character.frameHeight, 2);
      expect(character.animations.single.state, CharacterAnimationState.idle);
      expect(character.animations.single.direction, EntityFacing.south);
      expect(character.animations.single.frames.single.durationMs, 150);

      final json = jsonDecode(jsonEncode(character.toJson()));

      expect(
        ProjectCharacterEntry.fromJson(Map<String, dynamic>.from(json as Map)),
        character,
      );
      expect((json['animations'] as List<Object?>).single, <String, Object?>{
        'state': 'idle',
        'direction': 'south',
        'frames': <Object?>[
          <String, Object?>{
            'source': <String, Object?>{
              'x': 1,
              'y': 2,
              'width': 1,
              'height': 2,
            },
            'durationMs': 150,
          },
        ],
      });
    });

    test('keeps idle walk and run wire values stable', () {
      const animations = <CharacterAnimation>[
        CharacterAnimation(
          state: CharacterAnimationState.idle,
          direction: EntityFacing.north,
        ),
        CharacterAnimation(
          state: CharacterAnimationState.walk,
          direction: EntityFacing.south,
        ),
        CharacterAnimation(
          state: CharacterAnimationState.run,
          direction: EntityFacing.west,
        ),
      ];

      expect(
        animations.map((animation) => animation.toJson()['state']),
        <String>['idle', 'walk', 'run'],
      );
    });

    test('accepts an incomplete character without animations', () {
      const manifest = ProjectManifest(
        name: 'Character draft',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'characters',
            name: 'Characters',
            relativePath: 'assets/characters.png',
          ),
        ],
        characters: <ProjectCharacterEntry>[
          ProjectCharacterEntry(
            id: 'draft',
            name: 'Draft',
            tilesetId: 'characters',
          ),
        ],
      );

      expect(() => ProjectValidator.validate(manifest), returnsNormally);
    });
  });
}
