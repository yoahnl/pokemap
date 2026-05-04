import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/environment_area_generation_readiness.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Inspecteur Environment Studio : cible tuile (Lot 20) + zones (Lot 21), sans canvas.
class EnvironmentLayerInspectorPanel extends ConsumerWidget {
  const EnvironmentLayerInspectorPanel({
    super.key,
    required this.map,
    required this.layer,
    this.embedded = false,
  });

  final MapData map;
  final EnvironmentLayer layer;
  final bool embedded;

  List<TileLayer> _tileLayers() {
    final out = <TileLayer>[];
    for (final l in map.layers) {
      if (l is TileLayer) {
        out.add(l);
      }
    }
    return out;
  }

  TileLayer? _resolveTarget() {
    final tid = layer.content.targetTileLayerId;
    if (tid == null) return null;
    for (final l in map.layers) {
      if (l.id == tid && l is TileLayer) {
        return l;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final manifest = ref.watch(editorProjectManifestProvider);
    final tiles = _tileLayers();
    final target = _resolveTarget();
    final tid = layer.content.targetTileLayerId;
    final invalidTarget = tid != null && target == null;
    final presets = manifest?.environmentPresets ?? const <EnvironmentPreset>[];

    return SingleChildScrollView(
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(embedded ? 8 : 10, 4, embedded ? 8 : 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Environment Layer',
              key: const Key('map-inspector-environment-layer-title'),
              style: TextStyle(
                color: label,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ce layer servira à dessiner des zones organiques et à générer des '
              'éléments naturels.',
              key: const Key('map-inspector-environment-layer-body'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Zones d’environnement',
              key: const Key('env-layer-inspector-zones-title'),
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Les zones définissent où les presets organiques seront générés. '
              'Peignez le masque par zone pour marquer les cellules actives.',
              key: const Key('env-layer-inspector-zones-desc'),
              style: TextStyle(
                color: subtle,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (presets.isEmpty) ...[
              Text(
                'Aucun preset d’environnement disponible.\n'
                'Créez d’abord un preset dans Environment Studio.',
                key: const Key('env-layer-inspector-no-presets'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              if (layer.content.areas.isEmpty)
                Text(
                  'Aucune zone d’environnement pour ce layer.',
                  key: const Key('env-layer-inspector-no-areas'),
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ...layer.content.areas.map(
                  (area) => _EnvironmentAreaCard(
                    area: area,
                    manifest: manifest,
                    layerId: layer.id,
                    labelColor: label,
                    subtleColor: subtle,
                    resolvedTargetTileLayer: target,
                    targetTileLayerInvalid: invalidTarget,
                    hasTargetTileLayerId: tid != null,
                  ),
                ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-add-area'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickPresetAndAddArea(
                  context,
                  notifier,
                  presets,
                ),
                child: const Text('Ajouter une zone'),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'TileLayer cible',
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (tiles.isEmpty) ...[
              Text(
                'Aucun TileLayer disponible dans cette map.\n'
                'Ajoutez d’abord un TileLayer pour recevoir les résultats générés.',
                key: const Key('env-layer-inspector-no-tile-layers'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (invalidTarget) ...[
              Text(
                'La cible configurée est introuvable ou invalide : $tid',
                key: const Key('env-layer-inspector-invalid-target'),
                style: TextStyle(
                  color: CupertinoColors.systemOrange.resolveFrom(context),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-change-invalid'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickTileLayer(context, notifier, tiles),
                child: const Text('Choisir un autre TileLayer cible'),
              ),
              const SizedBox(height: 8),
              PushButton(
                key: const Key('env-layer-inspector-remove-invalid'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                  environmentLayerId: layer.id,
                  targetTileLayerId: null,
                ),
                child: const Text('Retirer la cible'),
              ),
            ] else if (target == null) ...[
              Text(
                'Aucun TileLayer cible sélectionné.',
                key: const Key('env-layer-inspector-no-target'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Vous pouvez peindre le masque maintenant. Le TileLayer cible '
                'sera nécessaire pour générer plus tard.',
                key: const Key('env-layer-inspector-mask-without-target-note'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-choose-target'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickTileLayer(context, notifier, tiles),
                child: const Text('Choisir le TileLayer cible'),
              ),
            ] else ...[
              Text(
                'Cible actuelle : ${target.name}',
                key: const Key('env-layer-inspector-current-target-name'),
                style: TextStyle(
                  color: label,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Id : ${target.id}',
                key: const Key('env-layer-inspector-current-target-id'),
                style: TextStyle(
                  color: subtle,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: const Key('env-layer-inspector-change-target'),
                controlSize: ControlSize.regular,
                onPressed: () => _pickTileLayer(context, notifier, tiles),
                child: const Text('Changer de TileLayer cible'),
              ),
              const SizedBox(height: 8),
              PushButton(
                key: const Key('env-layer-inspector-remove-target'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: () => notifier.setEnvironmentLayerTargetTileLayer(
                  environmentLayerId: layer.id,
                  targetTileLayerId: null,
                ),
                child: const Text('Retirer la cible'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickTileLayer(
    BuildContext context,
    EditorNotifier notifier,
    List<TileLayer> tiles,
  ) async {
    final picked = await showCupertinoListPicker<TileLayer>(
      context: context,
      title: 'TileLayer cible',
      items: tiles,
      labelOf: (t) => t.name,
    );
    if (picked == null) return;
    notifier.setEnvironmentLayerTargetTileLayer(
      environmentLayerId: layer.id,
      targetTileLayerId: picked.id,
    );
  }

  Future<void> _pickPresetAndAddArea(
    BuildContext context,
    EditorNotifier notifier,
    List<EnvironmentPreset> presets,
  ) async {
    final picked = await showCupertinoListPicker<EnvironmentPreset>(
      context: context,
      title: 'Preset d’environnement',
      items: presets,
      labelOf: (p) => '${p.name} — ${p.id}',
    );
    if (picked == null) return;
    notifier.addEnvironmentAreaToLayer(
      environmentLayerId: layer.id,
      presetId: picked.id,
    );
  }
}

const _kGenerateHelp =
    'Crée des placements dans le TileLayer cible en utilisant le preset et le '
    'masque de cette zone.';

const _kClearHelp =
    'Supprime uniquement les placements listés pour cette zone (pas le masque, '
    'pas les placements posés manuellement ailleurs).';

const _kShuffleHelp =
    'Change la seed de cette zone puis génère de nouveaux placements.';

const _kRegenerateHelp =
    'Recrée les placements générés en conservant la seed actuelle.';

class _EnvironmentAreaCard extends ConsumerWidget {
  const _EnvironmentAreaCard({
    required this.area,
    required this.manifest,
    required this.layerId,
    required this.labelColor,
    required this.subtleColor,
    required this.resolvedTargetTileLayer,
    required this.targetTileLayerInvalid,
    required this.hasTargetTileLayerId,
  });

  final EnvironmentArea area;
  final ProjectManifest? manifest;
  final String layerId;
  final Color labelColor;
  final Color subtleColor;

  /// `null` si pas de cible ou cible non résolue.
  final TileLayer? resolvedTargetTileLayer;
  final bool targetTileLayerInvalid;
  final bool hasTargetTileLayerId;

  EnvironmentPreset? _presetForArea() {
    final m = manifest;
    if (m == null) return null;
    for (final p in m.environmentPresets) {
      if (p.id == area.presetId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final editorState = ref.watch(editorNotifierProvider);
    final manifestPresets =
        manifest?.environmentPresets ?? const <EnvironmentPreset>[];
    final preset = _presetForArea();
    final readiness = EnvironmentAreaGenerationReadiness.evaluate(
      area: area,
      preset: preset,
      hasTargetTileLayerId: hasTargetTileLayerId,
      targetTileLayerInvalid: targetTileLayerInvalid,
      resolvedTargetTileLayer: resolvedTargetTileLayer,
    );
    final regenerateEnabled = readiness.canRegenerate;
    final shuffleEnabled = readiness.canShuffle;
    final totalCells = area.mask.width * area.mask.height;
    final activeCount = area.mask.activeCellCount;
    final maskLabel = 'Masque : $activeCount / $totalCells cellules actives';
    final warnPlacements = area.generatedPlacementIds.isNotEmpty;
    final isThisAreaActiveForMask = editorState.activeLayerId == layerId &&
        editorState.selectedEnvironmentAreaId == area.id;
    final maskMode = editorState.environmentMaskEditMode;
    String? editModeLabel;
    if (isThisAreaActiveForMask && maskMode != null) {
      editModeLabel = maskMode == EnvironmentMaskEditMode.paint
          ? 'Édition active : peinture'
          : 'Édition active : effacement';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zone : ${area.id}',
                key: Key('env-area-card-id-${area.id}'),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              if (preset != null) ...[
                Text(
                  'Preset : ${preset.name}',
                  key: Key('env-area-card-preset-name-${area.id}'),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Id preset : ${preset.id}',
                  key: Key('env-area-card-preset-id-${area.id}'),
                  style: TextStyle(
                    color: subtleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                Text(
                  'Preset associé introuvable : ${area.presetId}',
                  key: Key('env-area-card-preset-missing-${area.id}'),
                  style: TextStyle(
                    color: CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                maskLabel,
                key: Key('env-area-card-mask-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (editModeLabel != null) ...[
                const SizedBox(height: 6),
                Text(
                  editModeLabel,
                  key: Key('env-area-card-mask-edit-active-${area.id}'),
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Placements générés : ${area.generatedPlacementIds.length}',
                key: Key('env-area-card-placements-count-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Seed : ${area.seed}',
                key: Key('env-area-seed-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                readiness.stateSummaryLine,
                key: Key('env-area-readiness-summary-${area.id}'),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (warnPlacements) ...[
                const SizedBox(height: 6),
                Text(
                  'Cette zone référence des placements générés ; le retrait ne les '
                  'supprime pas automatiquement.',
                  key: Key('env-area-card-placements-warn-${area.id}'),
                  style: TextStyle(
                    color: CupertinoColors.systemOrange.resolveFrom(context),
                    fontSize: 10.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              PushButton(
                key: Key('env-area-mask-paint-${area.id}'),
                controlSize: ControlSize.small,
                onPressed: () => notifier.startEnvironmentAreaMaskPaint(
                  environmentLayerId: layerId,
                  areaId: area.id,
                ),
                child: const Text('Peindre le masque'),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-mask-erase-${area.id}'),
                controlSize: ControlSize.small,
                onPressed: () => notifier.startEnvironmentAreaMaskErase(
                  environmentLayerId: layerId,
                  areaId: area.id,
                ),
                child: const Text('Effacer du masque'),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-mask-stop-${area.id}'),
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: isThisAreaActiveForMask && maskMode != null
                    ? notifier.stopEnvironmentAreaMaskEditing
                    : null,
                child: const Text('Arrêter l’édition'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.generateDisabledMessage ?? _kGenerateHelp,
                key: Key('env-area-generate-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-generate-${area.id}'),
                controlSize: ControlSize.regular,
                onPressed: readiness.canGenerate
                    ? () => notifier.generateEnvironmentAreaPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Générer dans la map'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.clearDisabledMessage == null
                    ? _kClearHelp
                    : readiness.clearDisabledMessage!,
                key: Key('env-area-clear-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-clear-${area.id}'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: readiness.canClear
                    ? () => notifier.clearEnvironmentGeneratedPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Effacer les placements générés'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.regenerateDisabledMessage ?? _kRegenerateHelp,
                key: Key('env-area-regenerate-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-regenerate-${area.id}'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: regenerateEnabled
                    ? () => notifier.regenerateEnvironmentAreaPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Régénérer'),
              ),
              const SizedBox(height: 10),
              Text(
                readiness.shuffleDisabledMessage ?? _kShuffleHelp,
                key: Key('env-area-shuffle-hint-${area.id}'),
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 10.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-shuffle-${area.id}'),
                controlSize: ControlSize.regular,
                secondary: true,
                onPressed: shuffleEnabled
                    ? () => notifier.shuffleEnvironmentAreaPlacements(
                          environmentLayerId: layerId,
                          areaId: area.id,
                        )
                    : null,
                child: const Text('Mélanger et régénérer'),
              ),
              const SizedBox(height: 10),
              PushButton(
                key: Key('env-area-change-preset-${area.id}'),
                controlSize: ControlSize.small,
                onPressed: manifestPresets.isEmpty
                    ? null
                    : () => _pickPresetForArea(
                          context,
                          notifier,
                          manifestPresets,
                        ),
                child: const Text('Changer de preset'),
              ),
              const SizedBox(height: 6),
              PushButton(
                key: Key('env-area-remove-${area.id}'),
                controlSize: ControlSize.small,
                secondary: true,
                onPressed: () => notifier.removeEnvironmentArea(
                  environmentLayerId: layerId,
                  areaId: area.id,
                ),
                child: const Text('Retirer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPresetForArea(
    BuildContext context,
    EditorNotifier notifier,
    List<EnvironmentPreset> presets,
  ) async {
    final picked = await showCupertinoListPicker<EnvironmentPreset>(
      context: context,
      title: 'Nouveau preset',
      items: presets,
      labelOf: (p) => '${p.name} — ${p.id}',
    );
    if (picked == null) return;
    notifier.setEnvironmentAreaPreset(
      environmentLayerId: layerId,
      areaId: area.id,
      presetId: picked.id,
    );
  }
}
