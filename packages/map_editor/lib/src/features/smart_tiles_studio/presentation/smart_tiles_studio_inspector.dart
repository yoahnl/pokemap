import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_studio_library.dart';

class SmartTilesStudioInspector extends StatelessWidget {
  const SmartTilesStudioInspector({
    super.key,
    required this.isCreating,
    required this.isResumedDraft,
    required this.wizardStepLabel,
    required this.sourceChoiceLabel,
    required this.selectedItem,
    required this.diagnostics,
    required this.canAddSelectedPresetToMap,
    required this.isAddingSelectedPreset,
    this.selectedItemPreview,
    this.addSelectedPresetDisabledReason,
    this.onAddSelectedPresetToMap,
  });

  final bool isCreating;
  final bool isResumedDraft;
  final String wizardStepLabel;
  final String sourceChoiceLabel;
  final SmartTileLibraryItem? selectedItem;
  final List<SmartTileDiagnostic> diagnostics;
  final Widget? selectedItemPreview;
  final bool canAddSelectedPresetToMap;
  final bool isAddingSelectedPreset;
  final String? addSelectedPresetDisabledReason;
  final VoidCallback? onAddSelectedPresetToMap;

  @override
  Widget build(BuildContext context) {
    final item = selectedItem;
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(14),
      header: const Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: PokeMapSectionHeader(
          title: 'Inspecteur',
          description: 'Propriétés et validation contextuelle',
        ),
      ),
      child: ListView(
        children: <Widget>[
          if (isCreating) ...[
            PokeMapBadge(
              key: const Key('smart-tiles-active-draft-kind'),
              label:
                  isResumedDraft ? 'Brouillon repris' : 'Brouillon de session',
              variant: PokeMapBadgeVariant.warning,
            ),
            const SizedBox(height: 12),
            _InspectorValue(label: 'Étape', value: wizardStepLabel),
            _InspectorValue(label: 'Source', value: sourceChoiceLabel),
          ] else if (item != null) ...[
            PokeMapBadge(
              label: item.statusLabel,
              variant: item.isPattern
                  ? PokeMapBadgeVariant.info
                  : item.statusLabel == 'Publié'
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.warning,
            ),
            const SizedBox(height: 12),
            if (selectedItemPreview case final preview?) ...[
              Align(alignment: Alignment.centerLeft, child: preview),
              const SizedBox(height: 12),
            ],
            _InspectorValue(label: 'Nom', value: item.name),
            if (!item.isPattern)
              _InspectorValue(label: 'Identifiant', value: item.id),
            _InspectorValue(label: 'Usage', value: item.usageLabel),
            _InspectorValue(
              label: 'Origine',
              value: item.isPattern ? 'Motif natif' : 'Natif v6',
            ),
            if (item.nativePreset != null) ...[
              const SizedBox(height: 12),
              PokeMapButton(
                key: const Key('smart-tiles-add-to-active-map'),
                onPressed:
                    canAddSelectedPresetToMap ? onAddSelectedPresetToMap : null,
                disabledReason: addSelectedPresetDisabledReason,
                leading: isAddingSelectedPreset
                    ? const CupertinoActivityIndicator(radius: 7)
                    : const Icon(CupertinoIcons.square_grid_3x2, size: 15),
                child: const Text('Ajouter à la map active'),
              ),
            ],
          ] else
            const PokeMapEmptyState(
              title: 'Rien à inspecter',
              description: 'Sélectionnez un preset ou créez un brouillon.',
            ),
          const SizedBox(height: 18),
          PokeMapSectionHeader(
            title: 'Diagnostics du catalogue',
            description: diagnostics.isEmpty
                ? 'Aucune erreur structurelle.'
                : '${diagnostics.length} diagnostic(s) à examiner.',
          ),
          PokeMapBadge(
            label: diagnostics.isEmpty
                ? 'Structure valide'
                : '${diagnostics.length} diagnostic(s)',
            variant: diagnostics.any((diagnostic) => diagnostic.isError)
                ? PokeMapBadgeVariant.error
                : PokeMapBadgeVariant.warning,
          ),
        ],
      ),
    );
  }
}

class _InspectorValue extends StatelessWidget {
  const _InspectorValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
