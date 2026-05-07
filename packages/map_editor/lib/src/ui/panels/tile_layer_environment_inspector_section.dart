import 'package:flutter/cupertino.dart';

import '../../application/models/tile_layer_environment_attachment_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

class TileLayerEnvironmentInspectorSection extends StatelessWidget {
  const TileLayerEnvironmentInspectorSection({
    super.key,
    required this.readModel,
    this.onEnableEnvironment,
    this.availablePresets = const [],
    this.selectedPresetIdForNewArea,
    this.onSelectPresetForNewArea,
    this.onCreateArea,
    this.isMaskPaintingActive = false,
    this.onStartMaskPainting,
    this.onStopMaskPainting,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final VoidCallback? onEnableEnvironment;
  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final ValueChanged<String>? onSelectPresetForNewArea;
  final VoidCallback? onCreateArea;
  final bool isMaskPaintingActive;
  final VoidCallback? onStartMaskPainting;
  final VoidCallback? onStopMaskPainting;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return SingleChildScrollView(
      padding: kInspectorTileBodyPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _stateTitle(readModel),
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (readModel.isLegacyEnvironmentLayerSelection)
                const _StatusPill(
                  label: 'Mode legacy',
                  accent: accent,
                ),
            ],
          ),
          if (readModel.emptyStateMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              readModel.emptyStateMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SummaryRows(readModel: readModel),
          if (readModel.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...readModel.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _IssueBanner(issue: issue),
              ),
            ),
          ],
          if (isMaskPaintingActive) ...[
            const SizedBox(height: 12),
            const _ActivePaintingBanner(),
          ],
          const SizedBox(height: 12),
          if (_shouldShowCreateAreaGate(readModel)) ...[
            _CreateAreaPresetGate(
              availablePresets: availablePresets,
              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
              onSelectPresetForNewArea: onSelectPresetForNewArea,
            ),
            const SizedBox(height: 12),
          ],
          _FutureActions(
            readModel: readModel,
            onEnableEnvironment: onEnableEnvironment,
            availablePresets: availablePresets,
            selectedPresetIdForNewArea: selectedPresetIdForNewArea,
            onCreateArea: onCreateArea,
            isMaskPaintingActive: isMaskPaintingActive,
            onStartMaskPainting: onStartMaskPainting,
            onStopMaskPainting: onStopMaskPainting,
          ),
          const SizedBox(height: 8),
          const InspectorEmbeddedFootnote(
            text:
                'Section de lecture uniquement : les actions seront activées dans un prochain lot.',
            accent: accent,
          ),
        ],
      ),
    );
  }
}

final class TileLayerEnvironmentPresetOption {
  const TileLayerEnvironmentPresetOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class _ActivePaintingBanner extends StatelessWidget {
  const _ActivePaintingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peinture active',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRows extends StatelessWidget {
  const _SummaryRows({required this.readModel});

  final TileLayerEnvironmentAttachmentReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final rows = <_SummaryRowData>[];
    final activeTileLayerName = readModel.activeTileLayerName?.trim();
    if (activeTileLayerName != null && activeTileLayerName.isNotEmpty) {
      rows.add(_SummaryRowData('Layer', activeTileLayerName));
    }
    final presetName = readModel.selectedPresetName?.trim();
    final presetId = readModel.selectedPresetId?.trim();
    if (presetName != null && presetName.isNotEmpty) {
      rows.add(_SummaryRowData('Preset', presetName));
    } else if (presetId != null && presetId.isNotEmpty) {
      rows.add(_SummaryRowData('Preset', '$presetId introuvable'));
    }
    final areaName = readModel.selectedEnvironmentAreaName?.trim();
    if (areaName != null && areaName.isNotEmpty) {
      rows.add(_SummaryRowData('Zone', areaName));
    }
    if (readModel.hasAttachment || readModel.maskActiveCellCount > 0) {
      rows.add(
        _SummaryRowData(
          'Masque',
          _paintedCellsLabel(readModel.maskActiveCellCount),
        ),
      );
    }
    if (readModel.hasGeneratedPlacements ||
        readModel.generatedPlacementCount > 0) {
      rows.add(
        _SummaryRowData(
          'Placements générés',
          '${readModel.generatedPlacementCount}',
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SummaryRow(row: row),
          ),
      ],
    );
  }
}

