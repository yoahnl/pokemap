import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
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
