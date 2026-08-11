import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

final class ShopStateSimulationConditionRow {
  const ShopStateSimulationConditionRow({
    required this.stateId,
    required this.label,
    required this.priority,
    required this.matched,
    required this.selected,
  });

  final String stateId;
  final String label;
  final int priority;
  final bool matched;
  final bool selected;
}

final class ShopStateSimulationReadModel {
  ShopStateSimulationReadModel({
    required this.resolvedState,
    required List<ShopStateDefinition> matchedStates,
    required List<ShopStateSimulationConditionRow> conditionRows,
    required this.hasPriorityConflict,
  })  : matchedStates = List<ShopStateDefinition>.unmodifiable(matchedStates),
        conditionRows =
            List<ShopStateSimulationConditionRow>.unmodifiable(conditionRows);

  final ResolvedShopState resolvedState;
  final List<ShopStateDefinition> matchedStates;
  final List<ShopStateSimulationConditionRow> conditionRows;
  final bool hasPriorityConflict;
}

/// Editor-only shop preview backed by an isolated [GameState] draft.
///
/// No operation writes to EditorNotifier, project storage or a save file. The
/// same resolver and project-backed Fact context as production are used.
final class ShopStateSimulationController {
  ShopStateSimulationController({
    required this.project,
    GameState initialGameState =
        const GameState(saveId: 'shop-state-simulation'),
    this.resolver = const ShopStateResolver(),
    this.resolutionValidator = const ShopStateResolutionValidator(),
  }) : _draftGameState = initialGameState;

  final ProjectManifest project;
  final ShopStateResolver resolver;
  final ShopStateResolutionValidator resolutionValidator;
  GameState _draftGameState;

  GameState get draftGameState => _draftGameState;

  ScriptEvaluationContext get conditionContext => ScriptEvaluationContext(
        narrativeFactResolver:
            NarrativeFactRuntimeResolver.fromFacts(project.facts),
      );

  void replaceDraft(GameState gameState) {
    _draftGameState = gameState;
  }

  void setFactValue(String factId, NarrativeValue value) {
    _draftGameState = _draftGameState.copyWith(
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
        valuesByFactId: <String, NarrativeValue>{
          ..._draftGameState.narrativeFactRuntimeState.valuesByFactId,
          factId: value,
        },
      ),
    );
  }

  void setStepCompleted(String stepId, {required bool completed}) {
    final completedStepIds =
        _draftGameState.progression.completedStepIds.toSet();
    if (completed) {
      completedStepIds.add(stepId);
    } else {
      completedStepIds.remove(stepId);
    }
    _draftGameState = _draftGameState.copyWith(
      progression: _draftGameState.progression.copyWith(
        completedStepIds: completedStepIds.toList(growable: false),
      ),
    );
  }

  void setBadgeOwned(String badgeId, {required bool owned}) {
    final badgeIds = _draftGameState.trainerProfile.badgeIds.toSet();
    if (owned) {
      badgeIds.add(badgeId);
    } else {
      badgeIds.remove(badgeId);
    }
    _draftGameState = _draftGameState.copyWith(
      trainerProfile: _draftGameState.trainerProfile.copyWith(
        badgeIds: badgeIds.toList(growable: false),
      ),
    );
  }

  void setMoney(int amount) {
    if (amount < 0) return;
    _draftGameState = _draftGameState.copyWith(
      trainerProfile: _draftGameState.trainerProfile.copyWith(money: amount),
    );
  }

  void setItemQuantity(String itemId, int quantity) {
    if (quantity < 0) return;
    final entries = <BagEntry>[
      for (final entry in _draftGameState.bag.entries)
        if (entry.itemId != itemId) entry,
      if (quantity > 0)
        BagEntry(itemId: itemId, quantity: quantity),
    ];
    _draftGameState = _draftGameState.copyWith(
      bag: Bag(entries: entries).normalized(),
    );
  }

  ShopStateSimulationReadModel simulate(ShopDefinition shop) {
    final resolved = resolver.resolve(
      shop: shop,
      gameState: _draftGameState,
      conditionContext: conditionContext,
    );
    final statesById = <String, ShopStateDefinition>{
      for (final state in shop.states) state.id: state,
    };
    final matchedStates = resolved.matchedStateIds
        .map((stateId) => statesById[stateId])
        .whereType<ShopStateDefinition>()
        .toList(growable: false);
    final winningMatches = matchedStates
        .where((state) => state.priority == resolved.priority)
        .toList(growable: false);
    return ShopStateSimulationReadModel(
      resolvedState: resolved,
      matchedStates: matchedStates,
      conditionRows: <ShopStateSimulationConditionRow>[
        for (final state in shop.states)
          ShopStateSimulationConditionRow(
            stateId: state.id,
            label: state.label,
            priority: state.priority,
            matched: resolved.matchedStateIds.contains(state.id),
            selected: resolved.stateId == state.id,
          ),
      ],
      hasPriorityConflict: !resolved.isDefault && winningMatches.length > 1,
    );
  }

  List<ShopStateDiagnostic> validate(
    ShopDefinition shop, {
    required Set<String> knownItemIds,
  }) {
    final structural = ShopStateValidator(
      project: project,
      knownItemIds: knownItemIds,
    ).validate().where((diagnostic) => diagnostic.shopId == shop.id);
    final runtime = resolutionValidator.validate(
      shop: shop,
      scenarios: <ShopStateResolutionScenario>[
        ShopStateResolutionScenario(
          id: 'editor-draft',
          label: 'Contexte simulé',
          gameState: _draftGameState,
          conditionContext: conditionContext,
        ),
      ],
    );
    return List<ShopStateDiagnostic>.unmodifiable(
      <ShopStateDiagnostic>[...structural, ...runtime],
    );
  }
}
