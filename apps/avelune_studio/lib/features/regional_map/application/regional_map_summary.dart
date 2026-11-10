import 'package:map_core/map_core.dart';

String regionalPlaceVisibility(ProjectRegionPointOfInterest point) =>
    switch (point.visibility) {
      ProjectRegionPointVisibility.hidden => 'Masqué sur la carte régionale',
      ProjectRegionPointVisibility.always =>
        'Toujours visible sur la carte régionale',
      ProjectRegionPointVisibility.discoveredOnly =>
        point.discovery == ProjectRegionPointDiscovery.always
            ? 'Visible dès le départ sur la carte régionale'
            : 'Visible après la visite d’une carte liée',
    };

String regionalPlaceFlight(
  ProjectRegionPointOfInterest point,
  ProjectManifest project,
) {
  final destination = point.destination;
  if (destination == null) return 'Vol non autorisé';
  final map = project.maps
      .where((entry) => entry.id == destination.mapId)
      .firstOrNull;
  return map == null
      ? 'Vol vers une carte introuvable : ${destination.mapId}'
      : 'Vol autorisé vers ${map.name}';
}

String regionalPlacePosition(ProjectRegionPointOfInterest point) =>
    'Position : ${(point.u * 100).round()} % depuis la gauche, ${(point.v * 100).round()} % depuis le haut';

({String text, bool problem}) regionalFlightArrival({
  required ProjectRegionDestination destination,
  required ProjectManifest project,
  required MapData? map,
  required bool loading,
}) {
  final entry = project.maps
      .where((value) => value.id == destination.mapId)
      .firstOrNull;
  if (entry == null) {
    return (
      text:
          'La carte d’arrivée « ${destination.mapId} » n’existe plus dans le projet : choisissez-en une autre, la destination de Vol est incomplète.',
      problem: true,
    );
  }
  if (loading || map == null) {
    return (text: 'Chargement des arrivées de ${entry.name}…', problem: false);
  }
  final spawnId = destination.spawnId;
  if (spawnId == null) {
    return (
      text: 'Choisissez le point d’arrivée : sans lui, la destination de Vol est incomplète et le jeu la refuse.',
      problem: true,
    );
  }
  final spawn = map.entities
      .where(
        (entity) =>
            entity.kind == MapEntityKind.spawn &&
            entity.spawn != null &&
            (entity.id == spawnId || entity.spawn!.spawnKey == spawnId),
      )
      .firstOrNull;
  if (spawn == null) {
    return (
      text:
          'Le point d’arrivée « $spawnId » n’existe plus sur ${entry.name} : choisissez-en un autre, la destination de Vol est incomplète.',
      problem: true,
    );
  }
  final name = spawn.name.isEmpty ? 'Arrivée' : spawn.name;
  return (
    text:
        'Arrivée de Vol : ${entry.name}, à « $name » (${spawn.pos.x}, ${spawn.pos.y}), regard vers ${_towards(spawn.spawn!.facing)}.',
    problem: false,
  );
}

String _towards(EntityFacing facing) => switch (facing) {
  EntityFacing.north => 'le nord',
  EntityFacing.east => 'l’est',
  EntityFacing.south => 'le sud',
  EntityFacing.west => 'l’ouest',
};
