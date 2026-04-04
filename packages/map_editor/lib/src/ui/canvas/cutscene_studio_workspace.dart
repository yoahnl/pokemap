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
  final Map<String, List<MapEntity>> _spawnsByMapId =
      <String, List<MapEntity>>{};
  final Map<String, List<MapTrigger>> _triggersByMapId =
      <String, List<MapTrigger>>{};
  final Map<String, List<MapWarp>> _warpsByMapId = <String, List<MapWarp>>{};
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
        _spawnsByMapId.clear();
        _triggersByMapId.clear();
        _warpsByMapId.clear();
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
        _spawnsByMapId.clear();
        _triggersByMapId.clear();
        _warpsByMapId.clear();
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
      _spawnsByMapId.clear();
      _triggersByMapId.clear();
      _warpsByMapId.clear();
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

  List<MapWarp> _warpsForMap(String? mapId) {
    final normalized = _trimOrNull(mapId);
    if (normalized == null) {
      return const <MapWarp>[];
    }
    final activeMap = widget.activeMap;
    if (activeMap != null && activeMap.id == normalized) {
      return _sortedWarps(activeMap.warps);
    }
    return _warpsByMapId[normalized] ?? const <MapWarp>[];
  }

  List<MapEntity> _spawnsForMap(String? mapId) {
    final normalized = _trimOrNull(mapId);
    if (normalized == null) {
      return const <MapEntity>[];
    }
    final activeMap = widget.activeMap;
    if (activeMap != null && activeMap.id == normalized) {
      return _sortedSpawns(activeMap.entities);
    }
    return _spawnsByMapId[normalized] ?? const <MapEntity>[];
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

  List<MapWarp> _sortedWarps(Iterable<MapWarp> warps) {
    return warps.toList(growable: false)
      ..sort((a, b) => a.id.toLowerCase().compareTo(b.id.toLowerCase()));
  }

  List<MapEntity> _sortedSpawns(Iterable<MapEntity> entities) {
    return entities
        .where((entity) => entity.kind == MapEntityKind.spawn)
        .toList(growable: false)
      ..sort(
        (a, b) => a.inspectorHeadline
            .toLowerCase()
            .compareTo(b.inspectorHeadline.toLowerCase()),
      );
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
        _spawnsByMapId[mapId] = _sortedSpawns(activeMap.entities);
        _triggersByMapId[mapId] = _sortedTriggers(activeMap.triggers);
        _warpsByMapId[mapId] = _sortedWarps(activeMap.warps);
        _sourceLookupError = null;
        _isLoadingSourceLookups = false;
      });
      return;
    }

    // Cas 2: déjà chargé (snapshot disque), inutile de recharger.
    if (_npcsByMapId.containsKey(mapId) &&
        _spawnsByMapId.containsKey(mapId) &&
        _triggersByMapId.containsKey(mapId) &&
        _warpsByMapId.containsKey(mapId)) {
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
        _spawnsByMapId[mapId] = const <MapEntity>[];
        _triggersByMapId[mapId] = const <MapTrigger>[];
        _warpsByMapId[mapId] = const <MapWarp>[];
      });
      return;
    }

    setState(() {
      _npcsByMapId[mapId] = _sortedNpcs(loadedMap.entities);
      _spawnsByMapId[mapId] = _sortedSpawns(loadedMap.entities);
      _triggersByMapId[mapId] = _sortedTriggers(loadedMap.triggers);
      _warpsByMapId[mapId] = _sortedWarps(loadedMap.warps);
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
          'Assemblez des blocs concrets dans l’ordre: dialogues, déplacements, transitions, choix et résultats.',
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
          const SizedBox(height: 8),
          Text(
            'Lecture de haut en bas: chaque bloc représente une action de scène.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
            ),
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
                'Aucun bloc pour le moment. Commencez par "Faire parler un personnage" ou "Déplacer un personnage".',
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
    final category = cutsceneStudioBlockCategory(block.kind);
    final accent = _categoryAccent(category);
    final runtimeSupported = cutsceneStudioBlockRuntimeSupported(block);
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.34),
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
                  color: accent.withValues(alpha: 0.2),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
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
              if (!runtimeSupported)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color:
                        EditorChrome.inspectorJoyCoral.withValues(alpha: 0.18),
                    border: Border.all(
                      color: EditorChrome.inspectorJoyCoral
                          .withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Text(
                    'Préparation runtime',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 10,
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
          const SizedBox(height: 4),
          Text(
            cutsceneStudioBlockCategoryLabel(category),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildBlockEditor(
            context,
            draft: draft,
            block: block,
            index: index,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockEditor(
    BuildContext context, {
    required CutsceneStudioDocument draft,
    required CutsceneStudioBlock block,
    required int index,
  }) {
    return switch (block.kind) {
      CutsceneStudioBlockKind.dialogue => _buildDialogueBlockEditor(
          context,
          draft: draft,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.narration => _buildNarrationBlockEditor(
          context,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.moveCharacter => _buildMoveBlockEditor(
          context,
          draft: draft,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.followCharacter => _buildFollowBlockEditor(
          context,
          draft: draft,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.faceCharacter => _buildFaceBlockEditor(
          context,
          draft: draft,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.transitionMap => _buildTransitionMapBlockEditor(
          context,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.starterChoice => _buildStarterChoiceBlockEditor(
          context,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.wait => _buildWaitBlockEditor(
          context,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.sceneResult => _buildSceneResultBlockEditor(
          context,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.runScript => _buildRunScriptBlockEditor(
          context,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.setFlag ||
      CutsceneStudioBlockKind.clearFlag =>
        _buildFlagBlockEditor(
          context,
          block: block,
          index: index,
        ),
      CutsceneStudioBlockKind.emitOutcome => _buildLegacyOutcomeBlockEditor(
          context,
          block: block,
          index: index,
        ),
    };
  }

  Widget _buildDialogueBlockEditor(
    BuildContext context, {
    required CutsceneStudioDocument draft,
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final mapId = _trimOrNull(draft.source.mapId);
    final actorIds = _actorIdsForMap(mapId);
    final dialogueIds = widget.project.dialogues
        .map((entry) => entry.id)
        .toList(growable: false);
    return Column(
      children: [
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyMint,
          fieldLabel: 'Personnage qui parle',
          valueLabel: _actorLabelById(block.actorId, mapId: mapId) ??
              'Choisir un personnage',
          orderedIds: _canEdit ? actorIds : const <String>[],
          selectedMenuValue:
              _menuValueOrFirst(_trimOrNull(block.actorId), actorIds),
          selectedIdForCheck: _trimOrNull(block.actorId),
          idToLabel: (id) => _actorLabelById(id, mapId: mapId) ?? id,
          onSelected: (actorId) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(actorId: actorId));
          },
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyMint,
          fieldLabel: 'Dialogue à jouer',
          valueLabel: _dialogueLabelById(block.dialogueId) ??
              'Choisir un dialogue existant',
          orderedIds: _canEdit ? dialogueIds : const <String>[],
          selectedMenuValue:
              _menuValueOrFirst(_trimOrNull(block.dialogueId), dialogueIds),
          selectedIdForCheck: _trimOrNull(block.dialogueId),
          idToLabel: (id) => _dialogueLabelById(id) ?? id,
          onSelected: (dialogueId) {
            if (!_canEdit) return;
            _replaceBlock(
              index,
              block.copyWith(
                dialogueId: dialogueId,
                // On nettoie le fallback texte inline dès qu'un vrai dialogue
                // est sélectionné pour garder une donnée simple et lisible.
                messageText: null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNarrationBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    return _InlineActionRow(
      label: 'Texte de narration',
      value: _trimmedOrFallback(
        block.messageText,
        fallback: 'Aucun texte défini',
      ),
      icon: CupertinoIcons.text_bubble,
      enabled: _canEdit,
      onTap: () async {
        final nextText = await _promptTextValue(
          title: 'Texte de narration',
          initialValue: block.messageText,
          placeholder: 'Ex: Emma regarde vers le laboratoire...',
        );
        if (!mounted || nextText == null || !_canEdit) return;
        _replaceBlock(index, block.copyWith(messageText: nextText));
      },
    );
  }

  Widget _buildMoveBlockEditor(
    BuildContext context, {
    required CutsceneStudioDocument draft,
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final mapId = _trimOrNull(draft.source.mapId);
    final actorIds = _actorIdsForMap(mapId);
    const targetKinds = <String>[
      kCutsceneStudioMoveTargetWarp,
      kCutsceneStudioMoveTargetSpawn,
      kCutsceneStudioMoveTargetEntity,
    ];
    final selectedKind = _trimOrNull(block.destinationTargetKind) ??
        kCutsceneStudioMoveTargetWarp;
    final targetIds = _destinationIdsForMoveTarget(
      kind: selectedKind,
      mapId: mapId,
    );
    final selectedTargetId = _trimOrNull(block.destinationTargetId);
    return Column(
      children: [
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'Personnage qui se déplace',
          valueLabel: _actorLabelById(block.actorId, mapId: mapId) ??
              'Choisir un personnage',
          orderedIds: _canEdit ? actorIds : const <String>[],
          selectedMenuValue:
              _menuValueOrFirst(_trimOrNull(block.actorId), actorIds),
          selectedIdForCheck: _trimOrNull(block.actorId),
          idToLabel: (id) => _actorLabelById(id, mapId: mapId) ?? id,
          onSelected: (actorId) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(actorId: actorId));
          },
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'Type de destination',
          valueLabel: _moveTargetKindLabel(selectedKind),
          orderedIds: _canEdit ? targetKinds : const <String>[],
          selectedMenuValue: _menuValueOrFirst(selectedKind, targetKinds),
          selectedIdForCheck: selectedKind,
          idToLabel: _moveTargetKindLabel,
          onSelected: (nextKind) {
            if (!_canEdit) return;
            final nextTargetIds = _destinationIdsForMoveTarget(
              kind: nextKind,
              mapId: mapId,
            );
            _replaceBlock(
              index,
              block.copyWith(
                destinationTargetKind: nextKind,
                destinationTargetId: _firstOrNull(nextTargetIds),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'Destination',
          valueLabel: _destinationLabelForMoveTarget(
                kind: selectedKind,
                id: selectedTargetId,
                mapId: mapId,
              ) ??
              (targetIds.isEmpty
                  ? 'Aucune destination disponible'
                  : 'Choisir une destination'),
          orderedIds: _canEdit ? targetIds : const <String>[],
          selectedMenuValue: _menuValueOrFirst(selectedTargetId, targetIds),
          selectedIdForCheck: selectedTargetId,
          idToLabel: (id) =>
              _destinationLabelForMoveTarget(
                kind: selectedKind,
                id: id,
                mapId: mapId,
              ) ??
              id,
          onSelected: (targetId) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(destinationTargetId: targetId));
          },
        ),
        const SizedBox(height: 8),
        _ToggleOptionRow(
          label: 'Attendre la fin du déplacement',
          value: block.waitForCompletion ?? true,
          enabled: _canEdit,
          onChanged: (next) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(waitForCompletion: next));
          },
        ),
      ],
    );
  }

  Widget _buildFollowBlockEditor(
    BuildContext context, {
    required CutsceneStudioDocument draft,
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final mapId = _trimOrNull(draft.source.mapId);
    final leaderIds = _npcsForMap(mapId).map((entry) => entry.id).toList();
    return Column(
      children: [
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'PNJ leader',
          valueLabel: _actorLabelById(block.actorId, mapId: mapId) ??
              'Choisir le PNJ leader',
          orderedIds: _canEdit ? leaderIds : const <String>[],
          selectedMenuValue:
              _menuValueOrFirst(_trimOrNull(block.actorId), leaderIds),
          selectedIdForCheck: _trimOrNull(block.actorId),
          idToLabel: (id) => _actorLabelById(id, mapId: mapId) ?? id,
          onSelected: (leaderId) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(actorId: leaderId));
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Le joueur suivra ce PNJ pendant la scène.',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFaceBlockEditor(
    BuildContext context, {
    required CutsceneStudioDocument draft,
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final mapId = _trimOrNull(draft.source.mapId);
    final actorIds = _actorIdsForMap(mapId);
    const directions = <String>['north', 'south', 'east', 'west'];
    final selectedDirection = _trimOrNull(block.facingDirection) ?? 'south';
    return Column(
      children: [
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'Personnage à tourner',
          valueLabel: _actorLabelById(block.actorId, mapId: mapId) ??
              'Choisir un personnage',
          orderedIds: _canEdit ? actorIds : const <String>[],
          selectedMenuValue:
              _menuValueOrFirst(_trimOrNull(block.actorId), actorIds),
          selectedIdForCheck: _trimOrNull(block.actorId),
          idToLabel: (id) => _actorLabelById(id, mapId: mapId) ?? id,
          onSelected: (actorId) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(actorId: actorId));
          },
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'Direction',
          valueLabel: _directionLabel(selectedDirection),
          orderedIds: _canEdit ? directions : const <String>[],
          selectedMenuValue: _menuValueOrFirst(selectedDirection, directions),
          selectedIdForCheck: selectedDirection,
          idToLabel: _directionLabel,
          onSelected: (direction) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(facingDirection: direction));
          },
        ),
      ],
    );
  }

  Widget _buildTransitionMapBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final mapIds = _projectMaps.map((entry) => entry.id).toList();
    final selectedMapId = _trimOrNull(block.transitionMapId);
    final warps = _warpsForMap(selectedMapId);
    final warpIds = warps.map((entry) => entry.id).toList(growable: false);
    return Column(
      children: [
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'Map de destination',
          valueLabel: _mapLabelById(selectedMapId) ?? 'Choisir une map',
          orderedIds: _canEdit ? mapIds : const <String>[],
          selectedMenuValue: _menuValueOrFirst(selectedMapId, mapIds),
          selectedIdForCheck: selectedMapId,
          idToLabel: (id) => _mapLabelById(id) ?? id,
          onSelected: (mapId) {
            if (!_canEdit) return;
            _primeSourceLookups(mapId);
            final nextWarpIds =
                _warpsForMap(mapId).map((entry) => entry.id).toList();
            _replaceBlock(
              index,
              block.copyWith(
                transitionMapId: mapId,
                transitionWarpId: _firstOrNull(nextWarpIds),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyBlue,
          fieldLabel: 'Point d’arrivée (warp)',
          valueLabel: _warpLabelById(block.transitionWarpId, warps) ??
              (selectedMapId == null
                  ? 'Choisir d’abord une map'
                  : warps.isEmpty
                      ? 'Aucun warp sur cette map'
                      : 'Choisir un warp'),
          orderedIds: _canEdit ? warpIds : const <String>[],
          selectedMenuValue:
              _menuValueOrFirst(_trimOrNull(block.transitionWarpId), warpIds),
          selectedIdForCheck: _trimOrNull(block.transitionWarpId),
          idToLabel: (id) => _warpLabelById(id, warps) ?? id,
          onSelected: (warpId) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(transitionWarpId: warpId));
          },
        ),
      ],
    );
  }

  Widget _buildStarterChoiceBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final options = block.choiceOptions.isEmpty
        ? const <String>['Feu', 'Eau', 'Plante']
        : block.choiceOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Options proposées au joueur',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        for (var optionIndex = 0; optionIndex < options.length; optionIndex++)
          Padding(
            padding: EdgeInsets.only(
                bottom: optionIndex == options.length - 1 ? 0 : 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: EditorChrome.largeIslandSurfaceColor(
                  context,
                  tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.08),
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${optionIndex + 1}. ${options[optionIndex]}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _MiniIconButton(
                    icon: CupertinoIcons.pencil,
                    enabled: _canEdit,
                    onTap: () => _editStarterChoiceOption(
                      blockIndex: index,
                      optionIndex: optionIndex,
                      currentValue: options[optionIndex],
                    ),
                  ),
                  const SizedBox(width: 2),
                  _MiniIconButton(
                    icon: CupertinoIcons.delete,
                    enabled: _canEdit && options.length > 2,
                    onTap: () {
                      if (!_canEdit || options.length <= 2) return;
                      final nextOptions = List<String>.from(options)
                        ..removeAt(optionIndex);
                      _replaceBlock(
                        index,
                        block.copyWith(choiceOptions: nextOptions),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        InspectorEmbeddedSecondaryCapsule(
          accent: EditorChrome.inspectorJoyMint,
          icon: CupertinoIcons.plus,
          label: 'Ajouter une option',
          enabled: _canEdit,
          onPressed: () => _addStarterChoiceOption(index: index, block: block),
        ),
      ],
    );
  }

  Widget _buildWaitBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final knownDurations = <String>[
      '250',
      '500',
      '700',
      '1000',
      '1500',
      '2000'
    ];
    final currentDuration = (block.durationMs ?? 700).toString();
    final orderedDurations = <String>{
      currentDuration,
      ...knownDurations,
    }.toList(growable: false);
    return InspectorEmbeddedDropdown(
      accent: EditorChrome.inspectorJoyBlue,
      fieldLabel: 'Durée d’attente',
      valueLabel: '${block.durationMs ?? 700} ms',
      orderedIds: _canEdit ? orderedDurations : const <String>[],
      selectedMenuValue: _menuValueOrFirst(currentDuration, orderedDurations),
      selectedIdForCheck: currentDuration,
      idToLabel: (id) => '$id ms',
      onSelected: (duration) {
        if (!_canEdit) return;
        final parsed = int.tryParse(duration);
        if (parsed == null) return;
        _replaceBlock(index, block.copyWith(durationMs: parsed));
      },
    );
  }

  Widget _buildSceneResultBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final selectedScope =
        _trimOrNull(block.resultScope) ?? kCutsceneStudioResultScopeLocal;
    final generatedId = resolveCutsceneStudioOutcomeId(block);
    return Column(
      children: [
        _InlineActionRow(
          label: 'Nom visible du résultat',
          value: _trimmedOrFallback(
            block.resultLabel,
            fallback: 'Résultat de scène',
          ),
          icon: CupertinoIcons.sparkles,
          enabled: _canEdit,
          onTap: () async {
            final nextLabel = await _promptTextValue(
              title: 'Nom du résultat de scène',
              initialValue: block.resultLabel,
              placeholder: 'Ex: Emma rencontrée',
            );
            if (!mounted || nextLabel == null || !_canEdit) return;
            _replaceBlock(index, block.copyWith(resultLabel: nextLabel));
          },
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: EditorChrome.inspectorJoyMint,
          fieldLabel: 'Portée du résultat',
          valueLabel: _resultScopeLabel(selectedScope),
          orderedIds: _canEdit ? kCutsceneStudioResultScopes : const <String>[],
          selectedMenuValue:
              _menuValueOrFirst(selectedScope, kCutsceneStudioResultScopes),
          selectedIdForCheck: selectedScope,
          idToLabel: _resultScopeLabel,
          onSelected: (scope) {
            if (!_canEdit) return;
            _replaceBlock(index, block.copyWith(resultScope: scope));
          },
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.08),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            generatedId == null
                ? 'Identifiant interne: sera généré dès que le nom est renseigné.'
                : 'Identifiant interne généré: $generatedId',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunScriptBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final scriptIds =
        widget.project.scripts.map((entry) => entry.id).toList(growable: false);
    return InspectorEmbeddedDropdown(
      accent: EditorChrome.inspectorJoyCoral,
      fieldLabel: 'Script à exécuter (avancé)',
      valueLabel:
          _scriptLabelById(block.scriptId) ?? 'Choisir un script existant',
      orderedIds: _canEdit ? scriptIds : const <String>[],
      selectedMenuValue:
          _menuValueOrFirst(_trimOrNull(block.scriptId), scriptIds),
      selectedIdForCheck: _trimOrNull(block.scriptId),
      idToLabel: (id) => _scriptLabelById(id) ?? id,
      onSelected: (scriptId) {
        if (!_canEdit) return;
        _replaceBlock(index, block.copyWith(scriptId: scriptId));
      },
    );
  }

  Widget _buildFlagBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final flagNames = _collectKnownFlagNames();
    return InspectorEmbeddedDropdown(
      accent: EditorChrome.inspectorJoyCoral,
      fieldLabel: 'Flag (compatibilité legacy)',
      valueLabel: _trimmedOrFallback(block.flagName,
          fallback: 'Choisir un flag existant'),
      orderedIds: _canEdit ? flagNames : const <String>[],
      selectedMenuValue:
          _menuValueOrFirst(_trimOrNull(block.flagName), flagNames),
      selectedIdForCheck: _trimOrNull(block.flagName),
      idToLabel: (id) => id,
      onSelected: (flagName) {
        if (!_canEdit) return;
        _replaceBlock(index, block.copyWith(flagName: flagName));
      },
    );
  }

  Widget _buildLegacyOutcomeBlockEditor(
    BuildContext context, {
    required CutsceneStudioBlock block,
    required int index,
  }) {
    final outcomes = widget.projection.outcomes
        .map((entry) => entry.id)
        .toList(growable: false);
    return InspectorEmbeddedDropdown(
      accent: EditorChrome.inspectorJoyCoral,
      fieldLabel: 'Outcome (compatibilité legacy)',
      valueLabel: _trimmedOrFallback(
        block.outcomeId,
        fallback: 'Choisir un outcome existant',
      ),
      orderedIds: _canEdit ? outcomes : const <String>[],
      selectedMenuValue:
          _menuValueOrFirst(_trimOrNull(block.outcomeId), outcomes),
      selectedIdForCheck: _trimOrNull(block.outcomeId),
      idToLabel: (id) => id,
      onSelected: (outcomeId) {
        if (!_canEdit) return;
        _replaceBlock(index, block.copyWith(outcomeId: outcomeId));
        widget.onSelectOutcome(outcomeId);
      },
    );
  }

  Color _categoryAccent(CutsceneStudioBlockCategory category) {
    return switch (category) {
      CutsceneStudioBlockCategory.dialogue => EditorChrome.inspectorJoyMint,
      CutsceneStudioBlockCategory.movement => EditorChrome.inspectorJoyBlue,
      CutsceneStudioBlockCategory.transition => EditorChrome.inspectorJoyBlue,
      CutsceneStudioBlockCategory.gameplay => EditorChrome.inspectorJoyPlum,
      CutsceneStudioBlockCategory.logic => EditorChrome.inspectorJoyCyan,
      CutsceneStudioBlockCategory.technical => EditorChrome.inspectorJoyCoral,
    };
  }

  List<String> _actorIdsForMap(String? mapId) {
    final ids = <String>{kCutsceneActorPlayerId, kCutsceneActorNarratorId};
    ids.addAll(_npcsForMap(mapId).map((entry) => entry.id));
    return ids.toList(growable: false);
  }

  String? _actorLabelById(
    String? actorId, {
    required String? mapId,
  }) {
    final normalized = _trimOrNull(actorId);
    if (normalized == null) return null;
    if (normalized == kCutsceneActorPlayerId) {
      return 'Joueur';
    }
    if (normalized == kCutsceneActorNarratorId) {
      return 'Narrateur';
    }
    return _entityLabelById(normalized, _npcsForMap(mapId));
  }

  List<String> _destinationIdsForMoveTarget({
    required String kind,
    required String? mapId,
  }) {
    switch (kind) {
      case kCutsceneStudioMoveTargetWarp:
        return _warpsForMap(mapId)
            .map((entry) => entry.id)
            .toList(growable: false);
      case kCutsceneStudioMoveTargetSpawn:
        return _spawnsForMap(mapId)
            .map((entry) => entry.id)
            .toList(growable: false);
      case kCutsceneStudioMoveTargetEntity:
        return _actorIdsForMap(mapId)
            .where((id) => id != kCutsceneActorNarratorId)
            .toList(growable: false);
      default:
        return const <String>[];
    }
  }

  String _moveTargetKindLabel(String kind) {
    return switch (kind) {
      kCutsceneStudioMoveTargetWarp => 'Vers une sortie (warp)',
      kCutsceneStudioMoveTargetSpawn => 'Vers un point d’arrivée (spawn)',
      kCutsceneStudioMoveTargetEntity => 'Vers un personnage',
      _ => kind,
    };
  }

  String? _destinationLabelForMoveTarget({
    required String kind,
    required String? id,
    required String? mapId,
  }) {
    final normalizedId = _trimOrNull(id);
    if (normalizedId == null) {
      return null;
    }
    switch (kind) {
      case kCutsceneStudioMoveTargetWarp:
        return _warpLabelById(normalizedId, _warpsForMap(mapId));
      case kCutsceneStudioMoveTargetSpawn:
        return _spawnLabelById(normalizedId, _spawnsForMap(mapId));
      case kCutsceneStudioMoveTargetEntity:
        return _actorLabelById(normalizedId, mapId: mapId);
      default:
        return normalizedId;
    }
  }

  String _directionLabel(String direction) {
    return switch (direction) {
      'north' => 'Nord',
      'south' => 'Sud',
      'east' => 'Est',
      'west' => 'Ouest',
      _ => direction,
    };
  }

  String _resultScopeLabel(String scope) {
    return switch (scope) {
      kCutsceneStudioResultScopeLocal => 'Local (scène / étape)',
      kCutsceneStudioResultScopeProgression => 'Progression',
      kCutsceneStudioResultScopeGlobal => 'Global',
      _ => scope,
    };
  }

  Future<void> _editStarterChoiceOption({
    required int blockIndex,
    required int optionIndex,
    required String currentValue,
  }) async {
    final nextValue = await _promptTextValue(
      title: 'Modifier l’option',
      initialValue: currentValue,
      placeholder: 'Ex: Feu',
    );
    if (!mounted || nextValue == null || !_canEdit) return;
    final draft = _draftDocument;
    if (draft == null || blockIndex < 0 || blockIndex >= draft.blocks.length) {
      return;
    }
    final block = draft.blocks[blockIndex];
    final options = block.choiceOptions.isEmpty
        ? <String>['Feu', 'Eau', 'Plante']
        : List<String>.from(block.choiceOptions);
    if (optionIndex < 0 || optionIndex >= options.length) return;
    options[optionIndex] = nextValue;
    _replaceBlock(blockIndex, block.copyWith(choiceOptions: options));
  }

  Future<void> _addStarterChoiceOption({
    required int index,
    required CutsceneStudioBlock block,
  }) async {
    final nextValue = await _promptTextValue(
      title: 'Nouvelle option',
      initialValue: '',
      placeholder: 'Ex: Pikachu',
    );
    if (!mounted || nextValue == null || !_canEdit) return;
    final nextOptions = block.choiceOptions.isEmpty
        ? <String>['Feu', 'Eau', 'Plante', nextValue]
        : <String>[...block.choiceOptions, nextValue];
    _replaceBlock(index, block.copyWith(choiceOptions: nextOptions));
  }

  Future<String?> _promptTextValue({
    required String title,
    required String? initialValue,
    required String placeholder,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final confirmed = await showMacosEditorPromptSheet(
      context,
      title: title,
      controller: controller,
      placeholder: placeholder,
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
        for (final kind in _cutscenePaletteBlockKinds)
          MacosEditorSheetAction<CutsceneStudioBlockKind>(
            label:
                '${cutsceneStudioBlockCategoryLabel(cutsceneStudioBlockCategory(kind))} • ${cutsceneStudioBlockKindLabel(kind)}',
            value: kind,
          ),
      ],
      cancelLabel: 'Annuler',
    );
    if (!mounted || selectedKind == null) return;

    final blockId = 'block_${DateTime.now().microsecondsSinceEpoch}';
    final sourceMapId = _trimOrNull(draft.source.mapId);
    final actors = _actorIdsForMap(sourceMapId);
    final npcs = _npcsForMap(sourceMapId);
    final warps = _warpsForMap(sourceMapId);
    final spawns = _spawnsForMap(sourceMapId);
    final newBlock = switch (selectedKind) {
      CutsceneStudioBlockKind.dialogue => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          actorId: _firstOrNull(actors),
          dialogueId: widget.project.dialogues.isEmpty
              ? null
              : widget.project.dialogues.first.id,
        ),
      CutsceneStudioBlockKind.narration => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          messageText: 'Texte de narration',
        ),
      CutsceneStudioBlockKind.moveCharacter => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          actorId: npcs.isNotEmpty
              ? npcs.first.id
              : _firstOrNull(actors
                  .where((id) => id != kCutsceneActorNarratorId)
                  .toList()),
          destinationTargetKind: kCutsceneStudioMoveTargetWarp,
          destinationTargetId: warps.isNotEmpty
              ? warps.first.id
              : spawns.isNotEmpty
                  ? spawns.first.id
                  : _firstOrNull(
                      actors
                          .where((id) => id != kCutsceneActorNarratorId)
                          .toList(growable: false),
                    ),
          waitForCompletion: true,
        ),
      CutsceneStudioBlockKind.followCharacter => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          actorId: _firstOrNull(npcs.map((entry) => entry.id).toList()),
        ),
      CutsceneStudioBlockKind.faceCharacter => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          actorId: _firstOrNull(actors),
          facingDirection: 'south',
        ),
      CutsceneStudioBlockKind.transitionMap => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          transitionMapId: sourceMapId ??
              (widget.project.maps.isEmpty
                  ? null
                  : widget.project.maps.first.id),
          transitionWarpId:
              _firstOrNull(warps.map((entry) => entry.id).toList()),
        ),
      CutsceneStudioBlockKind.starterChoice => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          choiceOptions: const <String>['Feu', 'Eau', 'Plante'],
        ),
      CutsceneStudioBlockKind.wait => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          durationMs: 700,
        ),
      CutsceneStudioBlockKind.sceneResult => CutsceneStudioBlock(
          id: blockId,
          kind: selectedKind,
          resultLabel: 'Résultat de scène',
          resultScope: kCutsceneStudioResultScopeLocal,
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
    if (!mounted) {
      return null;
    }
    final npcs = _npcsForMap(normalizedMapId);
    if (npcs.isEmpty) {
      return null;
    }
    final selected = await showMacosListPicker<MapEntity>(
      context: context,
      title: 'PNJ concerné',
      items: npcs,
      labelOf: (entry) => '${entry.inspectorHeadline} (${entry.id})',
    );
    return selected?.id;
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

  String? _warpLabelById(String? warpId, List<MapWarp> warps) {
    if (warpId == null) return null;
    for (final warp in warps) {
      if (warp.id == warpId) {
        return 'Warp ${warp.id} -> ${warp.targetMapId} (${warp.targetPos.x}, ${warp.targetPos.y})';
      }
    }
    return warpId;
  }

  String? _spawnLabelById(String? spawnId, List<MapEntity> spawns) {
    if (spawnId == null) return null;
    for (final spawn in spawns) {
      if (spawn.id == spawnId) {
        return '${spawn.inspectorHeadline} (${spawn.id})';
      }
    }
    return spawnId;
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

class _InlineActionRow extends StatelessWidget {
  const _InlineActionRow({
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

class _ToggleOptionRow extends StatelessWidget {
  const _ToggleOptionRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EditorChrome.primaryLabel(context),
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
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

T? _firstOrNull<T>(List<T> list) {
  if (list.isEmpty) {
    return null;
  }
  return list.first;
}

const String kCutsceneActorPlayerId = 'player';
const String kCutsceneActorNarratorId = 'narrator';

/// Palette v1 exposée dans le bouton "Ajouter un bloc".
///
/// Intention produit:
/// - privilégier les blocs métier no-code;
/// - conserver `runScript` comme échappatoire avancée;
/// - éviter d'exposer par défaut les blocs legacy techniques.
const List<CutsceneStudioBlockKind> _cutscenePaletteBlockKinds =
    <CutsceneStudioBlockKind>[
  CutsceneStudioBlockKind.dialogue,
  CutsceneStudioBlockKind.narration,
  CutsceneStudioBlockKind.moveCharacter,
  CutsceneStudioBlockKind.followCharacter,
  CutsceneStudioBlockKind.faceCharacter,
  CutsceneStudioBlockKind.transitionMap,
  CutsceneStudioBlockKind.starterChoice,
  CutsceneStudioBlockKind.wait,
  CutsceneStudioBlockKind.sceneResult,
  CutsceneStudioBlockKind.runScript,
];
