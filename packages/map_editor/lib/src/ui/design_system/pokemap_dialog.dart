import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_panel.dart';
import 'pokemap_text_field.dart';

/// Token-driven confirmation dialog for editor workflows.
Future<bool> showPokeMapBinaryConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String secondaryLabel,
  required String primaryLabel,
  bool primaryIsDestructive = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PokeMapDialog(
      title: title,
      message: message,
      icon: icon,
      footer: _PokeMapDialogActions(
        secondaryLabel: secondaryLabel,
        primaryLabel: primaryLabel,
        primaryIsDestructive: primaryIsDestructive,
        onSecondary: () => Navigator.of(dialogContext).pop(false),
        onPrimary: () => Navigator.of(dialogContext).pop(true),
      ),
    ),
  );
  return result ?? false;
}

/// Token-driven single-action notice for recoverable workflow failures.
Future<void> showPokeMapNoticeDialog(
  BuildContext context, {
  required String title,
  required String message,
  String closeLabel = 'Fermer',
  IconData? icon,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PokeMapDialog(
      title: title,
      message: message,
      icon: icon,
      footer: Align(
        alignment: Alignment.centerRight,
        child: PokeMapButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(closeLabel),
        ),
      ),
    ),
  );
}

/// Token-driven single-field prompt for editor workflows.
Future<bool> showPokeMapPromptDialog(
  BuildContext context, {
  required String title,
  required TextEditingController controller,
  required String placeholder,
  required String cancelLabel,
  required String confirmLabel,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<bool>(
    context: context,
    barrierDismissible: false,
    themes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    builder: (dialogContext) => PokeMapDialog(
      title: title,
      footer: _PokeMapDialogActions(
        secondaryLabel: cancelLabel,
        primaryLabel: confirmLabel,
        onSecondary: () => Navigator.of(dialogContext).pop(false),
        onPrimary: () => Navigator.of(dialogContext).pop(true),
      ),
      child: PokeMapTextField(
        label: placeholder,
        controller: controller,
        placeholder: placeholder,
        autofocus: true,
        onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
      ),
    ),
  );
  final result = await navigator.push(route);
  await route.completed;
  return result ?? false;
}

/// Public token-driven frame for workflow dialogs with custom no-code content.
class PokeMapDialog extends StatelessWidget {
  const PokeMapDialog({
    super.key,
    required this.title,
    required this.footer,
    this.message,
    this.icon,
    this.child,
    this.maxWidth = 440,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? child;
  final Widget footer;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: PokeMapPanel(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colors.brandPrimary, size: 20),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          footer: Padding(
            padding: const EdgeInsets.all(12),
            child: footer,
          ),
          child: child ??
              Text(
                message ?? '',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
        ),
      ),
    );
  }
}

class _PokeMapDialogActions extends StatelessWidget {
  const _PokeMapDialogActions({
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
    this.primaryIsDestructive = false,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback onSecondary;
  final VoidCallback onPrimary;
  final bool primaryIsDestructive;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          PokeMapButton(
            onPressed: onSecondary,
            variant: PokeMapButtonVariant.secondary,
            child: Text(secondaryLabel),
          ),
          PokeMapButton(
            onPressed: onPrimary,
            variant: primaryIsDestructive
                ? PokeMapButtonVariant.danger
                : PokeMapButtonVariant.primary,
            child: Text(primaryLabel),
          ),
        ],
      );
}
