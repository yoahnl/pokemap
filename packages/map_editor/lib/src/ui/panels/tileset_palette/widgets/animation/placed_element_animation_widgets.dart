part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// These widgets stay local to the palette panel because they only make sense
// in the context of a selected placed element instance.

class _PlacedElementAnimationSection extends StatelessWidget {
  const _PlacedElementAnimationSection({
    required this.value,
    required this.frameCount,
    required this.previewEnabled,
    required this.image,
    required this.sourceFrames,
    required this.tileWidth,
    required this.tileHeight,
    required this.onChanged,
  });

  final MapPlacedElementAnimation? value;
  final int frameCount;
  final bool previewEnabled;
  final ui.Image image;
  final List<TilesetVisualFrame> sourceFrames;
  final int tileWidth;
  final int tileHeight;
  final ValueChanged<MapPlacedElementAnimation?> onChanged;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final current = value ?? const MapPlacedElementAnimation();
    final effectiveFrameCount = frameCount <= 0 ? 1 : frameCount;
    final canAnimate = effectiveFrameCount > 1;
    final speedLabel = current.speed.toStringAsFixed(2);
    final offset = current.startOffsetMs;
    final offsetLabel = offset == null ? 'Auto' : '${offset.round()} ms';

    void emit(MapPlacedElementAnimation next) {
      onChanged(next);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.015),
        ),
        borderRadius: BorderRadius.circular(6),
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
                  'Animation',
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                minimumSize: Size.zero,
                onPressed: value == null ? null : () => onChanged(null),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
          Text(
            canAnimate
                ? '$effectiveFrameCount frames détectées'
                : 'Une seule frame: animation visuelle limitée',
            style: TextStyle(
              color: secondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          _CompactSwitchRow(
            title: 'Activer animation',
            value: current.enabled,
            onChanged: (next) => emit(current.copyWith(enabled: next)),
          ),
          const SizedBox(height: 6),
          Opacity(
            opacity: current.enabled ? 1 : 0.55,
            child: IgnorePointer(
              ignoring: !current.enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mode',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CupertinoSlidingSegmentedControl<
                      MapPlacedElementAnimationMode>(
                    groupValue: current.mode,
                    onValueChanged: (next) {
                      if (next == null) {
                        return;
                      }
                      emit(current.copyWith(mode: next));
                    },
                    children: const {
                      MapPlacedElementAnimationMode.none: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text('None', style: TextStyle(fontSize: 10)),
                      ),
                      MapPlacedElementAnimationMode.loop: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text('Loop', style: TextStyle(fontSize: 10)),
                      ),
                      MapPlacedElementAnimationMode.pingPong: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text('PingPong', style: TextStyle(fontSize: 10)),
                      ),
                    },
                  ),
                  const SizedBox(height: 6),
                  _CompactSwitchRow(
                    title: 'Autoplay',
                    value: current.autoplay,
                    onChanged: (next) => emit(current.copyWith(autoplay: next)),
                  ),
                  const SizedBox(height: 6),
                  _CompactSwitchRow(
                    title: 'Random start',
                    value: current.randomStart,
                    onChanged: (next) =>
                        emit(current.copyWith(randomStart: next)),
                  ),
                  const SizedBox(height: 6),
                  _CompactStepperRow(
                    label: 'Speed',
                    value: speedLabel,
                    onMinus: () => emit(
                      current.copyWith(
                        speed: (current.speed - 0.10).clamp(0.1, 10.0),
                      ),
                    ),
                    onPlus: () => emit(
                      current.copyWith(
                        speed: (current.speed + 0.10).clamp(0.1, 10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _CompactStepperRow(
                    label: 'Start offset',
                    value: offsetLabel,
                    onMinus: () {
                      final next = (current.startOffsetMs ?? 0) - 100;
                      emit(current.copyWith(startOffsetMs: math.max(0, next)));
                    },
                    onPlus: () {
                      final next = (current.startOffsetMs ?? 0) + 100;
                      emit(current.copyWith(startOffsetMs: next));
                    },
                    onReset: () => emit(current.copyWith(startOffsetMs: null)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!previewEnabled || sourceFrames.isEmpty)
            Text(
              'Aperçu indisponible pour le tileset actuellement chargé.',
              style: TextStyle(
                color: secondary,
                fontSize: 10,
              ),
            )
          else
            SizedBox(
              height: 52,
              child: _PlacedElementAnimationPreview(
                image: image,
                sourceFrames: sourceFrames,
                tileWidth: tileWidth,
                tileHeight: tileHeight,
                config: current,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlacedElementAnimationPreview extends StatefulWidget {
  const _PlacedElementAnimationPreview({
    required this.image,
    required this.sourceFrames,
    required this.tileWidth,
    required this.tileHeight,
    required this.config,
  });

  final ui.Image image;
  final List<TilesetVisualFrame> sourceFrames;
  final int tileWidth;
  final int tileHeight;
  final MapPlacedElementAnimation config;

  @override
  State<_PlacedElementAnimationPreview> createState() =>
      _PlacedElementAnimationPreviewState();
}

class _PlacedElementAnimationPreviewState
    extends State<_PlacedElementAnimationPreview> {
  late final Stopwatch _stopwatch;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final durations = normalizeElementFrameDurationsMs(
      widget.sourceFrames
          .map((frame) => frame.durationMs)
          .toList(growable: false),
    );
    final index = resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: durations,
      elapsedMs: _stopwatch.elapsedMilliseconds.toDouble(),
      animation: widget.config,
      deterministicSeed: stableHash32('editor_preview'),
    );
    final clampedIndex = index.clamp(0, widget.sourceFrames.length - 1);
    final source = widget.sourceFrames[clampedIndex].source;
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ),
            child: _PaletteRectPreview(
              image: widget.image,
              source: source,
              tileWidth: widget.tileWidth,
              tileHeight: widget.tileHeight,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Frame ${clampedIndex + 1}/${widget.sourceFrames.length}',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _ElementFramesEditor extends StatefulWidget {
  const _ElementFramesEditor({
    required this.image,
    required this.tileWidth,
    required this.tileHeight,
    required this.ownerTilesetId,
    required this.frames,
    required this.onChanged,
  });

  final ui.Image image;
  final int tileWidth;
  final int tileHeight;
  final String ownerTilesetId;
  final List<TilesetVisualFrame> frames;
  final ValueChanged<List<TilesetVisualFrame>> onChanged;

  @override
  State<_ElementFramesEditor> createState() => _ElementFramesEditorState();
}

class _ElementFramesEditorState extends State<_ElementFramesEditor> {
  late final Stopwatch _previewStopwatch;
  Timer? _previewTimer;
  final TextEditingController _durationCtrl = TextEditingController();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _previewStopwatch = Stopwatch()..start();
    _previewTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {});
    });
    _syncDurationControl();
  }

  @override
  void didUpdateWidget(covariant _ElementFramesEditor oldWidget) {
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
    if (nextFrames.isEmpty) return;
    widget.onChanged(List<TilesetVisualFrame>.unmodifiable(nextFrames));
    if (_selectedIndex >= nextFrames.length) {
      _selectedIndex = nextFrames.length - 1;
    }
    _syncDurationControl();
  }

  int _resolvePreviewFrameIndex() {
    final frames = widget.frames;
    if (frames.isEmpty) return 0;
    if (frames.length == 1) return 0;
    final durations = normalizeElementFrameDurationsMs(
      frames.map((frame) => frame.durationMs).toList(growable: false),
    );
    return resolvePlacedElementAnimationFrameIndex(
      frameDurationsMs: durations,
      elapsedMs: _previewStopwatch.elapsedMilliseconds.toDouble(),
      animation: const MapPlacedElementAnimation(
        enabled: true,
        mode: MapPlacedElementAnimationMode.loop,
        autoplay: true,
        speed: 1.0,
      ),
    );
  }

  Future<void> _addFrame() async {
    final frames = widget.frames;
    if (frames.isEmpty) return;
    final base = frames.first.source;
    final picked = await _showElementFramePickerDialog(
      context,
      image: widget.image,
      tileWidth: widget.tileWidth,
      tileHeight: widget.tileHeight,
      frameWidthTiles: base.width,
      frameHeightTiles: base.height,
      initial: frames[_selectedIndex].source,
    );
    if (picked == null) return;
    final defaultDuration = (frames[_selectedIndex].durationMs ??
            frames.first.durationMs ??
            defaultPlacedElementAnimationFrameDurationMs)
        .clamp(1, 99999);
    final frame = TilesetVisualFrame(
      tilesetId: frames.first.tilesetId.trim().isEmpty
          ? ''
          : frames.first.tilesetId.trim(),
      source: picked,
      durationMs: defaultDuration,
    );
    final nextFrames = [...frames, frame];
    setState(() {
      _selectedIndex = nextFrames.length - 1;
    });
    _emitFrames(nextFrames);
  }

  void _duplicateFrame() {
    final frames = widget.frames;
    if (frames.isEmpty || _selectedIndex >= frames.length) return;
    final target = frames[_selectedIndex];
    final duplicate = target.copyWith();
    final nextFrames = <TilesetVisualFrame>[
      ...frames.take(_selectedIndex + 1),
      duplicate,
      ...frames.skip(_selectedIndex + 1),
    ];
    setState(() {
      _selectedIndex = _selectedIndex + 1;
    });
    _emitFrames(nextFrames);
  }

  void _deleteSelectedFrame() {
    final frames = widget.frames;
    if (frames.length <= 1) return;
    if (_selectedIndex < 0 || _selectedIndex >= frames.length) return;
    final nextFrames = <TilesetVisualFrame>[
      ...frames.take(_selectedIndex),
      ...frames.skip(_selectedIndex + 1),
    ];
    final nextIndex = math.min(_selectedIndex, nextFrames.length - 1);
    setState(() {
      _selectedIndex = nextIndex;
    });
    _emitFrames(nextFrames);
  }

  void _moveSelectedFrame(int delta) {
    final frames = widget.frames;
    if (frames.length <= 1) return;
    final current = _selectedIndex;
    final next = current + delta;
    if (current < 0 || current >= frames.length) return;
    if (next < 0 || next >= frames.length) return;
    final mutable = List<TilesetVisualFrame>.from(frames);
    final value = mutable.removeAt(current);
    mutable.insert(next, value);
    setState(() {
      _selectedIndex = next;
    });
    _emitFrames(mutable);
  }

  void _clearExtraFrames() {
    final frames = widget.frames;
    if (frames.length <= 1) return;
    setState(() {
      _selectedIndex = 0;
    });
    _emitFrames([frames.first]);
  }

  void _setSelectedDuration(int nextDurationMs) {
    final frames = widget.frames;
    if (frames.isEmpty || _selectedIndex >= frames.length) return;
    final clamped = nextDurationMs.clamp(1, 99999);
    final mutable = List<TilesetVisualFrame>.from(frames);
    mutable[_selectedIndex] =
        mutable[_selectedIndex].copyWith(durationMs: clamped);
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
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    final frames = widget.frames;
    final selectedFrame = frames[_selectedIndex];
    final previewIndex =
        _resolvePreviewFrameIndex().clamp(0, frames.length - 1);
    final previewFrame = frames[previewIndex];
    final frameSizeLabel =
        '${frames.first.source.width}x${frames.first.source.height} tiles';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: Colors.white.withValues(alpha: 0.02),
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
                  'Animation frames',
                  style: TextStyle(
                    color: label,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${frames.length} frame${frames.length > 1 ? 's' : ''}',
                style: TextStyle(color: secondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Size: $frameSizeLabel',
            style: TextStyle(color: secondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: _PaletteRectPreview(
                        image: widget.image,
                        source: previewFrame.source,
                        tileWidth: widget.tileWidth,
                        tileHeight: widget.tileHeight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    frames.length > 1
                        ? 'Preview frame ${previewIndex + 1}/${frames.length}'
                        : 'Static element preview',
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                onPressed: _duplicateFrame,
                child: const Text('Duplicate'),
              ),
              PushButton(
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: frames.length > 1 ? _deleteSelectedFrame : null,
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
          const SizedBox(height: 8),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: frames.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final frame = frames[index];
                final isSelected = index == _selectedIndex;
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
                    duration: const Duration(milliseconds: 120),
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? EditorPaintColors.orange.withValues(alpha: 0.12)
                          : EditorPaintColors.white10,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? EditorPaintColors.orange
                            : EditorPaintColors.white24,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: _PaletteRectPreview(
                              image: widget.image,
                              source: frame.source,
                              tileWidth: widget.tileWidth,
                              tileHeight: widget.tileHeight,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Frame ${_selectedIndex + 1}/${frames.length}',
                style: TextStyle(color: secondary, fontSize: 10),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _moveSelectedFrame(-1),
                child: const Icon(
                  CupertinoIcons.arrow_left,
                  size: 14,
                  color: EditorPaintColors.white60,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _moveSelectedFrame(1),
                child: const Icon(
                  CupertinoIcons.arrow_right,
                  size: 14,
                  color: EditorPaintColors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 26,
                child: CupertinoTextField(
                  controller: _durationCtrl,
                  placeholder: 'ms',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(22, 22),
                color: EditorPaintColors.orange.withValues(alpha: 0.85),
                onPressed: _applyDurationInput,
                child: const Text('Set', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 6),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(22, 22),
                color: EditorPaintColors.white24,
                onPressed: () {
                  final current = selectedFrame.durationMs ??
                      defaultPlacedElementAnimationFrameDurationMs;
                  _setSelectedDuration(current - 50);
                },
                child: const Text('-', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(22, 22),
                color: EditorPaintColors.white24,
                onPressed: () {
                  final current = selectedFrame.durationMs ??
                      defaultPlacedElementAnimationFrameDurationMs;
                  _setSelectedDuration(current + 50);
                },
                child: const Text('+', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
