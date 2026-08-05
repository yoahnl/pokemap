import 'package:flutter/material.dart';

import '../foundation/avelune_shape_tokens.dart';
import '../foundation/avelune_spacing_tokens.dart';
import '../theme/avelune_theme_extensions.dart';
import 'avelune_icon_control.dart';
import 'avelune_inset_panel.dart';

class AveluneSheet extends StatelessWidget {
  const AveluneSheet({
    super.key,
    required this.title,
    required this.child,
    required this.onDismiss,
  });

  final String title;
  final Widget child;
  final VoidCallback onDismiss;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
  }) {
    final colors = context.aveluneColors;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.canvas.withValues(alpha: 0),
      barrierColor: colors.canvas.withValues(alpha: 0.76),
      builder: (sheetContext) => AveluneSheet(
        title: title,
        onDismiss: () => Navigator.of(sheetContext).pop(),
        child: builder(sheetContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final colors = context.aveluneColors;
    return Material(
      color: colors.canvas.withValues(alpha: 0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: AveluneInsetPanel(
            borderRadius: AveluneShapes.xl,
            padding: const EdgeInsets.all(AveluneSpacing.lg),
            semanticLabel: title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: AveluneSpacing.sm),
                    AveluneIconControl(
                      semanticLabel: french ? 'Fermer' : 'Close',
                      icon: Icons.close_rounded,
                      onPressed: onDismiss,
                    ),
                  ],
                ),
                const SizedBox(height: AveluneSpacing.md),
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
