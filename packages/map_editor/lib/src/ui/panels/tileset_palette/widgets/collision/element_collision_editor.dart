part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// The collision editor owns a dense cluster of local widgets, modes, and
// affordances. Keeping them together in a dedicated part file makes the main
// palette panel easier to scan while preserving the existing private API.

class _ElementCollisionProfileSummaryCard extends StatelessWidget {
  const _ElementCollisionProfileSummaryCard({
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onOpenEditor,
    required this.onClearProfile,
  });

  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final VoidCallback onOpenEditor;
  final VoidCallback onClearProfile;

  @override
  Widget build(BuildContext context) {
    final snapshot = _elementCollisionAuthoringService.describe(
      source: source,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      profile: profile,
      fallbackPadding: draftPadding,
    );
    final truthSummary = summarizeElementCollisionTruth(profile);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Collision de l’élément',
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _CollisionTruthInline(summary: truthSummary),
          const SizedBox(height: 6),
          Text(
            snapshot.usesManualPrimaryShape
                ? 'Forme principale auteur active. Le polygone définit la base coarse ; les retouches la corrigent.'
                : 'Base padding automatique active. Le polygone peut remplacer cette base coarse pour définir une silhouette de bâtiment.',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionLegendChip(
                label: snapshot.usesManualPrimaryShape
                    ? 'Forme ${snapshot.baseCells.length}'
                    : 'Base ${snapshot.baseCells.length}',
                color: Colors.cyanAccent,
              ),
              _CollisionLegendChip(
                label: '+ ${snapshot.manualAddedCells.length}',
                color: Colors.greenAccent,
              ),
              _CollisionLegendChip(
                label: '- ${snapshot.manualRemovedCells.length}',
                color: Colors.redAccent,
              ),
              _CollisionLegendChip(
                label: 'Final ${snapshot.finalCells.length}',
                color: EditorChrome.inspectorJoyCoral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PushButton(
                  controlSize: ControlSize.regular,
                  secondary: true,
                  onPressed: onOpenEditor,
                  child: const Text('Ouvrir l’éditeur de collision'),
                ),
              ),
              const SizedBox(width: 8),
              PushButton(
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: onClearProfile,
                child: const Text('Effacer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElementCollisionProfileEditor extends StatefulWidget {
  const _ElementCollisionProfileEditor({
    required this.image,
    required this.source,
    required this.tileWidth,
    required this.tileHeight,
    required this.profile,
    required this.draftPadding,
    required this.onProfileChanged,
  });

  final ui.Image image;
  final TilesetSourceRect source;
  final int tileWidth;
  final int tileHeight;
  final ElementCollisionProfile? profile;
  final WarpTriggerPadding draftPadding;
  final ValueChanged<ElementCollisionProfile?> onProfileChanged;

  @override
  State<_ElementCollisionProfileEditor> createState() =>
      _ElementCollisionProfileEditorState();
}

class _ElementCollisionProfileEditorState
    extends State<_ElementCollisionProfileEditor> {
  _ElementCollisionPaintMode _paintMode = _ElementCollisionPaintMode.preview;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final snapshot = _elementCollisionAuthoringService.describe(
      source: widget.source,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      profile: widget.profile,
      fallbackPadding: widget.draftPadding,
    );
    final truthSummary = summarizeElementCollisionTruth(widget.profile);
    final padding = snapshot.padding;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Collision par cases',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${snapshot.finalCells.length} cellule${snapshot.finalCells.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Padding px: T${padding.top} R${padding.right} B${padding.bottom} L${padding.left}',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Édition grille / forme coarse. Si un masque fin existe, le gameplay l’utilise d’abord.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          _CollisionTruthInline(summary: truthSummary),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionLegendChip(
                label: 'Base ${snapshot.baseCells.length}',
                color: Colors.cyanAccent,
              ),
              _CollisionLegendChip(
                label: '+ Ajouts ${snapshot.manualAddedCells.length}',
                color: Colors.greenAccent,
              ),
              _CollisionLegendChip(
                label: '- Retraits ${snapshot.manualRemovedCells.length}',
                color: Colors.redAccent,
              ),
              _CollisionLegendChip(
                label: 'Final ${snapshot.finalCells.length}',
                color: EditorChrome.inspectorJoyCoral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _CollisionModeButton(
                  label: 'Apercu',
                  selected: _paintMode == _ElementCollisionPaintMode.preview,
                  onPressed: () => setState(
                    () => _paintMode = _ElementCollisionPaintMode.preview,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CollisionModeButton(
                  label: 'Ajouter',
                  selected: _paintMode == _ElementCollisionPaintMode.add,
                  onPressed: () => setState(
                    () => _paintMode = _ElementCollisionPaintMode.add,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CollisionModeButton(
                  label: 'Retirer',
                  selected: _paintMode == _ElementCollisionPaintMode.remove,
                  onPressed: () => setState(
                    () => _paintMode = _ElementCollisionPaintMode.remove,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionActionButton(
                label: 'Reinitialiser retouches',
                onPressed: () {
                  widget.onProfileChanged(
                    _elementCollisionAuthoringService.resetOverrides(
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                      current: widget.profile,
                      fallbackPadding: widget.draftPadding,
                    ),
                  );
                },
              ),
              _CollisionActionButton(
                label: 'Restaurer base seule',
                onPressed: () {
                  widget.onProfileChanged(
                    _elementCollisionAuthoringService.resetOverrides(
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                      current: widget.profile,
                      fallbackPadding: widget.draftPadding,
                    ),
                  );
                },
              ),
              _CollisionActionButton(
                label: 'Vider toute la collision',
                onPressed: () {
                  widget.onProfileChanged(
                    _elementCollisionAuthoringService.clearAllCollision(
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                      current: widget.profile,
                      fallbackPadding: widget.draftPadding,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final boxHeight = math
                  .min(210, constraints.maxWidth * 0.72)
                  .toDouble()
                  .clamp(120.0, 210.0);
              return SizedBox(
                height: boxHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    if (_paintMode == _ElementCollisionPaintMode.preview) {
                      return;
                    }
                    final local = details.localPosition;
                    final size = Size(constraints.maxWidth, boxHeight);
                    final targetRect = _fitCollisionPreviewRect(
                      size: size,
                      source: widget.source,
                      tileWidth: widget.tileWidth,
                      tileHeight: widget.tileHeight,
                    );
                    if (!targetRect.contains(local)) {
                      return;
                    }
                    final localX = local.dx - targetRect.left;
                    final localY = local.dy - targetRect.top;
                    final cellWidth = targetRect.width / widget.source.width;
                    final cellHeight = targetRect.height / widget.source.height;
                    final cellX = (localX / cellWidth)
                        .floor()
                        .clamp(0, widget.source.width - 1);
                    final cellY = (localY / cellHeight)
                        .floor()
                        .clamp(0, widget.source.height - 1);
                    final tappedCell = GridPos(x: cellX, y: cellY);
                    final next = switch (_paintMode) {
                      _ElementCollisionPaintMode.add =>
                        _elementCollisionAuthoringService.applyAddModeTap(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          cell: tappedCell,
                          current: widget.profile,
                          fallbackPadding: widget.draftPadding,
                        ),
                      _ElementCollisionPaintMode.remove =>
                        _elementCollisionAuthoringService.applyRemoveModeTap(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          cell: tappedCell,
                          current: widget.profile,
                          fallbackPadding: widget.draftPadding,
                        ),
                      _ElementCollisionPaintMode.preview =>
                        _elementCollisionAuthoringService
                            .recalculateFromPadding(
                          source: widget.source,
                          tileWidth: widget.tileWidth,
                          tileHeight: widget.tileHeight,
                          padding: padding,
                          current: widget.profile,
                        ),
                    };
                    widget.onProfileChanged(next);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: CustomPaint(
                      painter: _ElementCollisionProfilePainter(
                        image: widget.image,
                        source: widget.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                        padding: padding,
                        baseCells: snapshot.baseCells,
                        manualAddedCells: snapshot.manualAddedCells,
                        manualRemovedCells: snapshot.manualRemovedCells,
                        finalCells: snapshot.finalCells,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            switch (_paintMode) {
              _ElementCollisionPaintMode.preview =>
                'Apercu uniquement. Passe en mode Ajouter ou Retirer pour peindre les cellules.',
              _ElementCollisionPaintMode.add =>
                'Mode ajout: clique une case pour l’ajouter explicitement a la collision.',
              _ElementCollisionPaintMode.remove =>
                'Mode retrait: clique une case pour la retirer explicitement de la collision.',
            },
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollisionLegendChip extends StatelessWidget {
  const _CollisionLegendChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CollisionTruthInline extends StatelessWidget {
  const _CollisionTruthInline({required this.summary});

  final ElementCollisionTruthSummary summary;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final accent = switch (summary.mode) {
      ElementCollisionTruthMode.fineMask => Colors.redAccent,
      ElementCollisionTruthMode.legacyCells => Colors.orangeAccent,
      ElementCollisionTruthMode.empty => Colors.greenAccent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            summary.title,
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${summary.description} ${summary.detail}',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          for (final note in summary.notes) ...[
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(color: secondary, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _CollisionModeButton extends StatelessWidget {
  const _CollisionModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCoral;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      minimumSize: Size.zero,
      onPressed: onPressed,
      color: selected ? accent.withValues(alpha: 0.18) : Colors.black26,
      borderRadius: BorderRadius.circular(8),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? accent : labelColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CollisionActionButton extends StatelessWidget {
  const _CollisionActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PushButton(
      controlSize: ControlSize.small,
      secondary: true,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

// ignore: unused_element
class _ElementCollisionPaddingEditor extends StatelessWidget {
  const _ElementCollisionPaddingEditor({
    required this.padding,
    required this.maxHorizontal,
    required this.maxVertical,
    required this.onChanged,
  });

  final WarpTriggerPadding padding;
  final int maxHorizontal;
  final int maxVertical;
  final ValueChanged<WarpTriggerPadding> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.01),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Padding collision (px)',
            style: TextStyle(
              color: label,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ajuste l’auto-génération puis affine manuellement si besoin.',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CollisionPaddingStepper(
                label: 'Top',
                value: padding.top,
                maxValue: maxVertical,
                onChanged: (v) => onChanged(padding.copyWith(top: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Right',
                value: padding.right,
                maxValue: maxHorizontal,
                onChanged: (v) => onChanged(padding.copyWith(right: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Bottom',
                value: padding.bottom,
                maxValue: maxVertical,
                onChanged: (v) => onChanged(padding.copyWith(bottom: v)),
              ),
              _CollisionPaddingStepper(
                label: 'Left',
                value: padding.left,
                maxValue: maxHorizontal,
                onChanged: (v) => onChanged(padding.copyWith(left: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollisionPaddingStepper extends StatelessWidget {
  const _CollisionPaddingStepper({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canDecrease = value > 0;
    final canIncrease = value < maxValue;
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: canDecrease ? () => onChanged(value - 1) : null,
                child: Icon(
                  CupertinoIcons.minus_circle_fill,
                  size: 16,
                  color: canDecrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: canIncrease ? () => onChanged(value + 1) : null,
                child: Icon(
                  CupertinoIcons.plus_circle_fill,
                  size: 16,
                  color: canIncrease
                      ? labelColor
                      : labelColor.withValues(alpha: 0.25),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
