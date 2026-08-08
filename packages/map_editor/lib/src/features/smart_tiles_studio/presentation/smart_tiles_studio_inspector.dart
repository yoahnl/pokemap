import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/editor_receipt_presenter.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_studio_library.dart';

class SmartTilesStudioInspector extends StatefulWidget {
  const SmartTilesStudioInspector({
    super.key,
    required this.isCreating,
    required this.isResumedDraft,
    required this.wizardStepLabel,
    required this.sourceChoiceLabel,
    required this.selectedItem,
    required this.diagnostics,
    required this.isCapturedMapAvailable,
    this.selectedItemPreview,
    this.onPublishSelectedPreset,
    this.onUpdateSelectedPreset,
    this.onAddSelectedPresetToMap,
  });

  final bool isCreating;
  final bool isResumedDraft;
  final String wizardStepLabel;
  final String sourceChoiceLabel;
  final SmartTileLibraryItem? selectedItem;
  final List<SmartTileDiagnostic> diagnostics;
  final bool isCapturedMapAvailable;
  final Widget? selectedItemPreview;
  final Future<void> Function(ProjectSmartTilePreset preset)?
      onPublishSelectedPreset;
  final Future<void> Function(ProjectSmartTilePreset preset)?
      onUpdateSelectedPreset;
  final Future<bool> Function(ProjectSmartTilePreset preset)?
      onAddSelectedPresetToMap;

  @override
  State<SmartTilesStudioInspector> createState() =>
      _SmartTilesStudioInspectorState();
}

class _SmartTilesStudioInspectorState extends State<SmartTilesStudioInspector> {
  bool _publishing = false;
  bool _updating = false;
  bool _adding = false;
  String? _actionError;

  @override
  void didUpdateWidget(covariant SmartTilesStudioInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItem?.key != widget.selectedItem?.key) {
      _actionError = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.selectedItem;
    final preset = item?.nativePreset;
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
          if (widget.isCreating) ...[
            PokeMapBadge(
              key: const Key('smart-tiles-active-draft-kind'),
              label: widget.isResumedDraft
                  ? 'Brouillon repris'
                  : 'Brouillon de session',
              variant: PokeMapBadgeVariant.warning,
            ),
            const SizedBox(height: 12),
            _InspectorValue(label: 'Étape', value: widget.wizardStepLabel),
            _InspectorValue(label: 'Source', value: widget.sourceChoiceLabel),
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
            if (widget.selectedItemPreview case final preview?) ...[
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
            if (preset?.status == SmartTilePresetStatus.draft) ...[
              const SizedBox(height: 12),
              PokeMapButton(
                key: const Key('smart-tiles-publish-imported-preset'),
                onPressed: widget.onPublishSelectedPreset == null || _publishing
                    ? null
                    : () => unawaited(_publish(preset!)),
                disabledReason: widget.onPublishSelectedPreset == null
                    ? 'Ouvrez un projet enregistrable pour publier ce preset.'
                    : _publishing
                        ? 'Publication en cours.'
                        : null,
                leading: _publishing
                    ? const CupertinoActivityIndicator(radius: 7)
                    : const Icon(CupertinoIcons.cloud_upload, size: 15),
                child: const Text('Publier dans la bibliothèque'),
              ),
            ],
            if (preset != null) ...[
              const SizedBox(height: 12),
              PokeMapButton(
                key: const Key('smart-tiles-rename-preset'),
                onPressed: widget.onUpdateSelectedPreset == null || _updating
                    ? null
                    : () => unawaited(_rename(preset)),
                disabledReason: widget.onUpdateSelectedPreset == null
                    ? 'Ouvrez un projet enregistrable pour renommer ce preset.'
                    : _updating
                        ? 'Mise à jour en cours.'
                        : null,
                leading: _updating
                    ? const CupertinoActivityIndicator(radius: 7)
                    : const Icon(CupertinoIcons.pencil, size: 15),
                child: const Text('Renommer'),
              ),
              const SizedBox(height: 8),
              PokeMapButton(
                key: const Key('smart-tiles-add-to-active-map'),
                onPressed: _canAddToMap(preset)
                    ? () => unawaited(_addToMap(preset))
                    : null,
                disabledReason: _addToMapDisabledReason(preset),
                leading: _adding
                    ? const CupertinoActivityIndicator(radius: 7)
                    : const Icon(CupertinoIcons.square_grid_3x2, size: 15),
                child: const Text('Ajouter à la map active'),
              ),
            ],
            if (_actionError case final error?) ...[
              const SizedBox(height: 8),
              PokeMapDiagnosticCallout(
                key: const Key('smart-tiles-selected-preset-action-error'),
                severity: PokeMapDiagnosticSeverity.error,
                message: error,
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
            description: widget.diagnostics.isEmpty
                ? 'Aucune erreur structurelle.'
                : '${widget.diagnostics.length} diagnostic(s) à examiner.',
          ),
          PokeMapBadge(
            label: widget.diagnostics.isEmpty
                ? 'Structure valide'
                : '${widget.diagnostics.length} diagnostic(s)',
            variant: widget.diagnostics.any((diagnostic) => diagnostic.isError)
                ? PokeMapBadgeVariant.error
                : PokeMapBadgeVariant.warning,
          ),
        ],
      ),
    );
  }

