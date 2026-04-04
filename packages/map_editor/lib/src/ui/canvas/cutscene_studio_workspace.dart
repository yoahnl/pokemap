import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../application/use_cases/project_scenario_use_cases.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/application/cutscene_studio_authoring.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

/// Workspace central "Cutscene Studio" (v1 guidé, no-code).
///
/// Philosophie produit:
/// - édition principale au CENTRE (pas dans l'inspecteur latéral),
/// - authoring en blocs de haut niveau,
/// - langage orienté usage ("faire parler", "exécuter script"...),
/// - éviter les IDs techniques bruts dans le parcours principal.
///
/// Limite assumée du lot:
/// - v1 supporte un flow linéaire guidé (sans branches complexes).
/// - les scénarios hors format v1 restent visibles mais en lecture seule, avec
///   explication explicite pour rester honnête sur l'état réel.
class CutsceneStudioWorkspace extends StatefulWidget {
  const CutsceneStudioWorkspace({
    super.key,
    required this.editorNotifier,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedCutscene,
    required this.onSelectCutscene,
    required this.onSelectOutcome,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final NarrativeScenarioSummary? selectedCutscene;
  final ValueChanged<String> onSelectCutscene;
  final ValueChanged<String?> onSelectOutcome;

  @override
  State<CutsceneStudioWorkspace> createState() =>
      _CutsceneStudioWorkspaceState();
}

class _CutsceneStudioWorkspaceState extends State<CutsceneStudioWorkspace> {
  CutsceneStudioDocument? _savedDocument;
  CutsceneStudioDocument? _draftDocument;
  List<String> _compatWarnings = const <String>[];
  bool _isStudioCompatible = false;
  String? _loadedScenarioId;
  bool _busy = false;

  // Cache lookup par map pour alimenter les dropdowns source (PNJ/triggers).
  //
  // Pourquoi ce cache existe:
  // - l'utilisateur ne doit pas devoir "ouvrir une map" juste pour choisir un
  //   PNJ dans la source d'une cutscene;
  // - on peut charger une snapshot de map (non destructive) puis réutiliser
  //   les options dans le dropdown tant que le workspace est ouvert.
  final Map<String, List<MapEntity>> _npcsByMapId = <String, List<MapEntity>>{};
  final Map<String, List<MapTrigger>> _triggersByMapId =
      <String, List<MapTrigger>>{};
  bool _isLoadingSourceLookups = false;
  String? _sourceLookupError;

  @override
  void initState() {
    super.initState();
    _hydrateFromSelection();
  }

  @override
  void didUpdateWidget(covariant CutsceneStudioWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedChanged =
        oldWidget.selectedCutscene?.id != widget.selectedCutscene?.id;
    final projectChanged = oldWidget.project != widget.project;
    final activeMapChanged = oldWidget.activeMap != widget.activeMap;
    if (selectedChanged || projectChanged) {
      _hydrateFromSelection();
      return;
    }
    if (activeMapChanged) {
      // Si la map active change, on ressynchronise les dropdowns source avec
      // cette version (potentiellement non sauvegardée) pour éviter un décalage
      // entre ce que l'utilisateur voit sur la map et ce que le studio propose.
      final sourceMapId = _draftDocument?.source.mapId;
      _primeSourceLookups(sourceMapId);
    }
  }

  void _hydrateFromSelection() {
    final selectedId = widget.selectedCutscene?.id;
    if (selectedId == null || selectedId.trim().isEmpty) {
      setState(() {
        _loadedScenarioId = null;
        _savedDocument = null;
        _draftDocument = null;
        _isStudioCompatible = false;
        _compatWarnings = const <String>[];
        _isLoadingSourceLookups = false;
        _sourceLookupError = null;
        _npcsByMapId.clear();
        _triggersByMapId.clear();
      });
      return;
    }
    final scenario = _findScenarioById(selectedId);
    if (scenario == null) {
      setState(() {
        _loadedScenarioId = selectedId;
        _savedDocument = null;
        _draftDocument = null;
        _isStudioCompatible = false;
        _compatWarnings = const <String>[
          'Le scénario sélectionné est introuvable dans le manifest.',
        ];
        _isLoadingSourceLookups = false;
        _sourceLookupError = null;
        _npcsByMapId.clear();
        _triggersByMapId.clear();
      });
      return;
    }
    final parse = parseScenarioToCutsceneStudioDocument(scenario);
    setState(() {
      _loadedScenarioId = scenario.id;
      _savedDocument = parse.document;
      _draftDocument = parse.document;
      _isStudioCompatible = parse.editable;
      _compatWarnings = parse.warnings;
      _isLoadingSourceLookups = false;
      _sourceLookupError = null;
      _npcsByMapId.clear();
      _triggersByMapId.clear();
    });
    _primeSourceLookups(parse.document.source.mapId);
  }

  ScenarioAsset? _findScenarioById(String id) {
    for (final scenario in widget.project.scenarios) {
      if (scenario.id == id) {
        return scenario;
      }
    }
    return null;
  }

  List<ProjectMapEntry> get _projectMaps {
    final list = widget.project.maps.toList(growable: false);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<MapEntity> _npcsForMap(String? mapId) {
    final normalized = _trimOrNull(mapId);
    if (normalized == null) {
      return const <MapEntity>[];
    }
    final activeMap = widget.activeMap;
    if (activeMap != null && activeMap.id == normalized) {
      return _sortedNpcs(activeMap.entities);
    }
    return _npcsByMapId[normalized] ?? const <MapEntity>[];
  }

  List<MapTrigger> _triggersForMap(String? mapId) {
    final normalized = _trimOrNull(mapId);
    if (normalized == null) {
      return const <MapTrigger>[];
    }
    final activeMap = widget.activeMap;
    if (activeMap != null && activeMap.id == normalized) {
      return _sortedTriggers(activeMap.triggers);
    }
    return _triggersByMapId[normalized] ?? const <MapTrigger>[];
  }

  List<MapEntity> _sortedNpcs(Iterable<MapEntity> entities) {
    return entities
        .where((entity) => entity.kind == MapEntityKind.npc)
        .toList(growable: false)
      ..sort(
        (a, b) => a.inspectorHeadline
            .toLowerCase()
            .compareTo(b.inspectorHeadline.toLowerCase()),
      );
  }

  List<MapTrigger> _sortedTriggers(Iterable<MapTrigger> triggers) {
    return triggers.toList(growable: false)
      ..sort((a, b) => a.id.toLowerCase().compareTo(b.id.toLowerCase()));
  }

  void _primeSourceLookups(String? mapId) {
    final normalizedMapId = _trimOrNull(mapId);
    if (normalizedMapId == null) {
      return;
    }
    unawaited(_ensureLookupsLoadedForMap(normalizedMapId));
  }

  Future<void> _ensureLookupsLoadedForMap(String mapId) async {
    // Cas 1: la map est active, on exploite la version en mémoire (incluant
    // d'éventuelles modifications non sauvegardées).
    final activeMap = widget.activeMap;
    if (activeMap != null && activeMap.id == mapId) {
      if (!mounted) return;
      setState(() {
        _npcsByMapId[mapId] = _sortedNpcs(activeMap.entities);
        _triggersByMapId[mapId] = _sortedTriggers(activeMap.triggers);
        _sourceLookupError = null;
        _isLoadingSourceLookups = false;
      });
      return;
    }

    // Cas 2: déjà chargé (snapshot disque), inutile de recharger.
    if (_npcsByMapId.containsKey(mapId) &&
        _triggersByMapId.containsKey(mapId)) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingSourceLookups = true;
        _sourceLookupError = null;
      });
    }

    // Cas 3: lecture non destructive d'une autre map.
    final loadedMap = await widget.editorNotifier.loadMapSnapshotById(mapId);
    if (!mounted) return;

    if (loadedMap == null) {
      setState(() {
        _isLoadingSourceLookups = false;
        _sourceLookupError =
            'Impossible de charger les PNJ/triggers pour la map "$mapId".';
        _npcsByMapId[mapId] = const <MapEntity>[];
        _triggersByMapId[mapId] = const <MapTrigger>[];
      });
      return;
    }

    setState(() {
      _npcsByMapId[mapId] = _sortedNpcs(loadedMap.entities);
      _triggersByMapId[mapId] = _sortedTriggers(loadedMap.triggers);
      _isLoadingSourceLookups = false;
      _sourceLookupError = null;
    });
  }

