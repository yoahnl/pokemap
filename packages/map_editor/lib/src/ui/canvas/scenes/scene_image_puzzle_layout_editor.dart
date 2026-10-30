import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';

class SceneImagePuzzleLayoutEditor extends StatefulWidget {
  const SceneImagePuzzleLayoutEditor({
    super.key,
    required this.rows,
    required this.columns,
    required this.trayCapacity,
    required this.value,
    required this.onChanged,
  });

  final int rows, columns, trayCapacity;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  State<SceneImagePuzzleLayoutEditor> createState() =>
      _SceneImagePuzzleLayoutEditorState();
}

class _SceneImagePuzzleLayoutEditorState
    extends State<SceneImagePuzzleLayoutEditor> {
  var _page = 0;
  int get _count => widget.rows * widget.columns;
  List<int> get _fixed =>
      (widget.value['fixedPieceIds'] as List? ?? []).cast<int>();
  List<int> get _turns =>
      (widget.value['allowedQuarterTurns'] as List? ?? [0, 1, 2, 3])
          .cast<int>();
  List<Map<String, dynamic>>? get _pieces =>
      (widget.value['initialPieces'] as List?)
          ?.map((piece) => Map<String, dynamic>.from(piece as Map))
          .toList();

  void _change(String field, Object value) =>
      widget.onChanged({...widget.value, field: value});

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
              : widget.trayCapacity > 0
              ? _count
              : id,
          'quarterTurns':
              !_fixed.contains(id) &&
                  movable.length == 1 &&
                  widget.trayCapacity == 0 &&
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
    if (widget.rows < 1 ||
        widget.columns < 1 ||
        _count > ImagePuzzleDefinition.maximumPieces ||
        widget.trayCapacity < 0 ||
        widget.trayCapacity > ImagePuzzleDefinition.maximumPieces) {
      return const PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.warning,
        message:
            'Choisissez une grille de 1 à 1 024 pièces et une réserve de 0 à 1 024 cases.',
      );
    }
    final pages = (_count / 16).ceil();
    final page = _page.clamp(0, pages - 1);
    final pieces = _pieces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Rotations autorisées'),
        for (final turn in [1, 2, 3])
          PokeMapToggleTile(
            key: ValueKey('puzzle-rotation-$turn'),
            label: '${turn * 90}°',
            value: _turns.contains(turn),
            onChanged: (enabled) {
              final next = {..._turns};
              enabled ? next.add(turn) : next.remove(turn);
              _change('allowedQuarterTurns', next.toList()..sort());
            },
          ),
        PokeMapToggleTile(
          key: const ValueKey('puzzle-initial-layout'),
          label: 'Choisir la disposition initiale',
          value: pieces != null,
          onChanged: (enabled) {
            if (enabled) {
              _change('initialPieces', _initial());
            } else {
              widget.onChanged({...widget.value}..remove('initialPieces'));
            }
          },
        ),
        PokeMapDropdownField<int>(
          label: 'Pièces affichées',
          value: page,
          items: [
            for (var i = 0; i < pages; i++)
              PokeMapDropdownItem(
                value: i,
                label: '${i * 16 + 1}–${((i + 1) * 16).clamp(1, _count)}',
              ),
          ],
          onChanged: (next) => setState(() => _page = next),
        ),
        for (
          var id = page * 16;
          id < ((page + 1) * 16).clamp(0, _count);
          id++
        ) ...[
          PokeMapToggleTile(
            key: ValueKey('puzzle-piece-$id-fixed'),
            label:
                'Fixer la pièce ${id + 1} · ligne ${id ~/ widget.columns + 1}, colonne ${id % widget.columns + 1}',
            value: _fixed.contains(id),
            onChanged: (enabled) {
              final fixed = {..._fixed};
              enabled ? fixed.add(id) : fixed.remove(id);
              widget.onChanged({
                ...widget.value,
                'fixedPieceIds': fixed.toList()..sort(),
                if (pieces != null)
                  'initialPieces': [
                    for (final piece in pieces)
                      if (enabled && piece['pieceId'] == id)
                        {...piece, 'slot': id, 'quarterTurns': 0}
                      else
                        piece,
                  ],
              });
            },
          ),
          if (pieces != null) ...[
            PokeMapDropdownField<int>(
              key: ValueKey('puzzle-piece-$id-slot'),
              label: 'Position initiale de la pièce ${id + 1}',
              value:
                  pieces
                          .where((piece) => piece['pieceId'] == id)
                          .firstOrNull?['slot']
                      as int? ??
                  id,
              items: [
                for (var slot = 0; slot < _count + widget.trayCapacity; slot++)
                  PokeMapDropdownItem(
                    value: slot,
                    label: slot < _count
                        ? 'Ligne ${slot ~/ widget.columns + 1}, colonne ${slot % widget.columns + 1}'
                        : 'Réserve ${slot - _count + 1}',
                  ),
              ],
              onChanged: (slot) => _piece(id, 'slot', slot),
            ),
            PokeMapDropdownField<int>(
              label: 'Rotation initiale de la pièce ${id + 1}',
              value:
                  pieces
                          .where((piece) => piece['pieceId'] == id)
                          .firstOrNull?['quarterTurns']
                      as int? ??
                  0,
              items: [
                for (var turn = 0; turn < 4; turn++)
                  PokeMapDropdownItem(value: turn, label: '${turn * 90}°'),
              ],
              onChanged: (turn) => _piece(id, 'quarterTurns', turn),
            ),
          ],
        ],
      ],
    );
  }
}
