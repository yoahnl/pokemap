import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

/// Le défaut de projet des transitions de début de combat — BETA-BAT-034.
///
/// `ProjectManifest.battleTransitions` existait depuis BETA-BAT-019 et
/// n'avait AUCUN producteur : ni l'éditeur, ni l'authoring, ni les outils ne
/// l'écrivaient. Le runtime le lisait pourtant, en dernier recours avant son
/// propre défaut. Sans cette action, changer la transition de tous les
/// combats d'un projet demandait de passer calque par calque et dresseur par
/// dresseur.
///
/// La précédence de BETA-BAT-019 reste intacte : dresseur authoré, puis
/// source de rencontre, puis CE défaut, puis le défaut moteur.
final class BattleTransitionDefaultActions {
  const BattleTransitionDefaultActions();

  static const String updateActionId = 'project.battle_transitions.update';

  static final List<AuthoringActionDescriptor> descriptors =
      List.unmodifiable(<AuthoringActionDescriptor>[
    visualLibraryDescriptor(
      updateActionId,
      'Set the project-wide default battle transitions',
      resourceKinds: const <String>['project'],
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionId != updateActionId) {
      throw VisualLibraryException(
        'battle_transitions.action_unsupported',
        'The requested battle transition action is unsupported.',
      );
    }
    final parameters = VisualLibraryParameters(context.request.parameters);
    parameters.allow(const <String>{'wildTransitionId', 'trainerTransitionId'});

    final manifest = context.snapshot.manifest;
    final current = manifest.battleTransitions;
    final wild = _readTransition(
      parameters: context.request.parameters,
      key: 'wildTransitionId',
      allowed: battleWildTransitionIds,
      fallback: current?.wildTransitionId,
    );
    final trainer = _readTransition(
      parameters: context.request.parameters,
      key: 'trainerTransitionId',
      allowed: battleTrainerTransitionIds,
      fallback: current?.trainerTransitionId,
    );

    // Tout vide veut dire « rends la main au défaut moteur » : on retire la
    // section plutôt que d'écrire un objet de nulls dans le manifeste.
    final next = wild == null && trainer == null
        ? manifest.copyWith(battleTransitions: null)
        : manifest.copyWith(
            battleTransitions: ProjectBattleTransitionConfig(
              wildTransitionId: wild,
              trainerTransitionId: trainer,
            ),
          );

    return buildVisualManifestDraft(
      context.snapshot,
      next,
      operation: updateActionId,
      path: '/battleTransitions',
      before: current?.toJson(),
      after: next.battleTransitions?.toJson(),
    );
  }
}

/// Lit un identifiant de transition, ou garde celui déjà en place.
///
/// Trois cas distincts, et c'est le point délicat : le paramètre ABSENT ne
/// touche à rien, la chaîne VIDE efface explicitement, et un id inconnu du
/// contrat partagé est un refus — jamais un silence qui laisserait croire au
/// choix.
String? _readTransition({
  required Map<String, Object?> parameters,
  required String key,
  required List<String> allowed,
  required String? fallback,
}) {
  if (!parameters.containsKey(key)) {
    return fallback;
  }
  final value = parameters[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw VisualLibraryException(
      'battle_transitions.parameter_invalid',
      'The battle transition identifier must be a string.',
      details: <String, Object?>{'parameter': key},
    );
  }
  final id = value.trim();
  if (id.isEmpty) {
    return null;
  }
  if (!allowed.contains(id)) {
    throw VisualLibraryException(
      'battle_transitions.unknown_id',
      'The battle transition identifier is unknown for this side.',
      details: <String, Object?>{
        'parameter': key,
        'transitionId': id,
        'allowed': allowed,
      },
    );
  }
  return id;
}
