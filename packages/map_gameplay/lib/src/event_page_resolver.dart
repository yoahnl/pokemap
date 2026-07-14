import 'package:map_core/map_core.dart';

import 'script_condition_evaluator.dart';

/// Résolveur pur de page active pour un événement.
///
/// Prend un [MapEventDefinition] et un [GameState],
/// retourne la page active (première page dont les conditions sont true).
///
/// Ne contient aucun effet de bord.
/// Totalement testable et déterministe.
class EventPageResolver {
  const EventPageResolver({
    this.evaluator = const ScriptConditionEvaluator(),
  });

  final ScriptConditionEvaluator evaluator;

  /// Résout la page active pour un événement.
  ///
  /// Retourne null si aucune page n'est valide.
  ActiveEventPage? resolve(
    MapEventDefinition event,
    GameState state, {
    ScriptEvaluationContext? context,
    ScriptEvaluationContext? Function(MapEventPage page)? contextForPage,
  }) {
    for (var i = 0; i < event.pages.length; i++) {
      final page = event.pages[i];
      final evaluationContext =
          contextForPage == null ? context : contextForPage(page);
      if (_isPageActive(page, state, context: evaluationContext)) {
        return ActiveEventPage(
          eventId: event.id,
          page: page,
          pageIndex: i,
        );
      }
    }
    return null;
  }

  bool _isPageActive(
    MapEventPage page,
    GameState state, {
    ScriptEvaluationContext? context,
  }) {
    // Si pas de condition, la page est toujours active.
    final condition = page.condition;
    if (condition == null) return true;

    return evaluator.evaluate(condition, state, context: context);
  }

  /// Résout la page active pour une liste d'événements.
  ///
  /// Retourne une map eventId -> ActiveEventPage.
  Map<String, ActiveEventPage> resolveAll(
    List<MapEventDefinition> events,
    GameState state, {
    ScriptEvaluationContext? context,
    ScriptEvaluationContext? Function(MapEventPage page)? contextForPage,
  }) {
    final result = <String, ActiveEventPage>{};
    for (final event in events) {
      final activePage = resolve(
        event,
        state,
        context: context,
        contextForPage: contextForPage,
      );
      if (activePage != null) {
        result[event.id] = activePage;
      }
    }
    return result;
  }
}
