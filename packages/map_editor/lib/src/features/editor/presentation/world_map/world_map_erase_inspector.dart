import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../state/editor_notifier.dart';
import '../../state/editor_state.dart';

class WorldMapEraseInspector extends ConsumerStatefulWidget {
  const WorldMapEraseInspector({super.key});

  @override
  ConsumerState<WorldMapEraseInspector> createState() =>
      _WorldMapEraseInspectorState();
}

class _WorldMapEraseInspectorState
    extends ConsumerState<WorldMapEraseInspector> {
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final size = ref.read(editorNotifierProvider).eraserFootprint.size;
    _widthController = TextEditingController(text: '${size.width}');
    _heightController = TextEditingController(text: '${size.height}');
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _apply() {
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    if (width == null || height == null) {
      setState(() {
        _validationMessage = 'Saisissez une largeur et une hauteur entières.';
      });
      return;
    }
    if (width < 1 ||
        height < 1 ||
        width > kMaxEditorEraserFootprintDimension ||
        height > kMaxEditorEraserFootprintDimension) {
      setState(() {
        _validationMessage = 'Chaque dimension doit être comprise entre 1 et '
            '$kMaxEditorEraserFootprintDimension.';
      });
      return;
    }

    ref.read(editorNotifierProvider.notifier).setCustomEraserFootprint(
          width: width,
          height: height,
        );
    setState(() => _validationMessage = null);
  }

  void _reset() {
    _widthController.text = '1';
    _heightController.text = '1';
    ref.read(editorNotifierProvider.notifier).useSingleTileEraserFootprint();
    setState(() => _validationMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final footprint = ref.watch(
      editorNotifierProvider.select((state) => state.eraserFootprint),
    );
    ref.listen(
      editorNotifierProvider.select((state) => state.eraserFootprint),
      (previous, next) {
        if (previous == next) {
          return;
        }
        final size = next.size;
        _widthController.text = '${size.width}';
        _heightController.text = '${size.height}';
      },
    );

    return Semantics(
      container: true,
      label: 'Réglages de la gomme',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapSectionHeader(
              title: 'Empreinte de la gomme',
              description:
                  'Cette taille reste indépendante du dernier objet utilisé.',
              trailing: PokeMapBadge(
                key: const ValueKey<String>(
                  'world-map-eraser-current-size',
                ),
                label: _sizeLabel(footprint.size),
                variant: PokeMapBadgeVariant.info,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: PokeMapTextField(
                    label: 'Largeur',
                    controller: _widthController,
                    fieldKey: const ValueKey<String>(
                      'world-map-eraser-width',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _apply(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PokeMapTextField(
                    label: 'Hauteur',
                    controller: _heightController,
                    fieldKey: const ValueKey<String>(
                      'world-map-eraser-height',
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _apply(),
                  ),
                ),
              ],
            ),
            if (_validationMessage case final message?) ...[
              const SizedBox(height: 10),
              PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.error,
                title: 'Taille invalide',
                message: message,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey<String>('world-map-eraser-apply'),
                    onPressed: _apply,
                    child: const Text('Appliquer'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey<String>('world-map-eraser-reset'),
                    variant: PokeMapButtonVariant.secondary,
                    onPressed: _reset,
                    child: const Text('Réinitialiser à 1 × 1'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _sizeLabel(GridSize size) {
  final suffix = size.width == 1 && size.height == 1 ? 'case' : 'cases';
  return '${size.width} × ${size.height} $suffix';
}
