import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_control_profile.dart';
import 'player_service_layout.dart';
import 'runtime_player_actions.dart';

class PlayerImagePuzzleOverlay extends StatefulWidget {
  const PlayerImagePuzzleOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
  });
  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;
  @override
  State<PlayerImagePuzzleOverlay> createState() =>
      _PlayerImagePuzzleOverlayState();
}

class _PlayerImagePuzzleOverlayState extends State<PlayerImagePuzzleOverlay> {
  ui.Image? _image;
  Object? _imageError;
  int _generation = 0;
  RuntimeImagePuzzleServiceContent get _content =>
      widget.snapshot.content! as RuntimeImagePuzzleServiceContent;
  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(PlayerImagePuzzleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      (oldWidget.snapshot.content as RuntimeImagePuzzleServiceContent).bitmap,
      _content.bitmap,
    )) {
      _decode();
    }
  }

  Future<void> _decode() async {
    final generation = ++_generation;
    try {
      final codec = await ui.instantiateImageCodec(_content.bitmap.bytes);
      ui.Image decoded;
      try {
        decoded = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (!mounted || generation != _generation) {
        decoded.dispose();
        return;
      }
      final previous = _image;
      setState(() {
        _image = decoded;
        _imageError = null;
      });
      previous?.dispose();
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _imageError = error);
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _image?.dispose();
    super.dispose();
  }

  void _emit(RuntimeWorldServiceAction action, {int? piece, int? slot}) {
    if (!widget.snapshot.isActionEnabled(action)) return;
    widget.onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: widget.snapshot.revision,
        targetId: (piece ?? _content.selectedPieceId)?.toString(),
        secondaryTargetId: slot?.toString(),
      ),
    );
  }

  Widget _slot(BuildContext context, int slot, double width, double height) {
    final progress = _content.progress;
    final piece = progress.pieces
        .where((piece) => piece.slot == slot)
        .firstOrNull;
    final fixed =
        piece != null &&
        progress.definition.fixedPieceIds.contains(piece.pieceId);
    final selected = piece != null && piece.pieceId == _content.selectedPieceId;
    final canMove =
        _content.selectedPieceId != null &&
        !selected &&
        (piece == null || progress.definition.allowSwap);
    return SizedBox(
      key: ValueKey('puzzle-slot-$slot'),
      width: width,
      height: height,
      child: PlayerMenuSelectableRow(
        id: 'puzzle-slot-$slot',
        label: piece == null
            ? 'Case libre ${slot + 1}'
            : 'Pièce ${piece.pieceId + 1}${fixed ? ', fixe' : ''}',
        semanticValue: fixed
            ? 'fixe'
            : selected
            ? 'sélectionnée'
            : null,
        selected: selected,
        showLabel: false,
        iconOnly: true,
        integrated: true,
        contentPadding: const EdgeInsets.all(2),
        contentGap: 0,
        leading: SizedBox(
          width: width - 4,
          height: height - 4,
          child: piece == null
              ? const SizedBox.shrink()
              : CustomPaint(
                  painter: ImagePuzzlePiecePainter(
                    image: _image!,
                    definition: progress.definition,
                    piece: piece,
                  ),
                ),
        ),
        onPressed:
            fixed ||
                !widget.snapshot.isActionEnabled(
                  RuntimeWorldServiceAction.select,
                )
            ? null
            : () {
                if (canMove) {
                  _emit(RuntimeWorldServiceAction.move, slot: slot);
                } else if (piece != null) {
                  _emit(RuntimeWorldServiceAction.select, piece: piece.pieceId);
                }
              },
      ),
    );
  }

  Widget _board(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final definition = _content.progress.definition;
      final image = _image!;
      final ratio =
          (image.width / definition.columns) / (image.height / definition.rows);
      final width = math.max(
        math.max(48.0, 48 * ratio),
        math.min(100.0, constraints.maxWidth / definition.columns),
      );
      final height = width / ratio;
      return SingleChildScrollView(
        key: const ValueKey('puzzle-board-viewport'),
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(constraints.maxWidth, width * definition.columns),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var row = 0; row < definition.rows; row++)
                Row(
                  children: [
                    for (var column = 0; column < definition.columns; column++)
                      _slot(
                        context,
                        row * definition.columns + column,
                        width,
                        height,
                      ),
                  ],
                ),
              if (definition.trayCapacity > 0) ...[
                const SizedBox(height: 12),
                const Text('Réserve'),
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    for (
                      var index = 0;
                      index < definition.trayCapacity;
                      index++
                    )
                      _slot(
                        context,
                        definition.pieceCount + index,
                        width,
                        height,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _panelContent(BuildContext context, bool applying) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Puzzle d’image', style: context.playerMenuTheme.title),
      const SizedBox(height: 8),
      Expanded(
        child: SingleChildScrollView(
          key: const ValueKey('puzzle-content-viewport'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sélectionnez une pièce puis sa destination. R : tourner la pièce.',
              ),
              if (applying) const LinearProgressIndicator(),
              if (_content.message case final message?) Text(message),
              if (_imageError != null)
                const Text(
                  'L’image ne peut pas être affichée. Quittez puis rouvrez le puzzle.',
                ),
              if (_image == null && _imageError == null)
                const LinearProgressIndicator(),
              if (_image != null) _board(context),
              const SizedBox(height: 12),
              PlayerServiceActions(
                children: [
                  if (_content.progress.definition.allowedQuarterTurns.length >
                      1)
                    PlayerActionButton(
                      label: 'Tourner',
                      icon: Icons.rotate_right,
                      secondary: true,
                      onPressed: applying || _content.selectedPieceId == null
                          ? null
                          : () => _emit(RuntimeWorldServiceAction.rotate),
                    ),
                  if (_content.progress.definition.allowReset)
                    PlayerActionButton(
                      label: 'Recommencer',
                      icon: Icons.restart_alt,
                      secondary: true,
                      onPressed: applying
                          ? null
                          : () => _emit(RuntimeWorldServiceAction.reset),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      PlayerServiceActions(
        children: [
          PlayerActionButton(
            label: 'Vérifier',
            icon: Icons.check,
            onPressed: applying || _image == null
                ? null
                : () => _emit(RuntimeWorldServiceAction.confirm),
          ),
          PlayerActionButton(
            label: 'Quitter',
            icon: Icons.close,
            secondary: true,
            onPressed: applying
                ? null
                : () => _emit(RuntimeWorldServiceAction.cancel),
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final applying = widget.snapshot.stage == RuntimeWorldServiceStage.applying;
    return RuntimePlayerActions(
      includeDefaultKeyboardShortcuts: false,
      onBack: () => _emit(RuntimeWorldServiceAction.cancel),
      onMenu: () {},
      onInputSourceChanged: (_) {},
      child: RuntimePlayerInputBindings(
        controlProfile: widget.controlProfile,
        hardwareGamepadEnabled: widget.hardwareGamepadEnabled,
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyR): () =>
                _emit(RuntimeWorldServiceAction.rotate),
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                _emit(RuntimeWorldServiceAction.cancel),
          },
          child: Focus(
            autofocus: true,
            child: PlayerMenuThemeScope(
              role: ProjectPresentationSurfaceRole.confirmation,
              child: Builder(
                builder: (context) => ColoredBox(
                  color: context.playerColors.scrim,
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 680,
                            maxHeight: 900,
                          ),
                          child: PlayerMenuPanel(
                            primary: true,
                            padding: const EdgeInsets.all(12),
                            child: _panelContent(context, applying),
                          ),
                        ),
                      ),
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
}

class ImagePuzzlePiecePainter extends CustomPainter {
  const ImagePuzzlePiecePainter({
    required this.image,
    required this.definition,
    required this.piece,
  });
  final ui.Image image;
  final ImagePuzzleDefinition definition;
  final ImagePuzzlePiece piece;
  @override
  void paint(Canvas canvas, Size size) {
    final width = image.width / definition.columns;
    final height = image.height / definition.rows;
    final source = Rect.fromLTWH(
      (piece.pieceId % definition.columns) * width,
      (piece.pieceId ~/ definition.columns) * height,
      width,
      height,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(piece.quarterTurns * math.pi / 2);
    final target = piece.quarterTurns.isOdd
        ? Size(size.height, size.width)
        : size;
    canvas.drawImageRect(
      image,
      source,
      Rect.fromCenter(
        center: Offset.zero,
        width: target.width,
        height: target.height,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ImagePuzzlePiecePainter oldDelegate) =>
      image != oldDelegate.image ||
      definition != oldDelegate.definition ||
      piece != oldDelegate.piece;
}
