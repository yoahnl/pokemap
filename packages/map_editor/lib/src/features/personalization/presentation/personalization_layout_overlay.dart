import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/personalization_layout_gesture_planner.dart';

class PersonalizationLayoutOverlay extends StatefulWidget {
  const PersonalizationLayoutOverlay({
    super.key,
    required this.surface,
    required this.breakpoint,
    required this.profile,
    required this.textScale,
    required this.onPreviewChanged,
    required this.onCommitted,
    required this.child,
    this.dragBounds = const Rect.fromLTWH(0, 0, 1, 1),
  });

  final ProjectPresentationSurfaceRole surface;
  final ProjectPresentationBreakpoint breakpoint;
  final ProjectPresentationLayoutsProfile profile;
  final double textScale;
  final ValueChanged<ProjectPresentationLayoutsProfile> onPreviewChanged;
  final ValueChanged<ProjectPresentationLayoutsProfile> onCommitted;
  final Widget child;
  final Rect dragBounds;

  @override
  State<PersonalizationLayoutOverlay> createState() =>
      _PersonalizationLayoutOverlayState();
}

class _PersonalizationLayoutOverlayState
    extends State<PersonalizationLayoutOverlay> {
  static const _planner = PersonalizationLayoutGesturePlanner();
  PersonalizationLayoutGestureSession? _session;
  Offset _delta = Offset.zero;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.moveLeft),
      const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.moveRight),
      const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.moveUp),
      const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.moveDown),
      const SingleActivator(LogicalKeyboardKey.equal, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.grow),
      const SingleActivator(LogicalKeyboardKey.minus, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.shrink),
      const SingleActivator(LogicalKeyboardKey.bracketRight, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.increaseMargin),
      const SingleActivator(LogicalKeyboardKey.bracketLeft, alt: true): () =>
          _applyKeyboard(PersonalizationLayoutKeyboardCommand.decreaseMargin),
    },
    child: Focus(
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            widget.child,
            Positioned(
              left: constraints.maxWidth * widget.dragBounds.left,
              top: constraints.maxHeight * widget.dragBounds.top,
              width: constraints.maxWidth * widget.dragBounds.width,
              height: constraints.maxHeight * widget.dragBounds.height,
              child: GestureDetector(
                key: const ValueKey<String>('personalization-layout-drag-zone'),
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) {
                  _delta = Offset.zero;
                  _session = PersonalizationLayoutGestureSession(
                    planner: _planner,
                    surface: widget.surface,
                    breakpoint: widget.breakpoint,
                    profile: widget.profile,
                    textScale: widget.textScale,
                  );
                },
                onPanUpdate: (details) {
                  final size = context.size;
                  if (size == null || size.isEmpty) return;
                  _delta += Offset(
                    details.delta.dx / size.width,
                    details.delta.dy / size.height,
                  );
                  final plan = _session?.previewMove(_delta);
                  if (plan?.isAccepted == true) {
                    widget.onPreviewChanged(plan!.profile);
                  }
                },
                onPanEnd: (_) {
                  final session = _session;
                  _session = null;
                  if (session?.hasPendingChange == true) {
                    widget.onCommitted(session!.commit());
                  }
                },
                onPanCancel: _cancel,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: <Widget>[
                  _action(
                    'Déplacer à gauche',
                    Icons.arrow_back_rounded,
                    PersonalizationLayoutKeyboardCommand.moveLeft,
                  ),
                  _action(
                    'Déplacer à droite',
                    Icons.arrow_forward_rounded,
                    PersonalizationLayoutKeyboardCommand.moveRight,
                  ),
                  _action(
                    'Agrandir',
                    Icons.zoom_out_map_rounded,
                    PersonalizationLayoutKeyboardCommand.grow,
                  ),
                  _action(
                    'Réduire',
                    Icons.zoom_in_map_rounded,
                    PersonalizationLayoutKeyboardCommand.shrink,
                  ),
                  _action(
                    'Augmenter la marge',
                    Icons.padding_rounded,
                    PersonalizationLayoutKeyboardCommand.increaseMargin,
                  ),
                  _action(
                    'Réduire la marge',
                    Icons.compress_rounded,
                    PersonalizationLayoutKeyboardCommand.decreaseMargin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _action(
    String label,
    IconData icon,
    PersonalizationLayoutKeyboardCommand command,
  ) => PokeMapIconButton(
    onPressed: () => _applyKeyboard(command),
    icon: Icon(icon),
    tooltip: label,
    semanticLabel: label,
    variant: PokeMapIconButtonVariant.soft,
  );

  void _applyKeyboard(PersonalizationLayoutKeyboardCommand command) {
    final plan = _planner.planKeyboard(
      PersonalizationLayoutKeyboardRequest(
        surface: widget.surface,
        breakpoint: widget.breakpoint,
        profile: widget.profile,
        command: command,
        textScale: widget.textScale,
      ),
    );
    if (plan.isAccepted) widget.onCommitted(plan.profile);
  }

  void _cancel() {
    final session = _session;
    _session = null;
    if (session != null) widget.onPreviewChanged(session.cancel());
  }
}
