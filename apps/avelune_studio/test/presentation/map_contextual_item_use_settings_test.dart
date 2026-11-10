import 'package:avelune_studio/features/map_workspace/application/map_metadata_settings_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const map = MapData(
    id: 'alpha',
    name: 'Alpha',
    size: GridSize(width: 12, height: 12),
  );
  const items = {'rope': 'Corde Sortie'};
  const scenes = {'wall-scene': 'Ouvrir le mur'};

  MapContextualItemUseDraft validDraft() =>
      MapContextualItemUseDraft('context-item')
        ..itemId = 'rope'
        ..sceneId = 'wall-scene'
        ..precise = true
        ..x = '6'
        ..y = '3'
        ..facing = 'north'
        ..priority = '10';

  test('native item scene cell and direction produce canonical metadata', () {
    final draft = validDraft();
    expect(draft.isValid(map, items, scenes), isTrue);
    final settings = MapMetadataSettingsDraft(map)
      ..rules = [draft.toRule()]
      ..rulesEdited = true;
    final rules = settings.parameters['contextualItemUses'] as List;
    final rule = ContextualItemUseRule.fromJson(
      Map<String, dynamic>.from(rules.single as Map),
    );
    expect(rule.itemId, 'rope');
    expect(rule.sceneId, 'wall-scene');
    expect(rule.position, const GridPos(x: 6, y: 3));
    expect(rule.facing, EntityFacing.north);
    expect(rule.priority, 10);
    expect(map.contextualItemUses, isEmpty);
  });

  test('drafts retain rule identity condition and optional positions through a roundtrip', () {
    final rule =
        (validDraft()
              ..condition = NarrativeEventConditionExpression.all(const []))
            .toRule();
    expect(
      MapContextualItemUseDraft.fromRule(rule).toRule().toJson(),
      rule.toJson(),
    );
    final global = validDraft()
      ..precise = false
      ..facing = ''
      ..x = 'invalid'
      ..y = '-1';
    expect(global.isValid(map, items, scenes), isTrue);
    expect(global.toRule().position, isNull);
    expect(global.toRule().facing, isNull);
    final existing = map.copyWith(mapMetadata: map.mapMetadata.copyWith(contextualItemUses: [rule]));
    final settings = MapMetadataSettingsDraft(existing);
    expect(settings.rules.single.toJson(), rule.toJson());
    expect(settings.parameters.containsKey('contextualItemUses'), isFalse);
  });

  test(
    'missing references invalid integers and out of bounds cells are refused',
    () {
      final draft = validDraft();
      expect(draft.isValid(map, {}, scenes), isFalse);
      expect(draft.isValid(map, items, {}), isFalse);
      for (final value in ['1.5', '-1000001', '1000001']) {
        draft.priority = value;
        expect(draft.isValid(map, items, scenes), isFalse);
      }
      draft.priority = '-1000000';
      expect(draft.isValid(map, items, scenes), isTrue);
      draft.priority = '1000000';
      expect(draft.isValid(map, items, scenes), isTrue);
      for (final position in [
        ('12', '3'),
        ('6', '12'),
        ('-1', '3'),
        ('6', '1.5'),
      ]) {
        draft
          ..x = position.$1
          ..y = position.$2;
        expect(draft.isValid(map, items, scenes), isFalse);
      }
    },
  );
}
