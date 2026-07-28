import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import 'narrative/pokemap_dependency_inspector.dart';
import 'pokemap_button.dart';
import 'pokemap_diagnostic_callout.dart';
import 'pokemap_panel.dart';
import 'pokemap_section_header.dart';

const pokeMapDependencyPreflightDialogKey =
    ValueKey<String>('pokemap-dependency-preflight-dialog');

/// Presents a fail-closed map lifecycle result without offering a destructive
/// override.
///
/// Consumer navigation keeps the canonical Core intent intact. The dialog is
/// dismissed before [onOpen] runs so the destination is never hidden behind a
/// stale modal route.
Future<void> showPokeMapDependencyPreflightDialog(
  BuildContext context, {
  required String title,
  required String message,
  required NarrativeDependencyInspectionReadModel inspection,
  required List<String> indexDiagnostics,
  ValueChanged<NarrativeDependencyNavigationIntent>? onOpen,
}) async {
  final colors = context.pokeMapColors;
  final selectedIntent =
      await showGeneralDialog<NarrativeDependencyNavigationIntent>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le détail des dépendances',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return _PokeMapDependencyPreflightDialog(
        title: title,
        message: message,
        inspection: inspection,
        indexDiagnostics: indexDiagnostics,
        onOpen: onOpen == null
            ? null
            : (intent) => Navigator.of(dialogContext).pop(intent),
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
  if (selectedIntent != null) onOpen?.call(selectedIntent);
}

final class _PokeMapDependencyPreflightDialog extends StatelessWidget {
  const _PokeMapDependencyPreflightDialog({
    required this.title,
    required this.message,
    required this.inspection,
    required this.indexDiagnostics,
    required this.onOpen,
  });

  final String title;
  final String message;
  final NarrativeDependencyInspectionReadModel inspection;
  final List<String> indexDiagnostics;
  final ValueChanged<NarrativeDependencyNavigationIntent>? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(760.0, math.max(320.0, viewport.width - 48));
    final dialogHeight = math.min(760.0, math.max(320.0, viewport.height - 48));

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
                key: pokeMapDependencyPreflightDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: title,
                explicitChildNodes: true,
                child: SizedBox(
                  width: dialogWidth,
                  height: dialogHeight,
                  child: PokeMapPanel(
                    expandChild: true,
                    padding: EdgeInsets.zero,
                    header: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_tree_outlined,
                            color: colors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: PokeMapButton(
                          autofocus: true,
                          onPressed: () => Navigator.of(context).pop(),
                          variant: PokeMapButtonVariant.secondary,
                          child: const Text('Fermer'),
                        ),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PokeMapDiagnosticCallout(
                            severity: PokeMapDiagnosticSeverity.error,
                            title: 'Action non autorisée',
                            message: message,
                          ),
                          if (indexDiagnostics.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            PokeMapSectionHeader(
                              title: 'Index incomplet',
                              description:
                                  '${indexDiagnostics.length} diagnostic(s)',
                            ),
                            const SizedBox(height: 8),
                            for (var index = 0;
                                index < indexDiagnostics.length;
                                index++) ...[
                              if (index > 0) const SizedBox(height: 8),
                              PokeMapDiagnosticCallout(
                                severity: PokeMapDiagnosticSeverity.warning,
                                message: indexDiagnostics[index],
                              ),
                            ],
                          ],
                          const SizedBox(height: 18),
                          PokeMapDependencyInspector(
                            model: inspection,
                            onOpen: onOpen,
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
      ),
    );
  }
}