class _CreateAreaPresetGate extends StatelessWidget {
  const _CreateAreaPresetGate({
    required this.availablePresets,
    required this.selectedPresetIdForNewArea,
    required this.onSelectPresetForNewArea,
  });

  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final ValueChanged<String>? onSelectPresetForNewArea;

  @override
  Widget build(BuildContext context) {
    final selectedPreset = _selectedPreset(
      availablePresets,
      selectedPresetIdForNewArea,
    );
    if (availablePresets.isEmpty) {
      return const InspectorEmbeddedFootnote(
        text:
            'Créez d’abord un preset dans Environment Studio avant d’ajouter une zone.',
        accent: EditorChrome.inspectorJoyMint,
      );
    }
    if (availablePresets.length == 1) {
      return _PresetGateText(
          'Preset utilisé : ${availablePresets.single.name}');
    }

    final selectedName = selectedPreset?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PresetGateText(
          selectedName == null
              ? 'Choisissez un preset avant d’ajouter une zone.'
              : 'Preset pour la nouvelle zone : $selectedName',
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyMint,
          fieldLabel: 'Preset pour la nouvelle zone',
          valueLabel: selectedName ?? 'Choisir un preset',
          orderedIds: availablePresets.map((preset) => preset.id).toList(),
          selectedMenuValue: selectedPreset?.id ?? '',
          selectedIdForCheck: selectedPreset?.id,
          idToLabel: (id) => _presetNameForId(availablePresets, id) ?? id,
          onSelected: onSelectPresetForNewArea ?? (_) {},
          allowUnsetSelection: true,
        ),
      ],
    );
  }
}

