part of 'package:map_editor/src/ui/panels/terrain_editor_panel.dart';

// The path-mapping workspace, its painters, and the lightweight tileset cache
// are extracted together because they form one cohesive visual subsystem.
// Keeping them in a dedicated part file makes the library panel easier to read
// without changing runtime behavior.

class _PathVariantFramesEditor extends StatefulWidget {
  const _PathVariantFramesEditor({
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.frames,
    required this.onChanged,
    required this.onPickFrame,
  });

  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final List<TilesetVisualFrame> frames;
  final ValueChanged<List<TilesetVisualFrame>> onChanged;
  final Future<TilesetSourceRect?> Function(TilesetSourceRect initial)
      onPickFrame;

  @override
  State<_PathVariantFramesEditor> createState() =>
      _PathVariantFramesEditorState();
}

class _PathVariantFramesEditorState extends State<_PathVariantFramesEditor> {
  late final Stopwatch _previewStopwatch;
  Timer? _previewTimer;
  final TextEditingController _durationCtrl = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _previewStopwatch = Stopwatch()..start();
    _previewTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    _syncDurationControl();
  }

  @override
  void didUpdateWidget(covariant _PathVariantFramesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frames.isEmpty) {
      _selectedIndex = 0;
      _durationCtrl.text = '';
      return;
    }
    if (_selectedIndex >= widget.frames.length) {
      _selectedIndex = widget.frames.length - 1;
    }
    _syncDurationControl();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _syncDurationControl() {
    if (widget.frames.isEmpty || _selectedIndex >= widget.frames.length) {
      _durationCtrl.text = '';
      return;
    }
    final duration = widget.frames[_selectedIndex].durationMs ??
        defaultPlacedElementAnimationFrameDurationMs;
    _durationCtrl.text = '$duration';
  }

  void _emitFrames(List<TilesetVisualFrame> nextFrames) {
    widget.onChanged(List<TilesetVisualFrame>.unmodifiable(nextFrames));
    if (nextFrames.isEmpty) {
      _selectedIndex = 0;
      _durationCtrl.text = '';
      return;
    }
    if (_selectedIndex >= nextFrames.length) {
      _selectedIndex = nextFrames.length - 1;
    }
    _syncDurationControl();
  }

  int _resolvePreviewFrameIndex() {
    final frames = widget.frames;
    if (frames.isEmpty || frames.length == 1) {
      return 0;
    }
    final durations = normalizeElementFrameDurationsMs(
      frames.map((frame) => frame.durationMs).toList(growable: false),
    );
    final index = resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: durations,
      elapsedMs: _previewStopwatch.elapsedMilliseconds.toDouble(),
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: true,
        speed: 1.0,
      ),
    );
    return index.clamp(0, frames.length - 1);
  }

  Future<void> _addFrame() async {
    final frames = widget.frames;
    final initial = frames.isNotEmpty
        ? frames[_selectedIndex.clamp(0, frames.length - 1)].source
        : const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1);
    final picked = await widget.onPickFrame(initial);
    if (picked == null) {
      return;
    }
    final duration = frames.isNotEmpty
        ? (frames[_selectedIndex.clamp(0, frames.length - 1)].durationMs ??
                defaultPlacedElementAnimationFrameDurationMs)
            .clamp(1, 99999)
        : defaultPlacedElementAnimationFrameDurationMs;
    final frame = TilesetVisualFrame(
      source: TilesetSourceRect(
        x: picked.x,
        y: picked.y,
        width: 1,
        height: 1,
      ),
      durationMs: duration,
    );
    final nextFrames = <TilesetVisualFrame>[...frames, frame];
    setState(() {
      _selectedIndex = nextFrames.length - 1;
    });
    _emitFrames(nextFrames);
  }

  void _duplicateFrame() {
    final frames = widget.frames;
    if (frames.isEmpty || _selectedIndex >= frames.length) {
      return;
    }
    final nextFrames = <TilesetVisualFrame>[
      ...frames.take(_selectedIndex + 1),
      frames[_selectedIndex].copyWith(),
      ...frames.skip(_selectedIndex + 1),
    ];
    setState(() {
      _selectedIndex = _selectedIndex + 1;
    });
    _emitFrames(nextFrames);
  }

  void _deleteSelectedFrame() {
    final frames = widget.frames;
    if (frames.isEmpty || _selectedIndex >= frames.length) {
      return;
    }
    final nextFrames = <TilesetVisualFrame>[
      ...frames.take(_selectedIndex),
      ...frames.skip(_selectedIndex + 1),
    ];
    final nextIndex = nextFrames.isEmpty
        ? 0
        : math.min(_selectedIndex, nextFrames.length - 1);
    setState(() {
      _selectedIndex = nextIndex;
    });
    _emitFrames(nextFrames);
  }

  void _moveSelectedFrame(int delta) {
    final frames = widget.frames;
    if (frames.length <= 1) {
      return;
    }
    final current = _selectedIndex;
    final next = current + delta;
    if (current < 0 || current >= frames.length) {
      return;
    }
    if (next < 0 || next >= frames.length) {
      return;
    }
    final mutable = List<TilesetVisualFrame>.from(frames);
    final frame = mutable.removeAt(current);
    mutable.insert(next, frame);
    setState(() {
      _selectedIndex = next;
    });
    _emitFrames(mutable);
  }

  void _clearExtraFrames() {
    final frames = widget.frames;
    if (frames.length <= 1) {
      return;
    }
    setState(() {
      _selectedIndex = 0;
    });
    _emitFrames([frames.first]);
  }

  void _setSelectedDuration(int durationMs) {
    final frames = widget.frames;
    if (frames.isEmpty || _selectedIndex >= frames.length) {
      return;
    }
    final clamped = durationMs.clamp(1, 99999);
    final mutable = List<TilesetVisualFrame>.from(frames);
    mutable[_selectedIndex] = mutable[_selectedIndex].copyWith(
      durationMs: clamped,
    );
    _emitFrames(mutable);
  }

  void _applyDurationInput() {
    final parsed = int.tryParse(_durationCtrl.text.trim());
    if (parsed == null) {
      _syncDurationControl();
      return;
    }
    _setSelectedDuration(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.frames;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canEdit = frames.isNotEmpty;
    final selectedIndex =
        canEdit ? _selectedIndex.clamp(0, frames.length - 1) : 0;
    final previewFrame = canEdit ? frames[_resolvePreviewFrameIndex()] : null;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: EditorPaintColors.blueGrey.withValues(alpha: 0.16),
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
                  'Variant animation',
                  style: TextStyle(
                    fontSize: 11,
                    color: label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${frames.length} frame${frames.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 10, color: secondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (previewFrame == null)
            Text(
              'No frame yet. Click the tileset or add a frame.',
              style: TextStyle(fontSize: 10, color: secondary),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CustomPaint(
                        painter: _PathSlotPreviewPainter(
                          image: widget.image,
                          sourceTileWidth: widget.sourceTileWidth,
                          sourceTileHeight: widget.sourceTileHeight,
                          source: previewFrame.source,
                          selected: true,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    frames.length > 1 ? 'Animated preview' : 'Static preview',
                    style: TextStyle(fontSize: 10, color: secondary),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: _addFrame,
                child: const Text('Add frame'),
              ),
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: canEdit ? _duplicateFrame : null,
                child: const Text('Duplicate'),
              ),
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: canEdit ? _deleteSelectedFrame : null,
                child: const Text('Delete'),
              ),
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: frames.length > 1 ? _clearExtraFrames : null,
                child: const Text('Clear extras'),
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: frames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final frame = frames[index];
                  final selected = index == selectedIndex;
                  final duration = frame.durationMs ??
                      defaultPlacedElementAnimationFrameDurationMs;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        _syncDurationControl();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 62,
                      decoration: BoxDecoration(
                        color: selected
                            ? EditorPaintColors.orange.withValues(alpha: 0.14)
                            : EditorPaintColors.white10,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected
                              ? EditorPaintColors.orange
                              : EditorPaintColors.white24,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: CustomPaint(
                                painter: _PathSlotPreviewPainter(
                                  image: widget.image,
                                  sourceTileWidth: widget.sourceTileWidth,
                                  sourceTileHeight: widget.sourceTileHeight,
                                  source: frame.source,
                                  selected: selected,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${duration}ms',
                              style: const TextStyle(
                                fontSize: 9,
                                color: EditorPaintColors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Frame ${selectedIndex + 1}/${frames.length}',
                  style: TextStyle(fontSize: 10, color: secondary),
                ),
                const Spacer(),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.arrow_left,
                  iconSize: 13,
                  onPressed:
                      frames.length > 1 ? () => _moveSelectedFrame(-1) : null,
                  tooltip: 'Move left',
                ),
                EditorToolbarIconButton(
                  icon: CupertinoIcons.arrow_right,
                  iconSize: 13,
                  onPressed:
                      frames.length > 1 ? () => _moveSelectedFrame(1) : null,
                  tooltip: 'Move right',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 26,
                  child: CupertinoTextField(
                    controller: _durationCtrl,
                    placeholder: 'ms',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    onSubmitted: (_) => _applyDurationInput(),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ms',
                  style:
                      TextStyle(fontSize: 11, color: EditorPaintColors.white54),
                ),
                const SizedBox(width: 6),
                PushButton(
                  controlSize: ControlSize.small,
                  secondary: true,
                  onPressed: _applyDurationInput,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animation trigger helpers (moved to terrain_map_panel.dart)
// ---------------------------------------------------------------------------
// The animation triggers UI has been moved to terrain_map_panel.dart
// to be displayed in the right Paths tile.
// The following helper functions are kept for backward compatibility
// but are no longer used in this file.

class _PathSchemaCanvas extends StatelessWidget {
  const _PathSchemaCanvas({
    required this.mappings,
    required this.selectedVariant,
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.onSelect,
  });

  final Map<TerrainPathVariant, List<TilesetVisualFrame>> mappings;
  final TerrainPathVariant selectedVariant;
  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final ValueChanged<TerrainPathVariant> onSelect;

  static const List<TerrainPathVariant> _mainSquareVariants =
      <TerrainPathVariant>[
    TerrainPathVariant.cornerSE,
    TerrainPathVariant.endSouth,
    TerrainPathVariant.cornerSW,
    TerrainPathVariant.endEast,
    TerrainPathVariant.cross,
    TerrainPathVariant.endWest,
    TerrainPathVariant.cornerNE,
    TerrainPathVariant.endNorth,
    TerrainPathVariant.cornerNW,
  ];

  static const List<TerrainPathVariant> _innerCornerVariants =
      <TerrainPathVariant>[
    TerrainPathVariant.innerCornerSE,
    TerrainPathVariant.innerCornerSW,
    TerrainPathVariant.innerCornerNE,
    TerrainPathVariant.innerCornerNW,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final cellByWidth = (maxWidth - gap) / 5;
        final cellByHeight = maxHeight / 3;
        final cell = math.max(30.0, math.min(cellByWidth, cellByHeight));
        final bigSize = cell * 3;
        final smallSize = cell * 2;
        final totalWidth = bigSize + gap + smallSize;
        final offsetX = math.max(0.0, (maxWidth - totalWidth) / 2);
        final offsetY = math.max(0.0, (maxHeight - bigSize) / 2);

        return Stack(
          children: [
            Positioned(
              left: offsetX,
              top: offsetY,
              width: bigSize,
              height: bigSize,
              child: _PathSchemaGridSection(
                columns: 3,
                variants: _mainSquareVariants,
                mappings: mappings,
                selectedVariant: selectedVariant,
                image: image,
                sourceTileWidth: sourceTileWidth,
                sourceTileHeight: sourceTileHeight,
                onSelect: onSelect,
              ),
            ),
            Positioned(
              left: offsetX + bigSize + gap,
              top: offsetY + (bigSize - smallSize) / 2,
              width: smallSize,
              height: smallSize,
              child: _PathSchemaGridSection(
                columns: 2,
                variants: _innerCornerVariants,
                mappings: mappings,
                selectedVariant: selectedVariant,
                image: image,
                sourceTileWidth: sourceTileWidth,
                sourceTileHeight: sourceTileHeight,
                onSelect: onSelect,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PathSchemaGridSection extends StatelessWidget {
  const _PathSchemaGridSection({
    required this.columns,
    required this.variants,
    required this.mappings,
    required this.selectedVariant,
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.onSelect,
  });

  final int columns;
  final List<TerrainPathVariant> variants;
  final Map<TerrainPathVariant, List<TilesetVisualFrame>> mappings;
  final TerrainPathVariant selectedVariant;
  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final ValueChanged<TerrainPathVariant> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        childAspectRatio: 1,
      ),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        final variant = variants[index];
        final isSelected = variant == selectedVariant;
        final mappedSource = _pathMappingPrimarySource(mappings[variant]);
        return _PathSchemaGridSlot(
          variant: variant,
          selected: isSelected,
          mappedSource: mappedSource,
          image: image,
          sourceTileWidth: sourceTileWidth,
          sourceTileHeight: sourceTileHeight,
          onTap: () => onSelect(variant),
        );
      },
    );
  }
}

class _PathSchemaGridSlot extends StatelessWidget {
  const _PathSchemaGridSlot({
    required this.variant,
    required this.selected,
    required this.mappedSource,
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.onTap,
  });

  final TerrainPathVariant variant;
  final bool selected;
  final TilesetSourceRect? mappedSource;
  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasMapping = mappedSource != null;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? EditorPaintColors.lightBlueAccent.withValues(alpha: 0.18)
              : EditorPaintColors.black.withValues(alpha: 0.14),
          border: Border.all(
            color: selected
                ? EditorPaintColors.lightBlueAccent
                : EditorPaintColors.white12,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PathSlotPreviewPainter(
                  image: image,
                  sourceTileWidth: sourceTileWidth,
                  sourceTileHeight: sourceTileHeight,
                  source: mappedSource,
                  selected: selected,
                ),
              ),
            ),
            if (!hasMapping)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CustomPaint(
                    painter: _PathVariantGlyphPainter(
                      variant: variant,
                      selected: selected,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PathSlotPreviewPainter extends CustomPainter {
  const _PathSlotPreviewPainter({
    required this.image,
    required this.sourceTileWidth,
    required this.sourceTileHeight,
    required this.source,
    required this.selected,
  });

  final ui.Image image;
  final int sourceTileWidth;
  final int sourceTileHeight;
  final TilesetSourceRect? source;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final borderColor = selected
        ? EditorPaintColors.lightBlueAccent
        : EditorPaintColors.white24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = EditorPaintColors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.8 : 1.2,
    );
    if (source == null) {
      final linePaint = Paint()
        ..color = EditorPaintColors.white24
        ..strokeWidth = 1.2;
      canvas.drawLine(
        Offset(rect.left + 8, rect.top + 8),
        Offset(rect.right - 8, rect.bottom - 8),
        linePaint,
      );
      canvas.drawLine(
        Offset(rect.right - 8, rect.top + 8),
        Offset(rect.left + 8, rect.bottom - 8),
        linePaint,
      );
      return;
    }

    final srcRect = Rect.fromLTWH(
      source!.x * sourceTileWidth.toDouble(),
      source!.y * sourceTileHeight.toDouble(),
      source!.width * sourceTileWidth.toDouble(),
      source!.height * sourceTileHeight.toDouble(),
    );
    final dstRect = rect.deflate(3);
    canvas.clipRRect(
      RRect.fromRectAndRadius(dstRect, const Radius.circular(6)),
    );
    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(covariant _PathSlotPreviewPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceTileWidth != sourceTileWidth ||
        oldDelegate.sourceTileHeight != sourceTileHeight ||
        oldDelegate.source != source ||
        oldDelegate.selected != selected;
  }
}

class _PathVariantGlyphPainter extends CustomPainter {
  const _PathVariantGlyphPainter({
    required this.variant,
    required this.selected,
  });

  final TerrainPathVariant variant;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final iconRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(iconRect, const Radius.circular(8)),
      Paint()
        ..color = selected
            ? EditorPaintColors.lightBlueAccent.withValues(alpha: 0.16)
            : EditorPaintColors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final half = math.min(size.width, size.height) * 0.33;
    final activeColor =
        selected ? EditorPaintColors.lightBlueAccent : EditorPaintColors.white;
    final inactiveColor = EditorPaintColors.white.withValues(alpha: 0.22);
    final activeLinePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final axisPaint = Paint()
      ..color = EditorPaintColors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;
    final inactiveDotPaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    final connections = _pathVariantConnections(variant);
    final north = Offset(center.dx, center.dy - half);
    final east = Offset(center.dx + half, center.dy);
    final south = Offset(center.dx, center.dy + half);
    final west = Offset(center.dx - half, center.dy);

    canvas.drawLine(center, north, axisPaint);
    canvas.drawLine(center, east, axisPaint);
    canvas.drawLine(center, south, axisPaint);
    canvas.drawLine(center, west, axisPaint);

    if (connections.north) {
      canvas.drawLine(center, north, activeLinePaint);
    }
    if (connections.east) {
      canvas.drawLine(center, east, activeLinePaint);
    }
    if (connections.south) {
      canvas.drawLine(center, south, activeLinePaint);
    }
    if (connections.west) {
      canvas.drawLine(center, west, activeLinePaint);
    }

    canvas.drawCircle(
        north, 2.0, connections.north ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(
        east, 2.0, connections.east ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(
        south, 2.0, connections.south ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(
        west, 2.0, connections.west ? dotPaint : inactiveDotPaint);
    canvas.drawCircle(center, 2.8, dotPaint);

    final notchAlignment = _innerCornerAlignment(variant);
    if (notchAlignment != null) {
      final notchCenter = Offset(
        center.dx + notchAlignment.dx * half * 0.72,
        center.dy + notchAlignment.dy * half * 0.72,
      );
      canvas.drawCircle(
        notchCenter,
        4.1,
        Paint()
          ..color =
              EditorPaintColors.black.withValues(alpha: selected ? 0.72 : 0.58)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        notchCenter,
        3.2,
        Paint()
          ..color = EditorPaintColors.orangeAccent.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }

    _paintCompassLabel(
      canvas,
      'N',
      Offset(center.dx, 4),
      connections.north ? activeColor : EditorPaintColors.white54,
    );
    _paintCompassLabel(
      canvas,
      'E',
      Offset(size.width - 5, center.dy),
      connections.east ? activeColor : EditorPaintColors.white54,
    );
    _paintCompassLabel(
      canvas,
      'S',
      Offset(center.dx, size.height - 4),
      connections.south ? activeColor : EditorPaintColors.white54,
    );
    _paintCompassLabel(
      canvas,
      'W',
      Offset(5, center.dy),
      connections.west ? activeColor : EditorPaintColors.white54,
    );
  }

  @override
  bool shouldRepaint(covariant _PathVariantGlyphPainter oldDelegate) {
    return oldDelegate.variant != variant || oldDelegate.selected != selected;
  }
}

Offset? _innerCornerAlignment(TerrainPathVariant variant) {
  return switch (variant) {
    TerrainPathVariant.innerCornerNE => const Offset(1, -1),
    TerrainPathVariant.innerCornerSE => const Offset(1, 1),
    TerrainPathVariant.innerCornerSW => const Offset(-1, 1),
    TerrainPathVariant.innerCornerNW => const Offset(-1, -1),
    _ => null,
  };
}

void _paintCompassLabel(
  Canvas canvas,
  String text,
  Offset center,
  Color color,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
  );
}

class _PathTilesetMappingPainter extends CustomPainter {
  const _PathTilesetMappingPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.mappings,
    required this.selectedVariant,
  });

  final ui.Image image;
  final int columns;
  final int rows;
  final Map<TerrainPathVariant, List<TilesetVisualFrame>> mappings;
  final TerrainPathVariant selectedVariant;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, dst, Paint());
    if (columns <= 0 || rows <= 0) {
      return;
    }

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (final entry in mappings.entries) {
      final source = _pathMappingPrimarySource(entry.value);
      if (source == null) {
        continue;
      }
      final rect = Rect.fromLTWH(
        source.x * cellWidth,
        source.y * cellHeight,
        source.width * cellWidth,
        source.height * cellHeight,
      );
      final selected = entry.key == selectedVariant;
      canvas.drawRect(
        rect,
        Paint()
          ..color = (selected
                  ? EditorPaintColors.amberAccent
                  : EditorPaintColors.lightBlueAccent)
              .withValues(alpha: selected ? 0.34 : 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = selected
              ? EditorPaintColors.amberAccent
              : EditorPaintColors.lightBlueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.2 : 1.4,
      );
    }

    final gridPaint = Paint()
      ..color = EditorPaintColors.white24
      ..strokeWidth = 1;
    for (var x = 0; x <= columns; x++) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PathTilesetMappingPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        !_samePathMappings(oldDelegate.mappings, mappings) ||
        oldDelegate.selectedVariant != selectedVariant;
  }
}

({bool north, bool east, bool south, bool west}) _pathVariantConnections(
  TerrainPathVariant variant,
) {
  return switch (variant) {
    TerrainPathVariant.isolated => (
        north: false,
        east: false,
        south: false,
        west: false
      ),
    TerrainPathVariant.endNorth => (
        north: true,
        east: false,
        south: false,
        west: false
      ),
    TerrainPathVariant.endEast => (
        north: false,
        east: true,
        south: false,
        west: false
      ),
    TerrainPathVariant.endSouth => (
        north: false,
        east: false,
        south: true,
        west: false
      ),
    TerrainPathVariant.endWest => (
        north: false,
        east: false,
        south: false,
        west: true
      ),
    TerrainPathVariant.horizontal => (
        north: false,
        east: true,
        south: false,
        west: true
      ),
    TerrainPathVariant.vertical => (
        north: true,
        east: false,
        south: true,
        west: false
      ),
    TerrainPathVariant.cornerNE => (
        north: true,
        east: true,
        south: false,
        west: false
      ),
    TerrainPathVariant.cornerSE => (
        north: false,
        east: true,
        south: true,
        west: false
      ),
    TerrainPathVariant.cornerSW => (
        north: false,
        east: false,
        south: true,
        west: true
      ),
    TerrainPathVariant.cornerNW => (
        north: true,
        east: false,
        south: false,
        west: true
      ),
    TerrainPathVariant.innerCornerNE => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.innerCornerSE => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.innerCornerSW => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.innerCornerNW => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.teeNorth => (
        north: true,
        east: true,
        south: false,
        west: true
      ),
    TerrainPathVariant.teeEast => (
        north: true,
        east: true,
        south: true,
        west: false
      ),
    TerrainPathVariant.teeSouth => (
        north: false,
        east: true,
        south: true,
        west: true
      ),
    TerrainPathVariant.teeWest => (
        north: true,
        east: false,
        south: true,
        west: true
      ),
    TerrainPathVariant.cross => (
        north: true,
        east: true,
        south: true,
        west: true
      ),
  };
}

bool _samePathMappings(
  Map<TerrainPathVariant, List<TilesetVisualFrame>> left,
  Map<TerrainPathVariant, List<TilesetVisualFrame>> right,
) {
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    final frames = right[entry.key];
    if (!_sameFrameList(entry.value, frames)) {
      return false;
    }
  }
  return true;
}

class _TilesetRectSelectionPainter extends CustomPainter {
  const _TilesetRectSelectionPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.selection,
  });

  final ui.Image image;
  final int columns;
  final int rows;
  final TilesetSourceRect selection;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, src, dst, Paint());

    if (columns <= 0 || rows <= 0) {
      return;
    }
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    final gridPaint = Paint()
      ..color = EditorPaintColors.white24
      ..strokeWidth = 1;
    for (var x = 0; x <= columns; x++) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final left = selection.x * cellWidth;
    final top = selection.y * cellHeight;
    final width = selection.width * cellWidth;
    final height = selection.height * cellHeight;
    final rect = Rect.fromLTWH(left, top, width, height);
    canvas.drawRect(
      rect,
      Paint()
        ..color = EditorPaintColors.lightBlueAccent.withValues(alpha: 0.24),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = EditorPaintColors.lightBlueAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _TilesetRectSelectionPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.selection != selection;
  }
}

class _TerrainTilesetImageAsset {
  const _TerrainTilesetImageAsset({
    required this.bytes,
    required this.image,
  });

  final Uint8List bytes;
  final ui.Image image;
}

class _TerrainTilesetImageCache {
  static final Map<String, Future<_TerrainTilesetImageAsset?>> _cache = {};

  static Future<ui.Image?> load(String? path) async {
    return (await loadAsset(path))?.image;
  }

  static Future<_TerrainTilesetImageAsset?> loadAsset(String? path) {
    if (path == null || path.isEmpty) {
      return Future.value(null);
    }
    return _cache.putIfAbsent(path, () async {
      try {
        final file = File(path);
        if (!await file.exists()) {
          return null;
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          return null;
        }
        final image = await decodeBytes(bytes);
        if (image == null) {
          return null;
        }
        return _TerrainTilesetImageAsset(bytes: bytes, image: image);
      } catch (_) {
        return null;
      }
    });
  }

  static Future<ui.Image?> decodeBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}
