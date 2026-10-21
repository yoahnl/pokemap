import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

class SceneNpcPoseActionForm extends StatefulWidget {
  const SceneNpcPoseActionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
    this.loadMap,
  });
  final ProjectManifest project;
  final SceneActionPayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<MapData> Function(String)? loadMap;

  @override
  State<SceneNpcPoseActionForm> createState() => _SceneNpcPoseActionFormState();
}

class _SceneNpcPoseActionFormState extends State<SceneNpcPoseActionForm> {
  String? _mapId, _entityId, _facing;
  String _mode = 'position', _x = '', _y = '';
  MapData? _map;
  bool _loading = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(SceneNpcPoseActionForm old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      _read();
    } else if (old.project != widget.project || old.loadMap != widget.loadMap) {
      _load();
    }
  }

  void _read() {
    final pose = widget.current?.consequence;
    _mapId = null;
    _entityId = null;
    _mode = 'position';
    _facing = null;
    _x = '';
    _y = '';
    if (pose is SceneSetNpcPoseConsequence) {
      _mapId = pose.mapId;
      _entityId = pose.entityId;
      _mode = pose.x == null ? 'facing' : 'position';
      _x = pose.x?.toString() ?? '';
      _y = pose.y?.toString() ?? '';
      _facing = pose.facing?.name;
    }
    _load();
  }

  Map<String, String> get _maps => {
    if (widget.project.settings.dimension == ProjectDimension.twoD)
      for (final entry in widget.project.maps)
        if (widget.project.maps.where((value) => value.id == entry.id).length ==
            1)
          entry.id: entry.name,
  };

  Map<String, String> get _actors => {
    if (_map case final map?)
      for (final entity in map.entities)
        if (map.entities.where((value) => value.id == entity.id).length == 1 &&
            entity.presentation != null &&
            entity.presentation!.variants.any(
              (variant) => variant.characterId != null,
            ) &&
            validateMapEntityPresentation(
              project: widget.project,
              map: map,
              entity: entity,
            ).isEmpty)
          entity.id: entity.name.isEmpty ? 'PNJ (${entity.id})' : entity.name,
  };

  Future<void> _load() async {
    final token = ++_request;
    _map = null;
    _error = null;
    _loading = false;
    final id = _mapId;
    if (id == null) return;
    _loading = true;
    await Future<void>.value();
    try {
      if (!_maps.containsKey(id) || widget.loadMap == null) {
        throw StateError('Unavailable');
      }
      final map = await widget.loadMap!(id);
      if (map.id != id ||
          map.version == ProjectVersion.v9 ||
          map.spatialScene != null) {
        throw StateError('Unavailable');
      }
      if (mounted && token == _request) setState(() => _map = map);
    } on Object {
      if (mounted && token == _request) {
        setState(() => _error = 'Carte indisponible. Les références enregistrées sont conservées.');
      }
    } finally {
      if (mounted && token == _request) setState(() => _loading = false);
    }
  }

  SceneSetNpcPoseConsequence? get _pose {
    if (_loading ||
        _error != null ||
        !_maps.containsKey(_mapId) ||
        !_actors.containsKey(_entityId)) {
      return null;
    }
    try {
      final facing = _facing == null || _facing!.isEmpty
          ? null
          : EntityFacing.values.byName(_facing!);
      if (_mode == 'facing') {
        return SceneConsequence.setNpcPose(
          mapId: _mapId!,
          entityId: _entityId!,
          facing: facing,
        ) as SceneSetNpcPoseConsequence;
      }
      final x = int.tryParse(_x), y = int.tryParse(_y);
      if (x == null || y == null) return null;
      final owner = _map!.entities.singleWhere(
        (entity) => entity.id == _entityId,
      );
      if (x + owner.size.width > _map!.size.width ||
          y + owner.size.height > _map!.size.height ||
          owner.presentation!.variants.any(
            (variant) =>
                x + variant.size.width > _map!.size.width ||
                y + variant.size.height > _map!.size.height,
          )) {
        return null;
      }
      return SceneConsequence.setNpcPose(
        mapId: _mapId!,
        entityId: _entityId!,
        x: x,
        y: y,
        facing: facing,
      ) as SceneSetNpcPoseConsequence;
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        label: 'Carte du PNJ',
        value: _mapId,
        options: _maps,
        onChanged: (value) => setState(() {
          _mapId = value;
          _entityId = null;
          _load();
        }),
      ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'PNJ à variantes',
        value: _entityId,
        options: _actors,
        onChanged: _loading
            ? null
            : (value) => setState(() => _entityId = value),
      ),
      if (_loading) const StudioNotice('Chargement des PNJ…'),
      if (_error != null) StudioNotice(_error!, isError: true),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Modification du PNJ',
        value: _mode,
        options: const {
          'position': 'Position et direction',
          'facing': 'Direction uniquement',
        },
        onChanged: (value) => setState(() => _mode = value),
      ),
      if (_mode == 'position') ...[
        const StudioNotice(
          'Le placement est réservé à un PNJ actuellement masqué.',
        ),
        StudioDraftField(
          label: 'Case X',
          value: _x,
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => _x = value),
        ),
        StudioDraftField(
          label: 'Case Y',
          value: _y,
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => _y = value),
        ),
      ] else
        const StudioNotice(
          'La position actuelle du PNJ est conservée, même si le PNJ est masqué.',
        ),
      const SizedBox(height: 12),
      StudioSelect(
        label: 'Direction du PNJ',
        value: _facing,
        options: {
          if (_mode == 'position') '': 'Conserver la direction',
          'south': 'Sud',
          'north': 'Nord',
          'east': 'Est',
          'west': 'Ouest',
        },
        onChanged: (value) => setState(() => _facing = value),
      ),
      const SizedBox(height: 12),
      StudioButton(
        label: widget.current == null
            ? 'Ajouter l’action'
            : 'Appliquer l’action',
        onPressed: _pose == null
            ? null
            : () => widget.onApply(SceneActionPayload.consequence(_pose!)),
      ),
    ],
  );
}
