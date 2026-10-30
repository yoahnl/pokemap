import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class SceneImagePuzzleForm extends StatefulWidget {
  const SceneImagePuzzleForm({
    super.key,
    required this.current,
    required this.onApply,
    this.loadVisualMedia,
  });
  final SceneOpenImagePuzzleInteractiveCommand? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<ProjectMediaCatalog> Function()? loadVisualMedia;

  @override
  State<SceneImagePuzzleForm> createState() => _SceneImagePuzzleFormState();
}

class _SceneImagePuzzleFormState extends State<SceneImagePuzzleForm> {
  late Map<String, dynamic> _value;
  Map<String, String> _images = const {};
  Widget? _imagePicker;
  String? _mediaError;
  var _request = 0;
  var _page = 0;
  int get _count => (_value['rows'] as int) * (_value['columns'] as int);
  List<int> get _fixed => (_value['fixedPieceIds'] as List).cast<int>();
  List<int> get _turns => (_value['allowedQuarterTurns'] as List).cast<int>();
  List<Map<String, dynamic>>? get _pieces => (_value['initialPieces'] as List?)
      ?.map((piece) => Map<String, dynamic>.from(piece as Map))
      .toList();

  @override
  void initState() {
    super.initState();
    _read();
    _load();
  }

  @override
  void didUpdateWidget(SceneImagePuzzleForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) _read();
    if (oldWidget.loadVisualMedia != widget.loadVisualMedia) _load();
  }

  void _read() {
    _imagePicker = null;
    _value =
        widget.current?.definition.toJson() ??
        {
          'schemaVersion': 1,
          'puzzleId': '',
          'imageResourceId': '',
          'rows': 4,
          'columns': 4,
          'trayCapacity': 1,
          'allowedQuarterTurns': [0, 1, 2, 3],
          'fixedPieceIds': <int>[],
          'allowReset': true,
          'allowSwap': false,
        };
    _page = 0;
  }

  Future<void> _load() async {
    final request = ++_request;
    _images = const {};
    _imagePicker = null;
    _mediaError = null;
    final load = widget.loadVisualMedia;
    if (load == null) return;
    try {
      final media = await load();
      if (mounted && request == _request) {
        setState(() {
          _imagePicker = null;
          _images = {
            for (final entry in media.entries)
              if (entry.kind == ProjectMediaKind.image) entry.id: entry.label,
          };
        });
      }
    } on Object {
      if (mounted && request == _request) {
        setState(
          () => _mediaError = 'La médiathèque est indisponible. Rechargez-la avant d’appliquer.',
        );
      }
    }
  }

  ImagePuzzleDefinition? get _definition {
    if (!_images.containsKey(_value['imageResourceId'])) return null;
    try {
      return ImagePuzzleDefinition.fromJson(_value);
    } on Object {
      return null;
    }
  }

  void _change(String field, Object value) => setState(() {
    if (field == 'imageResourceId') _imagePicker = null;
    _value[field] = value;
  });

  List<Map<String, dynamic>> _initial() {
    final movable = [
      for (var id = 0; id < _count; id++)
        if (!_fixed.contains(id)) id,
    ];
    return [
      for (var id = 0; id < _count; id++)
        {
          'pieceId': id,
          'slot': _fixed.contains(id)
              ? id
              : movable.length > 1
              ? movable[(movable.indexOf(id) + 1) % movable.length]
              : (_value['trayCapacity'] as int) > 0
              ? _count
              : id,
          'quarterTurns':
              !_fixed.contains(id) &&
                  movable.length == 1 &&
                  _value['trayCapacity'] == 0 &&
                  _turns.length > 1
              ? _turns.last
              : 0,
        },
    ];
  }

  void _piece(int id, String field, int value) => _change('initialPieces', [
    for (final piece in _pieces!)
      piece['pieceId'] == id ? {...piece, field: value} : piece,
  ]);

  @override
  Widget build(BuildContext context) {
    final columns = _value['columns'] as int;
    final validGrid =
        (_value['rows'] as int) > 0 &&
        columns > 0 &&
        _count <= ImagePuzzleDefinition.maximumPieces &&
        (_value['trayCapacity'] as int) >= 0 &&
        (_value['trayCapacity'] as int) <= ImagePuzzleDefinition.maximumPieces;
    final pages = validGrid ? (_count / 16).ceil() : 1;
    final page = _page.clamp(0, pages - 1);
    final pieces = _pieces;
    final imageId = _value['imageResourceId'] as String;
    final definition = _definition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioDraftField(
          key: const ValueKey('puzzle-id'),
          label: 'Identité stable du puzzle',
          value: _value['puzzleId'] as String,
          onChanged: (value) => _change('puzzleId', value),
        ),
        _imagePicker ??= StudioSelect(
          key: const ValueKey('puzzle-image'),
          label: 'Image du puzzle',
          value: imageId.isEmpty ? null : imageId,
          options: {
            if (imageId.isNotEmpty && !_images.containsKey(imageId))
              imageId: 'Image enregistrée indisponible',
            ..._images,
          },
          onChanged: (value) => _change('imageResourceId', value),
        ),
        if (_mediaError != null) StudioNotice(_mediaError!, isError: true),
        if (_images.isEmpty)
          const StudioNotice(
            'Ajoutez une image à la médiathèque du projet pour créer ce puzzle.',
          ),
        StudioButton(
          label: 'Recharger les images',
          secondary: true,
          onPressed: () => setState(_load),
        ),
        for (final entry in {
          'rows': 'Lignes',
          'columns': 'Colonnes',
          'trayCapacity': 'Cases de réserve',
        }.entries)
          StudioDraftField(
            key: ValueKey('puzzle-${entry.key}'),
            label: entry.value,
            value: '${_value[entry.key]}',
            keyboardType: TextInputType.number,
            onChanged: (value) => _change(entry.key, int.tryParse(value) ?? 0),
          ),
        StudioToggleRow(
          label: 'Autoriser le recommencement',
          value: _value['allowReset'] as bool,
          onChanged: (value) => _change('allowReset', value),
        ),
        StudioToggleRow(
          label: 'Autoriser les échanges',
          value: _value['allowSwap'] as bool,
          onChanged: (value) => _change('allowSwap', value),
        ),
        for (final turn in [1, 2, 3])
          StudioToggleRow(
            key: ValueKey('puzzle-rotation-$turn'),
            label: 'Rotation de ${turn * 90}°',
            value: _turns.contains(turn),
            onChanged: (enabled) {
              final turns = {..._turns};
              enabled ? turns.add(turn) : turns.remove(turn);
              _change('allowedQuarterTurns', turns.toList()..sort());
            },
          ),
        if (validGrid) ...[
          StudioToggleRow(
            key: const ValueKey('puzzle-initial-layout'),
            label: 'Choisir la disposition initiale',
            value: pieces != null,
            onChanged: (enabled) => setState(() {
              if (enabled) {
                _value['initialPieces'] = _initial();
              } else {
                _value.remove('initialPieces');
              }
            }),
          ),
          StudioSelect(
            label: 'Pièces affichées',
            value: '$page',
            options: {
              for (var i = 0; i < pages; i++)
                '$i': '${i * 16 + 1}–${((i + 1) * 16).clamp(1, _count)}',
            },
            onChanged: (next) => setState(() => _page = int.parse(next)),
          ),
          for (
            var id = page * 16;
            id < ((page + 1) * 16).clamp(0, _count);
            id++
          ) ...[
            StudioToggleRow(
              key: ValueKey('puzzle-piece-$id-fixed'),
              label:
                  'Fixer la pièce ${id + 1} · ligne ${id ~/ columns + 1}, colonne ${id % columns + 1}',
              value: _fixed.contains(id),
              onChanged: (enabled) {
                final fixed = {..._fixed};
                enabled ? fixed.add(id) : fixed.remove(id);
                setState(() {
                  _value['fixedPieceIds'] = fixed.toList()..sort();
                  if (pieces != null && enabled) {
                    _value['initialPieces'] = [
                      for (final piece in pieces)
                        piece['pieceId'] == id
                            ? {...piece, 'slot': id, 'quarterTurns': 0}
                            : piece,
                    ];
                  }
                });
              },
            ),
            if (pieces != null) ...[
              StudioSelect(
                key: ValueKey('puzzle-piece-$id-slot'),
                label: 'Position initiale de la pièce ${id + 1}',
                value:
                    '${pieces.where((piece) => piece['pieceId'] == id).firstOrNull?['slot'] ?? id}',
                options: {
                  for (
                    var slot = 0;
                    slot < _count + (_value['trayCapacity'] as int);
                    slot++
                  )
                    '$slot': slot < _count
                        ? 'Ligne ${slot ~/ columns + 1}, colonne ${slot % columns + 1}'
                        : 'Réserve ${slot - _count + 1}',
                },
                onChanged: (next) => _piece(id, 'slot', int.parse(next)),
              ),
              StudioSelect(
                label: 'Rotation initiale de la pièce ${id + 1}',
                value:
                    '${pieces.where((piece) => piece['pieceId'] == id).firstOrNull?['quarterTurns'] ?? 0}',
                options: {
                  for (var turn = 0; turn < 4; turn++) '$turn': '${turn * 90}°',
                },
                onChanged: (next) =>
                    _piece(id, 'quarterTurns', int.parse(next)),
              ),
            ],
          ],
        ],
        if (definition == null)
          const StudioNotice(
            'Choisissez une image et une identité, une grille de 1 à 1 024 pièces, puis une disposition non résolue sans doublons, respectant les pièces fixes et les rotations. Sans réserve, activez les échanges.',
            isError: true,
          ),
        StudioButton(
          key: const ValueKey('puzzle-apply'),
          label: widget.current == null
              ? 'Ajouter l’action'
              : 'Appliquer l’action',
          onPressed: definition == null
              ? null
              : () => widget.onApply(
                  SceneActionPayload.interactive(
                    SceneInteractiveCommand.openImagePuzzle(
                      definition: definition,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
