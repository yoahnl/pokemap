import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/studio_search_text.dart';

final class MapArrivalChoice {
  const MapArrivalChoice(this.label, this.detail, this.pos);
  final String label, detail;
  final GridPos pos;
}

String _cell(GridPos pos) => 'case ${pos.x}, ${pos.y}';

List<MapArrivalChoice> mapArrivalChoices(
  MapData destination, {
  required String fromMapId,
  String query = '',
}) =>
    [
          for (final entity in destination.entities)
            if (entity.kind == MapEntityKind.spawn)
              MapArrivalChoice(
                (entity.spawn?.role ?? EntitySpawnRole.playerStart) ==
                        EntitySpawnRole.playerStart
                    ? 'Départ du joueur'
                    : 'Point d’apparition',
                _cell(entity.pos),
                entity.pos,
              ),
          for (final warp in destination.warps)
            if (warp.triggerMode == MapWarpTriggerMode.sceneOnly)
              MapArrivalChoice('Point d’arrivée', _cell(warp.pos), warp.pos)
            else if (warp.targetMapId == fromMapId)
              MapArrivalChoice(
                'Passage qui revient ici',
                warp.door == null
                    ? _cell(warp.pos)
                    : 'sortie de porte · ${_cell(warp.door!.exitPos)}',
                warp.door?.exitPos ?? warp.pos,
              ),
        ]
        .where(
          (choice) =>
              studioSearchMatches('${choice.label} ${choice.detail}', query),
        )
        .toList();

String? mapArrivalProblem(MapData destination, GridPos target) =>
    target.x < destination.size.width && target.y < destination.size.height
    ? null
    : 'La ${_cell(target)} est hors de « ${destination.name} » '
          '(${destination.size.width} × ${destination.size.height}). '
          'Choisissez un point d’arrivée.';
