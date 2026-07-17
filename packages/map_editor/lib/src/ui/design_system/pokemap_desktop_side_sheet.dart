import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

/// Opens a token-driven modal side sheet and restores the caller's focus.
Future<T?> showPokeMapDesktopSideSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  String? semanticLabel,
  String barrierLabel = 'Fermer le panneau latéral',
  FocusNode? initialFocusNode,
  double width = 420,
  bool barrierDismissible = true,
}) async {
  final previousFocus = FocusManager.instance.primaryFocus;
  final colors = context.pokeMapColors;

  final result = await showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 160),
    requestFocus: true,
    pageBuilder: (routeContext, animation, secondaryAnimation) {
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resolvedWidth = width.clamp(280.0, constraints.maxWidth);
            return Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SizedBox(
                width: resolvedWidth,
                height: constraints.maxHeight,
                child: PokeMapDesktopSideSheet(
                  title: title,
                  semanticLabel: semanticLabel,
                  initialFocusNode: initialFocusNode,
                  onClose: () => Navigator.of(routeContext).maybePop(),
                  child: builder(routeContext),
                ),
              ),
            );
          },
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );

  if (previousFocus?.context != null && previousFocus!.canRequestFocus) {
    previousFocus.requestFocus();
  }
  return result;
}

/// Right-aligned desktop sheet surface used by [showPokeMapDesktopSideSheet].
class PokeMapDesktopSideSheet extends StatefulWidget {
  const PokeMapDesktopSideSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.semanticLabel,
    this.initialFocusNode,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;
  final String? semanticLabel;
  final FocusNode? initialFocusNode;

  @override
  State<PokeMapDesktopSideSheet> createState() =>
      _PokeMapDesktopSideSheetState();
}

class _PokeMapDesktopSideSheetState extends State<PokeMapDesktopSideSheet> {
  final FocusNode _closeFocusNode = FocusNode(debugLabel: 'side sheet close');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestInitialFocus());
  }

  @override
  void dispose() {
    _closeFocusNode.dispose();
    super.dispose();
  }

  void _requestInitialFocus() {
    if (!mounted) {
      return;
    }
    final initialFocusNode = widget.initialFocusNode;
    if (initialFocusNode?.context != null &&
        initialFocusNode!.canRequestFocus) {
      initialFocusNode.requestFocus();
      return;
    }
    _closeFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      label: widget.semanticLabel ?? widget.title,
      explicitChildNodes: true,
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: FocusScope(
            child: Material(
              color: colors.surfaceRaised,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                side: BorderSide(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Fermer',
                            child: IconButton(
                              focusNode: _closeFocusNode,
                              onPressed: widget.onClose,
                              style: IconButton.styleFrom(
                                foregroundColor: colors.textSecondary,
                                hoverColor: colors.cardHover,
                                focusColor: colors.cardSelected,
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: colors.divider),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
