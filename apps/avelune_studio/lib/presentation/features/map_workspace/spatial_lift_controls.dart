import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class SpatialLiftControls extends StatefulWidget {
  const SpatialLiftControls({
    super.key,
    required this.document,
    required this.instance,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final SpatialModelInstance instance;
  final VoidCallback onChanged;
  @override
  State<SpatialLiftControls> createState() => _SpatialLiftControlsState();
}

class _SpatialLiftControlsState extends State<SpatialLiftControls> {
  final values = <String, String>{};
  SpatialLiftDefinition? lift;
  MapData? source;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(SpatialLiftControls old) {
    super.didUpdateWidget(old);
    if (!identical(source, widget.document.current) ||
        old.instance.id != widget.instance.id) {
      load();
    }
  }

  void load() {
    source = widget.document.current;
    lift = source!.spatialScene!.lifts
        .where((v) => v.instanceId == widget.instance.id)
        .firstOrNull;
    final point = widget.instance.position;
    final ground = source!.spatialScene!.worldHeightAt(point.x, point.z);
    values.addAll({
      'name': lift?.name ?? 'Ascenseur',
      'x': '${lift?.x ?? point.x.floor()}',
      'z': '${lift?.z ?? point.z.floor()}',
      'width': '${lift?.width ?? 1}',
      'depth': '${lift?.depth ?? 1}',
      'lower': '${lift?.lowerHeight ?? ground}',
      'upper': '${lift?.upperHeight ?? ground + 1}',
      'duration': '${lift?.durationMs ?? 1000}',
    });
    error = null;
  }

  String nextId() {
    var index = 1;
    while (source!.spatialScene!.lifts.any(
      (v) => v.id == 'vertical-platform-$index',
    )) {
      index++;
    }
    return 'vertical-platform-$index';
  }

  void apply() {
    try {
      if (widget.document.saving ||
          !identical(source, widget.document.current) ||
          widget.document.isElementLocked('model', widget.instance.id)) {
        throw StateError('La carte a changé ou cet élément est verrouillé.');
      }
      final definition = SpatialLiftDefinition(
        id: lift?.id ?? nextId(),
        name: values['name']!.trim(),
        instanceId: widget.instance.id,
        x: int.parse(values['x']!),
        z: int.parse(values['z']!),
        width: int.parse(values['width']!),
        depth: int.parse(values['depth']!),
        lowerHeight: double.parse(values['lower']!.replaceAll(',', '.')),
        upperHeight: double.parse(values['upper']!.replaceAll(',', '.')),
        durationMs: int.parse(values['duration']!),
      );
      widget.document.commit(
        const SpatialMapOperations().upsertLifts(widget.document.current, [
          definition,
        ]),
      );
      setState(load);
      widget.onChanged();
    } catch (e) {
      setState(
        () => error = e is StateError ? e.message.toString() : 'Vérifiez la zone, les deux hauteurs et une durée entre 100 et 30000 ms.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Plateforme verticale',
    children: [
      const Text('Plateforme verticale'),
      const Text(
        'La zone définie transporte ses occupants entre deux hauteurs. Une scène peut demander la montée ou la descente.',
      ),
      for (final field in [
        ('name', 'Nom'),
        ('x', 'Zone · X'),
        ('z', 'Zone · Z'),
        ('width', 'Largeur de la zone'),
        ('depth', 'Profondeur de la zone'),
        ('lower', 'Hauteur basse'),
        ('upper', 'Hauteur haute'),
        ('duration', 'Durée du trajet (ms)'),
      ])
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: StudioDraftField(
            label: field.$2,
            value: values[field.$1]!,
            enabled: !widget.document.saving,
            onChanged: (v) => values[field.$1] = v,
          ),
        ),
      if (error != null) StudioNotice(error!, isError: true),
      const SizedBox(height: 8),
      StudioButton(
        label: lift == null ? 'Créer la plateforme' : 'Appliquer les réglages',
        onPressed: widget.document.saving ? null : apply,
      ),
      if (lift != null)
        StudioButton(
          label: 'Retirer le mécanisme',
          onPressed: widget.document.saving
              ? null
              : () {
                  if (widget.document.isElementLocked(
                    'model',
                    widget.instance.id,
                  )) {
                    return;
                  }
                  widget.document.commit(
                    const SpatialMapOperations().deleteLifts(
                      widget.document.current,
                      [lift!.id],
                    ),
                  );
                  setState(load);
                  widget.onChanged();
                },
        ),
    ],
  );
}
