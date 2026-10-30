import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class SpatialPlatformControls extends StatefulWidget {
  const SpatialPlatformControls({
    super.key,
    required this.document,
    required this.project,
    required this.instance,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final SpatialModelInstance instance;
  final VoidCallback onChanged;
  @override
  State<SpatialPlatformControls> createState() =>
      _SpatialPlatformControlsState();
}

class _SpatialPlatformControlsState extends State<SpatialPlatformControls> {
  MapData? source;
  SpatialPlatformDefinition? platform;
  final values = <String, String>{};
  final routes = <_RouteDraft>[];
  String? error;
  bool get enabled =>
      !widget.document.saving &&
      !widget.document.isElementLocked('model', widget.instance.id);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(SpatialPlatformControls old) {
    super.didUpdateWidget(old);
    if (!identical(source, widget.document.current) ||
        old.instance.id != widget.instance.id) {
      load();
    }
  }

  void load() {
    source = widget.document.current;
    platform = source!.spatialScene!.platforms
        .where((value) => value.instanceId == widget.instance.id)
        .firstOrNull;
    final position = widget.instance.position;
    values.addAll({
      'name': platform?.name ?? 'Plateforme',
      'x': '${platform?.x ?? position.x.floor()}',
      'z': '${platform?.z ?? position.z.floor()}',
      'width': '${platform?.width ?? 1}',
      'depth': '${platform?.depth ?? 1}',
      'height':
          '${platform?.height ?? source!.spatialScene!.worldHeightAt(position.x, position.z)}',
      'duration': '${platform?.durationMs ?? 1500}',
    });
    routes.clear();
    routes.addAll(
      platform?.routes.map(_RouteDraft.fromRoute) ?? [_RouteDraft('route-1')],
    );
    error = null;
  }

  double number(String value) => double.parse(value.replaceAll(',', '.'));
  void apply() {
    try {
      if (widget.instance.blocksMovement) {
        throw StateError(
          'Désactivez la collision du modèle complet avant de créer le support mobile.',
        );
      }
      if (!enabled || !identical(source, widget.document.current)) {
        throw StateError('La carte a changé ou cet élément est verrouillé.');
      }
      var serial = 1;
      while (source!.spatialScene!.platforms.any(
            (value) => value.id == 'route-platform-$serial',
          ) ||
          source!.spatialScene!.lifts.any(
            (value) => value.id == 'route-platform-$serial',
          )) {
        serial++;
      }
      final value = SpatialPlatformDefinition(
        id: platform?.id ?? 'route-platform-$serial',
        name: values['name']!.trim(),
        instanceId: widget.instance.id,
        x: number(values['x']!),
        z: number(values['z']!),
        width: number(values['width']!),
        depth: number(values['depth']!),
        height: number(values['height']!),
        durationMs: int.parse(values['duration']!),
        routes: [
          for (final route in routes)
            SpatialPlatformRoute(
              id: route.id,
              waypoints: [
                for (final point in route.points)
                  SpatialPlatformStop(x: number(point[0]), z: number(point[1])),
              ],
              conditions: [
                for (final condition in route.conditions)
                  SpatialPlatformCondition(
                    factId: condition.$1,
                    value: condition.$2,
                  ),
              ],
            ),
        ],
      );
      widget.document.commit(
        const SpatialMapOperations().upsertPlatform(
          widget.document.current,
          value,
        ),
      );
      setState(load);
      widget.onChanged();
    } catch (exception) {
      setState(
        () => error = exception is StateError ? exception.message.toString() : 'Vérifiez la zone, les quais, les conditions et la durée (100 à 30000 ms). Gardez exactement un trajet sans condition.',
      );
    }
  }

  Widget field(String label, String value, ValueChanged<String> changed) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: StudioDraftField(
          label: label,
          value: value,
          enabled: enabled,
          onChanged: changed,
        ),
      );
  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Plateforme sur trajet',
    children: [
      const Text('Plateforme sur trajet'),
      const Text(
        'Le modèle complet transporte le joueur et son compagnon. Les étapes sont des décalages X/Z depuis sa pose initiale ; seuls le départ et l’arrivée sont des quais. Les scènes commandent aller ou retour.',
      ),
      for (final entry in [
        ('name', 'Nom de la plateforme'),
        ('x', 'Support · X'),
        ('z', 'Support · Z'),
        ('width', 'Largeur du support'),
        ('depth', 'Profondeur du support'),
        ('height', 'Hauteur du support'),
        ('duration', 'Durée du trajet (ms)'),
      ])
        field(entry.$2, values[entry.$1]!, (value) => values[entry.$1] = value),
      for (var r = 0; r < routes.length; r++) ...[
        Text(
          'Trajet ${r + 1}${routes[r].conditions.isEmpty ? ' · par défaut' : ''}',
        ),
        for (var p = 0; p < routes[r].points.length; p++) ...[
          field(
            'Trajet ${r + 1} · étape ${p + 1} · X',
            routes[r].points[p][0],
            (value) => routes[r].points[p][0] = value,
          ),
          field(
            'Trajet ${r + 1} · étape ${p + 1} · Z',
            routes[r].points[p][1],
            (value) => routes[r].points[p][1] = value,
          ),
          if (routes[r].points.length > 2)
            StudioButton(
              label: 'Retirer l’étape ${p + 1} du trajet ${r + 1}',
              onPressed: enabled
                  ? () => setState(() => routes[r].points.removeAt(p))
                  : null,
            ),
        ],
        if (routes[r].points.length < 32)
          StudioButton(
            label: 'Ajouter une étape au trajet ${r + 1}',
            onPressed: enabled
                ? () => setState(() => routes[r].points.add(['1', '0']))
                : null,
          ),
        for (var c = 0; c < routes[r].conditions.length; c++) ...[
          StudioSelect(
            label: 'Trajet ${r + 1} · condition ${c + 1}',
            value: routes[r].conditions[c].$1,
            options: {
              for (final fact in widget.project.facts.where(
                (value) => value.valueKind == NarrativeValueKind.boolean,
              ))
                fact.id: fact.label,
            },
            onChanged: enabled
                ? (value) => setState(
                    () => routes[r].conditions[c] = (
                      value,
                      routes[r].conditions[c].$2,
                    ),
                  )
                : null,
          ),
          StudioSelect(
            label: 'Trajet ${r + 1} · valeur ${c + 1}',
            value: '${routes[r].conditions[c].$2}',
            options: const {'true': 'Vrai', 'false': 'Faux'},
            onChanged: enabled
                ? (value) => setState(
                    () => routes[r].conditions[c] = (
                      routes[r].conditions[c].$1,
                      value == 'true',
                    ),
                  )
                : null,
          ),
          StudioButton(
            label: 'Retirer la condition ${c + 1} du trajet ${r + 1}',
            onPressed: enabled
                ? () => setState(() => routes[r].conditions.removeAt(c))
                : null,
          ),
        ],
        if (routes[r].conditions.length < 8 &&
            widget.project.facts.any(
              (value) =>
                  value.valueKind == NarrativeValueKind.boolean &&
                  !routes[r].conditions.any(
                    (condition) => condition.$1 == value.id,
                  ),
            ))
          StudioButton(
            label: 'Ajouter une condition au trajet ${r + 1}',
            onPressed: enabled
                ? () => setState(
                    () => routes[r].conditions.add((
                      widget.project.facts
                          .firstWhere(
                            (value) =>
                                value.valueKind == NarrativeValueKind.boolean &&
                                !routes[r].conditions.any(
                                  (condition) => condition.$1 == value.id,
                                ),
                          )
                          .id,
                      true,
                    )),
                  )
                : null,
          ),
        if (routes.length > 1)
          StudioButton(
            label: 'Retirer le trajet ${r + 1}',
            onPressed: enabled
                ? () => setState(() => routes.removeAt(r))
                : null,
          ),
      ],
      if (routes.length < 16)
        StudioButton(
          label: 'Ajouter un trajet',
          onPressed: enabled
              ? () => setState(() {
                  var serial = 1;
                  while (routes.any((value) => value.id == 'route-$serial')) {
                    serial++;
                  }
                  routes.add(_RouteDraft('route-$serial'));
                })
              : null,
        ),
      if (error != null) StudioNotice(error!, isError: true),
      StudioButton(
        label: platform == null ? 'Créer le trajet' : 'Appliquer le trajet',
        onPressed: enabled ? apply : null,
      ),
    ],
  );
}

final class _RouteDraft {
  _RouteDraft(this.id)
    : points = [
        ['0', '0'],
        ['1', '0'],
      ],
      conditions = [];
  _RouteDraft.fromRoute(SpatialPlatformRoute route)
    : id = route.id,
      points = [
        for (final point in route.waypoints) ['${point.x}', '${point.z}'],
      ],
      conditions = [
        for (final condition in route.conditions)
          (condition.factId, condition.value),
      ];
  final String id;
  final List<List<String>> points;
  final List<(String, bool)> conditions;
}
