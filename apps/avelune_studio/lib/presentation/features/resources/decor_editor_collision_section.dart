part of 'decor_editor_screen.dart';

extension _DecorEditorCollisionSection on _DecorEditorScreenState {
  Widget collisions(ProjectElementEntry result) {
    final problem = draft.collisionProblem;
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              label: 'Par case',
              icon: Icons.grid_on,
              secondary: fine,
              onPressed: problem != null
                  ? null
                  : () => _change(() => fine = false),
            ),
            StudioButton(
              label: 'Au pixel',
              icon: Icons.zoom_in,
              secondary: !fine,
              onPressed: problem != null
                  ? null
                  : () => _change(() => fine = true),
            ),
            StudioButton(
              label: 'Bloquer',
              icon: Icons.brush,
              secondary: erase,
              onPressed: problem != null
                  ? null
                  : () => _change(() => erase = false),
            ),
            StudioButton(
              label: 'Gomme',
              icon: Icons.auto_fix_normal,
              secondary: !erase,
              onPressed: problem != null
                  ? null
                  : () => _change(() => erase = true),
            ),
            StudioButton(
              label: 'Annuler le trait',
              icon: Icons.undo,
              secondary: true,
              onPressed: draft.canUndoCollision
                  ? () => _change(draft.undoCollision)
                  : null,
            ),
            StudioButton(
              label: 'Rétablir le trait',
              icon: Icons.redo,
              secondary: true,
              onPressed: draft.canRedoCollision
                  ? () => _change(draft.redoCollision)
                  : null,
            ),
          ],
        ),
        if (fine)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Text('Taille du pinceau'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: brushSize,
                  items: [
                    for (final size in [1, 2, 4, 8])
                      DropdownMenuItem(value: size, child: Text('$size px')),
                  ],
                  onChanged: (value) => _change(() => brushSize = value!),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (problem != null) ...[
          StudioNotice(problem),
          Expanded(
            child: StudioAssetPreview(
              child: widget.visuals.thumbnail(result, size: 320),
            ),
          ),
        ] else
          Expanded(
            child: DecorCollisionMask(
              width: draft.selection.width,
              height: draft.selection.height,
              tileWidth: draft.tileWidth,
              tileHeight: draft.tileHeight,
              blocked: {...draft.blocked},
              pixels: draft.collisionPixels,
              maskWidth: draft.pixelWidth,
              revision: draft.collisionRevision,
              fine: fine,
              erase: erase,
              brushSize: brushSize,
              image: widget.visuals.placementPreview(
                result,
                Size(
                  (draft.selection.width * draft.tileWidth).toDouble(),
                  (draft.selection.height * draft.tileHeight).toDouble(),
                ),
              ),
              onStrokeStart: draft.beginCollisionStroke,
              onStrokeEnd: () => _change(draft.endCollisionStroke),
              onStrokeCancel: () => _change(draft.cancelCollisionStroke),
              onPaint: (point) => _change(() {
                if (fine) {
                  draft.paintCollisionPixel(
                    point,
                    solid: !erase,
                    size: brushSize,
                  );
                } else {
                  draft.paintCollisionCell(point, solid: !erase);
                }
              }),
            ),
          ),
      ],
    );
  }
}
