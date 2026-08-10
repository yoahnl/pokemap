import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project character studio structural validation', () {
    test('accepts a complete structurally valid character', () {
      final manifest = _project(
        catalog: _catalog(
          portraitStates: const <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'surprised',
              displayName: 'Surprise',
            ),
          ],
          customAnimationDefinitions:
              const <CharacterCustomAnimationDefinition>[
                CharacterCustomAnimationDefinition(
                  id: 'wave',
                  displayName: 'Saluer',
                  mode: CharacterCustomAnimationMode.directional,
                ),
              ],
        ),
        character: _character(
          portraits: const <CharacterPortraitVariant>[
            CharacterPortraitVariant(
              portraitStateId: 'surprised',
              assetId: 'portrait_hero_surprised',
            ),
          ],
          animations: _baseAnimations(),
          customAnimations: _directionalCustomAnimations('wave'),
        ),
      );

      expect(() => ProjectValidator.validate(manifest), returnsNormally);
    });

    test('rejects duplicate portrait state ids', () {
      final manifest = _project(
        catalog: _catalog(
          portraitStates: const <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'surprised',
              displayName: 'Surprise',
            ),
            CharacterPortraitStateDefinition(
              id: 'surprised',
              displayName: 'Étonnée',
            ),
          ],
        ),
      );

      _expectValidationCode(
        manifest,
        'character_studio.portrait_state.duplicate_id',
      );
    });

    test('rejects a portrait referencing an unknown global state', () {
      final manifest = _project(
        character: _character(
          portraits: const <CharacterPortraitVariant>[
            CharacterPortraitVariant(
              portraitStateId: 'missing',
              assetId: 'portrait_hero_missing',
            ),
          ],
        ),
      );

      _expectValidationCode(
        manifest,
        'character_studio.portrait.state_unknown',
      );
    });

    test('rejects duplicate portrait slots on a character', () {
      final manifest = _project(
        catalog: _catalog(
          portraitStates: const <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'neutral',
              displayName: 'Neutre',
            ),
          ],
        ),
        character: _character(
          portraits: const <CharacterPortraitVariant>[
            CharacterPortraitVariant(
              portraitStateId: 'neutral',
              assetId: 'portrait_hero_neutral_a',
            ),
            CharacterPortraitVariant(
              portraitStateId: 'neutral',
              assetId: 'portrait_hero_neutral_b',
            ),
          ],
        ),
      );

      _expectValidationCode(
        manifest,
        'character_studio.portrait.duplicate_state',
      );
    });

    test('rejects a single custom clip carrying a direction', () {
      final manifest = _project(
        catalog: _catalog(
          customAnimationDefinitions:
              const <CharacterCustomAnimationDefinition>[
                CharacterCustomAnimationDefinition(
                  id: 'sleep',
                  displayName: 'Dormir',
                  mode: CharacterCustomAnimationMode.single,
                ),
              ],
        ),
        character: _character(
          customAnimations: const <CharacterCustomAnimationClip>[
            CharacterCustomAnimationClip(
              definitionId: 'sleep',
              direction: EntityFacing.south,
              sourceAssetId: 'sprite_hero_sleep',
            ),
          ],
        ),
      );

      _expectValidationCode(
        manifest,
        'character_studio.custom_animation.direction_forbidden',
      );
    });

    test('rejects a directional custom clip without direction', () {
      final manifest = _project(
        catalog: _catalog(
          customAnimationDefinitions:
              const <CharacterCustomAnimationDefinition>[
                CharacterCustomAnimationDefinition(
                  id: 'wave',
                  displayName: 'Saluer',
                  mode: CharacterCustomAnimationMode.directional,
                ),
              ],
        ),
        character: _character(
          customAnimations: const <CharacterCustomAnimationClip>[
            CharacterCustomAnimationClip(
              definitionId: 'wave',
              sourceAssetId: 'sprite_hero_wave',
            ),
          ],
        ),
      );

      _expectValidationCode(
        manifest,
        'character_studio.custom_animation.direction_required',
      );
    });

    test('rejects a custom clip referencing an unknown definition', () {
      final manifest = _project(
        character: _character(
          customAnimations: const <CharacterCustomAnimationClip>[
            CharacterCustomAnimationClip(
              definitionId: 'missing',
              sourceAssetId: 'sprite_hero_missing',
            ),
          ],
        ),
      );

      _expectValidationCode(
        manifest,
        'character_studio.custom_animation.definition_unknown',
      );
    });

    test('rejects duplicate built-in animation slots', () {
      final animation = _animation(
        state: CharacterAnimationState.idle,
        direction: EntityFacing.south,
      );
      final manifest = _project(
        character: _character(
          animations: <CharacterAnimation>[animation, animation],
        ),
      );

      _expectValidationCode(
        manifest,
        'character_studio.animation.duplicate_slot',
      );
    });

    test('keeps incomplete drafts structurally valid', () {
      final manifest = _project(
        catalog: _catalog(
          portraitStates: const <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'neutral',
              displayName: 'Neutre',
            ),
          ],
          customAnimationDefinitions:
              const <CharacterCustomAnimationDefinition>[
                CharacterCustomAnimationDefinition(
                  id: 'wave',
                  displayName: 'Saluer',
                  mode: CharacterCustomAnimationMode.directional,
                ),
              ],
        ),
      );

      expect(() => ProjectValidator.validate(manifest), returnsNormally);
    });
  });

  group('Character studio readiness', () {
    for (final direction in EntityFacing.values) {
      test('reports a required Base $direction direction as missing', () {
        final animations = _baseAnimations()
            .where((animation) => animation.direction != direction)
            .toList(growable: false);
        final manifest = _project(
          character: _character(animations: animations),
        );

        final report = analyzeCharacterStudioReadiness(
          manifest: manifest,
          requiredCharacterIds: const <String>{'hero'},
        );

        expect(report.hasErrors, isTrue);
        expect(
          report.diagnostics,
          contains(
            isA<CharacterStudioReadinessDiagnostic>()
                .having(
                  (diagnostic) => diagnostic.code,
                  'code',
                  CharacterStudioReadinessCode.baseDirectionMissing,
                )
                .having(
                  (diagnostic) => diagnostic.direction,
                  'direction',
                  direction,
                ),
          ),
        );
      });
    }

    test('accepts all four Base directions for a required character', () {
      final manifest = _project(
        character: _character(animations: _baseAnimations()),
      );

      final report = analyzeCharacterStudioReadiness(
        manifest: manifest,
        requiredCharacterIds: const <String>{'hero'},
      );

      expect(report.hasErrors, isFalse);
      expect(
        report.byCode(CharacterStudioReadinessCode.baseDirectionMissing),
        isEmpty,
      );
    });

    test('uses the default player as a required character', () {
      final manifest = _project(
        character: _character(),
        defaultPlayerCharacterId: 'hero',
      );

      final report = analyzeCharacterStudioReadiness(manifest: manifest);

      expect(
        report.byCode(CharacterStudioReadinessCode.baseDirectionMissing),
        hasLength(EntityFacing.values.length),
      );
    });

    test('reports a missing portrait as non-blocking', () {
      final manifest = _project(
        catalog: _catalog(
          portraitStates: const <CharacterPortraitStateDefinition>[
            CharacterPortraitStateDefinition(
              id: 'neutral',
              displayName: 'Neutre',
            ),
          ],
        ),
        character: _character(animations: _baseAnimations()),
      );

      final report = analyzeCharacterStudioReadiness(
        manifest: manifest,
        requiredCharacterIds: const <String>{'hero'},
      );

      expect(report.hasErrors, isFalse);
      expect(
        report.byCode(CharacterStudioReadinessCode.portraitMissing),
        hasLength(1),
      );
    });

    test('reports partial optional walk coverage as warnings', () {
      final manifest = _project(
        character: _character(
          animations: <CharacterAnimation>[
            ..._baseAnimations(),
            _animation(
              state: CharacterAnimationState.walk,
              direction: EntityFacing.south,
            ),
          ],
        ),
      );

      final report = analyzeCharacterStudioReadiness(manifest: manifest);

      expect(
        report.byCode(
          CharacterStudioReadinessCode.optionalAnimationDirectionMissing,
        ),
        hasLength(EntityFacing.values.length - 1),
      );
      expect(report.hasErrors, isFalse);
    });

    test('reports missing custom coverage as warnings', () {
      final manifest = _project(
        catalog: _catalog(
          customAnimationDefinitions:
              const <CharacterCustomAnimationDefinition>[
                CharacterCustomAnimationDefinition(
                  id: 'wave',
                  displayName: 'Saluer',
                  mode: CharacterCustomAnimationMode.directional,
                ),
              ],
        ),
      );

      final report = analyzeCharacterStudioReadiness(manifest: manifest);

      expect(
        report.byCode(
          CharacterStudioReadinessCode.customAnimationDirectionMissing,
        ),
        hasLength(EntityFacing.values.length),
      );
      expect(report.hasErrors, isFalse);
    });
  });
}

