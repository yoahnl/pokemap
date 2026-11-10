import '../../../features/map_workspace/application/spatial_platform_editing_session.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/features/map_workspace/application/traversal_labels.dart';

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
  late SpatialPlatformEditingSession editing;
  MapData? get source => editing.source;
  SpatialPlatformDefinition? get platform => editing.platform;
  Map<String, String> get values => editing.values;
  String? get error => editing.error;
  List<SpatialPlatformRouteDraft> get routes => editing.routes;
  bool get enabled => editing.enabled;

  @override
  void initState() {
    super.initState();
    editing = SpatialPlatformEditingSession(widget.document, widget.instance);
  }

  @override
  void didUpdateWidget(SpatialPlatformControls old) {
    super.didUpdateWidget(old);
    if (!identical(old.document, widget.document) ||
        old.instance.id != widget.instance.id) {
      editing.dispose();
      editing = SpatialPlatformEditingSession(widget.document, widget.instance);
    } else {
      editing.instance = widget.instance;
      if (!identical(source, widget.document.current)) editing.load();
    }
  }

  @override
  void dispose() {
    editing.dispose();
    super.dispose();
  }

  void apply() {
    final applied = editing.apply();
    setState(() {});
    if (applied) widget.onChanged();
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
      if (platform case final applied?)
        Text(
          'Trajet appliqué : ${traversalDurationLabel(applied.durationMs)} (de 100 à 30 000 ms).',
          key: const ValueKey('spatial-platform-duration'),
        ),
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
          onPressed: enabled ? () => setState(editing.addRoute) : null,
        ),
      if (widget.instance.blocksMovement)
        const StudioNotice(
          'Pour en faire une plateforme, désactivez d’abord la collision du modèle complet.',
        )
      else if (error != null)
        StudioNotice(error!, isError: true),
      StudioButton(
        label: platform == null ? 'Créer le trajet' : 'Appliquer le trajet',
        onPressed: enabled && !widget.instance.blocksMovement ? apply : null,
      ),
    ],
  );
}
