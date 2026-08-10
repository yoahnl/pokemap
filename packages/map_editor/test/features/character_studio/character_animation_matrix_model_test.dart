import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_animation_matrix_model.dart';

void main() {
  test('orders system and custom rows and projects exact slot shapes', () {
    final project = _project();
    final model = CharacterAnimationMatrixModel.build(
      project: project,
      character: project.characters.single,
    );

    expect(model.rows.map((row) => row.id), <String>[
      'base',
      'walk',
      'run',
      'jump',
      'wave',
    ]);
    expect(model.rows[0].slots, hasLength(4));
    expect(model.rows[3].slots, hasLength(1));
    expect(model.rows[3].slots.single.key.direction, isNull);
    expect(model.rows[4].slots, hasLength(4));
  });

  test('distinguishes required optional invalid and ready slots', () {
    final project = _project();
    final model = CharacterAnimationMatrixModel.build(
      project: project,
      character: project.characters.single,
    );

    expect(
      model
          .slot(_system(CharacterAnimationState.idle, EntityFacing.north))
          .status,
      CharacterAnimationSlotStatus.missingRequired,
    );
    expect(
      model
          .slot(_system(CharacterAnimationState.walk, EntityFacing.north))
          .status,
      CharacterAnimationSlotStatus.missingOptional,
    );
    expect(
      model
          .slot(_system(CharacterAnimationState.idle, EntityFacing.south))
          .status,
      CharacterAnimationSlotStatus.defined,
    );
    expect(
      model
          .slot(_system(CharacterAnimationState.idle, EntityFacing.east))
          .status,
      CharacterAnimationSlotStatus.invalid,
    );
    expect(
      model
          .slot(_system(CharacterAnimationState.idle, EntityFacing.south))
          .frameCount,
      2,
    );
  });

  test(
    'filters missing and ready slots without inventing single directions',
    () {
      final project = _project();
      final model = CharacterAnimationMatrixModel.build(
        project: project,
        character: project.characters.single,
      );

      final missing = model.slotsFor(CharacterAnimationMatrixFilter.missing);
      final ready = model.slotsFor(CharacterAnimationMatrixFilter.ready);

      expect(
        missing.every(
          (slot) => slot.status != CharacterAnimationSlotStatus.defined,
        ),
        isTrue,
      );
      expect(
        ready.every(
          (slot) => slot.status == CharacterAnimationSlotStatus.defined,
        ),
        isTrue,
      );
      expect(
        missing.where((slot) => slot.key.definitionId == 'jump'),
        hasLength(1),
      );
    },
  );
}

CharacterAnimationSlotKey _system(
  CharacterAnimationState state,
  EntityFacing direction,
) {
  return CharacterAnimationSlotKey.system(state: state, direction: direction);
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Matrix',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
        CharacterCustomAnimationDefinition(
          id: 'wave',
          displayName: 'Saluer',
          mode: CharacterCustomAnimationMode.directional,
          sortOrder: 2,
        ),
        CharacterCustomAnimationDefinition(
          id: 'jump',
          displayName: 'Saut',
          mode: CharacterCustomAnimationMode.single,
        ),
      ],
    ),
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'elia',
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0),
                durationMs: 100,
              ),
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 1, y: 0),
                durationMs: 180,
              ),
            ],
          ),
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.east,
          ),
        ],
      ),
    ],
  );
}
