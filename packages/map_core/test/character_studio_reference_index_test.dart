import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CharacterStudioReferenceIndex', () {
    test('indexes portrait state and custom animation usages', () {
      final index = buildCharacterStudioReferenceIndex(
        _manifest(
          character: const ProjectCharacterEntry(
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
                direction: EntityFacing.south,
                sourceAssetId: 'sprite_hero_wave',
              ),
            ],
          ),
        ),
      );

      expect(
        index.referencesTo(
          CharacterStudioReferenceTargetKind.portraitState,
          'surprised',
        ),
        contains(
          isA<CharacterStudioReference>()
              .having(
                (reference) => reference.sourceKind,
                'sourceKind',
                CharacterStudioReferenceSourceKind.characterPortrait,
              )
              .having((reference) => reference.sourceId, 'sourceId', 'hero'),
        ),
      );
      expect(
        index.referencesTo(
          CharacterStudioReferenceTargetKind.customAnimationDefinition,
          'wave',
        ),
        hasLength(1),
      );
    });

    test('indexes current character dependencies', () {
      final index = buildCharacterStudioReferenceIndex(
        _manifest(
          defaultPlayerCharacterId: 'hero',
          newGameAvatarIds: const <String>['hero'],
          trainerCharacterId: 'hero',
          cinematicCharacterId: 'hero',
        ),
      );

      final references = index.referencesTo(
        CharacterStudioReferenceTargetKind.character,
        'hero',
      );

      expect(
        references.map((reference) => reference.sourceKind),
        containsAll(<CharacterStudioReferenceSourceKind>{
          CharacterStudioReferenceSourceKind.defaultPlayer,
          CharacterStudioReferenceSourceKind.newGameAvatar,
          CharacterStudioReferenceSourceKind.trainer,
          CharacterStudioReferenceSourceKind.cinematicAppearance,
        }),
      );
    });

    test('indexes character dependencies placed on maps', () {
      final index = buildCharacterStudioReferenceIndex(
        _manifest(),
        maps: const <MapData>[
          MapData(
            id: 'village',
            name: 'Village',
            size: GridSize(width: 8, height: 8),
            entities: <MapEntity>[
              MapEntity(
                id: 'elia_npc',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 2, y: 3),
                npc: MapEntityNpcData(characterId: 'hero'),
              ),
            ],
          ),
        ],
      );

      expect(
        index.referencesTo(
          CharacterStudioReferenceTargetKind.character,
          'hero',
        ),
        contains(
          isA<CharacterStudioReference>()
              .having(
                (reference) => reference.sourceKind,
                'sourceKind',
                CharacterStudioReferenceSourceKind.mapNpc,
              )
              .having((reference) => reference.sourceId, 'sourceId', 'elia_npc')
              .having(
                (reference) => reference.path,
                'path',
                r'$.maps[village].entities[0].npc.characterId',
              ),
        ),
      );
    });

    test('returns deterministic immutable query results', () {
      final index = buildCharacterStudioReferenceIndex(
        _manifest(
          defaultPlayerCharacterId: 'hero',
          newGameAvatarIds: const <String>['hero'],
        ),
      );

      final first = index.referencesTo(
        CharacterStudioReferenceTargetKind.character,
        'hero',
      );
      final second = index.referencesTo(
        CharacterStudioReferenceTargetKind.character,
        'hero',
      );

      expect(first, orderedEquals(second));
      expect(() => first.add(first.first), throwsUnsupportedError);
      expect(
        first.map((reference) => reference.path).toList(),
        orderedEquals(<String>[
          r'$.newGame.playerAvatarCharacterIds[0]',
          r'$.settings.defaultPlayerCharacterId',
        ]),
      );
    });
  });
}

ProjectManifest _manifest({
  ProjectCharacterEntry? character,
  String? defaultPlayerCharacterId,
  List<String> newGameAvatarIds = const [],
  String? trainerCharacterId,
  String? cinematicCharacterId,
}) {
  return ProjectManifest(
    name: 'Character Studio references',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Characters',
        relativePath: 'assets/characters.png',
      ),
    ],
    characters: <ProjectCharacterEntry>[
      character ??
          const ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'characters',
          ),
    ],
    settings: ProjectSettings(
      defaultPlayerCharacterId: defaultPlayerCharacterId,
    ),
    newGame: ProjectNewGameConfig(playerAvatarCharacterIds: newGameAvatarIds),
    trainers: trainerCharacterId == null
        ? const <ProjectTrainerEntry>[]
        : <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'trainer',
              name: 'Trainer',
              trainerClass: 'Ace',
              characterId: trainerCharacterId,
            ),
          ],
    cinematics: cinematicCharacterId == null
        ? const <CinematicAsset>[]
        : <CinematicAsset>[
            CinematicAsset(
              id: 'intro',
              title: 'Intro',
              stageContext: CinematicStageContext(
                actorAppearanceBindings: <CinematicActorAppearanceBinding>[
                  CinematicActorAppearanceBinding(
                    actorId: 'hero_actor',
                    characterId: cinematicCharacterId,
                  ),
                ],
              ),
              timeline: CinematicTimeline(),
            ),
          ],
  );
}
