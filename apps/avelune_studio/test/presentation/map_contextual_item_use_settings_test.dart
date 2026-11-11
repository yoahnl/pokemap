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
    final existing = map.copyWith(
      mapMetadata: map.mapMetadata.copyWith(contextualItemUses: [rule]),
    );
    final settings = MapMetadataSettingsDraft(existing);
    expect(settings.rules.single.toJson(), rule.toJson());
    expect(settings.parameters.containsKey('contextualItemUses'), isFalse);
  });

  test('blank rule identities are refused before publication', () {
    for (final id in ['', '   ']) {
      final draft = MapContextualItemUseDraft(id)
        ..itemId = 'rope'
        ..sceneId = 'wall-scene';
      expect(draft.isValid(map, items, scenes), isFalse);
    }
  });

  test(
    'collection identities stay unique after removal and repeated additions',
    () {
      final original = validDraft().toRule();
      final reserved = ContextualItemUseRule(
        id: 'context-item-1',
        itemId: 'rope',
        sceneId: 'wall-scene',
      );
      final collection = MapContextualItemUseCollectionDraft([
        original,
        reserved,
      ]);
      final added = collection.add();
      expect(added.id.trim(), isNotEmpty);
      expect(added.id, isNot(isIn([original.id, reserved.id])));
      collection.removeAt(2);
      final replacement = collection.add();
      expect(replacement.id, isNot(added.id));
      collection.removeAt(1);
      final next = collection.add();
      expect(next.id, isNot(reserved.id));
      final ids = collection.drafts.map((draft) => draft.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(collection.drafts.first.toRule(), original);
      expect(() => collection.drafts.add(validDraft()), throwsUnsupportedError);
    },
  );

  test(
    'collection accepts 128 rules and refuses a 129th without data loss',
    () {
      final collection = MapContextualItemUseCollectionDraft(const []);
      for (var index = 0; index < 128; index++) {
        collection.add()
          ..itemId = 'rope'
          ..sceneId = 'wall-scene';
      }
      expect(collection.canAdd, isFalse);
      expect(collection.isValid(map, items, scenes), isTrue);
      final before = collection.toRules();
      expect(before, hasLength(128));
      expect(before.map((rule) => rule.id).toSet(), hasLength(128));
      expect(collection.add, throwsStateError);
      expect(collection.toRules(), before);
      collection.removeAt(63);
      expect(collection.canAdd, isTrue);
      final replacement = collection.add()
        ..itemId = 'rope'
        ..sceneId = 'wall-scene';
      expect(before.map((rule) => rule.id), isNot(contains(replacement.id)));
      expect(collection.isValid(map, items, scenes), isTrue);
      expect(collection.toRules(), hasLength(128));
    },
  );

  test(
    'oversized and duplicate loaded collections are retained and refused',
    () {
      final rules = [
        for (var index = 0; index < 129; index++)
          ContextualItemUseRule(
            id: 'loaded-$index',
            itemId: 'rope',
            sceneId: 'wall-scene',
          ),
      ];
      final oversized = MapContextualItemUseCollectionDraft(rules);
      expect(oversized.drafts, hasLength(129));
      expect(oversized.isValid(map, items, scenes), isFalse);
      expect(oversized.toRules, throwsStateError);
      expect(rules, hasLength(129));
      final duplicates = MapContextualItemUseCollectionDraft([
        rules.first,
        rules.first,
      ]);
      expect(duplicates.drafts, hasLength(2));
      expect(duplicates.isValid(map, items, scenes), isFalse);
      expect(duplicates.toRules, throwsStateError);
    },
  );

  test('collection edits preserve other rules and existing conditions', () {
    final condition = NarrativeEventConditionExpression.all([
      NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('wall-open', true),
      ),
    ]);
    final original = (validDraft()..condition = condition).toRule();
    final source = [original];
    final collection = MapContextualItemUseCollectionDraft(source);
    collection.add()
      ..itemId = 'rope'
      ..sceneId = 'wall-scene';
    collection.drafts.last.priority = '7';
    expect(collection.toRules().first.toJson(), original.toJson());
    collection.drafts.first.priority = '11';
    expect(collection.toRules().first.conditionExpression, condition);
    expect(source.single.toJson(), original.toJson());
    final existing = map.copyWith(
      mapMetadata: map.mapMetadata.copyWith(contextualItemUses: source),
    );
    final settings = MapMetadataSettingsDraft(existing)..bicycle = false;
    expect(settings.parameters.containsKey('contextualItemUses'), isFalse);
    expect(settings.rules.single.toJson(), original.toJson());
    settings
      ..rules = collection.toRules()
      ..rulesEdited = true;
    final encoded = settings.parameters['contextualItemUses'] as List;
    expect(
      ContextualItemUseRule.fromJson(
        Map<String, dynamic>.from(encoded.first as Map),
      ).conditionExpression,
      condition,
    );
    expect(existing.contextualItemUses.single.toJson(), original.toJson());
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