class _PresetGateText extends StatelessWidget {
  const _PresetGateText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: EditorChrome.primaryLabel(context),
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.row});

  final _SummaryRowData row;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${row.label} : ${row.value}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueBanner extends StatelessWidget {
  const _IssueBanner({required this.issue});

  final TileLayerEnvironmentAttachmentIssue issue;

  @override
  Widget build(BuildContext context) {
    final isError =
        issue.severity == TileLayerEnvironmentAttachmentIssueSeverity.error;
    final accent = isError
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.systemOrange.resolveFrom(context);
    final prefix = isError ? 'Erreur' : 'Attention';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.09),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        '$prefix : ${issue.message}',
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 11.5,
          height: 1.28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.readModel,
    required this.onEnableEnvironment,
    required this.availablePresets,
    required this.selectedPresetIdForNewArea,
    required this.onCreateArea,
    required this.isMaskPaintingActive,
    required this.onStartMaskPainting,
    required this.onStopMaskPainting,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;
  final VoidCallback? onEnableEnvironment;
  final List<TileLayerEnvironmentPresetOption> availablePresets;
  final String? selectedPresetIdForNewArea;
  final VoidCallback? onCreateArea;
  final bool isMaskPaintingActive;
  final VoidCallback? onStartMaskPainting;
  final VoidCallback? onStopMaskPainting;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[];
    if (readModel.canEnableEnvironment) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.add_circled,
          label: readModel.primaryActionLabel ?? 'Activer l’environnement',
          enabled: onEnableEnvironment != null,
          onPressed: onEnableEnvironment,
        ),
      );
    }
    if (_shouldShowCreateAreaGate(readModel)) {
      final hasPresetForNewArea =
          _selectedPreset(availablePresets, selectedPresetIdForNewArea) != null;
      actions.add(
        _ActionData(
          icon: CupertinoIcons.add_circled,
          label: readModel.primaryActionLabel ?? 'Ajouter une zone',
          enabled: !readModel.hasErrors &&
              hasPresetForNewArea &&
              onCreateArea != null,
          onPressed: onCreateArea,
        ),
      );
    }
    if (isMaskPaintingActive) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.stop_circle,
          label: 'Arrêter la peinture',
          enabled: onStopMaskPainting != null,
          onPressed: onStopMaskPainting,
        ),
      );
    } else if (readModel.canPaintMask) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.paintbrush,
          label: 'Peindre le masque',
          enabled: !readModel.hasErrors && onStartMaskPainting != null,
          onPressed: onStartMaskPainting,
        ),
      );
    }
    if (readModel.canGenerate) {
      actions.add(
        const _ActionData(
          icon: CupertinoIcons.play,
          label: 'Générer dans ce layer',
        ),
      );
    }
    if (readModel.canClearGeneratedPlacements) {
      actions.add(
        const _ActionData(
          icon: CupertinoIcons.trash,
          label: 'Effacer les placements générés',
        ),
      );
    }

    if (actions.isEmpty) {
      return InspectorEmbeddedSecondaryCapsule(
        accent: EditorChrome.inspectorJoyMint,
        icon: CupertinoIcons.clock,
        label: 'Actions bientôt disponibles',
        enabled: false,
        onPressed: () {},
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: InspectorEmbeddedPrimaryCapsule(
              accent: EditorChrome.inspectorJoyMint,
              icon: action.icon,
              label: action.label,
              enabled: action.enabled,
              onPressed: action.onPressed ?? () {},
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryRowData {
  const _SummaryRowData(this.label, this.value);

  final String label;
  final String value;
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.label,
    this.enabled = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;
}

bool _shouldShowCreateAreaGate(TileLayerEnvironmentAttachmentReadModel model) {
  return model.hasAttachment &&
      (model.state == TileLayerEnvironmentAttachmentState.noArea ||
          model.state ==
              TileLayerEnvironmentAttachmentState.areaSelectionRequired);
}

TileLayerEnvironmentPresetOption? _selectedPreset(
  List<TileLayerEnvironmentPresetOption> presets,
  String? selectedPresetId,
) {
  if (presets.length == 1) {
    return presets.single;
  }
  final id = selectedPresetId?.trim();
  if (id == null || id.isEmpty) {
    return null;
  }
  for (final preset in presets) {
    if (preset.id == id) {
      return preset;
    }
  }
  return null;
}

String? _presetNameForId(
  List<TileLayerEnvironmentPresetOption> presets,
  String id,
) {
  for (final preset in presets) {
    if (preset.id == id) {
      return preset.name;
    }
  }
  return null;
}

String _stateTitle(TileLayerEnvironmentAttachmentReadModel model) {
  final title = model.emptyStateTitle.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return switch (model.state) {
    TileLayerEnvironmentAttachmentState.ready => 'Prêt à générer',
    TileLayerEnvironmentAttachmentState.generated => 'Placements générés',
    TileLayerEnvironmentAttachmentState.emptyMask => 'Masque vide',
    TileLayerEnvironmentAttachmentState.missingPreset => 'Preset introuvable',
    TileLayerEnvironmentAttachmentState.noAttachment =>
      'Aucun environnement sur ce layer',
    TileLayerEnvironmentAttachmentState.noArea => 'Aucune zone d’environnement',
    TileLayerEnvironmentAttachmentState.areaSelectionRequired =>
      'Sélectionnez une zone d’environnement',
    TileLayerEnvironmentAttachmentState.selectedAreaMissing =>
      'Zone introuvable',
    TileLayerEnvironmentAttachmentState.missingTargetTileLayer =>
      'Layer cible manquant',
    TileLayerEnvironmentAttachmentState.targetTileLayerMissing =>
      'Layer cible introuvable',
    TileLayerEnvironmentAttachmentState.targetLayerIsNotTileLayer =>
      'Layer cible incompatible',
    TileLayerEnvironmentAttachmentState.noProject => 'Aucun projet chargé',
    TileLayerEnvironmentAttachmentState.noMap => 'Aucune carte active',
    TileLayerEnvironmentAttachmentState.noLayerSelected =>
      'Aucun layer sélectionné',
    TileLayerEnvironmentAttachmentState.selectedLayerMissing =>
      'Layer introuvable',
    TileLayerEnvironmentAttachmentState.unsupportedLayer =>
      'Sélectionnez un TileLayer',
  };
}

String _paintedCellsLabel(int count) {
  if (count <= 0) {
    return '0 case peinte';
  }
  if (count == 1) {
    return '1 case peinte';
  }
  return '$count cases peintes';
}
