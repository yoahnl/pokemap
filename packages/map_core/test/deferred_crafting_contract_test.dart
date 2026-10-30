import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  DeferredCraftingRecipe recipe({
    String id = 'one',
    int input = 1,
    int output = 2,
  }) => DeferredCraftingRecipe(
    recipeId: id,
    label: 'Recipe',
    inputItemId: 'ingredient',
    inputQuantity: input,
    outputItemId: 'result',
    outputQuantity: output,
  );
  DeferredCraftingOrder order() => DeferredCraftingOrder(
    orderId: 'artisan:1',
    recipeId: 'one',
    inputItemId: 'ingredient',
    inputQuantity: 3,
    outputItemId: 'result',
    outputQuantity: 6,
    submittedDayRevision: 2,
    requiredDayChanges: 1,
  );

  test(
    'recipe and definition codecs are strict and preserve immutable lists',
    () {
      final recipes = [recipe()];
      final definition = DeferredCraftingDefinition(
        serviceId: 'artisan',
        label: 'Artisan',
        recipes: recipes,
        maximumBatchQuantity: 99,
        requiredDayChanges: 2,
      );
      recipes.clear();
      expect(definition.recipes, hasLength(1));
      expect(() => definition.recipes.clear(), throwsUnsupportedError);
      expect(
        DeferredCraftingDefinition.fromJson(definition.toJson()),
        definition,
      );
      expect(DeferredCraftingRecipe.fromJson(recipe().toJson()), recipe());
      expect(
        () => DeferredCraftingDefinition.fromJson({
          ...definition.toJson(),
          'schemaVersion': 2,
        }),
        throwsFormatException,
      );
      expect(
        () => DeferredCraftingDefinition.fromJson({
          ...definition.toJson(),
          'schemaVersion': 1.0,
        }),
        throwsFormatException,
      );
      expect(
        () => DeferredCraftingDefinition.fromJson({
          ...definition.toJson(),
          'futureField': true,
        }),
        throwsFormatException,
      );
      expect(
        () => DeferredCraftingRecipe.fromJson({
          ...recipe().toJson(),
          'inputQuantity': 1.0,
        }),
        throwsFormatException,
      );
    },
  );

  for (final value in [0, -1, maximumDeferredCraftingQuantity + 1]) {
    test('recipe, maximum batch and delay reject $value', () {
      expect(() => recipe(input: value), throwsFormatException);
      expect(() => recipe(output: value), throwsFormatException);
      expect(
        () => DeferredCraftingDefinition(
          serviceId: 'artisan',
          label: 'Artisan',
          recipes: [recipe()],
          maximumBatchQuantity: value,
        ),
        throwsFormatException,
      );
      expect(
        () => DeferredCraftingDefinition(
          serviceId: 'artisan',
          label: 'Artisan',
          recipes: [recipe()],
          requiredDayChanges: value,
        ),
        throwsFormatException,
      );
    });
  }

  test(
    'empty identities and duplicate recipes fail before authoring a definition',
    () {
      expect(() => recipe(id: ''), throwsFormatException);
      expect(() => recipe(id: ' one '), throwsFormatException);
      expect(
        () => DeferredCraftingDefinition(
          serviceId: '',
          label: 'Artisan',
          recipes: [recipe()],
        ),
        throwsFormatException,
      );
      expect(
        () => DeferredCraftingDefinition(
          serviceId: 'artisan',
          label: 'Artisan',
          recipes: [],
        ),
        throwsFormatException,
      );
      expect(
        () => DeferredCraftingDefinition(
          serviceId: 'artisan',
          label: 'Artisan',
          recipes: [recipe(), recipe()],
        ),
        throwsFormatException,
      );
    },
  );

  test('orders and service state roundtrip without mutable aliases', () {
    final services = {
      'artisan': DeferredCraftingServiceState(
        revision: 1,
        pendingOrder: order(),
      ),
    };
    final state = DeferredCraftingState(servicesById: services);
    services.clear();
    expect(state.servicesById, hasLength(1));
    expect(() => state.servicesById.clear(), throwsUnsupportedError);
    expect(DeferredCraftingState.fromJson(state.toJson()), state);
    expect(DeferredCraftingOrder.fromJson(order().toJson()), order());
    expect(
      state.serviceFor('missing'),
      const DeferredCraftingServiceState.empty(),
    );
    expect(
      () => DeferredCraftingServiceState(revision: 0, pendingOrder: order()),
      throwsFormatException,
    );
  });

  test(
    'calendar codec rejects future schemas, fractional revisions and unknown fields',
    () {
      final json = GameplayCalendarState(
        observedLocalDay: '2026-10-30',
        dayRevision: 2,
      ).toJson();
      expect(GameplayCalendarState.fromJson(json).toJson(), json);
      for (final patch in [
        {'schemaVersion': 2},
        {'schemaVersion': 1.0},
        {'dayRevision': 2.0},
        {'dayRevision': -1},
        {'observedLocalDay': '2026-02-29'},
        {'futureField': 1},
      ]) {
        expect(
          () => GameplayCalendarState.fromJson({...json, ...patch}),
          throwsFormatException,
        );
      }
      expect(
        () => GameplayCalendarState(observedLocalDay: null, dayRevision: 1),
        throwsFormatException,
      );
      expect(
        GameplayCalendarState.fromJson(
          const GameplayCalendarState.empty().toJson(),
        ),
        const GameplayCalendarState.empty(),
      );
    },
  );

  test(
    'missing states are compatible but explicit null and future states are rejected',
    () {
      final json = const GameState(saveId: 'legacy').toJson()
        ..remove('gameplayCalendarState')
        ..remove('deferredCraftingState');
      final legacy = GameState.fromJson(json);
      expect(legacy.gameplayCalendarState, const GameplayCalendarState.empty());
      expect(legacy.deferredCraftingState, const DeferredCraftingState.empty());
      for (final field in ['gameplayCalendarState', 'deferredCraftingState']) {
        expect(
          () => GameState.fromJson({...json, field: null}),
          throwsFormatException,
        );
        final future = field == 'gameplayCalendarState'
            ? const GameplayCalendarState.empty().toJson()
            : const DeferredCraftingState.empty().toJson();
        future['schemaVersion'] = 999;
        final before = jsonEncode(future);
        expect(
          () => GameState.fromJson({...json, field: future}),
          throwsFormatException,
        );
        expect(jsonEncode(future), before);
      }
    },
  );

  test(
    'save boundary refuses a pending order without its observed calendar',
    () {
      final state = const GameState(saveId: 'inconsistent').copyWith(
        deferredCraftingState: DeferredCraftingState(
          servicesById: {
            'artisan': DeferredCraftingServiceState(
              revision: 1,
              pendingOrder: order(),
            ),
          },
        ),
      );
      expect(() => GameState.fromJson(state.toJson()), throwsFormatException);
      expect(() => strictGameStateSaveJson(state), throwsFormatException);
      final saveJson = saveDataFromGameState(
        const GameState(saveId: 'inconsistent'),
      ).toJson();
      saveJson['deferredCraftingState'] = state.deferredCraftingState.toJson();
      expect(() => SaveData.fromJson(saveJson), throwsFormatException);
    },
  );

  test('nested order future or invalid fields are not silently dropped', () {
    final json = DeferredCraftingState(
      servicesById: {
        'artisan': DeferredCraftingServiceState(
          revision: 1,
          pendingOrder: order(),
        ),
      },
    ).toJson();
    for (final patch in [
      {'schemaVersion': 999},
      {'inputQuantity': 0},
      {'outputQuantity': 1.5},
      {'futureField': true},
      {'submittedDayRevision': -1},
    ]) {
      final raw = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
      final services = raw['servicesById'] as Map<String, dynamic>;
      final service = services['artisan'] as Map<String, dynamic>;
      (service['pendingOrder'] as Map<String, dynamic>).addAll(patch);
      final before = jsonEncode(raw);
      expect(() => DeferredCraftingState.fromJson(raw), throwsFormatException);
      expect(jsonEncode(raw), before);
    }
  });
}
