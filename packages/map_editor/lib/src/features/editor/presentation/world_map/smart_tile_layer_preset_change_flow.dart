import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../application/authoring_api/editor_receipt_presenter.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_layer_preset_change_gateway.dart';

Future<SmartTileLayerPresetChangeCanonicalResult?>
showSmartTileLayerPresetChangeFlow({
  required BuildContext context,
  required SmartTileLayerPresetChangeGateway gateway,
  required String projectRootPath,
  required ProjectManifest manifest,
  required MapData map,
  required SmartTileLayer layer,
  required ProjectSmartTilePreset targetPreset,
}) async {
  final sourcePreset = manifest.smartTileCatalog.presets
      .where((preset) => preset.id == layer.presetId)
      .firstOrNull;
  if (sourcePreset == null) {
    await showPokeMapNoticeDialog(
      context,
      title: 'Motif source introuvable',
      message: 'Le motif actuel du calque n’existe plus dans la bibliothèque.',
      icon: Icons.error_outline,
    );
    return null;
  }
  final localPlan = planSmartTileLayerPresetChange(
    map: map,
    layer: layer,
    sourcePreset: sourcePreset,
    targetPreset: targetPreset,
    catalog: manifest.smartTileCatalog,
  );
  final requiredMaterialIds = switch (localPlan) {
    SmartTileLayerPresetChangeFailure(
      code: 'smart_tile.layer_preset_material_mapping_required',
      :final requiredMaterialIds,
    ) =>
      requiredMaterialIds,
    SmartTileLayerPresetChangeFailure(:final message) =>
      await _showLocalFailure(context, message),
    SmartTileLayerPresetChangeSuccess() => const <String>[],
  };
  if (requiredMaterialIds == null || !context.mounted) return null;
  final materials = <String, ProjectSmartTileMaterial>{
    for (final material in manifest.smartTileCatalog.materials)
      material.id: material,
  };
  final targetMaterials = <ProjectSmartTileMaterial>[
    for (final id in targetPreset.allowedMaterialIds)
      ?materials[id],
  ];
  if (targetMaterials.isEmpty) {
    await showPokeMapNoticeDialog(
      context,
      title: 'Motif cible incomplet',
      message: 'Ce motif ne contient aucune matière utilisable.',
      icon: Icons.error_outline,
    );
    return null;
  }
  final configuration =
      await showDialog<SmartTileLayerPresetChangeConfiguration>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => SmartTileLayerPresetChangeDialog(
          layerName: layer.name,
          sourcePreset: sourcePreset,
          targetPreset: targetPreset,
          requiredMaterialIds: requiredMaterialIds,
          materials: materials,
          targetMaterials: targetMaterials,
        ),
      );
  if (configuration == null || !context.mounted) return null;
  late final SmartTileLayerPresetChangeCanonicalPlan canonicalPlan;
  try {
    canonicalPlan = await gateway.planChange(
      projectRootPath: projectRootPath,
      mapId: map.id,
      layerId: layer.id,
      targetPresetId: targetPreset.id,
      materialMappings: configuration.materialMappings,
    );
  } on Object catch (error) {
    if (context.mounted) await _showCanonicalFailure(context, error);
    return null;
  }
  if (!context.mounted) return null;
  final confirmed = await showPokeMapConfirmationDialog<bool>(
    context: context,
    title: 'Vérifier le changement de motif',
    message:
        'Le calque « ${layer.name} » gardera son identité et sa '
        'géométrie peinte. Seul son motif visuel sera remplacé.',
    details: PokeMapDiagnosticCallout(
      severity: PokeMapDiagnosticSeverity.info,
      title: 'Aperçu transactionnel',
      message: _previewMessage(canonicalPlan),
    ),
    actions: const <PokeMapDialogAction<bool>>[
      PokeMapDialogAction<bool>(label: 'Annuler', value: false),
      PokeMapDialogAction<bool>(
        label: 'Appliquer',
        value: true,
        variant: PokeMapButtonVariant.primary,
      ),
    ],
  );
  if (confirmed != true) return null;
  try {
    return await gateway.applyChange(plan: canonicalPlan);
  } on Object catch (error) {
    if (context.mounted) await _showCanonicalFailure(context, error);
    return null;
  }
}