  bool _canAddToMap(ProjectSmartTilePreset preset) {
    return !_adding &&
        preset.status == SmartTilePresetStatus.published &&
        widget.isCapturedMapAvailable &&
        widget.onAddSelectedPresetToMap != null;
  }

  String? _addToMapDisabledReason(ProjectSmartTilePreset preset) {
    if (_adding) return 'Ajout de la couche en cours.';
    if (preset.status != SmartTilePresetStatus.published) {
      return 'Publiez ce preset avant de l’ajouter à une carte.';
    }
    if (!widget.isCapturedMapAvailable) {
      return 'Ouvrez une carte enregistrée depuis laquelle le Studio a été lancé.';
    }
    if (widget.onAddSelectedPresetToMap == null) {
      return 'La session canonique de la carte n’est pas disponible.';
    }
    return null;
  }

  Future<void> _publish(ProjectSmartTilePreset preset) async {
    final callback = widget.onPublishSelectedPreset;
    if (callback == null || _publishing) return;
    setState(() {
      _publishing = true;
      _actionError = null;
    });
    try {
      await callback(preset);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = EditorAuthoringMutationFailure.capture(error).message;
      });
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _rename(ProjectSmartTilePreset preset) async {
    final callback = widget.onUpdateSelectedPreset;
    if (callback == null || _updating) return;
    final controller = TextEditingController(text: preset.name);
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Renommer le Smart Tile',
      controller: controller,
      placeholder: 'Nom du Smart Tile',
      cancelLabel: 'Annuler',
      confirmLabel: 'Renommer',
    );
    final name = controller.text.trim();
    controller.dispose();
    if (!confirmed || !mounted || name == preset.name) return;
    if (name.isEmpty) {
      setState(
          () => _actionError = 'Le nom du Smart Tile ne peut pas être vide.');
      return;
    }
    setState(() {
      _updating = true;
      _actionError = null;
    });
    try {
      await callback(preset.copyWith(name: name));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = EditorAuthoringMutationFailure.capture(error).message;
      });
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _addToMap(ProjectSmartTilePreset preset) async {
    final callback = widget.onAddSelectedPresetToMap;
    if (callback == null || _adding) return;
    setState(() {
      _adding = true;
      _actionError = null;
    });
    try {
      final added = await callback(preset);
      if (!added && mounted) {
        setState(() {
          _actionError = 'La couche n’a pas pu être ajoutée à la carte.';
        });
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _actionError = EditorAuthoringMutationFailure.capture(error).message;
      });
    } finally {
      if (mounted) setState(() => _adding = false);
    }
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
