import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/gameplay_zone_editing_commands.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_dive_pair_port.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class DivePairPublishingScope extends InheritedWidget {
  const DivePairPublishingScope({
    super.key,
    required this.controller,
    required this.port,
    required super.child,
  });
  final MapWorkspaceController controller;
  final MapDivePairPort? port;
  static DivePairPublishingScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DivePairPublishingScope>();
  @override
  bool updateShouldNotify(DivePairPublishingScope oldWidget) => true;
}

class MapDiveZonePanel extends StatefulWidget {
  const MapDiveZonePanel({
    super.key,
    required this.zone,
    required this.commands,
    required this.onChanged,
  });
  final MapGameplayZone zone;
  final GameplayZoneEditingCommands commands;
  final void Function(VoidCallback) onChanged;
  @override
  State<MapDiveZonePanel> createState() => _MapDiveZonePanelState();
}

class _MapDiveZonePanelState extends State<MapDiveZonePanel> {
  String? _targetMapId, _targetZoneId, _message;
  MapData? _target;
  bool _busy = false;
  int _epoch = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = DivePairPublishingScope.maybeOf(context);
    final link = widget.zone.fieldAction?.dive?.link;
    if (scope != null && link != null && _targetMapId != link.mapId) {
      _selectMap(scope, link.mapId);
    }
  }

  Future<void> _selectMap(DivePairPublishingScope scope, String id) async {
    final epoch = ++_epoch;
    setState(() {
      _targetMapId = id;
      _targetZoneId = null;
      _target = null;
      _message = null;
    });
    try {
      final map =
          scope.controller.documents[id]?.current ??
          await scope.controller.previewMap(id);
      if (mounted && epoch == _epoch) setState(() => _target = map);
    } on Object catch (error) {
      if (mounted && epoch == _epoch) setState(() => _message = '$error');
    }
  }

  Future<void> _publish(DivePairPublishingScope scope) async {
    final source = widget.commands.document;
    final controller = scope.controller;
    final zone = widget.zone;
    final link = zone.fieldAction!.dive!.link;
    final targetId = link?.mapId ?? _targetMapId;
    final targetZoneId = link?.zoneId ?? _targetZoneId;
    if (scope.port == null ||
        targetId == null ||
        targetZoneId == null ||
        _busy) {
      return;
    }
    if (source.dirty ||
        source.saving ||
        controller.documents[targetId]?.dirty == true ||
        controller.documents[targetId]?.saving == true) {
      setState(
        () => _message = 'Enregistrez les brouillons des deux cartes avant de publier leur liaison.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final target =
          controller.documents[targetId]?.current ??
          (link == null ? _target : null) ??
          await controller.previewMap(targetId);
      if (target == null) {
        throw StateError('Carte opposée indisponible.');
      }
      if (source.dirty || controller.documents[targetId]?.dirty == true) {
        throw StateError('Un brouillon a changé avant la publication.');
      }
      await scope.port!.publishDivePair(
        session: controller.session,
        source: source.current,
        expectedTarget: target,
        zoneId: zone.id,
        targetZoneId: targetZoneId,
        unlink: link != null,
      );
      await controller.refreshSavedMaps({source.current.id, targetId});
      if (mounted) {
        setState(
          () => _message = link == null
              ? 'Les deux points sont liés. Délier annule cette publication.'
              : 'Les deux points sont déliés et conservés en préparation.',
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _endpointLabel(MapGameplayZone? point) => point == null
      ? 'Point indisponible'
      : '${point.name.isEmpty ? 'Point de Plongée' : point.name} (${point.area.pos.x}, ${point.area.pos.y})';

  @override
  Widget build(BuildContext context) {
    final zone = widget.zone;
    final payload = zone.fieldAction!.dive!;
    final link = payload.link;
    final scope = DivePairPublishingScope.maybeOf(context);
    final local = widget.commands.document.current;
    final spawns = local.entities.where(
      (entity) =>
          entity.kind == MapEntityKind.spawn &&
          entity.spawn != null &&
          entity.pos == zone.area.pos &&
          local.entities
                  .where((candidate) => candidate.id == entity.id)
                  .length ==
              1,
    );
    final candidates =
        _target?.gameplayZones
            .where(
              (other) =>
                  isDiveZone(other) &&
                  other.fieldAction!.dive!.role != payload.role &&
                  other.fieldAction!.dive!.link == null,
            )
            .toList() ??
        [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Rôle du point',
          value: payload.role.name,
          options: const {
            'surface': 'Surface · descente',
            'underwater': 'Sous l’eau · remontée',
          },
          onChanged: link != null || _busy
              ? null
              : (next) => widget.onChanged(
                  () => widget.commands.configureDive(
                    zone.id,
                    role: DiveZoneRole.values.byName(next),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        StudioSelect(
          label: 'Arrivée sur ce point',
          value: payload.arrivalSpawnId,
          options: {
            for (final spawn in spawns)
              spawn.id: spawn.name.isEmpty
                  ? 'Arrivée ${spawn.pos.x}, ${spawn.pos.y}'
                  : spawn.name,
          },
          onChanged: link != null || _busy
              ? null
              : (next) => widget.onChanged(
                  () => widget.commands.configureDive(
                    zone.id,
                    arrivalSpawnId: next,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        if (link == null && scope != null) ...[
          StudioSelect(
            label: 'Carte opposée',
            value: _targetMapId,
            options: {
              for (final map in widget.commands.project.maps.where(
                (map) => map.id != local.id,
              ))
                map.id: map.name,
            },
            onChanged: _busy ? null : (id) => _selectMap(scope, id),
          ),
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Point opposé',
            value: _targetZoneId,
            options: {
              for (final point in candidates)
                point.id: point.name.isEmpty
                    ? 'Point ${point.area.pos.x}, ${point.area.pos.y}'
                    : point.name,
            },
            onChanged: _busy
                ? null
                : (id) => setState(() => _targetZoneId = id),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          link == null
              ? 'Préparation inactive. Enregistrez les deux cartes, puis publiez leur liaison.'
              : 'Lié à ${widget.commands.project.maps.where((map) => map.id == link.mapId).firstOrNull?.name ?? 'Carte indisponible'} · ${_endpointLabel(_target?.gameplayZones.where((point) => point.id == link.zoneId).firstOrNull)}',
        ),
        if (link == null && _targetMapId != null && _targetZoneId != null)
          Text(
            'Publier : ${local.name} (${zone.area.pos.x}, ${zone.area.pos.y}) ↔ ${_target?.name ?? 'Carte indisponible'} · ${_endpointLabel(candidates.where((point) => point.id == _targetZoneId).firstOrNull)}',
          ),
        const SizedBox(height: 8),
        StudioButton(
          label: link == null
              ? 'Lier les deux points'
              : 'Délier les deux points',
          icon: link == null ? Icons.link : Icons.link_off,
          onPressed:
              scope?.port == null ||
                  _busy ||
                  (link == null &&
                      (_targetMapId == null || _targetZoneId == null))
              ? null
              : () => _publish(scope!),
        ),
        const Text(
          'Lier et Délier publient les deux cartes. Cette publication se défait avec Délier ; Ctrl+Z reste local au brouillon.',
        ),
        if (_message != null) Text(_message!),
      ],
    );
  }
}
