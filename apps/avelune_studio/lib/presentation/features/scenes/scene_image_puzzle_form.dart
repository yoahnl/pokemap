import '../../../features/scenes/application/scene_image_puzzle_draft.dart';

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
  late final SceneImagePuzzleDraft draft;
  Widget? _imagePicker;
  int _imageRevision = -1, _page = 0;
  @override
  void initState() {
    super.initState();
    draft = SceneImagePuzzleDraft(
      current: widget.current,
      loadVisualMedia: widget.loadVisualMedia,
      changed: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(SceneImagePuzzleForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) _page = 0;
    draft.configure(
      current: widget.current,
      loadVisualMedia: widget.loadVisualMedia,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_imageRevision != draft.imageRevision) {
      _imageRevision = draft.imageRevision;
      _imagePicker = null;
    }
    final columns = draft.value['columns'] as int;
    final validGrid =
        (draft.value['rows'] as int) > 0 &&
        columns > 0 &&
        draft.count <= ImagePuzzleDefinition.maximumPieces &&
        (draft.value['trayCapacity'] as int) >= 0 &&
        (draft.value['trayCapacity'] as int) <=
            ImagePuzzleDefinition.maximumPieces;
    final pages = validGrid ? (draft.count / 16).ceil() : 1;
    final page = _page.clamp(0, pages - 1);
    final pieces = draft.pieces;
    final imageId = draft.value['imageResourceId'] as String;
    final definition = draft.definition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioDraftField(
          key: const ValueKey('puzzle-id'),
          label: 'Identité stable du puzzle',
          value: draft.value['puzzleId'] as String,
          onChanged: (value) => draft.change('puzzleId', value),
        ),
        _imagePicker ??= StudioSelect(
          key: const ValueKey('puzzle-image'),
          label: 'Image du puzzle',
          value: imageId.isEmpty ? null : imageId,
          options: {
            if (imageId.isNotEmpty && !draft.images.containsKey(imageId))
              imageId: 'Image enregistrée indisponible',
            ...draft.images,
          },
          onChanged: (value) => draft.change('imageResourceId', value),
        ),
        if (draft.mediaError != null)
          StudioNotice(draft.mediaError!, isError: true),
        if (draft.images.isEmpty)
          const StudioNotice(
            'Ajoutez une image à la médiathèque du projet pour créer ce puzzle.',
          ),
        StudioButton(
          label: 'Recharger les images',
          secondary: true,
          onPressed: () => setState(draft.load),
        ),
        for (final entry in {
          'rows': 'Lignes',
          'columns': 'Colonnes',
          'trayCapacity': 'Cases de réserve',
        }.entries)
          StudioDraftField(
            key: ValueKey('puzzle-${entry.key}'),
            label: entry.value,
            value: '${draft.value[entry.key]}',
            keyboardType: TextInputType.number,
            onChanged: (value) =>
                draft.change(entry.key, int.tryParse(value) ?? 0),
          ),
        StudioToggleRow(
          label: 'Autoriser le recommencement',
          value: draft.value['allowReset'] as bool,
          onChanged: (value) => draft.change('allowReset', value),
        ),
        StudioToggleRow(
          label: 'Autoriser les échanges',
          value: draft.value['allowSwap'] as bool,
          onChanged: (value) => draft.change('allowSwap', value),
        ),
        for (final turn in [1, 2, 3])
          StudioToggleRow(
            key: ValueKey('puzzle-rotation-$turn'),
            label: 'Rotation de ${turn * 90}°',
            value: draft.turns.contains(turn),
            onChanged: (enabled) {
              final turns = {...draft.turns};
              enabled ? turns.add(turn) : turns.remove(turn);
              draft.change('allowedQuarterTurns', turns.toList()..sort());
            },
          ),
        if (validGrid) ...[
          StudioToggleRow(
            key: const ValueKey('puzzle-initial-layout'),
            label: 'Choisir la disposition initiale',
            value: pieces != null,
            onChanged: (enabled) => setState(() {
              if (enabled) {
                draft.value['initialPieces'] = draft.initial();
              } else {
                draft.value.remove('initialPieces');
              }
            }),
          ),
          StudioSelect(
            label: 'Pièces affichées',
            value: '$page',
            options: {
              for (var i = 0; i < pages; i++)
                '$i': '${i * 16 + 1}–${((i + 1) * 16).clamp(1, draft.count)}',
            },
            onChanged: (next) => setState(() => _page = int.parse(next)),
          ),
          for (
            var id = page * 16;
            id < ((page + 1) * 16).clamp(0, draft.count);
            id++
          ) ...[
            StudioToggleRow(
              key: ValueKey('puzzle-piece-$id-fixed'),
              label:
                  'Fixer la pièce ${id + 1} · ligne ${id ~/ columns + 1}, colonne ${id % columns + 1}',
              value: draft.fixed.contains(id),
              onChanged: (enabled) {
                final fixed = {...draft.fixed};
                enabled ? fixed.add(id) : fixed.remove(id);
                setState(() {
                  draft.value['fixedPieceIds'] = fixed.toList()..sort();
                  if (pieces != null && enabled) {
                    draft.value['initialPieces'] = [
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
                    slot < draft.count + (draft.value['trayCapacity'] as int);
                    slot++
                  )
                    '$slot': slot < draft.count
                        ? 'Ligne ${slot ~/ columns + 1}, colonne ${slot % columns + 1}'
                        : 'Réserve ${slot - draft.count + 1}',
                },
                onChanged: (next) => draft.piece(id, 'slot', int.parse(next)),
              ),
              StudioSelect(
                label: 'Rotation initiale de la pièce ${id + 1}',
                value:
                    '${pieces.where((piece) => piece['pieceId'] == id).firstOrNull?['quarterTurns'] ?? 0}',
                options: {
                  for (var turn = 0; turn < 4; turn++) '$turn': '${turn * 90}°',
                },
                onChanged: (next) =>
                    draft.piece(id, 'quarterTurns', int.parse(next)),
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
