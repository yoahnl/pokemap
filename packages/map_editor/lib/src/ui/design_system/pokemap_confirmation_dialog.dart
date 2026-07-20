import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_panel.dart';

const pokeMapConfirmationDialogKey =
    ValueKey<String>('pokemap-confirmation-dialog');

@immutable
final class PokeMapDialogAction<T> {
  const PokeMapDialogAction({
    required this.label,
    required this.value,
    this.variant = PokeMapButtonVariant.secondary,
  });

  final String label;
  final T value;
  final PokeMapButtonVariant variant;
}

/// Opens a token-driven, keyboard-dismissible decision dialog.
Future<T?> showPokeMapConfirmationDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required List<PokeMapDialogAction<T>> actions,
  String barrierLabel = 'Fermer la confirmation',
}) {
  assert(actions.isNotEmpty);
  final colors = context.pokeMapColors;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PokeMapConfirmationDialog<T>(
        title: title,
        message: message,
        actions: actions,
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
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final class _PokeMapConfirmationDialog<T> extends StatelessWidget {
  const _PokeMapConfirmationDialog({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<PokeMapDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SafeArea(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: FocusTraversalGroup(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                key: pokeMapConfirmationDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: title,
                explicitChildNodes: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: PokeMapPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final action in actions)
                              PokeMapButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(action.value),
                                variant: action.variant,
                                size: PokeMapButtonSize.compact,
                                child: Text(action.label),
                              ),
                          ],
                        ),
                      ],
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