final class SmartTileLayerPresetChangeConfiguration {
  SmartTileLayerPresetChangeConfiguration({
    required Map<String, String> materialMappings,
  }) : materialMappings = Map<String, String>.unmodifiable(materialMappings);

  final Map<String, String> materialMappings;
}

final class SmartTileLayerPresetChangeDialog extends StatefulWidget {
  const SmartTileLayerPresetChangeDialog({
    super.key,
    required this.layerName,
    required this.sourcePreset,
    required this.targetPreset,
    required this.requiredMaterialIds,
    required this.materials,
    required this.targetMaterials,
  });

  final String layerName;
  final ProjectSmartTilePreset sourcePreset;
  final ProjectSmartTilePreset targetPreset;
  final List<String> requiredMaterialIds;
  final Map<String, ProjectSmartTileMaterial> materials;
  final List<ProjectSmartTileMaterial> targetMaterials;

  @override
  State<SmartTileLayerPresetChangeDialog> createState() =>
      _SmartTileLayerPresetChangeDialogState();
}

final class _SmartTileLayerPresetChangeDialogState
    extends State<SmartTileLayerPresetChangeDialog> {
  late final Map<String, String> _materialMappings;

  @override
  void initState() {
    super.initState();
    _materialMappings = <String, String>{
      for (final sourceId in widget.requiredMaterialIds)
        sourceId: widget.targetPreset.defaultMaterialId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapDialog(
      title: 'Changer le motif du calque',
      icon: Icons.swap_horiz_rounded,
      maxWidth: 520,
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          PokeMapButton(
            onPressed: () => Navigator.of(context).pop(),
            variant: PokeMapButtonVariant.secondary,
            child: const Text('Annuler'),
          ),
          PokeMapButton(
            onPressed: () => Navigator.of(context).pop(
              SmartTileLayerPresetChangeConfiguration(
                materialMappings: _materialMappings,
              ),
            ),
            child: const Text('Prévisualiser'),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            PokeMapCard(
              child: Row(
                children: [
                  Expanded(
                    child: _PresetName(
                      label: 'Motif actuel',
                      name: widget.sourcePreset.name,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: colors.brandPrimary,
                    ),
                  ),
                  Expanded(
                    child: _PresetName(
                      label: 'Nouveau motif',
                      name: widget.targetPreset.name,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: 'Le dessin reste en place',
              message:
                  'Le calque « ${widget.layerName} », sa géométrie '
                  'peinte et ses motifs réutilisables seront conservés.',
            ),
            if (widget.requiredMaterialIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Correspondance des matières',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choisissez par quoi remplacer les matières absentes du '
                'nouveau motif.',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 10),
              for (final sourceId in widget.requiredMaterialIds) ...[
                PokeMapDropdownField<String>(
                  label: 'Remplacer ${_materialName(sourceId)}',
                  value: _materialMappings[sourceId]!,
                  items: <PokeMapDropdownItem<String>>[
                    for (final material in widget.targetMaterials)
                      PokeMapDropdownItem<String>(
                        value: material.id,
                        label: material.name,
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _materialMappings[sourceId] = value),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _materialName(String id) => widget.materials[id]?.name ?? id;
}

final class _PresetName extends StatelessWidget {
  const _PresetName({required this.label, required this.name});

  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors.textMuted, fontSize: 10)),
        const SizedBox(height: 3),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

Future<List<String>?> _showLocalFailure(
  BuildContext context,
  String message,
) async {
  await showPokeMapNoticeDialog(
    context,
    title: 'Changement impossible',
    message: message,
    icon: Icons.error_outline,
  );
  return null;
}

Future<void> _showCanonicalFailure(BuildContext context, Object error) async {
  final failure = EditorAuthoringMutationFailure.capture(error);
  await showPokeMapNoticeDialog(
    context,
    title: 'Changement non appliqué',
    message: failure.message,
    icon: Icons.error_outline,
  );
}

String _previewMessage(SmartTileLayerPresetChangeCanonicalPlan plan) {
  final remapped = plan.remappedEntryCount;
  final cleared = plan.clearedCandidateWeightCount;
  return '$remapped valeurs de matière seront remappées. '
      '$cleared pondérations de variantes seront réinitialisées. '
      'La modification sera appliquée en une seule transaction.';
}
