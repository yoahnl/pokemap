import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_moving_prop_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class MapMovingPropPanel extends StatefulWidget {
  const MapMovingPropPanel({
    super.key,
    required this.document,
    required this.project,
    required this.placement,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapPlacedElement placement;
  final VoidCallback onChanged;

  @override
  State<MapMovingPropPanel> createState() => _MapMovingPropPanelState();
}

class _MapMovingPropPanelState extends State<MapMovingPropPanel> {
  late MapMovingPropDraft draft;
  String? _error;

  MapMovingPropCommands get commands =>
      MapMovingPropCommands(widget.document, widget.project);
  MovingPropDefinition? get _prop => commands.forPlacement(widget.placement.id);

  @override
  void initState() {
    super.initState();
    draft = MapMovingPropDraft.fromPlacement(
      widget.document.current,
      widget.project,
      widget.placement.id,
    );
  }

  void _save() {
    final error = commands.save(widget.placement.id, draft);
    setState(() => _error = error);
    if (error == null) widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (!commands.canConfigure(widget.placement)) {
      return const SizedBox.shrink();
    }
    Widget field(
      String key,
      String label,
      String value,
      ValueChanged<String> changed,
    ) => StudioDraftField(
      key: ValueKey('prop-$key'),
      label: label,
      value: value,
      keyboardType: TextInputType.number,
      onChanged: (value) => setState(() => changed(value)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Décor mobile', style: Theme.of(context).textTheme.titleSmall),
        const Text(
          'Le décor suit un rail entre fermé et ouvert. Une scène peut synchroniser plusieurs décors.',
        ),
        StudioSelect(
          key: const ValueKey('prop-direction'),
          label: 'Direction d’ouverture',
          value: draft.direction,
          options: const {
            'north': 'Nord',
            'south': 'Sud',
            'east': 'Est',
            'west': 'Ouest',
          },
          onChanged: (value) => setState(() => draft.direction = value),
        ),
        field(
          'distance',
          'Distance (pixels)',
          draft.distance,
          (value) => draft.distance = value,
        ),
        field(
          'left',
          'Décalage collision horizontal (pixels)',
          draft.left,
          (value) => draft.left = value,
        ),
        field(
          'top',
          'Décalage collision vertical (pixels)',
          draft.top,
          (value) => draft.top = value,
        ),
        field(
          'width',
          'Largeur collision (pixels)',
          draft.width,
          (value) => draft.width = value,
        ),
        field(
          'height',
          'Hauteur collision (pixels)',
          draft.height,
          (value) => draft.height = value,
        ),
        StudioSelect(
          key: const ValueKey('prop-initial-state'),
          label: 'État initial',
          value: draft.initialState,
          options: const {'closed': 'Fermé', 'open': 'Ouvert'},
          onChanged: (value) => setState(() => draft.initialState = value),
        ),
        if (_error != null) StudioNotice(_error!),
        StudioButton(
          key: const ValueKey('prop-save'),
          label: _prop == null
              ? 'Configurer le déplacement'
              : 'Appliquer le déplacement',
          onPressed: _save,
        ),
        if (_prop != null)
          StudioButton(
            label: 'Retirer le déplacement',
            secondary: true,
            onPressed: () {
              final error = commands.delete(_prop!.id);
              setState(() => _error = error);
              if (error == null) widget.onChanged();
            },
          ),
      ],
    );
  }
}
