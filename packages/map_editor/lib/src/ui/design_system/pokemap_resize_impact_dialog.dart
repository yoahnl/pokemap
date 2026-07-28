import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_diagnostic_callout.dart';
import 'pokemap_panel.dart';
import 'pokemap_section_header.dart';
import 'pokemap_text_field.dart';

const pokeMapResizeImpactDialogKey =
    ValueKey<String>('pokemap-resize-impact-dialog');
const pokeMapResizeWidthFieldKey =
    ValueKey<String>('pokemap-resize-width-field');
const pokeMapResizeHeightFieldKey =
    ValueKey<String>('pokemap-resize-height-field');
const pokeMapResizeApplyButtonKey =
    ValueKey<String>('pokemap-resize-apply-button');

typedef PokeMapResizePlanBuilder = MapResizePlan Function(
  int width,
  int height,
);

/// Validated target returned only after a loss-safe resize plan is applicable.
@immutable
final class PokeMapResizeTarget {
  const PokeMapResizeTarget({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokeMapResizeTarget &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Presents a live, fail-closed preview of every resize impact.
///
/// The modal never returns a destructive target. The application use case
/// still rebuilds the plan before mutation, so closing the dialog is not a
/// security or consistency boundary.
Future<PokeMapResizeTarget?> showPokeMapResizeImpactDialog(
  BuildContext context, {
  required int currentWidth,
  required int currentHeight,
  required PokeMapResizePlanBuilder buildPlan,
}) {
  final colors = context.pokeMapColors;
  return showGeneralDialog<PokeMapResizeTarget>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le redimensionnement de la carte',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _PokeMapResizeImpactDialog(
      currentWidth: currentWidth,
      currentHeight: currentHeight,
      buildPlan: buildPlan,
    ),
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

final class _PokeMapResizeImpactDialog extends StatefulWidget {
  const _PokeMapResizeImpactDialog({
    required this.currentWidth,
    required this.currentHeight,
    required this.buildPlan,
  });

  final int currentWidth;
  final int currentHeight;
  final PokeMapResizePlanBuilder buildPlan;

  @override
  State<_PokeMapResizeImpactDialog> createState() =>
      _PokeMapResizeImpactDialogState();
}

final class _PokeMapResizeImpactDialogState
    extends State<_PokeMapResizeImpactDialog> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  MapResizePlan? _plan;
  String? _widthError;
  String? _heightError;
  String? _planningError;
  Timer? _planDebounce;

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(
      text: widget.currentWidth.toString(),
    );
    _heightController = TextEditingController(
      text: widget.currentHeight.toString(),
    );
    _rebuildPlan();
  }

  @override
  void dispose() {
    _planDebounce?.cancel();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _schedulePlanRebuild() {
    _planDebounce?.cancel();
    setState(() {
      _plan = null;
      _planningError = null;
    });
    _planDebounce = Timer(
      const Duration(milliseconds: 120),
      _rebuildPlan,
    );
  }

  void _submitCurrentTarget() {
    _planDebounce?.cancel();
    _rebuildPlan();
    _apply();
  }

  void _rebuildPlan() {
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    final widthError = width == null || width <= 0
        ? 'Utilisez un entier supérieur à 0.'
        : null;
    final heightError = height == null || height <= 0
        ? 'Utilisez un entier supérieur à 0.'
        : null;
    if (widthError != null || heightError != null) {
      setState(() {
        _widthError = widthError;
        _heightError = heightError;
        _planningError = null;
        _plan = null;
      });
      return;
    }

    try {
      final plan = widget.buildPlan(width!, height!);
      setState(() {
        _widthError = null;
        _heightError = null;
        _planningError = null;
        _plan = plan;
      });
    } on Object {
      setState(() {
        _widthError = null;
        _heightError = null;
        _planningError =
            'Le plan d’impact n’a pas pu être calculé. La carte reste intacte.';
        _plan = null;
      });
    }
  }

  void _apply() {
    final plan = _plan;
    if (plan == null || plan.isNoOp || !plan.canApply) return;
    Navigator.of(context).pop(
      PokeMapResizeTarget(
        width: plan.targetSize.width,
        height: plan.targetSize.height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(760.0, math.max(320.0, viewport.width - 48));
    final dialogHeight = math.min(760.0, math.max(420.0, viewport.height - 48));
    final plan = _plan;
    final canApply = plan != null && !plan.isNoOp && plan.canApply;

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
                key: pokeMapResizeImpactDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: 'Redimensionner la carte',
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
                            Icons.aspect_ratio_rounded,
                            color: plan?.canApply == false
                                ? colors.error
                                : colors.mapAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Redimensionner la carte',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Taille actuelle : ${widget.currentWidth} × '
                                  '${widget.currentHeight} cases',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    footer: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          PokeMapButton(
                            onPressed: () => Navigator.of(context).pop(),
                            variant: PokeMapButtonVariant.secondary,
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 8),
                          PokeMapButton(
                            key: pokeMapResizeApplyButtonKey,
                            onPressed: canApply ? _apply : null,
                            autofocus: canApply,
                            child: const Text('Appliquer'),
                          ),
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: PokeMapTextField(
                                  label: 'Largeur (cases)',
                                  controller: _widthController,
                                  fieldKey: pokeMapResizeWidthFieldKey,
                                  errorText: _widthError,
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) => _schedulePlanRebuild(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PokeMapTextField(
                                  label: 'Hauteur (cases)',
                                  controller: _heightController,
                                  fieldKey: pokeMapResizeHeightFieldKey,
                                  errorText: _heightError,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => _schedulePlanRebuild(),
                                  onSubmitted: (_) => _submitCurrentTarget(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (_planningError != null)
                            PokeMapDiagnosticCallout(
                              severity: PokeMapDiagnosticSeverity.error,
                              title: 'Prévisualisation indisponible',
                              message: _planningError!,
                            )
                          else if (plan != null)
                            _ResizePlanStatus(plan: plan),
                          if (plan != null && plan.impacts.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            PokeMapSectionHeader(
                              title: 'Objets concernés',
                              description:
                                  '${plan.impacts.length} impact${plan.impacts.length > 1 ? 's' : ''} à corriger avant de réduire la carte',
                            ),
                            const SizedBox(height: 4),
                            for (var index = 0;
                                index < plan.impacts.length;
                                index++) ...[
                              if (index > 0) const SizedBox(height: 8),
                              PokeMapDiagnosticCallout(
                                severity: PokeMapDiagnosticSeverity.warning,
                                title: plan.impacts[index].subjectLabel,
                                message:
                                    _resizeImpactMessage(plan.impacts[index]),
                              ),
                            ],
                          ],
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

final class _ResizePlanStatus extends StatelessWidget {
  const _ResizePlanStatus({required this.plan});

  final MapResizePlan plan;

  @override
  Widget build(BuildContext context) {
    if (plan.isNoOp) {
      return const PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Aucune modification',
        message: 'La taille cible est identique à la taille actuelle.',
      );
    }
    if (!plan.canApply) {
      final count = plan.impacts.length;
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.error,
        title: 'Redimensionnement bloqué',
        message: '$count impact${count > 1 ? 's' : ''} '
            'bloquant${count > 1 ? 's' : ''} détecté${count > 1 ? 's' : ''}. '
            'Corrigez ou déplacez les éléments listés ; aucune donnée ne sera '
            'supprimée automatiquement.',
      );
    }
    if (plan.isExpansion) {
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Aucune perte détectée',
        message: 'La carte sera agrandie à ${plan.targetSize.width} × '
            '${plan.targetSize.height} cases.',
      );
    }
    return PokeMapDiagnosticCallout(
      severity: PokeMapDiagnosticSeverity.info,
      title: 'Aucune perte détectée',
      message: 'Le contenu conservé tient entièrement dans '
          '${plan.targetSize.width} × ${plan.targetSize.height} cases.',
    );
  }
}

String _resizeImpactMessage(MapResizeImpact impact) {
  final count = impact.affectedCount;
  final cases = '$count case${count > 1 ? 's' : ''}';
  final detail = switch (impact.reason) {
    MapResizeImpactReason.clippedCells =>
      '$cases non vide${count > 1 ? 's' : ''} serait${count > 1 ? 'ent' : ''} supprimée${count > 1 ? 's' : ''}.',
    MapResizeImpactReason.positionOutside =>
      'Sa position sort de la nouvelle carte.',
    MapResizeImpactReason.footprintOutside =>
      '$cases de son emprise sort${count > 1 ? 'ent' : ''} de la nouvelle carte.',
    MapResizeImpactReason.footprintUnknown =>
      'Son emprise ne peut pas être résolue avec le manifeste actuel.',
    MapResizeImpactReason.areaOutside =>
      '$cases de sa zone sort${count > 1 ? 'ent' : ''} de la nouvelle carte.',
    MapResizeImpactReason.patrolWaypointOutside =>
      '$count point${count > 1 ? 's' : ''} de patrouille '
          'sort${count > 1 ? 'ent' : ''} de la nouvelle carte.',
    MapResizeImpactReason.localTargetOutside =>
      'Sa destination sur cette carte sort des nouvelles limites.',
    MapResizeImpactReason.triggerAreaClipped =>
      '$cases de sa zone d’activation deviendrai${count > 1 ? 'ent' : 't'} inaccessible${count > 1 ? 's' : ''}.',
    MapResizeImpactReason.danglingReference =>
      '$count référence${count > 1 ? 's' : ''} générée${count > 1 ? 's' : ''} deviendrai${count > 1 ? 'ent' : 't'} orpheline${count > 1 ? 's' : ''}.',
    MapResizeImpactReason.borderDiagnostic =>
      'La bordure serait modifiée de façon destructive'
          '${impact.diagnosticCode == null ? '.' : ' (${impact.diagnosticCode}).'}',
    MapResizeImpactReason.connectionTopologyChanged =>
      'Le bord source de la connexion changerait ; son alignement doit être revu.',
    MapResizeImpactReason.missingContext =>
      'Le contexte nécessaire à une prévisualisation sûre est indisponible.',
  };
  final coordinates = impact.positions.take(3).map(
        (position) => '(${position.x}, ${position.y})',
      );
  final coordinateSummary = coordinates.isEmpty
      ? ''
      : ' Positions : ${coordinates.join(', ')}'
          '${impact.positions.length > 3 ? ', …' : ''}.';
  return '$detail$coordinateSummary';
}
