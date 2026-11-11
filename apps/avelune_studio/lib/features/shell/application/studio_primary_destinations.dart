class StudioPrimaryDestination {
  const StudioPrimaryDestination(this.id, this.label);
  final String id;
  final String label;
}

const studioPrimaryDestinations = [
  StudioPrimaryDestination('home', 'Accueil'),
  StudioPrimaryDestination('map', 'Carte'),
  StudioPrimaryDestination('regionalMap', 'Carte régionale'),
  StudioPrimaryDestination('resources', 'Ressources'),
  StudioPrimaryDestination('story', 'Histoire'),
  StudioPrimaryDestination('pokemon', 'Pokémon'),
  StudioPrimaryDestination('projectSettings', 'Réglages du projet'),
  StudioPrimaryDestination('test', 'Test du jeu'),
];

const _storyPages = {'scene', 'progression', 'events', 'dialogue', 'cinematic'};

String studioSelectedDestination(String active) => active == 'gameExport'
    ? 'home'
    : _storyPages.contains(active)
    ? 'story'
    : active;

String? studioDestinationUnavailableReason(
  String destination, {
  required bool busy,
  required bool canTest,
}) => busy
    ? 'indisponible pendant l’opération en cours'
    : destination == 'test' && !canTest
    ? 'ouvrez une carte du projet pour lancer un test'
    : null;
