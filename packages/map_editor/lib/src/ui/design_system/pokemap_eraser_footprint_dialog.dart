import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_card.dart';
import 'pokemap_panel.dart';
import 'pokemap_text_field.dart';

const pokeMapEraserFootprintDialogKey =
    ValueKey<String>('pokemap-eraser-footprint-dialog');
const pokeMapEraserSingleTileChoiceKey =
    ValueKey<String>('pokemap-eraser-single-tile-choice');
const pokeMapEraserPreviousBrushChoiceKey =
    ValueKey<String>('pokemap-eraser-previous-brush-choice');
const pokeMapEraserCustomChoiceKey =
    ValueKey<String>('pokemap-eraser-custom-choice');
const pokeMapEraserWidthFieldKey =
    ValueKey<String>('pokemap-eraser-width-field');
const pokeMapEraserHeightFieldKey =
    ValueKey<String>('pokemap-eraser-height-field');
const pokeMapEraserFootprintApplyButtonKey =
    ValueKey<String>('pokemap-eraser-footprint-apply-button');

/// User-facing ways to define the footprint of the eraser.
enum PokeMapEraserFootprintMode {
  singleTile,
  previousBrush,
  custom,
}

/// Typed, validated choice returned by [showPokeMapEraserFootprintDialog].
///
/// This design-system contract deliberately does not depend on editor state or
/// notifier types. Feature code can map it to its own immutable domain model.
@immutable
final class PokeMapEraserFootprintResult {
  const PokeMapEraserFootprintResult._({
    required this.mode,
    required this.width,
    required this.height,
  })  : assert(width > 0),
        assert(height > 0);

  const PokeMapEraserFootprintResult.singleTile()
      : mode = PokeMapEraserFootprintMode.singleTile,
        width = 1,
        height = 1;

  const PokeMapEraserFootprintResult.previousBrush({
    required int width,
    required int height,
  }) : this._(
          mode: PokeMapEraserFootprintMode.previousBrush,
          width: width,
          height: height,
        );

  const PokeMapEraserFootprintResult.custom({
    required int width,
    required int height,
  }) : this._(
          mode: PokeMapEraserFootprintMode.custom,
          width: width,
          height: height,
        );

  final PokeMapEraserFootprintMode mode;
  final int width;
  final int height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokeMapEraserFootprintResult &&
          mode == other.mode &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(mode, width, height);

  @override
  String toString() => 'PokeMapEraserFootprintResult($mode, $width × $height)';
}

