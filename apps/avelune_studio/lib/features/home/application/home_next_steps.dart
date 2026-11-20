import 'package:map_core/map_core_domain.dart';

enum HomeNextStepKind { map, start, character, interaction, test }

enum HomeNextStepStatus { done, todo, unverified }

final class HomeNextStep {
  const HomeNextStep({
    required this.kind,
    required this.title,
    required this.detail,
    required this.action,
    required this.status,
    required this.destination,
    this.mapId,
    this.unavailableReason,
  });

  final HomeNextStepKind kind;
  final String title, detail, action, destination;
  final HomeNextStepStatus status;
  final String? mapId, unavailableReason;
}

typedef HomeNextStepMap = ({String id, String name});

List<HomeNextStep> homeNextSteps({
  required List<HomeNextStepMap> maps,
  required ProjectNewGameConfig? newGame,
  required bool canTest,
}) {
  final startId = newGame?.startMapId.trim() ?? '';
  HomeNextStepMap? start;
  for (final entry in maps) {
    if (entry.id == startId) start = entry;
  }
  return [
    maps.isEmpty
        ? const HomeNextStep(
            kind: HomeNextStepKind.map,
            title: 'Créer une première carte',
            detail: 'Le projet ne contient encore aucune carte.',
            action: 'Créer une carte',
            status: HomeNextStepStatus.todo,
            destination: 'createMap',
          )
        : HomeNextStep(
            kind: HomeNextStepKind.map,
            title: 'Ouvrir une carte',
            detail: maps.length == 1
                ? '1 carte dans le projet.'
                : '${maps.length} cartes dans le projet.',
            action: 'Ouvrir la carte',
            status: HomeNextStepStatus.done,
            destination: 'map',
          ),
    newGame == null
        ? const HomeNextStep(
            kind: HomeNextStepKind.start,
            title: 'Définir le départ du joueur',
            detail: 'Le départ se vérifie depuis la carte, pas depuis l’accueil de ce projet.',
            action: 'Ouvrir une carte',
            status: HomeNextStepStatus.unverified,
            destination: 'map',
          )
        : start != null
        ? HomeNextStep(
            kind: HomeNextStepKind.start,
            title: 'Définir le départ du joueur',
            detail: 'La partie commence sur ${start.name}.',
            action: 'Ouvrir la carte de départ',
            status: HomeNextStepStatus.done,
            destination: 'map',
            mapId: start.id,
          )
        : HomeNextStep(
            kind: HomeNextStepKind.start,
            title: 'Définir le départ du joueur',
            detail: startId.isEmpty
                ? 'Aucune carte de départ n’est choisie pour une nouvelle partie.'
                : 'La carte de départ enregistrée est introuvable dans le projet.',
            action: 'Placer le départ',
            status: HomeNextStepStatus.todo,
            destination: 'map',
          ),
    const HomeNextStep(
      kind: HomeNextStepKind.character,
      title: 'Placer un personnage',
      detail: 'Les personnages placés ne sont pas recensés depuis l’accueil.',
      action: 'Placer un personnage',
      status: HomeNextStepStatus.unverified,
      destination: 'characters',
    ),
    const HomeNextStep(
      kind: HomeNextStepKind.interaction,
      title: 'Ajouter une interaction',
      detail: 'Dialogues et événements se vérifient dans Histoire.',
      action: 'Ouvrir Histoire',
      status: HomeNextStepStatus.unverified,
      destination: 'story',
    ),
    HomeNextStep(
      kind: HomeNextStepKind.test,
      title: 'Tester le jeu',
      detail: 'Le résultat d’un test n’est pas conservé par l’accueil.',
      action: 'Tester le jeu',
      status: HomeNextStepStatus.unverified,
      destination: 'testGame',
      unavailableReason: canTest
          ? null
          : 'Ouvrez une carte du projet pour lancer un test.',
    ),
  ];
}
