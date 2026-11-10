import '../../../features/map_workspace/application/spatial_lift_editing_session.dart';

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
  late SpatialLiftEditingSession editing;
  MapData? get source => editing.source;
  SpatialLiftDefinition? get lift => editing.lift;
  Map<String, String> get values => editing.values;
  String? get error => editing.error;

  @override
  void initState() {
    super.initState();
    editing = SpatialLiftEditingSession(widget.document, widget.instance);
  }

  @override
  void didUpdateWidget(SpatialLiftControls old) {
    super.didUpdateWidget(old);
    if (!identical(old.document, widget.document) ||
        old.instance.id != widget.instance.id) {
      editing.dispose();
      editing = SpatialLiftEditingSession(widget.document, widget.instance);
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

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Plateforme verticale',
    children: [
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
                  if (editing.delete()) {
                    setState(() {});
                    widget.onChanged();
                  }
                },
        ),
    ],
  );
}
