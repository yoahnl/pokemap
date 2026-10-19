import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart';

import '../design_system/design_system.dart';

class MovingPropPanel extends StatefulWidget {
  const MovingPropPanel({
    super.key,
    required this.map,
    required this.project,
    required this.placement,
    required this.onApply,
    required this.onDelete,
  });

  final MapData map;
  final ProjectManifest project;
  final MapPlacedElement placement;
  final ValueChanged<MovingPropDefinition> onApply;
  final ValueChanged<String> onDelete;

  @override
  State<MovingPropPanel> createState() => _MovingPropPanelState();
}

class _MovingPropPanelState extends State<MovingPropPanel> {
  late final Map<String, TextEditingController> _fields;
  late String _direction;
  late String _initialState;
  String? _error;

  MovingPropDefinition? get _prop => widget.map.movingProps
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
    _initialState = prop?.initialState.name ?? 'closed';
    _fields = {
      for (final entry in {
        'distance': prop == null
            ? widget.project.settings.tileWidth
            : dx.abs() + dy.abs(),
        'left': prop?.collisionRect.leftPx ?? 0,
        'top': prop?.collisionRect.topPx ?? 0,
        'width':
            prop?.collisionRect.widthPx ?? widget.project.settings.tileWidth,
        'height':
            prop?.collisionRect.heightPx ?? widget.project.settings.tileHeight,
      }.entries)
        entry.key: TextEditingController(text: '${entry.value}'),
    };
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _save() {
    try {
      final prop = const MovingPropEditing().definition(
        map: widget.map,
        project: widget.project,
        placedElementId: widget.placement.id,
        direction: EntityFacing.values.byName(_direction),
        distancePx: int.parse(_fields['distance']!.text),
        initialState: MovingPropState.values.byName(_initialState),
        collisionRect: PixelRect(
          leftPx: int.parse(_fields['left']!.text),
          topPx: int.parse(_fields['top']!.text),
          widthPx: int.parse(_fields['width']!.text),
          heightPx: int.parse(_fields['height']!.text),
        ),
      );
      const MovingPropEditing().upsert(
        map: widget.map,
        project: widget.project,
        prop: prop,
      );
      widget.onApply(prop);
      setState(() => _error = null);
    } catch (_) {
      setState(
        () => _error =
            'Vérifiez les entiers, le rail de 1 à 1024 pixels, l’empreinte dans le décor et les deux positions dans la carte.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.map.spatialScene != null ||
        widget.project.settings.dimension != ProjectDimension.twoD ||
        !isAuthoredMapPlacedElement(widget.placement)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Décor mobile'),
        const Text(
          'Une scène peut ouvrir ou fermer plusieurs décors en même temps.',
        ),
        PokeMapDropdownField<String>(
          key: const ValueKey('prop-direction'),
          label: 'Direction d’ouverture',
          value: _direction,
          items: const [
            PokeMapDropdownItem(value: 'north', label: 'Nord'),
            PokeMapDropdownItem(value: 'south', label: 'Sud'),
            PokeMapDropdownItem(value: 'east', label: 'Est'),
            PokeMapDropdownItem(value: 'west', label: 'Ouest'),
          ],
          onChanged: (value) => setState(() => _direction = value),
        ),
        for (final entry in const {
          'distance': 'Distance (pixels)',
          'left': 'Décalage collision horizontal (pixels)',
          'top': 'Décalage collision vertical (pixels)',
          'width': 'Largeur collision (pixels)',
          'height': 'Hauteur collision (pixels)',
        }.entries)
          PokeMapTextField(
            key: ValueKey('prop-${entry.key}'),
            label: entry.value,
            controller: _fields[entry.key],
            keyboardType: TextInputType.number,
          ),
        PokeMapDropdownField<String>(
          key: const ValueKey('prop-initial-state'),
          label: 'État initial',
          value: _initialState,
          items: const [
            PokeMapDropdownItem(value: 'closed', label: 'Fermé'),
            PokeMapDropdownItem(value: 'open', label: 'Ouvert'),
          ],
          onChanged: (value) => setState(() => _initialState = value),
        ),
        if (_error != null)
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Déplacement invalide',
            message: _error!,
          ),
        PokeMapButton(
          key: const ValueKey('prop-save'),
          onPressed: _save,
          child: Text(
            _prop == null
                ? 'Configurer le déplacement'
                : 'Appliquer le déplacement',
          ),
        ),
        if (_prop != null)
          PokeMapButton(
            variant: PokeMapButtonVariant.secondary,
            onPressed: () {
              try {
                const MovingPropEditing().delete(
                  map: widget.map,
                  project: widget.project,
                  propId: _prop!.id,
                );
                widget.onDelete(_prop!.id);
                setState(() => _error = null);
              } catch (_) {
                setState(
                  () => _error =
                      'Ce déplacement est utilisé par une scène. Retirez sa référence avant de le supprimer.',
                );
              }
            },
            child: const Text('Retirer le déplacement'),
          ),
      ],
    );
  }
}
