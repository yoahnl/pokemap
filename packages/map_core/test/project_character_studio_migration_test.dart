import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project character studio v6 migration', () {
    test('does not add studio keys when a legacy project is serialized', () {
      final manifest = ProjectManifest.fromJson(_legacyProjectJson());

      final json = manifest.toJson();
      final character = (json['characters'] as List<Object?>).single as Map;
      final animation =
          (character['animations'] as List<Object?>).single as Map;

      expect(json, isNot(contains('characterStudioCatalog')));
      expect(character, isNot(contains('portraits')));
      expect(character, isNot(contains('customAnimations')));
      expect(animation, isNot(contains('sourceAssetId')));
      expect(animation, isNot(contains('loop')));
    });

    test('normalizes explicit null studio collections to empty values', () {
      final json = _legacyProjectJson()..['characterStudioCatalog'] = null;
      final character = (json['characters'] as List<Object?>).single as Map;
      character['portraits'] = null;
      character['customAnimations'] = null;

      final manifest = ProjectManifest.fromJson(json);

      expect(
        manifest.characterStudioCatalog,
        const ProjectCharacterStudioCatalog(),
      );
      expect(manifest.characters.single.portraits, isEmpty);
      expect(manifest.characters.single.customAnimations, isEmpty);
      expect(manifest.toJson(), isNot(contains('characterStudioCatalog')));
    });

    test('preserves studio data through JSON and keeps v6', () {
      const manifest = ProjectManifest(
        name: 'Character Studio project',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        characterStudioCatalog: ProjectCharacterStudioCatalog(
          portraitStates: <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'surprised',
              displayName: 'Surprise',
            ),
          ],
          customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Saluer',
              mode: CharacterCustomAnimationMode.single,
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
              ),
            ],
            customAnimations: <CharacterCustomAnimationClip>[
              CharacterCustomAnimationClip(
                definitionId: 'wave',
                sourceAssetId: 'sprite_hero_wave',
              ),
            ],
          ),
        ],
      );

      final encoded = jsonDecode(jsonEncode(manifest.toJson()));
      final decoded = ProjectManifest.fromJson(
        Map<String, dynamic>.from(encoded as Map),
      );

      expect(decoded, manifest);
      expect(decoded.version, ProjectVersion.v6);
      expect(decoded.toJson(), contains('characterStudioCatalog'));
    });

    test('renames a definition without changing its stable id', () {
      const definition = CharacterPortraitStateDefinition(
        id: 'surprised',
        displayName: 'Surprise',
      );
      const portrait = CharacterPortraitVariant(
        portraitStateId: 'surprised',
        assetId: 'portrait_hero_surprised',
      );

      final renamed = definition.copyWith(displayName: 'Étonnée');

      expect(renamed.id, definition.id);
      expect(portrait.portraitStateId, renamed.id);
    });

    test('ignores unknown future studio keys without changing known data', () {
      final json = _legacyProjectJson()
        ..['characterStudioCatalog'] = <String, Object?>{
          'portraitStates': <Object?>[],
          'customAnimationDefinitions': <Object?>[],
          'futureCatalogField': true,
        };
      final character = (json['characters'] as List<Object?>).single as Map;
      character['futureCharacterField'] = 'ignored';

      final manifest = ProjectManifest.fromJson(json);

      expect(manifest.characterStudioCatalog.portraitStates, isEmpty);
      expect(manifest.characters.single.id, 'hero');
    });
  });
}

Map<String, dynamic> _legacyProjectJson() {
  return <String, dynamic>{
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
        'animations': <Object?>[
          <String, Object?>{
            'state': 'idle',
            'direction': 'south',
            'frames': <Object?>[],
          },
        ],
      },
    ],
  };
}
