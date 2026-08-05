import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_reconstruction_service.dart';

/// Guided, no-code inspection and confirmation surface for literal-to-native
/// Smart Tile reconstruction.
class SmartTileReconstructionEditor extends StatefulWidget {
  const SmartTileReconstructionEditor({
    super.key,
    required this.manifest,
    required this.map,
    required this.onCancel,
    required this.onInspect,
    required this.onApply,
    this.plan,
    this.isPlanning = false,
    this.isApplying = false,
    this.externalError,
  });

  final ProjectManifest manifest;
  final MapData map;
  final VoidCallback onCancel;
  final Future<void> Function(SmartTileReconstructionRequest request) onInspect;
  final Future<void> Function() onApply;
  final SmartTileReconstructionPlan? plan;
  final bool isPlanning;
  final bool isApplying;
  final String? externalError;

  @override
  State<SmartTileReconstructionEditor> createState() =>
      _SmartTileReconstructionEditorState();
}

class _SmartTileReconstructionEditorState
    extends State<SmartTileReconstructionEditor> {
  late final TextEditingController _targetIdController;
  late final TextEditingController _targetNameController;
  String? _sourceLayerId;
  String? _presetId;

  List<TileLayer> get _sources => widget.map.layers
      .whereType<TileLayer>()
      .where(
        (layer) =>
            layer.purpose == MapLayerPurpose.visual &&
            layer.cells.any((cell) => cell > 0),
      )
      .toList(growable: false);

  List<ProjectSmartTilePreset> get _presets =>
      widget.manifest.smartTileCatalog.presets
          .where((preset) => preset.status == SmartTilePresetStatus.published)
          .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _sourceLayerId = _sources.firstOrNull?.id;
    _presetId = _presets.firstOrNull?.id;
    final source = _sources.firstOrNull;
    _targetIdController = TextEditingController(
      text: source == null ? '' : _suggestTargetId(source.id),
    );
    _targetNameController = TextEditingController(
      text: source == null ? '' : '${source.name} — Smart Tiles',
    );
  }

  @override
  void didUpdateWidget(covariant SmartTileReconstructionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sources.any((layer) => layer.id == _sourceLayerId)) {
      _sourceLayerId = _sources.firstOrNull?.id;
    }
    if (!_presets.any((preset) => preset.id == _presetId)) {
      _presetId = _presets.firstOrNull?.id;
    }
  }

  @override
  void dispose() {
    _targetIdController.dispose();
    _targetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    final presets = _presets;
    final plan = _matchingPlan;
    final busy = widget.isPlanning || widget.isApplying;
    if (sources.isEmpty || presets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          const PokeMapSectionHeader(
            title: 'Reconstruire une couche littérale',
            description:
                'Convertit une couche importée en intention Smart Tiles native.',
          ),
          const SizedBox(height: 14),
          PokeMapEmptyState(
            title: sources.isEmpty
                ? 'Aucune couche littérale remplie'
                : 'Aucun preset publié',
            description: sources.isEmpty
                ? 'Importez une map contenant des tuiles avant de lancer la reconstruction.'
                : 'Validez puis publiez le Wang Set correspondant dans le Studio.',
            icon: const Icon(CupertinoIcons.wand_stars),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: PokeMapButton(
              onPressed: widget.onCancel,
              variant: PokeMapButtonVariant.ghost,
              child: const Text('Retour'),
            ),
          ),
        ],
      );
    }
    return ListView(
      key: const Key('smart-tile-reconstruction-editor'),
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Reconstruire une couche littérale',
          description:
              'Le Studio inverse les règles visuelles du preset pour retrouver les matériaux, arêtes et coins natifs.',
        ),
        const SizedBox(height: 14),
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Assistant non destructif',
          message:
              'La couche littérale restera intacte. La proposition Smart Tiles sera ajoutée juste après et masquée pour permettre la comparaison.',
        ),
        const SizedBox(height: 14),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PokeMapDropdownField<String>(
                label: 'Couche source',
                value: _sourceLayerId!,
                enabled: !busy,
                items: <PokeMapDropdownItem<String>>[
                  for (final layer in sources)
                    PokeMapDropdownItem<String>(
                      value: layer.id,
                      label: layer.name,
                    ),
                ],
                onChanged: _selectSource,
              ),
              const SizedBox(height: 12),
              PokeMapDropdownField<String>(
                label: 'Preset Smart Tile publié',
                value: _presetId!,
                enabled: !busy,
                items: <PokeMapDropdownItem<String>>[
                  for (final preset in presets)
                    PokeMapDropdownItem<String>(
                      value: preset.id,
                      label: '${preset.name} • ${_usageLabel(preset.usage)}',
                    ),
                ],
                onChanged: (value) => setState(() => _presetId = value),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: PokeMapTextField(
                      label: 'Identifiant de la nouvelle couche',
                      controller: _targetIdController,
                      enabled: !busy,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PokeMapTextField(
                      label: 'Nom visible',
                      controller: _targetNameController,
                      enabled: !busy,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.externalError case final error?) ...<Widget>[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            key: const Key('smart-tile-reconstruction-error'),
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Reconstruction impossible',
            message: error,
          ),
        ],
        if (plan != null) ...<Widget>[
          const SizedBox(height: 16),
          PokeMapCard(
            key: const Key('smart-tile-reconstruction-assessment'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const PokeMapSectionHeader(
                  title: 'Résultat de l’analyse',
                  description:
                      'Cette prévisualisation est liée à la révision actuelle du projet.',
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    PokeMapBadge(
                      label: 'Couverture ${(plan.coverage * 100).round()} %',
                      variant: plan.coverage == 1
                          ? PokeMapBadgeVariant.success
                          : PokeMapBadgeVariant.warning,
                    ),
                    PokeMapBadge(
                      label: _exactMatchLabel(plan.exactVisualMatchCount),
                      variant: plan.visualMismatchCellCount == 0
                          ? PokeMapBadgeVariant.success
                          : PokeMapBadgeVariant.warning,
                    ),
                    if (plan.unresolvedCellCount > 0)
                      PokeMapBadge(
                        label:
                            '${plan.unresolvedCellCount} tuile(s) non reconnue(s)',
                        variant: PokeMapBadgeVariant.warning,
                      ),
                    if (plan.ambiguousCellCount > 0 || plan.conflictCount > 0)
                      PokeMapBadge(
                        label:
                            '${plan.ambiguousCellCount + plan.conflictCount} ambiguïté(s)',
                        variant: PokeMapBadgeVariant.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                PokeMapDiagnosticCallout(
                  severity: plan.coverage == 1 &&
                          plan.visualMismatchCellCount == 0 &&
                          plan.conflictCount == 0
                      ? PokeMapDiagnosticSeverity.info
                      : PokeMapDiagnosticSeverity.warning,
                  title: plan.coverage == 1
                      ? 'Proposition complète'
                      : 'Proposition partielle',
                  message:
                      '${plan.reconstructedCellCount} cellule(s) reconstruite(s) sur ${plan.sourceCellCount}. '
                      'La source est conservée et la nouvelle couche restera masquée.',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            PokeMapButton(
              key: const Key('smart-tile-reconstruction-cancel'),
              onPressed: busy ? null : widget.onCancel,
              variant: PokeMapButtonVariant.ghost,
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              key: const Key('smart-tile-reconstruction-inspect'),
              onPressed: _canInspect && !busy ? _inspect : null,
              variant: plan == null
                  ? PokeMapButtonVariant.primary
                  : PokeMapButtonVariant.secondary,
              leading: widget.isPlanning
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(CupertinoIcons.search, size: 15),
              child: Text(
                widget.isPlanning
                    ? 'Analyse en cours…'
                    : plan == null
                        ? 'Analyser la reconstruction'
                        : 'Relancer l’analyse',
              ),
            ),
            if (plan != null)
              PokeMapButton(
                key: const Key('smart-tile-reconstruction-apply'),
                onPressed: busy ? null : widget.onApply,
                leading: widget.isApplying
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.checkmark_shield, size: 15),
                child: Text(
                  widget.isApplying
                      ? 'Création en cours…'
                      : 'Confirmer et créer la couche',
                ),
              ),
          ],
        ),
      ],
    );
  }

  SmartTileReconstructionPlan? get _matchingPlan {
    final plan = widget.plan;
    if (plan == null ||
        plan.request.mapId != widget.map.id ||
        plan.request.sourceLayerId != _sourceLayerId ||
        plan.request.presetId != _presetId ||
        plan.request.targetLayerId != _targetIdController.text.trim() ||
        plan.request.targetLayerName != _targetNameController.text.trim()) {
      return null;
    }
    return plan;
  }

  bool get _canInspect =>
      _sourceLayerId != null &&
      _presetId != null &&
      _targetIdController.text.trim().isNotEmpty &&
      _targetNameController.text.trim().isNotEmpty;

  Future<void> _inspect() async {
    if (!_canInspect) return;
    await widget.onInspect(
      SmartTileReconstructionRequest(
        mapId: widget.map.id,
        sourceLayerId: _sourceLayerId!,
        presetId: _presetId!,
        targetLayerId: _targetIdController.text.trim(),
        targetLayerName: _targetNameController.text.trim(),
      ),
    );
  }

  void _selectSource(String sourceLayerId) {
    final source = _sources.singleWhere((layer) => layer.id == sourceLayerId);
    setState(() {
      _sourceLayerId = sourceLayerId;
      _targetIdController.text = _suggestTargetId(source.id);
      _targetNameController.text = '${source.name} — Smart Tiles';
    });
  }
}

String _suggestTargetId(String sourceLayerId) {
  final stem = sourceLayerId
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9_]+'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return '${stem.isEmpty ? 'layer' : stem}_smart_tiles';
}

String _usageLabel(SmartTileUsage usage) => switch (usage) {
      SmartTileUsage.terrain => 'Terrain',
      SmartTileUsage.path => 'Chemin',
      SmartTileUsage.forestSurface => 'Surface forestière',
    };

String _exactMatchLabel(int count) => count == 1
    ? '1 correspondance visuelle exacte'
    : '$count correspondances visuelles exactes';