void _expectValidationCode(ProjectManifest manifest, String code) {
  expect(
    () => ProjectValidator.validate(manifest),
    throwsA(
      isA<ValidationException>().having(
        (exception) => exception.code,
        'code',
        code,
      ),
    ),
  );
}

ProjectManifest _project({
  ProjectCharacterStudioCatalog catalog = const ProjectCharacterStudioCatalog(),
  ProjectCharacterEntry? character,
  String? defaultPlayerCharacterId,
}) {
  return ProjectManifest(
    name: 'Character Studio validation',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Characters',
        relativePath: 'assets/characters.png',
      ),
    ],
    characterStudioCatalog: catalog,
    characters: <ProjectCharacterEntry>[character ?? _character()],
    settings: ProjectSettings(
      defaultPlayerCharacterId: defaultPlayerCharacterId,
    ),
  );
}

ProjectCharacterStudioCatalog _catalog({
  List<CharacterPortraitStateDefinition> portraitStates = const [],
  List<CharacterCustomAnimationDefinition> customAnimationDefinitions =
      const [],
}) {
  return ProjectCharacterStudioCatalog(
    portraitStates: portraitStates,
    customAnimationDefinitions: customAnimationDefinitions,
  );
}

ProjectCharacterEntry _character({
  List<CharacterPortraitVariant> portraits = const [],
  List<CharacterAnimation> animations = const [],
  List<CharacterCustomAnimationClip> customAnimations = const [],
}) {
  return ProjectCharacterEntry(
    id: 'hero',
    name: 'Hero',
    tilesetId: 'characters',
    portraits: portraits,
    animations: animations,
    customAnimations: customAnimations,
  );
}

List<CharacterAnimation> _baseAnimations() {
  return <CharacterAnimation>[
    for (final direction in EntityFacing.values)
      _animation(state: CharacterAnimationState.idle, direction: direction),
  ];
}

List<CharacterCustomAnimationClip> _directionalCustomAnimations(
  String definitionId,
) {
  return <CharacterCustomAnimationClip>[
    for (final direction in EntityFacing.values)
      CharacterCustomAnimationClip(
        definitionId: definitionId,
        direction: direction,
        sourceAssetId: 'sprite_hero_$definitionId',
        frames: const <CharacterAnimationFrame>[
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
          ),
        ],
      ),
  ];
}

CharacterAnimation _animation({
  required CharacterAnimationState state,
  required EntityFacing direction,
}) {
  return CharacterAnimation(
    state: state,
    direction: direction,
    frames: const <CharacterAnimationFrame>[
      CharacterAnimationFrame(
        source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
      ),
    ],
  );
}