  bool get _hasUnsavedChanges =>
      _draftDocument != null &&
      _savedDocument != null &&
      _draftDocument != _savedDocument;

  bool get _canEdit => !_busy && _draftDocument != null && _isStudioCompatible;

  void _replaceDraft(CutsceneStudioDocument next) {
    setState(() {
      _draftDocument = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftDocument;
    if (draft == null) {
      return _buildEmptyState(context);
    }
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: ListView(
        children: [
          _buildHeader(context, draft),
          const SizedBox(height: 12),
          if (!_isStudioCompatible) ...[
            _CompatibilityWarningCard(
              warnings: _compatWarnings,
            ),
            const SizedBox(height: 12),
          ],
          _buildSourceSection(context, draft),
          const SizedBox(height: 12),
          _buildBlocksSection(context, draft),
          const SizedBox(height: 12),
          const InspectorEmbeddedFootnote(
            text:
                'Cutscene Studio v1 édite un flow guidé linéaire. Pour les graphes complexes, utilisez une migration progressive plutôt qu\'une édition destructive.',
            accent: EditorChrome.inspectorJoyPlum,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.play_rectangle_fill,
                size: 34,
                color: EditorChrome.inspectorJoyPlum,
              ),
              const SizedBox(height: 10),
              Text(
                'Aucune cutscene sélectionnée',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez une scène avec un template guidé: dialogue, script, hook map ou interaction PNJ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 260,
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyPlum,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Créer une cutscene',
                  prominent: true,
                  enabled: !_busy,
                  onPressed: _createCutsceneFromTemplateFlow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CutsceneStudioDocument draft) {
    final subtitle = _isStudioCompatible
        ? 'Édition guidée en blocs (v1).'
        : 'Scénario détecté hors format guidé v1 (lecture seule).';
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.name,
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasUnsavedChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        EditorChrome.inspectorJoyCoral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: EditorChrome.inspectorJoyCoral
                          .withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Text(
                    'Non sauvegardé',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyMint,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Nouvelle cutscene',
                  enabled: !_busy,
                  onPressed: _createCutsceneFromTemplateFlow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyBlue,
                  icon: CupertinoIcons.floppy_disk,
                  label: 'Sauvegarder',
                  prominent: true,
                  enabled: _canEdit && _hasUnsavedChanges,
                  onPressed: _saveDraftToProject,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCyan,
                  icon: CupertinoIcons.arrow_uturn_left,
                  label: 'Réinitialiser',
                  enabled: _canEdit && _hasUnsavedChanges,
                  onPressed: _restoreSavedDocument,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.delete,
              label: 'Supprimer cette cutscene',
              enabled: !_busy && _loadedScenarioId != null,
              onPressed: _deleteSelectedCutscene,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSection(
      BuildContext context, CutsceneStudioDocument draft) {
    final canEditSource = _canEdit;
    final selectedMapId = _trimOrNull(draft.source.mapId);
    final mapLabel = _mapLabelById(selectedMapId) ?? 'Choisir une map';
    final mapIds =
        _projectMaps.map((entry) => entry.id).toList(growable: false);
    final npcs = _npcsForMap(draft.source.mapId);
    final triggers = _triggersForMap(draft.source.mapId);
    final npcIds = npcs.map((entry) => entry.id).toList(growable: false);
    final triggerIds =
        triggers.map((entry) => entry.id).toList(growable: false);

    final entityValueLabel = _entityLabelById(draft.source.entityId, npcs) ??
        (selectedMapId == null
            ? 'Choisissez d’abord une map'
            : _isLoadingSourceLookups
                ? 'Chargement des PNJ…'
                : 'Aucun PNJ sur cette map');
    final triggerValueLabel =
        _triggerLabelById(draft.source.triggerId, triggers) ??
            (selectedMapId == null
                ? 'Choisissez d’abord une map'
                : _isLoadingSourceLookups
                    ? 'Chargement des triggers…'
                    : 'Aucun trigger sur cette map');

    return _StudioSectionCard(
      title: 'Quand cette scène démarre',
      subtitle:
          'Définissez le hook monde de déclenchement. Le flow ci-dessous s’exécute ensuite.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoSlidingSegmentedControl<CutsceneStudioSourceKind>(
            groupValue: draft.source.kind,
            children: {
              for (final kind in CutsceneStudioSourceKind.values)
                kind: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    cutsceneStudioSourceKindLabel(kind),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            },
            onValueChanged: (kind) {
              if (!canEditSource || kind == null) return;
              // Quand le type change, on nettoie les champs non pertinents
              // pour éviter des bindings ambigus.
              switch (kind) {
                case CutsceneStudioSourceKind.mapEnter:
                  _replaceDraft(
                    draft.copyWith(
                      source: draft.source.copyWith(
                        kind: kind,
                        triggerId: null,
                        entityId: null,
                      ),
                    ),
                  );
                  break;
                case CutsceneStudioSourceKind.triggerEnter:
                  _replaceDraft(
                    draft.copyWith(
                      source: draft.source.copyWith(
                        kind: kind,
                        entityId: null,
                      ),
                    ),
                  );
                  break;
                case CutsceneStudioSourceKind.entityInteract:
                  _replaceDraft(
                    draft.copyWith(
                      source: draft.source.copyWith(
                        kind: kind,
                        triggerId: null,
                      ),
                    ),
                  );
                  break;
              }
            },
          ),
          const SizedBox(height: 10),
          // IMPORTANT UX:
          // on utilise un dropdown inline (pas une alerte modale) pour rendre
          // la sélection map immédiate et lisible dans le flux d’édition.
          InspectorEmbeddedDropdown(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: 'Map',
            valueLabel: mapLabel,
            orderedIds: canEditSource ? mapIds : const <String>[],
            selectedMenuValue: _menuValueOrFirst(selectedMapId, mapIds),
            selectedIdForCheck: selectedMapId,
            idToLabel: (mapId) => _mapLabelById(mapId) ?? mapId,
            onSelected: (nextMapId) {
              if (!canEditSource) return;
              var nextSource = draft.source.copyWith(mapId: nextMapId);
              // Quand la map change, on nettoie les références dépendantes:
              // elles pourraient pointer vers un PNJ/trigger d'une autre map.
              if (nextSource.kind == CutsceneStudioSourceKind.entityInteract) {
                nextSource = nextSource.copyWith(entityId: null);
              }
              if (nextSource.kind == CutsceneStudioSourceKind.triggerEnter) {
                nextSource = nextSource.copyWith(triggerId: null);
              }
              _replaceDraft(draft.copyWith(source: nextSource));
              _primeSourceLookups(nextMapId);
            },
          ),
          if (draft.source.kind == CutsceneStudioSourceKind.entityInteract) ...[
            const SizedBox(height: 8),
            // Dropdown PNJ: propose TOUS les PNJ de la map sélectionnée.
            InspectorEmbeddedDropdown(
              accent: EditorChrome.inspectorJoyCyan,
              fieldLabel: 'PNJ concerné',
              valueLabel: entityValueLabel,
              orderedIds: canEditSource ? npcIds : const <String>[],
              selectedMenuValue:
                  _menuValueOrFirst(_trimOrNull(draft.source.entityId), npcIds),
              selectedIdForCheck: _trimOrNull(draft.source.entityId),
              idToLabel: (entityId) =>
                  _entityLabelById(entityId, npcs) ?? entityId,
              onSelected: (entityId) {
                if (!canEditSource) return;
                _replaceDraft(
                  draft.copyWith(
                    source: draft.source.copyWith(entityId: entityId),
                  ),
                );
              },
            ),
          ],
          if (draft.source.kind == CutsceneStudioSourceKind.triggerEnter) ...[
            const SizedBox(height: 8),
            InspectorEmbeddedDropdown(
              accent: EditorChrome.inspectorJoyCyan,
              fieldLabel: 'Trigger concerné',
              valueLabel: triggerValueLabel,
              orderedIds: canEditSource ? triggerIds : const <String>[],
              selectedMenuValue: _menuValueOrFirst(
                _trimOrNull(draft.source.triggerId),
                triggerIds,
              ),
              selectedIdForCheck: _trimOrNull(draft.source.triggerId),
              idToLabel: (triggerId) =>
                  _triggerLabelById(triggerId, triggers) ?? triggerId,
              onSelected: (triggerId) {
                if (!canEditSource) return;
                _replaceDraft(
                  draft.copyWith(
                    source: draft.source.copyWith(triggerId: triggerId),
                  ),
                );
              },
            ),
          ],
          if (_sourceLookupError != null) ...[
            const SizedBox(height: 8),
            Text(
              _sourceLookupError!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlocksSection(
      BuildContext context, CutsceneStudioDocument draft) {
    return _StudioSectionCard(
      title: 'Construction de la scène',
      subtitle:
          'Ajoutez des blocs dans l’ordre d’exécution. Le v1 reste volontairement simple et guidé.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorEmbeddedPrimaryCapsule(
            accent: EditorChrome.inspectorJoyPlum,
            icon: CupertinoIcons.add_circled_solid,
            label: 'Ajouter un bloc',
            enabled: _canEdit,
            onPressed: _addBlockFlow,
          ),
          const SizedBox(height: 10),
          if (draft.blocks.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: EditorChrome.largeIslandSurfaceColor(
                  context,
                  tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.07),
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.28),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                'Aucun bloc pour le moment. Ajoutez un bloc dialogue, script, flag ou outcome.',
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 12,
                ),
              ),
            )
          else
            for (var i = 0; i < draft.blocks.length; i++) ...[
              _buildBlockCard(
                context,
                draft: draft,
                block: draft.blocks[i],
                index: i,
              ),
              if (i < draft.blocks.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildBlockCard(
    BuildContext context, {
    required CutsceneStudioDocument draft,
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final canMoveUp = index > 0;
    final canMoveDown = index < draft.blocks.length - 1;
    final canEditBlock = _canEdit;
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.26),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.2),
                  border: Border.all(
                    color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Bloc ${index + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cutsceneStudioBlockKindLabel(block.kind),
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MiniIconButton(
                icon: CupertinoIcons.chevron_up,
                enabled: canEditBlock && canMoveUp,
                onTap: () => _moveBlock(index, index - 1),
              ),
              const SizedBox(width: 4),
              _MiniIconButton(
                icon: CupertinoIcons.chevron_down,
                enabled: canEditBlock && canMoveDown,
                onTap: () => _moveBlock(index, index + 1),
              ),
              const SizedBox(width: 4),
              _MiniIconButton(
                icon: CupertinoIcons.trash,
                enabled: canEditBlock,
                onTap: () => _removeBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...switch (block.kind) {
            CutsceneStudioBlockKind.dialogue => [
                _ValuePickerRow(
                  label: 'Dialogue',
                  value: _dialogueLabelById(block.dialogueId) ??
                      'Choisir un dialogue',
                  icon: CupertinoIcons.chat_bubble_2_fill,
                  enabled: canEditBlock,
                  onTap: () => _pickDialogueForBlock(index),
                ),
              ],
            CutsceneStudioBlockKind.runScript => [
                _ValuePickerRow(
                  label: 'Script',
                  value:
                      _scriptLabelById(block.scriptId) ?? 'Choisir un script',
                  icon: CupertinoIcons.chevron_left_slash_chevron_right,
                  enabled: canEditBlock,
                  onTap: () => _pickScriptForBlock(index),
                ),
              ],
            CutsceneStudioBlockKind.setFlag ||
            CutsceneStudioBlockKind.clearFlag =>
              [
                _ValuePickerRow(
                  label: 'Flag',
                  value: _trimmedOrFallback(
                    block.flagName,
                    fallback: 'Choisir ou saisir un flag',
                  ),
                  icon: CupertinoIcons.flag_fill,
                  enabled: canEditBlock,
                  onTap: () => _pickFlagForBlock(index),
                ),
              ],
            CutsceneStudioBlockKind.emitOutcome => [
                _ValuePickerRow(
                  label: 'Outcome',
                  value: _trimmedOrFallback(
                    block.outcomeId,
                    fallback: 'Choisir ou saisir un outcome',
                  ),
                  icon: CupertinoIcons.sparkles,
                  enabled: canEditBlock,
                  onTap: () => _pickOutcomeForBlock(index),
                ),
              ],
          },
        ],
      ),
    );
  }

  Future<void> _pickDialogueForBlock(int index) async {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final selected = await _pickValueWithOptionalCustomInput(
      title: 'Choisir un dialogue',
      values: widget.project.dialogues.map((dialogue) => dialogue.id).toList(),
      valueToLabel: (id) => _dialogueLabelById(id) ?? id,
      currentValue: draft.blocks[index].dialogueId,
      customTitle: 'Saisir un dialogueId',
      customPlaceholder: 'ex: intro_professor',
    );
    if (!mounted || selected == null) return;
    _replaceBlock(
      index,
      draft.blocks[index].copyWith(dialogueId: selected),
    );
  }

  Future<void> _pickScriptForBlock(int index) async {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final selected = await _pickValueWithOptionalCustomInput(
      title: 'Choisir un script',
      values: widget.project.scripts.map((script) => script.id).toList(),
      valueToLabel: (id) => _scriptLabelById(id) ?? id,
      currentValue: draft.blocks[index].scriptId,
      customTitle: 'Saisir un scriptId',
      customPlaceholder: 'ex: professor_intro_script',
    );
    if (!mounted || selected == null) return;
    _replaceBlock(
      index,
      draft.blocks[index].copyWith(scriptId: selected),
    );
  }

  Future<void> _pickFlagForBlock(int index) async {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final knownFlags = _collectKnownFlagNames();
    final selected = await _pickValueWithOptionalCustomInput(
      title: 'Choisir un flag',
      values: knownFlags,
      valueToLabel: (id) => id,
      currentValue: draft.blocks[index].flagName,
      customTitle: 'Saisir un nom de flag',
      customPlaceholder: 'ex: story.met_professor',
    );
    if (!mounted || selected == null) return;
    _replaceBlock(
      index,
      draft.blocks[index].copyWith(flagName: selected),
    );
  }

  Future<void> _pickOutcomeForBlock(int index) async {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final knownOutcomes = widget.projection.outcomes
        .map((entry) => entry.id)
        .toList(growable: false);
    final selected = await _pickValueWithOptionalCustomInput(
      title: 'Choisir un outcome',
      values: knownOutcomes,
      valueToLabel: (id) => id,
      currentValue: draft.blocks[index].outcomeId,
      customTitle: 'Saisir un outcome id',
      customPlaceholder: 'ex: chapter_1.starter_chosen',
    );
    if (!mounted || selected == null) return;
    _replaceBlock(
      index,
      draft.blocks[index].copyWith(outcomeId: selected),
    );
    widget.onSelectOutcome(selected);
  }

  Future<String?> _pickValueWithOptionalCustomInput({
    required String title,
    required List<String> values,
    required String Function(String value) valueToLabel,
    required String? currentValue,
    required String customTitle,
    required String customPlaceholder,
  }) async {
    // Étape 1: sélecteur guidé si des valeurs existent.
    if (values.isNotEmpty) {
      final options = <_PickerOption>[
        for (final value in values)
          _PickerOption(value: value, label: valueToLabel(value)),
        const _PickerOption(
            value: _customPickerSentinel, label: 'Saisir manuellement…'),
      ];
      final selected = await showMacosListPicker<_PickerOption>(
        context: context,
        title: title,
        items: options,
        labelOf: (entry) => entry.label,
      );
      if (!mounted || selected == null) {
        return null;
      }
      if (selected.value != _customPickerSentinel) {
        return selected.value;
      }
    }

    // Étape 2: fallback manuel explicite.
    final controller = TextEditingController(text: currentValue ?? '');
    final confirmed = await showMacosEditorPromptSheet(
      context,
      title: customTitle,
      controller: controller,
      placeholder: customPlaceholder,
      confirmLabel: 'Valider',
      cancelLabel: 'Annuler',
      requireNonEmpty: true,
      compact: true,
    );
    if (!confirmed) {
      return null;
    }
    return controller.text.trim();
  }

  Future<void> _addBlockFlow() async {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final selectedKind =
        await showMacosEditorActionsSheet<CutsceneStudioBlockKind>(
      context: context,
      title: const Text('Ajouter un bloc'),
      actions: <MacosEditorSheetAction<CutsceneStudioBlockKind>>[
        for (final kind in CutsceneStudioBlockKind.values)
          MacosEditorSheetAction<CutsceneStudioBlockKind>(
            label: cutsceneStudioBlockKindLabel(kind),
            value: kind,
          ),
      ],
      cancelLabel: 'Annuler',
    );
    if (!mounted || selectedKind == null) return;

    final blockId = 'block_${DateTime.now().microsecondsSinceEpoch}';
    final newBlock = switch (selectedKind) {
      CutsceneStudioBlockKind.dialogue => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          dialogueId: widget.project.dialogues.isEmpty
              ? null
              : widget.project.dialogues.first.id,
        ),
      CutsceneStudioBlockKind.runScript => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          scriptId: widget.project.scripts.isEmpty
              ? null
              : widget.project.scripts.first.id,
        ),
      CutsceneStudioBlockKind.setFlag ||
      CutsceneStudioBlockKind.clearFlag =>
        CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          flagName: 'story.flag_name',
        ),
      CutsceneStudioBlockKind.emitOutcome => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          outcomeId: widget.projection.outcomes.isEmpty
              ? 'chapter_1.example_outcome'
              : widget.projection.outcomes.first.id,
        ),
    };

    _replaceDraft(
      draft.copyWith(
        blocks: <CutsceneStudioBlock>[...draft.blocks, newBlock],
      ),
    );
  }

  void _replaceBlock(int index, CutsceneStudioBlock nextBlock) {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final blocks = List<CutsceneStudioBlock>.from(draft.blocks);
    if (index < 0 || index >= blocks.length) return;
    blocks[index] = nextBlock;
    _replaceDraft(draft.copyWith(blocks: blocks));
  }

  void _removeBlock(int index) {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final blocks = List<CutsceneStudioBlock>.from(draft.blocks);
    if (index < 0 || index >= blocks.length) return;
    blocks.removeAt(index);
    _replaceDraft(draft.copyWith(blocks: blocks));
  }

  void _moveBlock(int from, int to) {
    final draft = _draftDocument;
    if (draft == null || !_canEdit) return;
    final blocks = List<CutsceneStudioBlock>.from(draft.blocks);
    if (from < 0 || from >= blocks.length || to < 0 || to >= blocks.length) {
      return;
    }
    final entry = blocks.removeAt(from);
    blocks.insert(to, entry);
    _replaceDraft(draft.copyWith(blocks: blocks));
  }

  Future<void> _saveDraftToProject() async {
    final draft = _draftDocument;
    final scenarioId = _loadedScenarioId;
    if (draft == null || scenarioId == null || !_canEdit) return;
    final previous = _findScenarioById(scenarioId);
    if (previous == null) {
      await showCupertinoEditorAlert(
        context,
        title: 'Sauvegarde impossible',
        message: 'Le scénario source est introuvable.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final compiled = buildScenarioFromCutsceneStudioDocument(
        draft,
        previousScenario: previous,
      );
      await widget.editorNotifier.updateProjectScenario(
        scenarioId: scenarioId,
        scenario: compiled,
      );
      if (!mounted) return;
      setState(() {
        _savedDocument = draft;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _restoreSavedDocument() {
    if (!_canEdit || _savedDocument == null) return;
    _replaceDraft(_savedDocument!);
  }

  Future<void> _deleteSelectedCutscene() async {
    final scenarioId = _loadedScenarioId;
    if (scenarioId == null || _busy) return;
    final confirmed = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer cette cutscene ?',
      message:
          'Cette action retire définitivement la cutscene du projet. Les links qui la référencent devront être mis à jour.',
      primaryLabel: 'Supprimer',
      secondaryLabel: 'Annuler',
      primaryIsDestructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.editorNotifier.deleteProjectScenario(scenarioId);
      if (!mounted) return;
      final fallback = widget.projection.localEventFlows
          .where((entry) => entry.id != scenarioId)
          .cast<NarrativeScenarioSummary?>()
          .firstWhere((entry) => entry != null, orElse: () => null);
      if (fallback != null) {
        widget.onSelectCutscene(fallback.id);
      } else {
        setState(() {
          _loadedScenarioId = null;
          _savedDocument = null;
          _draftDocument = null;
          _isStudioCompatible = false;
          _compatWarnings = const <String>[];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createCutsceneFromTemplateFlow() async {
    if (_busy) return;
    final template =
        await showMacosEditorActionsSheet<CutsceneStudioTemplateKind>(
      context: context,
      title: const Text('Template de cutscene'),
      actions: <MacosEditorSheetAction<CutsceneStudioTemplateKind>>[
        for (final kind in CutsceneStudioTemplateKind.values)
          MacosEditorSheetAction<CutsceneStudioTemplateKind>(
            label: cutsceneStudioTemplateLabel(kind),
            value: kind,
          ),
      ],
      cancelLabel: 'Annuler',
    );
    if (!mounted || template == null) return;

    final nameController = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'Nom de la cutscene',
      controller: nameController,
      placeholder: 'ex: Arrivée du professeur',
      confirmLabel: 'Créer',
      cancelLabel: 'Annuler',
      requireNonEmpty: true,
    );
    if (!ok || !mounted) return;
    final name = nameController.text.trim();

    final selectedMapId = await _pickMapForTemplate();
    if (!mounted) return;

    String? selectedEntityId;
    if (template == CutsceneStudioTemplateKind.npcDialogue ||
        template == CutsceneStudioTemplateKind.npcScript) {
      selectedEntityId = await _pickEntityForTemplate(mapId: selectedMapId);
      if (!mounted) return;
    }

    String? selectedDialogueId;
    if (template == CutsceneStudioTemplateKind.npcDialogue ||
        template == CutsceneStudioTemplateKind.mapEnterDialogue) {
      selectedDialogueId = await _pickDialogueForTemplate();
      if (!mounted) return;
    }

    String? selectedScriptId;
    if (template == CutsceneStudioTemplateKind.npcScript) {
      selectedScriptId = await _pickScriptForTemplate();
      if (!mounted) return;
    }

    final scenarioId = generateUniqueScenarioId(widget.project, name);
    final document = createCutsceneStudioTemplateDocument(
      template: template,
      id: scenarioId,
      name: name,
      mapId: selectedMapId,
      entityId: selectedEntityId,
      dialogueId: selectedDialogueId,
      scriptId: selectedScriptId,
      description:
          'Créé depuis template Cutscene Studio v1 (${cutsceneStudioTemplateLabel(template)}).',
    );
    final scenario = buildScenarioFromCutsceneStudioDocument(document);

    setState(() => _busy = true);
    try {
      await widget.editorNotifier.createProjectScenario(scenario);
      if (!mounted) return;
      widget.onSelectCutscene(scenario.id);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _pickMapForTemplate() async {
    final maps = _projectMaps;
    if (maps.isEmpty) {
      return null;
    }
    // UX: si une map est active et appartient au projet, on l'utilise par défaut
    // sans étape supplémentaire. Le but est de réduire les clics.
    final activeMap = widget.activeMap;
    if (activeMap != null && maps.any((entry) => entry.id == activeMap.id)) {
      return activeMap.id;
    }
    final selected = await showMacosListPicker<ProjectMapEntry>(
      context: context,
      title: 'Map de la scène',
      items: maps,
      labelOf: (entry) => '${entry.name} (${entry.id})',
    );
    return selected?.id;
  }

  Future<String?> _pickEntityForTemplate({required String? mapId}) async {
    // On précharge explicitement les PNJ de la map cible pour éviter un
    // fallback "manuel" inutile quand la map n'est pas actuellement ouverte.
    final normalizedMapId = _trimOrNull(mapId);
    if (normalizedMapId != null) {
      await _ensureLookupsLoadedForMap(normalizedMapId);
    }
    final npcs = _npcsForMap(normalizedMapId);
    return _pickValueWithOptionalCustomInput(
      title: 'PNJ concerné',
      values: npcs.map((entry) => entry.id).toList(growable: false),
      valueToLabel: (id) => _entityLabelById(id, npcs) ?? id,
      currentValue: null,
      customTitle: 'Saisir un identifiant PNJ',
      customPlaceholder: 'ex: professor',
    );
  }

  Future<String?> _pickDialogueForTemplate() async {
    if (widget.project.dialogues.isEmpty) {
      return null;
    }
    final selected = await showMacosListPicker<ProjectDialogueEntry>(
      context: context,
      title: 'Dialogue principal',
      items: widget.project.dialogues,
      labelOf: (entry) => '${entry.name} (${entry.id})',
    );
    return selected?.id;
  }

  Future<String?> _pickScriptForTemplate() async {
    if (widget.project.scripts.isEmpty) {
      return null;
    }
    final selected = await showMacosListPicker<ProjectScriptEntry>(
      context: context,
      title: 'Script principal',
      items: widget.project.scripts,
      labelOf: (entry) => '${entry.name} (${entry.id})',
    );
    return selected?.id;
  }

  String? _mapLabelById(String? mapId) {
    if (mapId == null) return null;
    for (final map in _projectMaps) {
      if (map.id == mapId) {
        final name = map.name.trim().isEmpty ? map.id : map.name;
        return '$name (${map.id})';
      }
    }
    return mapId;
  }

  String? _entityLabelById(String? entityId, List<MapEntity> npcs) {
    if (entityId == null) return null;
    for (final entity in npcs) {
      if (entity.id == entityId) {
        return '${entity.inspectorHeadline} (${entity.id})';
      }
    }
    return entityId;
  }

  String? _triggerLabelById(String? triggerId, List<MapTrigger> triggers) {
    if (triggerId == null) return null;
    for (final trigger in triggers) {
      if (trigger.id == triggerId) {
        final label = trigger.name.trim().isEmpty ? trigger.id : trigger.name;
        return '$label (${trigger.id})';
      }
    }
    return triggerId;
  }

  String? _dialogueLabelById(String? dialogueId) {
    if (dialogueId == null) return null;
    for (final dialogue in widget.project.dialogues) {
      if (dialogue.id == dialogueId) {
        final name = dialogue.name.trim().isEmpty ? dialogue.id : dialogue.name;
        return '$name (${dialogue.id})';
      }
    }
    return dialogueId;
  }

  String? _scriptLabelById(String? scriptId) {
    if (scriptId == null) return null;
    for (final script in widget.project.scripts) {
      if (script.id == scriptId) {
        final name = script.name.trim().isEmpty ? script.id : script.name;
        return '$name (${script.id})';
      }
    }
    return scriptId;
  }

  List<String> _collectKnownFlagNames() {
    final values = <String>{};
    for (final scenario in widget.project.scenarios) {
      for (final node in scenario.nodes) {
        final flag = node.binding.flagName?.trim();
        if (flag != null && flag.isNotEmpty) {
          values.add(flag);
        }
      }
    }
    final list = values.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }
}

class _StudioSectionCard extends StatelessWidget {
  const _StudioSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ValuePickerRow extends StatelessWidget {
  const _ValuePickerRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.06),
          ),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: enabled
                ? EditorChrome.inspectorJoyCyan.withValues(alpha: 0.45)
                : CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled
                  ? EditorChrome.inspectorJoyCyan
                  : CupertinoColors.placeholderText.resolveFrom(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EditorChrome.primaryLabel(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 13,
              color: enabled
                  ? EditorChrome.inspectorJoyCyan
                  : CupertinoColors.placeholderText.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(4),
      minimumSize: const Size(24, 24),
      onPressed: enabled ? onTap : null,
      child: Icon(
        icon,
        size: 14,
        color: enabled
            ? EditorChrome.inspectorJoyPlum
            : CupertinoColors.placeholderText.resolveFrom(context),
      ),
    );
  }
}

class _CompatibilityWarningCard extends StatelessWidget {
  const _CompatibilityWarningCard({
    required this.warnings,
  });

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.07),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyCoral.withValues(alpha: 0.45),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scénario hors format guidé v1',
            style: TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Le studio affiche ce scénario, mais ne peut pas l’éditer sans risque de perte de structure (branches/graphes avancés).',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
            ),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final warning in warnings)
              Text(
                '• $warning',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontSize: 11,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PickerOption {
  const _PickerOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

const String _customPickerSentinel = '__custom__';

String? _trimOrNull(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

String _trimmedOrFallback(
  String? value, {
  required String fallback,
}) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return fallback;
  }
  return normalized;
}

/// Retourne une valeur de menu valide pour un dropdown.
///
/// - si `selected` existe dans `options`, on la garde;
/// - sinon on prend la première option pour satisfaire le contrat widget;
/// - sinon chaîne vide (dropdown désactivé).
String _menuValueOrFirst(String? selected, List<String> options) {
  if (options.isEmpty) {
    return '';
  }
  if (selected != null && options.contains(selected)) {
    return selected;
  }
  return options.first;
}
