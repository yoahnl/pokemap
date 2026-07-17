import 'package:flutter/material.dart';

import 'pokemap_button.dart';
import 'pokemap_tone.dart';

/// Severity levels for editor diagnostics.
enum PokeMapDiagnosticSeverity {
  info,
  warning,
  error,
}

/// Dense diagnostic message with text, icon, semantics and an optional action.
class PokeMapDiagnosticCallout extends StatelessWidget {
  const PokeMapDiagnosticCallout({
    super.key,
    required this.severity,
    required this.message,
    this.title,
    this.semanticLabel,
    this.actionLabel,
    this.onAction,
  }) : assert(
          (actionLabel == null) == (onAction == null),
          'actionLabel and onAction must be provided together.',
        );

  final PokeMapDiagnosticSeverity severity;
  final String message;
  final String? title;
  final String? semanticLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tone = switch (severity) {
      PokeMapDiagnosticSeverity.info => PokeMapTone.info,
      PokeMapDiagnosticSeverity.warning => PokeMapTone.warning,
      PokeMapDiagnosticSeverity.error => PokeMapTone.danger,
    };
    final toneColors = tone.resolve(context);
    final icon = switch (severity) {
      PokeMapDiagnosticSeverity.info => Icons.info_outline_rounded,
      PokeMapDiagnosticSeverity.warning => Icons.warning_amber_rounded,
      PokeMapDiagnosticSeverity.error => Icons.error_outline_rounded,
    };
    final severityLabel = switch (severity) {
      PokeMapDiagnosticSeverity.info => 'Information',
      PokeMapDiagnosticSeverity.warning => 'Avertissement',
      PokeMapDiagnosticSeverity.error => 'Erreur',
    };
    final defaultSemanticLabel = <String>[
      severityLabel,
      if (title != null && title!.trim().isNotEmpty) title!.trim(),
      message.trim(),
    ].join('. ');

    return Semantics(
      container: true,
      liveRegion: severity == PokeMapDiagnosticSeverity.error,
      label: semanticLabel ?? defaultSemanticLabel,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: toneColors.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: toneColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 17, color: toneColors.icon),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && title!.trim().isNotEmpty) ...[
                          Text(
                            title!,
                            style: TextStyle(
                              color: toneColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text(
                          message,
                          style: TextStyle(
                            color: toneColors.text,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 8),
                    PokeMapButton(
                      onPressed: onAction,
                      variant: PokeMapButtonVariant.ghost,
                      size: PokeMapButtonSize.small,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
