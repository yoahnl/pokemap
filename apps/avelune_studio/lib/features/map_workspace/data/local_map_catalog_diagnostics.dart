import 'package:map_core/map_core_domain.dart';

import '../domain/map_catalog_preparation.dart';

List<MapCatalogIssue> mapCatalogIssues(
  String? code,
  Map<String, Object?> details,
  ProjectManifest manifest,
) {
  final issues = <MapCatalogIssue>[];
  final impacts = details['impacts'];
  if (impacts is List) {
    for (final impact in impacts.whereType<Map>()) {
      final mapId = impact['ownerMapId'] ?? impact['mapId'];
      final label = impact['subjectLabel'] ?? impact['subjectId'];
      final kind = _kind(impact['kind']);
      final reason = _reason(impact['reason']);
      issues.add(
        MapCatalogIssue(
          code: (impact['diagnosticCode'] ?? code ?? 'map.resize_impacts')
              .toString(),
          message: '$kind${label == null ? '' : ' « $label »'} : $reason',
          mapId: mapId is String ? mapId : null,
        ),
      );
    }
  }
  final dependents = details['dependents'];
  if (dependents is List) {
    for (final dependent in dependents.whereType<Map>()) {
      final navigation = dependent['navigation'];
      final key = dependent['key'];
      final mapId = navigation is Map ? navigation['mapId'] : null;
      final inferredId =
          mapId ??
          (key is Map && key['scope'] == 'map' ? key['parentId'] : null);
      final entry = manifest.maps
          .where((entry) => entry.id == inferredId)
          .firstOrNull;
      final label =
          dependent['label'] ??
          entry?.name ??
          (key is Map ? key['id'] : null) ??
          'Document lié';
      issues.add(
        MapCatalogIssue(
          code: code ?? 'map.references_blocking',
          message:
              '« $label » utilise cette carte. Modifiez cette référence avant de la supprimer.',
          mapId: inferredId is String ? inferredId : null,
        ),
      );
    }
  }
  if (issues.isEmpty && code != null) {
    issues.add(
      MapCatalogIssue(
        code: code,
        message: switch (code) {
          'map.inventory_incomplete' =>
            'Des documents du projet sont absents ou illisibles. L’analyse des usages est incomplète.',
          'map.references_blocking' =>
            'Cette carte est utilisée par le projet. Modifiez ses références avant de la supprimer.',
          'map.resize_impacts' =>
            'Ces dimensions retireraient du contenu ou invalideraient une référence. Agrandissez la zone proposée.',
          'map.id_exists' => 'Cet identifiant existe déjà dans le projet.',
          'map.group_missing' =>
            'Le dossier choisi n’existe plus. Sélectionnez un autre dossier.',
          'map.request_invalid' =>
            'Vérifiez les informations saisies avant de poursuivre.',
          _ =>
            'Cette opération est refusée. Vérifiez les données et les références de la carte.',
        },
      ),
    );
  }
  return issues;
}

String _kind(Object? kind) => switch (kind) {
  'tileLayer' => 'Tuiles',
  'collisionLayer' => 'Collisions',
  'smartTileLayer' => 'Terrain',
  'environmentArea' => 'Zone d’environnement',
  'borderLayer' => 'Bordure',
  'placedElement' => 'Décor',
  'entity' || 'entityWaypoint' => 'Personnage ou départ',
  'warp' || 'warpTriggerArea' || 'localWarpTarget' => 'Passage',
  'trigger' => 'Zone narrative',
  'gameplayZone' => 'Zone de jeu',
  'event' => 'Événement',
  'connection' => 'Connexion entre cartes',
  _ => 'Élément ou référence',
};

String _reason(Object? reason) => switch (reason) {
  'clippedCells' => 'des cases seraient retirées',
  'positionOutside' ||
  'localTargetOutside' ||
  'patrolWaypointOutside' => 'une position sortirait de la carte',
  'footprintOutside' => 'l’emprise dépasse les nouvelles limites',
  'footprintUnknown' ||
  'missingContext' => 'les dimensions nécessaires ne sont pas disponibles',
  'areaOutside' ||
  'triggerAreaClipped' => 'la zone dépasserait les nouvelles limites',
  'danglingReference' => 'une référence deviendrait introuvable',
  'borderDiagnostic' =>
    'la bordure ne peut pas être conservée dans ces dimensions',
  'connectionTopologyChanged' =>
    'la liaison ne correspondrait plus aux limites des cartes',
  _ => 'une donnée ou référence ne resterait pas valide dans ces dimensions',
};
