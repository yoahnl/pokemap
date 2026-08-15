import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../application/authoring_api/editor_receipt_presenter.dart';
import '../../../design_system/design_system.dart';

const presentationStudioDiagnosticFocusKey = ValueKey<String>(
  'presentation-studio-diagnostic-focus',
);
const presentationStudioDiagnosticCalloutKey = ValueKey<String>(
  'presentation-studio-diagnostic-callout',
);

@immutable
final class PresentationStudioDiagnostic {
  const PresentationStudioDiagnostic({
    required this.code,
    required this.severity,
    required this.title,
    required this.cause,
    required this.impact,
    required this.actionLabel,
  });

  factory PresentationStudioDiagnostic.fromError(
    Object error, {
    required String title,
    required String impact,
    String actionLabel = 'Réessayer',
    String fallbackCode = PresentationDiagnosticCodes.saveFailed,
  }) {
    final failure = EditorAuthoringMutationFailure.capture(error);
    return PresentationStudioDiagnostic(
      code: failure.code == 'authoring.unexpected_failure'
          ? fallbackCode
          : failure.code,
      severity: PresentationDiagnosticSeverity.error,
      title: title,
      cause: failure.message,
      impact: impact,
      actionLabel: actionLabel,
    );
  }

  final String code;
  final PresentationDiagnosticSeverity severity;
  final String title;
  final String cause;
  final String impact;
  final String actionLabel;

  String get message => 'Cause : $cause\nImpact : $impact\nCode : $code';
}

class PresentationStudioDiagnosticCallout extends StatefulWidget {
  const PresentationStudioDiagnosticCallout({
    super.key,
    required this.diagnostic,
    required this.onAction,
  });

  final PresentationStudioDiagnostic diagnostic;
  final VoidCallback onAction;

  @override
  State<PresentationStudioDiagnosticCallout> createState() =>
      _PresentationStudioDiagnosticCalloutState();
}

class _PresentationStudioDiagnosticCalloutState
    extends State<PresentationStudioDiagnosticCallout> {
  final FocusNode _focusNode = FocusNode(
    debugLabel: 'Presentation Studio diagnostic',
  );

  @override
  void initState() {
    super.initState();
    _requestFocus();
  }

  @override
  void didUpdateWidget(PresentationStudioDiagnosticCallout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.diagnostic.code != widget.diagnostic.code ||
        oldWidget.diagnostic.cause != widget.diagnostic.cause) {
      _requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _requestFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final severity = switch (widget.diagnostic.severity) {
      PresentationDiagnosticSeverity.warning =>
        PokeMapDiagnosticSeverity.warning,
      PresentationDiagnosticSeverity.error => PokeMapDiagnosticSeverity.error,
    };
    return Focus(
      key: presentationStudioDiagnosticFocusKey,
      focusNode: _focusNode,
      child: Semantics(
        key: presentationStudioDiagnosticCalloutKey,
        container: true,
        liveRegion:
            widget.diagnostic.severity == PresentationDiagnosticSeverity.error,
        label:
            '${widget.diagnostic.title}. ${widget.diagnostic.message}. '
            '${widget.diagnostic.actionLabel}',
        child: PokeMapDiagnosticCallout(
          severity: severity,
          title: widget.diagnostic.title,
          message: widget.diagnostic.message,
          actionLabel: widget.diagnostic.actionLabel,
          onAction: widget.onAction,
        ),
      ),
    );
  }
}
