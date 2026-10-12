import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('spatial cell offsets survive weight collision copy edits and invalid input blocks saving', () {
    final offset = Model3dVector3(x: .25, y: .1, z: -.5);
    final preset = EnvironmentPreset(
      id: 'forest',
      name: 'Forêt',
      templateId: 'manual',
      sortOrder: 0,
      palette: [
        EnvironmentPaletteItem(
          modelId: 'oak',
          weight: 1,
          cellOffsetWorld: offset,
        ),
      ],
      defaultParams: EnvironmentGenerationParams.standard(),
    );
    final draft = EnvironmentDraft(original: preset);
    draft.setWeightInput('oak', '3');
    draft.setItem('oak', collision: EnvironmentCollisionMode.forceDisabled);
    expect(draft.build().palette.single.cellOffsetWorld, offset);
    expect(
      EnvironmentDraft.copy(draft.build())
          .build()
          .palette
          .single
          .cellOffsetWorld,
      offset,
    );
    draft.setOffsetInput('oak', 'x', '0,75');
    expect(draft.build().palette.single.cellOffsetWorld!.x, .75);
    expect(draft.build().palette.single.cellOffsetWorld!.y, .1);
    draft.setOffsetInput('oak', 'y', 'NaN');
    expect(draft.offsetInput('oak', 'y'), 'NaN');
    expect(draft.build, throwsFormatException);
    draft.setOffsetInput('oak', 'y', '0,4');
    expect(draft.build().palette.single.cellOffsetWorld!.y, .4);
    expect(draft.build().palette.single.cellOffsetWorld!.z, -.5);
  });
  test('model recipes keep typed sources and metadata while editing', () {
    final draft = EnvironmentDraft()..name = 'Bosquet 3D';
    draft.add('oak', spatial: true);
    draft.add('oak', spatial: true);
    draft.setWeightInput('oak', '4');
    draft.setItem('oak', collision: EnvironmentCollisionMode.forceDisabled);
    final preset = draft.build();
    expect(preset.isSpatial, isTrue);
    expect(preset.palette.single.modelId, 'oak');
    expect(preset.palette.single.elementId, isNull);
    expect(preset.palette.single.weight, 4);
    expect(
      preset.palette.single.collisionMode,
      EnvironmentCollisionMode.forceDisabled,
    );
    expect(() => draft.add('flower'), throwsFormatException);
    expect(draft.palette, hasLength(1));
    draft.remove('oak');
    expect(draft.palette, isEmpty);
  });
  test('a recipe preserves its identity and untouched palette metadata', () {
    final preset = EnvironmentPreset(
      id: 'forest',
      name: 'Forêt',
      templateId: 'woodland',
      sortOrder: 4,
      categoryId: 'nature',
      defaultParams: EnvironmentGenerationParams.standard(),
      palette: [
        EnvironmentPaletteItem(elementId: 'tree', weight: 3, tags: {'canopy'}),
      ],
    );
    final draft = EnvironmentDraft(original: preset)..name = 'Forêt étoilée';
    expect(draft.dirty, isTrue);
    final saved = draft.build();
    expect(saved.id, preset.id);
    expect(saved.templateId, preset.templateId);
    expect(saved.categoryId, preset.categoryId);
    expect(saved.sortOrder, preset.sortOrder);
    expect(saved.palette.single.tags, {'canopy'});
    draft.rebase(saved);
    expect(draft.dirty, isFalse);
  });

  test(
    'palette additions do not duplicate identities and invalid recipes refuse',
    () {
      final draft = EnvironmentDraft();
      expect(draft.build, throwsFormatException);
      draft.name = 'Bosquet';
      draft.add('tree');
      draft.add('tree');
      expect(draft.build().palette, hasLength(1));
      draft.setItem(
        'tree',
        weight: 4,
        collision: EnvironmentCollisionMode.forceDisabled,
      );
      expect(draft.build().palette.single.weight, 4);
      expect(
        draft.build().palette.single.collisionMode,
        EnvironmentCollisionMode.forceDisabled,
      );
      draft.remove('tree');
      expect(draft.build, throwsFormatException);
    },
  );

  test('invalid numeric input survives and prevents saving old values', () {
    final draft = EnvironmentDraft()..name = 'Bosquet';
    draft.add('tree');
    draft.setWeightInput('tree', 'no');
    expect(draft.weightInput('tree'), 'no');
    expect(draft.build, throwsFormatException);
    draft.setWeightInput('tree', '4');
    draft.setSpacingInput('-1');
    expect(draft.spacingInput, '-1');
    expect(draft.build, throwsFormatException);
    draft.setSpacingInput('2');
    expect(draft.build().palette.single.weight, 4);
    expect(draft.build().defaultParams.minSpacingCells, 2);
  });
}
