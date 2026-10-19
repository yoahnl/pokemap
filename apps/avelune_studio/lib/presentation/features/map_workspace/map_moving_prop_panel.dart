import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
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
  late String _direction;
  late String _distance;
  late String _width;
  late String _height;
  late String _left;
  late String _top;
  late String _initialState;
  String? _error;

  MovingPropDefinition? get _prop => widget.document.current.movingProps
      .where((value) => value.placedElementId == widget.placement.id)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    final prop = _prop;
    final dx = prop == null
        ? 0
        : prop.openPositionPx.x - prop.closedPositionPx.x;
    final dy = prop == null
        ? 0
        : prop.openPositionPx.y - prop.closedPositionPx.y;
    _direction = dx < 0
        ? 'west'
        : dy < 0
        ? 'north'
        : dy > 0
        ? 'south'
        : 'east';
    _distance =
        '${prop == null ? widget.project.settings.tileWidth : dx.abs() + dy.abs()}';
    _width =
        '${prop?.collisionRect.widthPx ?? widget.project.settings.tileWidth}';
    _height =
        '${prop?.collisionRect.heightPx ?? widget.project.settings.tileHeight}';
    _left = '${prop?.collisionRect.leftPx ?? 0}';
    _top = '${prop?.collisionRect.topPx ?? 0}';
    _initialState = prop?.initialState.name ?? 'closed';
  }

  void _save() {
    try {
      final editing = const MovingPropEditing();
      final prop = editing.definition(
        map: widget.document.current,
        project: widget.project,
        placedElementId: widget.placement.id,
        direction: EntityFacing.values.byName(_direction),
        distancePx: int.parse(_distance),
        initialState: MovingPropState.values.byName(_initialState),
        collisionRect: PixelRect(
          leftPx: int.parse(_left),
          topPx: int.parse(_top),
          widthPx: int.parse(_width),
          heightPx: int.parse(_height),
        ),
      );
      widget.document.commit(
        editing.upsert(
          map: widget.document.current,
          project: widget.project,
          prop: prop,
        ),
      );
      setState(() => _error = null);
      widget.onChanged();
    } catch (_) {
      setState(
        () => _error = 'Vérifiez les valeurs entières, le rail de 1 à 1024 pixels, l’empreinte dans le décor et les deux positions dans la carte.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.document.current.spatialScene != null ||
        widget.project.settings.dimension != ProjectDimension.twoD ||
        !isAuthoredMapPlacedElement(widget.placement)) {
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
          value: _direction,
          options: const {
            'north': 'Nord',
            'south': 'Sud',
            'east': 'Est',
            'west': 'Ouest',
          },
          onChanged: (value) => setState(() => _direction = value),
        ),
        field(
          'distance',
          'Distance (pixels)',
          _distance,
          (value) => _distance = value,
        ),
        field(
          'left',
          'Décalage collision horizontal (pixels)',
          _left,
          (value) => _left = value,
        ),
        field(
          'top',
          'Décalage collision vertical (pixels)',
          _top,
          (value) => _top = value,
        ),
        field(
          'width',
          'Largeur collision (pixels)',
          _width,
          (value) => _width = value,
        ),
        field(
          'height',
          'Hauteur collision (pixels)',
          _height,
          (value) => _height = value,
        ),
        StudioSelect(
          key: const ValueKey('prop-initial-state'),
          label: 'État initial',
          value: _initialState,
          options: const {'closed': 'Fermé', 'open': 'Ouvert'},
          onChanged: (value) => setState(() => _initialState = value),
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
              try {
                widget.document.commit(
                  const MovingPropEditing().delete(
                    map: widget.document.current,
                    project: widget.project,
                    propId: _prop!.id,
                  ),
                );
                setState(() => _error = null);
                widget.onChanged();
              } catch (_) {
                setState(
                  () => _error = 'Ce déplacement est utilisé par une scène. Retirez sa référence avant de le supprimer.',
                );
              }
            },
          ),
      ],
    );
  }
}
