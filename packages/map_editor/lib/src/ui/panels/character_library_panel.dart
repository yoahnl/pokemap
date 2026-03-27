import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import '../shared/inspector_embedded_widgets.dart';

const _kCharNoneMenuId = '__char_none__';
const _kDefaultDurMs = 150;

// ─────────────────────────────────────────────────────────────────────────────
// Image cache
// ─────────────────────────────────────────────────────────────────────────────

class _CharacterImageCache {
  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(String? path) {
    if (path == null || path.isEmpty) return Future.value(null);
    return _cache.putIfAbsent(path, () async {
      try {
        final bytes = await File(path).readAsBytes();
        if (bytes.isEmpty) return null;
        final codec = await ui.instantiateImageCodec(bytes);
        return (await codec.getNextFrame()).image;
      } catch (_) {
        return null;
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _SpritesheetPainter extends CustomPainter {
  final ui.Image image;
  final int cols;
  final int rows;
  final Set<(int, int)> occupied;

  const _SpritesheetPainter({
    required this.image,
    required this.cols,
    required this.rows,
    required this.occupied,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    final cw = size.width / cols;
    final ch = size.height / rows;
    final gridPaint = Paint()
      ..color = EditorPaintColors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var x = 0; x <= cols; x++) {
      canvas.drawLine(Offset(x * cw, 0), Offset(x * cw, size.height), gridPaint);
    }
    for (var y = 0; y <= rows; y++) {
      canvas.drawLine(Offset(0, y * ch), Offset(size.width, y * ch), gridPaint);
    }

    for (final (col, row) in occupied) {
      final rect = Rect.fromLTWH(col * cw, row * ch, cw, ch);
      canvas.drawRect(
        rect,
        Paint()..color = EditorPaintColors.orange.withValues(alpha: 0.28),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = EditorPaintColors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpritesheetPainter old) =>
      old.image != image ||
      old.cols != cols ||
      old.rows != rows ||
      old.occupied != occupied;
}

class _FramePainter extends CustomPainter {
  final ui.Image image;
  final int pixelX, pixelY, frameW, frameH;

  const _FramePainter({
    required this.image,
    required this.pixelX,
    required this.pixelY,
    required this.frameW,
    required this.frameH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      pixelX.toDouble(),
      pixelY.toDouble(),
      frameW.toDouble(),
      frameH.toDouble(),
    );
    final srcAspect = frameW / math.max(1, frameH);
    final dstAspect = size.width / math.max(0.01, size.height);
    final Rect dst;
    if (srcAspect > dstAspect) {
      final h = size.width / srcAspect;
      dst = Rect.fromLTWH(0, (size.height - h) / 2, size.width, h);
    } else {
      final w = size.height * srcAspect;
      dst = Rect.fromLTWH((size.width - w) / 2, 0, w, size.height);
    }
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) =>
      old.image != image || old.pixelX != pixelX || old.pixelY != pixelY;
}

// ─────────────────────────────────────────────────────────────────────────────
// Live preview
// ─────────────────────────────────────────────────────────────────────────────

class _AnimPreview extends StatefulWidget {
  final ui.Image? image;
  final int framePixelW;
  final int framePixelH;
  final List<CharacterAnimationFrame> frames;
  const _AnimPreview({
    required this.image,
    required this.framePixelW,
    required this.framePixelH,
    required this.frames,
  });

  @override
  State<_AnimPreview> createState() => _AnimPreviewState();
}

class _AnimPreviewState extends State<_AnimPreview> {
  Timer? _timer;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void didUpdateWidget(covariant _AnimPreview old) {
    super.didUpdateWidget(old);
    if (old.frames != widget.frames) {
      _idx = 0;
      _timer?.cancel();
      _scheduleNext();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext() {
    if (widget.frames.isEmpty) return;
    final dur = widget.frames[_idx % widget.frames.length].durationMs;
    _timer = Timer(Duration(milliseconds: dur), () {
      if (!mounted) return;
      setState(() => _idx = (_idx + 1) % widget.frames.length);
      _scheduleNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final frames = widget.frames;
    final isEmpty = image == null || frames.isEmpty;

    return SizedBox(
      width: 56,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorPaintColors.white10,
          border: Border.all(color: EditorPaintColors.white24),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isEmpty
            ? const Center(
                child: Icon(
                  CupertinoIcons.play_fill,
                  size: 16,
                  color: EditorPaintColors.white38,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CustomPaint(
                  painter: _FramePainter(
                    image: image,
                    pixelX: frames[_idx % frames.length].source.x *
                        widget.framePixelW,
                    pixelY: frames[_idx % frames.length].source.y *
                        widget.framePixelH,
                    frameW: widget.framePixelW,
                    frameH: widget.framePixelH,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animation slot grid (3 states × 4 directions)
// ─────────────────────────────────────────────────────────────────────────────

class _AnimSlotGrid extends StatelessWidget {
  final ProjectCharacterEntry character;
  final CharacterAnimationState selectedState;
  final EntityFacing selectedDir;
  final void Function(CharacterAnimationState, EntityFacing) onTap;

  const _AnimSlotGrid({
    required this.character,
    required this.selectedState,
    required this.selectedDir,
    required this.onTap,
  });

  int _frameCount(CharacterAnimationState s, EntityFacing d) =>
      character.animations
          .where((a) => a.state == s && a.direction == d)
          .firstOrNull
          ?.frames
          .length ??
      0;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);

    const stateLabel = {
      CharacterAnimationState.idle: 'Idle',
      CharacterAnimationState.walk: 'Walk',
      CharacterAnimationState.run: 'Run',
    };
    const dirLabel = {
      EntityFacing.north: 'N',
      EntityFacing.south: 'S',
      EntityFacing.east: 'E',
      EntityFacing.west: 'W',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Direction header
        Row(
          children: [
            const SizedBox(width: 34),
            ...EntityFacing.values.map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    dirLabel[d]!,
                    style: TextStyle(
                      fontSize: 10,
                      color: subtle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // One row per animation state
        ...CharacterAnimationState.values.map(
          (s) => Padding(
            padding: const EdgeInsets.only(top: 3),
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(
                      stateLabel[s]!,
                      style: TextStyle(fontSize: 10, color: subtle),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...EntityFacing.values.map((d) {
                    final count = _frameCount(s, d);
                    final sel = s == selectedState && d == selectedDir;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(s, d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: sel
                                ? EditorPaintColors.orange
                                    .withValues(alpha: 0.20)
                                : EditorPaintColors.white10,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: sel
                                  ? EditorPaintColors.orange
                                  : EditorPaintColors.white24,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: count == 0
                                ? Icon(
                                    CupertinoIcons.minus,
                                    size: 9,
                                    color: subtle,
                                  )
                                : Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sel
                                          ? EditorPaintColors.orange
                                          : label,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visual animation editor for a selected character
// ─────────────────────────────────────────────────────────────────────────────

class _CharacterAnimEditor extends ConsumerStatefulWidget {
  final ProjectCharacterEntry character;

  const _CharacterAnimEditor({required this.character});

  @override
  ConsumerState<_CharacterAnimEditor> createState() =>
      _CharacterAnimEditorState();
}

class _CharacterAnimEditorState extends ConsumerState<_CharacterAnimEditor> {
  CharacterAnimationState _animState = CharacterAnimationState.idle;
  EntityFacing _animDir = EntityFacing.south;
  int? _selectedFrameIdx;
  final _durCtrl = TextEditingController(text: '$_kDefaultDurMs');

  @override
  void didUpdateWidget(covariant _CharacterAnimEditor old) {
    super.didUpdateWidget(old);
    if (old.character.id != widget.character.id) {
      _animState = CharacterAnimationState.idle;
      _animDir = EntityFacing.south;
      _selectedFrameIdx = null;
      _durCtrl.text = '$_kDefaultDurMs';
      return;
    }
    final frames = _currentFrames;
    if (_selectedFrameIdx != null && _selectedFrameIdx! >= frames.length) {
      _selectedFrameIdx = frames.isEmpty ? null : frames.length - 1;
    }
  }

  @override
  void dispose() {
    _durCtrl.dispose();
    super.dispose();
  }

  List<CharacterAnimationFrame> get _currentFrames =>
      widget.character.animations
          .where((a) => a.state == _animState && a.direction == _animDir)
          .firstOrNull
          ?.frames ??
      const [];

  void _saveFrames(List<CharacterAnimationFrame> frames) {
    ref.read(editorNotifierProvider.notifier).upsertCharacterAnimation(
      characterId: widget.character.id,
      animState: _animState,
      direction: _animDir,
      frames: frames,
    );
  }

  void _onCellTap(int col, int row) {
    final current = List<CharacterAnimationFrame>.from(_currentFrames);
    final existing = current.indexWhere(
      (f) => f.source.x == col && f.source.y == row,
    );
    if (existing >= 0) {
      current.removeAt(existing);
    } else {
      final dur = int.tryParse(_durCtrl.text) ?? _kDefaultDurMs;
      current.add(CharacterAnimationFrame(
        source: TilesetSourceRect(x: col, y: row),
        durationMs: dur.clamp(1, 99999),
      ));
    }
    _saveFrames(current);
  }

  void _deleteFrame(int index) {
    final current = List<CharacterAnimationFrame>.from(_currentFrames);
    current.removeAt(index);
    _saveFrames(current);
  }

  void _moveFrame(int from, int delta) {
    final current = List<CharacterAnimationFrame>.from(_currentFrames);
    final to = from + delta;
    if (to < 0 || to >= current.length) return;
    final item = current.removeAt(from);
    current.insert(to, item);
    setState(() => _selectedFrameIdx = to);
    _saveFrames(current);
  }

  void _commitDuration() {
    final idx = _selectedFrameIdx;
    if (idx == null) return;
    final current = List<CharacterAnimationFrame>.from(_currentFrames);
    if (idx >= current.length) return;
    final dur = int.tryParse(_durCtrl.text) ?? _kDefaultDurMs;
    current[idx] = current[idx].copyWith(durationMs: dur.clamp(1, 99999));
    _saveFrames(current);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    if (project == null) return const SizedBox.shrink();

    final settings = project.settings;
    final framePixelW =
        math.max(1, widget.character.frameWidth * settings.tileWidth);
    final framePixelH =
        math.max(1, widget.character.frameHeight * settings.tileHeight);
    final tilesetPath =
        notifier.getTilesetAbsolutePathById(widget.character.tilesetId);
    final frames = _currentFrames;
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return FutureBuilder<ui.Image?>(
      future: _CharacterImageCache.load(tilesetPath),
      builder: (context, snapshot) {
        final image = snapshot.data;
        final cols =
            image != null ? image.width ~/ math.max(1, framePixelW) : 0;
        final rows =
            image != null ? image.height ~/ math.max(1, framePixelH) : 0;
        final occupied = {for (final f in frames) (f.source.x, f.source.y)};

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Slot grid + live preview ─────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AnimSlotGrid(
                      character: widget.character,
                      selectedState: _animState,
                      selectedDir: _animDir,
                      onTap: (s, d) => setState(() {
                        _animState = s;
                        _animDir = d;
                        _selectedFrameIdx = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(fontSize: 9, color: subtle),
                      ),
                      const SizedBox(height: 2),
                      _AnimPreview(
                        image: image,
                        framePixelW: framePixelW,
                        framePixelH: framePixelH,
                        frames: frames,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const EditorHorizontalDivider(),
              const SizedBox(height: 6),

              // ── Spritesheet picker ───────────────────────────────────
              if (image == null || cols <= 0 || rows <= 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      tilesetPath == null
                          ? 'Tileset "${widget.character.tilesetId}" not found'
                          : 'Loading spritesheet…',
                      style: TextStyle(fontSize: 11, color: subtle),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Text(
                      'Spritesheet ($cols×$rows frames)',
                      style: TextStyle(fontSize: 10, color: subtle),
                    ),
                    const Spacer(),
                    Text(
                      'Tap = add / remove',
                      style: TextStyle(fontSize: 10, color: subtle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildSpritesheetCanvas(
                  image,
                  cols,
                  rows,
                  framePixelW,
                  framePixelH,
                  occupied,
                ),
              ],
              const SizedBox(height: 8),
              const EditorHorizontalDivider(),
              const SizedBox(height: 4),

              // ── Frame strip ──────────────────────────────────────────
              _buildFrameStrip(image, frames, framePixelW, framePixelH, subtle),

              // ── Selected frame controls ──────────────────────────────
              if (_selectedFrameIdx != null &&
                  _selectedFrameIdx! < frames.length)
                _buildFrameControls(frames),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpritesheetCanvas(
    ui.Image image,
    int cols,
    int rows,
    int framePixelW,
    int framePixelH,
    Set<(int, int)> occupied,
  ) {
    const minCell = 20.0;
    final cellW = math.max(minCell, framePixelW.toDouble());
    final cellH = math.max(minCell, framePixelH.toDouble());

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: CupertinoScrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CupertinoScrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: SizedBox(
                width: cols * cellW,
                height: rows * cellH,
                child: GestureDetector(
                  onTapUp: (d) {
                    final col =
                        (d.localPosition.dx / cellW).floor().clamp(0, cols - 1);
                    final row =
                        (d.localPosition.dy / cellH).floor().clamp(0, rows - 1);
                    _onCellTap(col, row);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: EditorPaintColors.white24),
                    ),
                    child: CustomPaint(
                      painter: _SpritesheetPainter(
                        image: image,
                        cols: cols,
                        rows: rows,
                        occupied: occupied,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrameStrip(
    ui.Image? image,
    List<CharacterAnimationFrame> frames,
    int framePixelW,
    int framePixelH,
    Color subtle,
  ) {
    if (frames.isEmpty) {
      return SizedBox(
        height: 64,
        child: Center(
          child: Text(
            'No frames — tap spritesheet cells above',
            style: TextStyle(fontSize: 11, color: subtle),
          ),
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        itemCount: frames.length,
        itemBuilder: (context, i) {
          final frame = frames[i];
          final isSelected = _selectedFrameIdx == i;
          final pxX = frame.source.x * framePixelW;
          final pxY = frame.source.y * framePixelH;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedFrameIdx = isSelected ? null : i;
              if (!isSelected) _durCtrl.text = '${frame.durationMs}';
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 60,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? EditorPaintColors.orange.withValues(alpha: 0.14)
                    : EditorPaintColors.white10,
                borderRadius: BorderRadius.circular(5),
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
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                      child: image != null
                          ? CustomPaint(
                              painter: _FramePainter(
                                image: image,
                                pixelX: pxX,
                                pixelY: pxY,
                                frameW: framePixelW,
                                frameH: framePixelH,
                              ),
                              child: const SizedBox.expand(),
                            )
                          : const ColoredBox(
                              color: EditorPaintColors.white10,
                              child: SizedBox.expand(),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      '${frame.durationMs}ms',
                      style: const TextStyle(
                        fontSize: 9,
                        color: EditorPaintColors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameControls(List<CharacterAnimationFrame> frames) {
    final idx = _selectedFrameIdx!;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            'Frame ${idx + 1}/${frames.length}',
            style: const TextStyle(fontSize: 11, color: EditorPaintColors.white54),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _moveFrame(idx, -1),
            child: const Icon(
              CupertinoIcons.arrow_left,
              size: 14,
              color: EditorPaintColors.white60,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            height: 26,
            child: CupertinoTextField(
              controller: _durCtrl,
              placeholder: 'ms',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              onSubmitted: (_) => _commitDuration(),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'ms',
            style: TextStyle(fontSize: 11, color: EditorPaintColors.white54),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _moveFrame(idx, 1),
            child: const Icon(
              CupertinoIcons.arrow_right,
              size: 14,
              color: EditorPaintColors.white60,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minSize: 22,
            color: EditorPaintColors.orange.withValues(alpha: 0.85),
            onPressed: _commitDuration,
            child: const Text('Set', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 6),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minSize: 22,
            color: CupertinoColors.destructiveRed,
            onPressed: () => _deleteFrame(idx),
            child: const Text('Del', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create character form
// ─────────────────────────────────────────────────────────────────────────────

class _CreateCharacterForm extends StatelessWidget {
  const _CreateCharacterForm({
    required this.nameCtrl,
    required this.tilesetCtrl,
    required this.frameWidthCtrl,
    required this.frameHeightCtrl,
    required this.onCancel,
    required this.onCreate,
  });

  final TextEditingController nameCtrl;
  final TextEditingController tilesetCtrl;
  final TextEditingController frameWidthCtrl;
  final TextEditingController frameHeightCtrl;
  final VoidCallback onCancel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(
          controller: nameCtrl,
          placeholder: 'Name',
          autofocus: true,
          onSubmitted: (_) => onCreate(),
        ),
        const SizedBox(height: 5),
        CupertinoTextField(
          controller: tilesetCtrl,
          placeholder: 'Tileset ID',
          onSubmitted: (_) => onCreate(),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: frameWidthCtrl,
                placeholder: 'Frame W',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CupertinoTextField(
                controller: frameHeightCtrl,
                placeholder: 'Frame H',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minSize: 26,
              color: CupertinoColors.destructiveRed,
              onPressed: onCancel,
              child: const Text('Cancel', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minSize: 26,
                onPressed: onCreate,
                child: const Text('Create', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main panel
// ─────────────────────────────────────────────────────────────────────────────

class CharacterLibraryPanel extends ConsumerStatefulWidget {
  const CharacterLibraryPanel({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<CharacterLibraryPanel> createState() =>
      _CharacterLibraryPanelState();
}

class _CharacterLibraryPanelState
    extends ConsumerState<CharacterLibraryPanel> {
  bool _showCreateForm = false;
  final _newNameCtrl = TextEditingController();
  final _newTilesetCtrl = TextEditingController();
  final _newFrameWidthCtrl = TextEditingController(text: '1');
  final _newFrameHeightCtrl = TextEditingController(text: '2');

  String? _editingCharId;
  final _editNameCtrl = TextEditingController();
  final _editTilesetCtrl = TextEditingController();
  final _editFrameWidthCtrl = TextEditingController();
  final _editFrameHeightCtrl = TextEditingController();

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _newTilesetCtrl.dispose();
    _newFrameWidthCtrl.dispose();
    _newFrameHeightCtrl.dispose();
    _editNameCtrl.dispose();
    _editTilesetCtrl.dispose();
    _editFrameWidthCtrl.dispose();
    _editFrameHeightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;
    final characters = project?.characters ?? const <ProjectCharacterEntry>[];
    final selectedCharId = state.selectedCharacterId;
    final selectedChar =
        characters.where((c) => c.id == selectedCharId).firstOrNull;
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    final body = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Player character ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: _buildPlayerSection(
                    context,
                    notifier,
                    characters,
                    project.settings.playerCharacterId,
                  ),
                ),
                const EditorHorizontalDivider(),

                // ── Create row ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                  child: _buildCreateRow(context, notifier),
                ),

                // ── Character list ───────────────────────────────────
                if (characters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Text(
                      'No characters yet.',
                      style: TextStyle(color: subtle, fontSize: 11),
                    ),
                  )
                else
                  ...characters.map(
                    (char) => _buildCharRow(
                      context,
                      char,
                      notifier,
                      selectedCharId,
                    ),
                  ),

                const EditorHorizontalDivider(),

                // ── Animation editor ─────────────────────────────────
                if (selectedChar == null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        characters.isEmpty
                            ? 'Create a character to get started'
                            : 'Select a character to edit animations',
                        style: TextStyle(fontSize: 11, color: subtle),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  _CharacterAnimEditor(character: selectedChar),
              ],
            ),
          );

    if (widget.embedded) return body;

    return Container(
      decoration: BoxDecoration(color: EditorChrome.islandFill(context)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
            child: Row(
              children: [
                const Icon(CupertinoIcons.person_2_fill, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Characters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          const EditorHorizontalDivider(),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _buildPlayerSection(
    BuildContext context,
    EditorNotifier notifier,
    List<ProjectCharacterEntry> characters,
    String? playerCharId,
  ) {
    final menuIds = [_kCharNoneMenuId, ...characters.map((c) => c.id)];
    String labelOf(String id) {
      if (id == _kCharNoneMenuId) return 'None';
      return characters.where((c) => c.id == id).firstOrNull?.name ?? id;
    }

    final selected =
        menuIds.contains(playerCharId) ? playerCharId! : _kCharNoneMenuId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InspectorEmbeddedSectionLabel('PLAYER CHARACTER'),
        const SizedBox(height: 4),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyCyan,
          fieldLabel: 'Player character',
          valueLabel: labelOf(selected),
          orderedIds: menuIds,
          selectedMenuValue: selected,
          selectedIdForCheck: selected,
          idToLabel: labelOf,
          onSelected: (id) =>
              notifier.setPlayerCharacter(id == _kCharNoneMenuId ? null : id),
          tooltip: 'The character sprite used for the player on the overworld',
        ),
      ],
    );
  }

  Widget _buildCreateRow(BuildContext context, EditorNotifier notifier) {
    if (_showCreateForm) {
      return _CreateCharacterForm(
        nameCtrl: _newNameCtrl,
        tilesetCtrl: _newTilesetCtrl,
        frameWidthCtrl: _newFrameWidthCtrl,
        frameHeightCtrl: _newFrameHeightCtrl,
        onCancel: () => setState(() => _showCreateForm = false),
        onCreate: () {
          final name = _newNameCtrl.text.trim();
          final tileset = _newTilesetCtrl.text.trim();
          if (name.isEmpty || tileset.isEmpty) return;
          final fw = int.tryParse(_newFrameWidthCtrl.text.trim()) ?? 1;
          final fh = int.tryParse(_newFrameHeightCtrl.text.trim()) ?? 2;
          notifier.createCharacter(
            name: name,
            tilesetId: tileset,
            frameWidth: fw.clamp(1, 99),
            frameHeight: fh.clamp(1, 99),
          );
          setState(() => _showCreateForm = false);
        },
      );
    }
    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 28,
      onPressed: () => setState(() {
        _showCreateForm = true;
        _newNameCtrl.clear();
        _newTilesetCtrl.clear();
        _newFrameWidthCtrl.text = '1';
        _newFrameHeightCtrl.text = '2';
      }),
      child: const Text('New Character', style: TextStyle(fontSize: 13)),
    );
  }

  Widget _buildCharRow(
    BuildContext context,
    ProjectCharacterEntry char,
    EditorNotifier notifier,
    String? selectedCharId,
  ) {
    final isSelected = char.id == selectedCharId;
    final isEditing = char.id == _editingCharId;
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            notifier.selectCharacter(char.id);
            if (_editingCharId == char.id) setState(() => _editingCharId = null);
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isSelected
                  ? EditorPaintColors.orange.withValues(alpha: 0.10)
                  : EditorPaintColors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          char.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: label,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${char.tilesetId} · ${char.frameWidth}×${char.frameHeight}',
                          style: TextStyle(fontSize: 10, color: subtle),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minSize: 24,
                    onPressed: () {
                      notifier.selectCharacter(char.id);
                      if (isEditing) {
                        setState(() => _editingCharId = null);
                      } else {
                        setState(() {
                          _editingCharId = char.id;
                          _editNameCtrl.text = char.name;
                          _editTilesetCtrl.text = char.tilesetId;
                          _editFrameWidthCtrl.text = '${char.frameWidth}';
                          _editFrameHeightCtrl.text = '${char.frameHeight}';
                        });
                      }
                    },
                    child: Icon(
                      isEditing ? CupertinoIcons.xmark : CupertinoIcons.pencil,
                      size: 12,
                      color: subtle,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(4),
                    minSize: 24,
                    onPressed: () {
                      notifier.deleteCharacter(char.id);
                      if (_editingCharId == char.id) {
                        setState(() => _editingCharId = null);
                      }
                    },
                    child: const Icon(
                      CupertinoIcons.trash,
                      size: 12,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isEditing)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: _buildEditForm(char, notifier),
          ),
      ],
    );
  }

  Widget _buildEditForm(ProjectCharacterEntry char, EditorNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(controller: _editNameCtrl, placeholder: 'Name'),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: _editTilesetCtrl,
          placeholder: 'Tileset ID',
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _editFrameWidthCtrl,
                placeholder: 'Frame W',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CupertinoTextField(
                controller: _editFrameHeightCtrl,
                placeholder: 'Frame H',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minSize: 24,
          onPressed: () {
            final name = _editNameCtrl.text.trim();
            final tileset = _editTilesetCtrl.text.trim();
            if (name.isEmpty || tileset.isEmpty) return;
            final fw =
                int.tryParse(_editFrameWidthCtrl.text) ?? char.frameWidth;
            final fh =
                int.tryParse(_editFrameHeightCtrl.text) ?? char.frameHeight;
            notifier.updateCharacter(
              characterId: char.id,
              name: name,
              tilesetId: tileset,
              frameWidth: fw.clamp(1, 99),
              frameHeight: fh.clamp(1, 99),
            );
            setState(() => _editingCharId = null);
          },
          child: const Text('Save', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
