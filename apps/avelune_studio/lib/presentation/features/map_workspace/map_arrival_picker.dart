import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/text/studio_search_text.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../theme/studio_tokens.dart';

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

Future<GridPos?> showMapArrivalPicker(
  BuildContext context, {
  required String destinationName,
  required String fromMapId,
  required GridPos current,
  required Future<MapData?> destination,
}) => showDialog<GridPos>(
  context: context,
  builder: (_) => _MapArrivalPicker(
    destinationName: destinationName,
    fromMapId: fromMapId,
    current: current,
    destination: destination,
  ),
);

class _MapArrivalPicker extends StatefulWidget {
  const _MapArrivalPicker({
    required this.destinationName,
    required this.fromMapId,
    required this.current,
    required this.destination,
  });

  final String destinationName, fromMapId;
  final GridPos current;
  final Future<MapData?> destination;

  @override
  State<_MapArrivalPicker> createState() => _MapArrivalPickerState();
}

class _MapArrivalPickerState extends State<_MapArrivalPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Widget _content(BuildContext context, AsyncSnapshot<MapData?> snapshot) {
    final theme = Theme.of(context);
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    final map = snapshot.data;
    if (snapshot.hasError || map == null) {
      return Center(
        child: Text(
          'La carte « ${widget.destinationName} » ne peut pas être lue. '
          'La case d’arrivée actuelle est conservée.',
          key: const ValueKey('map-arrival-unavailable'),
        ),
      );
    }
    final problem = mapArrivalProblem(map, widget.current);
    final choices = mapArrivalChoices(
      map,
      fromMapId: widget.fromMapId,
      query: _query.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          problem ?? 'Arrivée actuelle : ${_cell(widget.current)}.',
          key: const ValueKey('map-arrival-current'),
          style: problem == null
              ? theme.textTheme.bodySmall
              : theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
        ),
        const SizedBox(height: 8),
        StudioSearchField(
          key: const ValueKey('map-arrival-search'),
          controller: _query,
          label: 'Rechercher un point d’arrivée',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: choices.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun point d’arrivée nommé sur cette carte. '
                    'Saisissez la case X et Y dans l’inspecteur.',
                  ),
                )
              : ListView.builder(
                  itemCount: choices.length,
                  itemBuilder: (context, index) {
                    final choice = choices[index];
                    return StudioChoice(
                      key: ValueKey(
                        'map-arrival-${choice.pos.x}-${choice.pos.y}',
                      ),
                      label: choice.label,
                      subtitle: choice.detail,
                      leading: const Icon(Icons.place_outlined, size: 18),
                      selected: choice.pos == widget.current,
                      onTap: () => Navigator.of(context).pop(choice.pos),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: (MediaQuery.sizeOf(context).height - 48).clamp(240, 560),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StudioMetrics.panelPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Point d’arrivée sur « ${widget.destinationName} »',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Seule la carte d’arrivée est lue pour proposer ses points.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<MapData?>(
                  future: widget.destination,
                  builder: _content,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: StudioButton(
                  label: 'Annuler',
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