/// Lets the author choose an eraser size without coupling it to the last brush.
///
/// [previousBrushSize] is optional because a project may not have used a paint
/// brush yet. Custom dimensions are validated inclusively from `1` to
/// [maxDimension]. Previous-brush dimensions stay exact and are only required
/// to be positive.
Future<PokeMapEraserFootprintResult?> showPokeMapEraserFootprintDialog(
  BuildContext context, {
  required PokeMapEraserFootprintResult initialValue,
  ({int width, int height})? previousBrushSize,
  required int maxDimension,
}) {
  assert(maxDimension > 0);
  final colors = context.pokeMapColors;
  return showGeneralDialog<PokeMapEraserFootprintResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer le réglage de la gomme',
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (dialogContext, animation, secondaryAnimation) =>
        _PokeMapEraserFootprintDialog(
      initialValue: initialValue,
      previousBrushSize: previousBrushSize,
      maxDimension: maxDimension,
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

final class _PokeMapEraserFootprintDialog extends StatefulWidget {
  const _PokeMapEraserFootprintDialog({
    required this.initialValue,
    required this.previousBrushSize,
    required this.maxDimension,
  });

  final PokeMapEraserFootprintResult initialValue;
  final ({int width, int height})? previousBrushSize;
  final int maxDimension;

  @override
  State<_PokeMapEraserFootprintDialog> createState() =>
      _PokeMapEraserFootprintDialogState();
}

final class _PokeMapEraserFootprintDialogState
    extends State<_PokeMapEraserFootprintDialog> {
  late PokeMapEraserFootprintMode _mode;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final FocusNode _widthFocusNode;

  ({int width, int height})? get _previousBrushSize {
    final supplied = widget.previousBrushSize;
    if (supplied != null && supplied.width > 0 && supplied.height > 0) {
      return supplied;
    }
    final initial = widget.initialValue;
    if (initial.mode == PokeMapEraserFootprintMode.previousBrush) {
      return (width: initial.width, height: initial.height);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _mode = initial.mode == PokeMapEraserFootprintMode.previousBrush &&
            _previousBrushSize == null
        ? PokeMapEraserFootprintMode.singleTile
        : initial.mode;
    final initialCustomWidth =
        initial.mode == PokeMapEraserFootprintMode.custom ? initial.width : 1;
    final initialCustomHeight =
        initial.mode == PokeMapEraserFootprintMode.custom ? initial.height : 1;
    _widthController = TextEditingController(
      text: initialCustomWidth.toString(),
    );
    _heightController = TextEditingController(
      text: initialCustomHeight.toString(),
    );
    _widthFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _widthFocusNode.dispose();
    super.dispose();
  }

  int? _parseCustomDimension(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value < 1 || value > widget.maxDimension) {
      return null;
    }
    return value;
  }

  String? _customError(TextEditingController controller) {
    if (_parseCustomDimension(controller) != null) return null;
    return 'Entrez un entier entre 1 et ${widget.maxDimension}.';
  }

  PokeMapEraserFootprintResult? get _result {
    switch (_mode) {
      case PokeMapEraserFootprintMode.singleTile:
        return const PokeMapEraserFootprintResult.singleTile();
      case PokeMapEraserFootprintMode.previousBrush:
        final size = _previousBrushSize;
        if (size == null) return null;
        return PokeMapEraserFootprintResult.previousBrush(
          width: size.width,
          height: size.height,
        );
      case PokeMapEraserFootprintMode.custom:
        final width = _parseCustomDimension(_widthController);
        final height = _parseCustomDimension(_heightController);
        if (width == null || height == null) return null;
        return PokeMapEraserFootprintResult.custom(
          width: width,
          height: height,
        );
    }
  }

  void _selectMode(PokeMapEraserFootprintMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (mode == PokeMapEraserFootprintMode.custom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _widthFocusNode.requestFocus();
      });
    }
  }

  void _submit() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(680.0, math.max(340.0, viewport.width - 48));
    final dialogHeight = math.min(620.0, math.max(420.0, viewport.height - 48));
    final previousSize = _previousBrushSize;
    final result = _result;

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
                key: pokeMapEraserFootprintDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: 'Taille de la gomme',
                explicitChildNodes: true,
                child: SizedBox(
                  width: dialogWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: dialogHeight),
                    child: PokeMapPanel(
                      padding: EdgeInsets.zero,
                      header: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cleaning_services_rounded,
                              color: colors.mapAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Taille de la gomme',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Choisissez son emprise sans modifier '
                                    'la taille de vos outils de peinture.',
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
                              key: pokeMapEraserFootprintApplyButtonKey,
                              onPressed: result == null ? null : _submit,
                              autofocus: result != null &&
                                  _mode != PokeMapEraserFootprintMode.custom,
                              child: const Text('Utiliser cette gomme'),
                            ),
                          ],
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final choices = <Widget>[
                                  _EraserModeChoice(
                                    buttonKey: pokeMapEraserSingleTileChoiceKey,
                                    label: 'Une case',
                                    detail: '1 × 1 case',
                                    selected: _mode ==
                                        PokeMapEraserFootprintMode.singleTile,
                                    onPressed: () => _selectMode(
                                      PokeMapEraserFootprintMode.singleTile,
                                    ),
                                  ),
                                  _EraserModeChoice(
                                    buttonKey:
                                        pokeMapEraserPreviousBrushChoiceKey,
                                    label: 'Pinceau précédent',
                                    detail: previousSize == null
                                        ? 'Aucun pinceau à reprendre'
                                        : '${previousSize.width} × '
                                            '${previousSize.height} cases',
                                    selected: _mode ==
                                        PokeMapEraserFootprintMode
                                            .previousBrush,
                                    onPressed: previousSize == null
                                        ? null
                                        : () => _selectMode(
                                              PokeMapEraserFootprintMode
                                                  .previousBrush,
                                            ),
                                  ),
                                  _EraserModeChoice(
                                    buttonKey: pokeMapEraserCustomChoiceKey,
                                    label: 'Personnalisée',
                                    detail: 'De 1 à ${widget.maxDimension}',
                                    selected: _mode ==
                                        PokeMapEraserFootprintMode.custom,
                                    onPressed: () => _selectMode(
                                      PokeMapEraserFootprintMode.custom,
                                    ),
                                  ),
                                ];
                                if (constraints.maxWidth < 560) {
                                  return Column(
                                    children: [
                                      for (var index = 0;
                                          index < choices.length;
                                          index++) ...[
                                        if (index > 0)
                                          const SizedBox(height: 8),
                                        choices[index],
                                      ],
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var index = 0;
                                        index < choices.length;
                                        index++) ...[
                                      if (index > 0) const SizedBox(width: 8),
                                      Expanded(child: choices[index]),
                                    ],
                                  ],
                                );
                              },
                            ),
                            if (_mode == PokeMapEraserFootprintMode.custom) ...[
                              const SizedBox(height: 18),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: PokeMapTextField(
                                      label: 'Largeur (cases)',
                                      controller: _widthController,
                                      focusNode: _widthFocusNode,
                                      fieldKey: pokeMapEraserWidthFieldKey,
                                      errorText: _customError(_widthController),
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PokeMapTextField(
                                      label: 'Hauteur (cases)',
                                      controller: _heightController,
                                      fieldKey: pokeMapEraserHeightFieldKey,
                                      errorText:
                                          _customError(_heightController),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                      onSubmitted: (_) => _submit(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 18),
                            PokeMapCard(
                              selected: result != null,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.crop_free_rounded,
                                    color: result == null
                                        ? colors.error
                                        : colors.mapAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      result == null
                                          ? 'Corrigez la taille personnalisée.'
                                          : 'Taille choisie : ${result.width} × '
                                              '${result.height} '
                                              '${result.width * result.height > 1 ? 'cases' : 'case'}',
                                      style: TextStyle(
                                        color: result == null
                                            ? colors.error
                                            : colors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }
}

final class _EraserModeChoice extends StatelessWidget {
  const _EraserModeChoice({
    required this.buttonKey,
    required this.label,
    required this.detail,
    required this.selected,
    required this.onPressed,
  });

  final Key buttonKey;
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          selected: selected,
          inMutuallyExclusiveGroup: true,
          child: PokeMapButton(
            key: buttonKey,
            onPressed: onPressed,
            variant: PokeMapButtonVariant.secondary,
            isSelected: selected,
            size: PokeMapButtonSize.compact,
            child: Text(label),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: onPressed == null ? colors.textDisabled : colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
