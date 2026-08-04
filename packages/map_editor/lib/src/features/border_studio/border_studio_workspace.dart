import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../ui/design_system/design_system.dart';
import '../editor/state/editor_notifier.dart';
import '../editor/state/editor_selectors.dart';
import 'application/border_asset_snapshot_service.dart';
import 'application/border_project_element_asset_service.dart';
import 'application/border_publication_candidate_builder.dart';
import 'application/border_publication_transaction.dart';
import 'application/border_studio_draft.dart';
import 'application/border_studio_draft_controller.dart';
import 'application/border_studio_publication_coordinator.dart';
import 'application/border_smart_tile_ground_snapshot_service.dart';
import 'presentation/border_assets_step.dart';
import 'presentation/border_preview_publication_step.dart';
import 'presentation/border_roles_step.dart';
import 'presentation/border_rules_step.dart';
import 'presentation/border_studio_presentation.dart';
import 'presentation/border_type_step.dart';
import 'state/border_studio_providers.dart';

/// Project-scoped authoring workspace for reusable Border blueprints.
///
/// The workspace intentionally watches no active-map provider: it prepares a
/// recipe only. World Maps owns all later drawing and materialization.
class BorderStudioWorkspace extends ConsumerStatefulWidget {
  const BorderStudioWorkspace({super.key, this.onPublishRequested});

  /// Focused seam for the publication orchestration supplied by BORD-02A.
  ///
  /// The regular editor route leaves this null until prepared snapshot inputs
  /// exist; the workspace still exposes the publication gate and never writes
  /// a partial manifest from a widget.
  final Future<void> Function()? onPublishRequested;

  @override
  ConsumerState<BorderStudioWorkspace> createState() =>
      _BorderStudioWorkspaceState();
}

class _BorderStudioWorkspaceState extends ConsumerState<BorderStudioWorkspace> {
  static const _assetService = BorderProjectElementAssetService();
  static const _groundSnapshotService = BorderSmartTileGroundSnapshotService();

  int _activeStep = 0;
  String? _feedback;
  String? _selectedAssetElementId;
  bool _isAnalyzingAsset = false;
  bool _isPreparingPublication = false;
  bool _isPublishing = false;
  BorderAssetStepFeedback? _assetFeedback;
  BorderStudioPublicationPreview? _publicationPreview;
  final Map<String, Map<String, Uint8List>> _assetPreviewBytesByBlueprintId =
      <String, Map<String, Uint8List>>{};
  final TextEditingController _renameController = TextEditingController();
  bool _isRenaming = false;

  static const _steps = <({String label, IconData icon})>[
    (label: 'Type', icon: CupertinoIcons.square_grid_2x2),
    (label: 'Assets', icon: CupertinoIcons.photo_on_rectangle),
    (label: 'Rôles', icon: CupertinoIcons.tag),
    (label: 'Règles', icon: CupertinoIcons.slider_horizontal_3),
    (label: 'Aperçu et publication', icon: CupertinoIcons.play_rectangle),
  ];

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manifest = ref.watch(editorProjectManifestProvider);
    if (manifest == null) {
      return const PokeMapPageSurface(
        child: PokeMapEmptyState(
          key: ValueKey<String>('border-studio-missing-project'),
          title: 'Ouvrez un projet pour utiliser Border Studio',
          description:
              'Les blueprints appartiennent au projet, mais ne nécessitent aucune carte active.',
          icon: Icon(CupertinoIcons.square_on_square),
        ),
      );
    }

    final state = ref.watch(borderStudioDraftControllerProvider);
    final controller = ref.read(borderStudioDraftControllerProvider.notifier);
    final projectRootPath = ref.watch(editorProjectRootPathProvider);
    final publicationPreview = _currentPublicationPreview(
      manifest: manifest,
      state: state,
    );
    final isPublicationBusy = _isPreparingPublication || _isPublishing;

    return PokeMapPageSurface(
      key: const ValueKey<String>('border-studio-workspace'),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 232,
            child: PokeMapPanel(
              expandChild: true,
              header: const Padding(
                padding: EdgeInsets.all(14),
                child: PokeMapSectionHeader(
                  title: 'Blueprints',
                  description: 'Recettes réutilisables du projet',
                ),
              ),
              footer: Padding(
                padding: const EdgeInsets.all(12),
                child: PokeMapButton(
                  key: const ValueKey<String>('border-studio-new-blueprint'),
                  onPressed: state.isDirty || isPublicationBusy
                      ? null
                      : () => _createBlueprint(controller, state),
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.add, size: 14),
                  child: const Text('Nouveau blueprint'),
                ),
              ),
              child: state.catalogRecords.isEmpty && state.workingDraft == null
                  ? const PokeMapEmptyState(
                      title: 'Aucun blueprint',
                      description:
                          'Créez une première recette de côte, muret ou clôture.',
                      icon: Icon(CupertinoIcons.square_on_square),
                    )
                  : ListView(
                      children: [
                        for (final record in state.catalogRecords) ...[
                          PokeMapSidebarItem(
                            label: record.draft.definition.name,
                            subtitle: record.latestPublished == null
                                ? 'Brouillon'
                                : 'Révision ${record.latestPublished!.revision}',
                            selected: state.selectedBlueprintId == record.id,
                            icon: const Icon(
                              CupertinoIcons.square_on_square,
                              size: 16,
                            ),
                            onTap: isPublicationBusy ||
                                    (state.isDirty &&
                                        state.selectedBlueprintId != record.id)
                                ? null
                                : () => controller.selectBlueprint(record.id),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (state.workingDraft != null &&
                            !state.catalogRecords.any(
                              (record) => record.id == state.workingDraft!.id,
                            ))
                          PokeMapSidebarItem(
                            label:
                                state.workingDraft!.blueprint.definition.name,
                            subtitle: 'Nouveau brouillon',
                            selected: true,
                            icon: const Icon(CupertinoIcons.doc_append),
                            onTap: isPublicationBusy ? null : () {},
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PokeMapPanel(
              expandChild: true,
              header: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.workingDraft case final workingDraft?) ...[
                      Row(
                        children: [
                          Expanded(
                            child: PokeMapSectionHeader(
                              title: workingDraft.blueprint.definition.name,
                              description: 'Blueprint en cours d’édition',
                            ),
                          ),
                          PokeMapIconButton(
                            key: const ValueKey<String>(
                              'border-studio-rename-blueprint',
                            ),
                            tooltip: 'Renommer',
                            onPressed: isPublicationBusy
                                ? null
                                : () => _beginRename(state),
                            icon: const Icon(CupertinoIcons.pencil),
                          ),
                          const SizedBox(width: 4),
                          PokeMapIconButton(
                            key: const ValueKey<String>(
                              'border-studio-duplicate-blueprint',
                            ),
                            tooltip: 'Dupliquer',
                            onPressed: isPublicationBusy
                                ? null
                                : () => _duplicateBlueprint(
                                      controller,
                                      state,
                                    ),
                            icon: const Icon(CupertinoIcons.doc_on_doc),
                          ),
                          const SizedBox(width: 4),
                          PokeMapIconButton(
                            key: const ValueKey<String>(
                              'border-studio-delete-blueprint',
                            ),
                            tooltip: state.canDeleteSelectedDraft
                                ? 'Supprimer le brouillon'
                                : 'Une identité publiée ne peut pas être supprimée',
                            variant: PokeMapIconButtonVariant.danger,
                            onPressed: state.canDeleteSelectedDraft &&
                                    !isPublicationBusy
                                ? () => _deleteBlueprint(controller)
                                : null,
                            icon: const Icon(CupertinoIcons.delete),
                          ),
                        ],
                      ),
                      if (_isRenaming) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: PokeMapTextField(
                                fieldKey: const ValueKey<String>(
                                  'border-studio-rename-field',
                                ),
                                controller: _renameController,
                                label: 'Nom visible du blueprint',
                                autofocus: true,
                                onSubmitted: isPublicationBusy
                                    ? null
                                    : (_) => _confirmRename(controller),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PokeMapButton(
                              key: const ValueKey<String>(
                                'border-studio-confirm-rename',
                              ),
                              onPressed: isPublicationBusy
                                  ? null
                                  : () => _confirmRename(controller),
                              size: PokeMapButtonSize.small,
                              child: const Text('Valider'),
                            ),
                            const SizedBox(width: 6),
                            PokeMapButton(
                              onPressed: isPublicationBusy
                                  ? null
                                  : () => setState(() => _isRenaming = false),
                              variant: PokeMapButtonVariant.ghost,
                              size: PokeMapButtonSize.small,
                              child: const Text('Annuler'),
                            ),
                          ],
                        ),
                      ],
                    ],
                    if (state.workingDraft != null) const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: Row(
                          children: [
                            for (var index = 0;
                                index < _steps.length;
                                index += 1) ...[
                              PokeMapButton(
                                key: ValueKey<String>(
                                  'border-studio-step-${_steps[index].label}',
                                ),
                                onPressed: isPublicationBusy
                                    ? null
                                    : () => setState(() => _activeStep = index),
                                autofocus: index == 0,
                                variant: PokeMapButtonVariant.secondary,
                                size: PokeMapButtonSize.small,
                                isSelected: _activeStep == index,
                                leading: Icon(_steps[index].icon),
                                child: Text(_steps[index].label),
                              ),
                              if (index < _steps.length - 1)
                                const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              child: switch (_activeStep) {
                0 => BorderTypeStep(
                    state: state,
                    onTemplateSelected: controller.setTemplate,
                  ),
                1 => BorderAssetsStep(
                    state: state,
                    manifest: manifest,
                    selectedSourceElementId: _selectedAssetElementId,
                    onSourceElementSelected: (id) => setState(() {
                      _selectedAssetElementId = id;
                      _assetFeedback = null;
                    }),
                    onAnalyzeSelected: () => _analyzeSelectedAsset(
                      controller,
                      state,
                      manifest,
                      projectRootPath,
                    ),
                    onReanalyzePrimitive: (primitiveId) => _reanalyzeAsset(
                      controller,
                      state,
                      manifest,
                      projectRootPath,
                      primitiveId,
                    ),
                    onRemovePrimitive: (primitiveId) =>
                        _removeAsset(controller, primitiveId),
                    onAuthoredOrientationChanged: (primitiveId, orientation) =>
                        _changeAuthoredOrientation(
                      controller,
                      primitiveId,
                      orientation,
                    ),
                    previewBytesByPrimitiveId: _assetPreviewBytesByBlueprintId[
                            state.selectedBlueprintId] ??
                        const <String, Uint8List>{},
                    feedback: _assetFeedback,
                    isAnalyzing: _isAnalyzingAsset,
                  ),
                2 => BorderRolesStep(
                    state: state,
                    onRoleChanged: (primitiveId, role) => _changeRole(
                      controller,
                      state,
                      primitiveId,
                      role,
                    ),
                  ),
                3 => BorderRulesStep(
                    state: state,
                    onRulesChanged: controller.setGenerationParams,
                  ),
                _ => BorderPreviewPublicationStep(
                    state: state,
                    preview: publicationPreview,
                    isPreparing: _isPreparingPublication,
                    isPublishing: _isPublishing,
                    feedback: _feedback,
                    onPreparePreview: () => _preparePublication(controller),
                    onNewVariation: () => _newPreviewVariation(controller),
                    onAcknowledgeWarning: controller.acknowledgeWarningCode,
                    onSaveDraft: () => _saveDraft(controller),
                    onPublish: () => _publish(controller),
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  void _createBlueprint(
    BorderStudioDraftController controller,
    BorderStudioDraftState state,
  ) {
    var ordinal = state.catalogRecords.length + 1;
    var id = 'border-blueprint-$ordinal';
    final workingDraft = state.workingDraft;
    final ids = <String>{
      for (final record in state.catalogRecords) record.id,
      if (workingDraft != null) workingDraft.id,
    };
    while (ids.contains(id)) {
      ordinal += 1;
      id = 'border-blueprint-$ordinal';
    }
    controller.createBlueprint(
      id: id,
      name: 'Nouvelle bordure $ordinal',
      template: BorderBlueprintTemplate.organicEdge,
    );
    setState(() {
      _activeStep = 0;
      _feedback = null;
      _assetFeedback = null;
      _assetPreviewBytesByBlueprintId.clear();
      _publicationPreview = null;
      _isRenaming = false;
    });
  }

  void _beginRename(BorderStudioDraftState state) {
    final name = state.workingDraft?.blueprint.definition.name;
    if (name == null) return;
    _renameController.text = name;
    _renameController.selection = TextSelection.collapsed(offset: name.length);
    setState(() => _isRenaming = true);
  }

  void _confirmRename(BorderStudioDraftController controller) {
    final name = _renameController.text.trim();
    if (name.isEmpty) return;
    controller.renameBlueprint(name);
    setState(() => _isRenaming = false);
  }

  void _duplicateBlueprint(
    BorderStudioDraftController controller,
    BorderStudioDraftState state,
  ) {
    final working = state.workingDraft;
    if (working == null) return;
    final knownIds = <String>{
      for (final record in state.catalogRecords) record.id,
      working.id,
    };
    var ordinal = 1;
    var id = '${working.id}-copy-$ordinal';
    while (knownIds.contains(id)) {
      ordinal += 1;
      id = '${working.id}-copy-$ordinal';
    }
    controller.copyBlueprint(
      sourceBlueprintId: working.id,
      newBlueprintId: id,
      name: '${working.blueprint.definition.name} — copie',
    );
    setState(() {
      _assetPreviewBytesByBlueprintId.clear();
      _publicationPreview = null;
      _assetFeedback = null;
      _isRenaming = false;
    });
  }

  void _deleteBlueprint(BorderStudioDraftController controller) {
    final updated = controller.deleteSelectedDraft();
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: 'Brouillon Border supprimé du projet.',
        );
    setState(() {
      _activeStep = 0;
      _assetPreviewBytesByBlueprintId.clear();
      _publicationPreview = null;
      _assetFeedback = null;
      _isRenaming = false;
    });
  }

  Future<void> _analyzeSelectedAsset(
    BorderStudioDraftController controller,
    BorderStudioDraftState state,
    ProjectManifest manifest,
    String? projectRootPath,
  ) async {
    final working = state.workingDraft;
    final sourceElementId = _resolveSelectedElementId(manifest);
    if (working == null || sourceElementId == null) return;
    final targetBlueprintId = working.id;
    final role = orderedBorderRoles(state.allowedPrimitiveRoles).firstOrNull;
    if (role == null) return;
    final primitiveId = _nextPrimitiveId(
      working.blueprint.definition.primitives,
    );
    await _runAssetAnalysis(() async {
      final prepared = await _assetService.prepare(
        manifest: manifest,
        projectRootPath: projectRootPath ?? '',
        sourceElementId: sourceElementId,
        primitiveId: primitiveId,
        role: role,
        weight: 1000,
        transforms: BorderTransformPolicy(
          allowFlipX: working.blueprint.definition.template ==
                  BorderBlueprintTemplate.connectedLine ||
              working.blueprint.definition.template ==
                  BorderBlueprintTemplate.masonryLine,
          allowedQuarterTurns: const <int>[0, 1, 2, 3],
        ),
      );
      if (!_isAssetAnalysisTargetCurrent(
        manifest: manifest,
        projectRootPath: projectRootPath,
        blueprintId: targetBlueprintId,
        primitiveIdMustBeAbsent: primitiveId,
      )) {
        return 'Le résultat a été ignoré car le projet ou le blueprint actif a changé.';
      }
      controller.addPreparedPrimitive(prepared.primitive);
      (_assetPreviewBytesByBlueprintId[targetBlueprintId] ??=
              <String, Uint8List>{})[primitiveId] =
          prepared.preparation.files.first.bytes;
      return 'L’élément ${prepared.sourceElement.name} est prêt dans le blueprint.';
    });
  }

  Future<void> _reanalyzeAsset(
    BorderStudioDraftController controller,
    BorderStudioDraftState state,
    ProjectManifest manifest,
    String? projectRootPath,
    String primitiveId,
  ) async {
    BorderPrimitiveDraft? primitive;
    for (final candidate
        in state.workingDraft!.blueprint.definition.primitives) {
      if (candidate.id == primitiveId) {
        primitive = candidate;
        break;
      }
    }
    if (primitive == null) return;
    final source = primitive;
    final targetBlueprintId = state.workingDraft!.id;
    await _runAssetAnalysis(() async {
      final prepared = await _assetService.reanalyze(
        manifest: manifest,
        projectRootPath: projectRootPath ?? '',
        primitive: source,
      );
      if (!_isAssetAnalysisTargetCurrent(
        manifest: manifest,
        projectRootPath: projectRootPath,
        blueprintId: targetBlueprintId,
        expectedPrimitive: source,
      )) {
        return 'Le résultat a été ignoré car le projet, le blueprint ou l’asset actif a changé.';
      }
      controller.replacePrimitiveAfterReanalysis(prepared.primitive);
      (_assetPreviewBytesByBlueprintId[targetBlueprintId] ??=
              <String, Uint8List>{})[primitiveId] =
          prepared.preparation.files.first.bytes;
      return 'La source de ${prepared.sourceElement.name} a été relue explicitement.';
    });
  }

  void _removeAsset(
    BorderStudioDraftController controller,
    String primitiveId,
  ) {
    controller.removePrimitive(primitiveId);
    setState(() {
      final blueprintId =
          ref.read(borderStudioDraftControllerProvider).selectedBlueprintId;
      _assetPreviewBytesByBlueprintId[blueprintId]?.remove(primitiveId);
      _assetFeedback = const BorderAssetStepFeedback.info(
        'Asset retiré du brouillon.',
      );
    });
  }

  bool _isAssetAnalysisTargetCurrent({
    required ProjectManifest manifest,
    required String? projectRootPath,
    required String blueprintId,
    BorderPrimitiveDraft? expectedPrimitive,
    String? primitiveIdMustBeAbsent,
  }) {
    if (!mounted ||
        ref.read(editorProjectManifestProvider) != manifest ||
        ref.read(editorProjectRootPathProvider) != projectRootPath) {
      return false;
    }
    final current = ref.read(borderStudioDraftControllerProvider);
    if (current.selectedBlueprintId != blueprintId ||
        current.workingDraft?.id != blueprintId) {
      return false;
    }
    final primitives = current.workingDraft!.blueprint.definition.primitives;
    if (primitiveIdMustBeAbsent != null &&
        primitives
            .any((primitive) => primitive.id == primitiveIdMustBeAbsent)) {
      return false;
    }
    if (expectedPrimitive != null &&
        !primitives.any((primitive) => primitive == expectedPrimitive)) {
      return false;
    }
    return true;
  }

  Future<void> _runAssetAnalysis(
    Future<String> Function() action,
  ) async {
    setState(() {
      _isAnalyzingAsset = true;
      _assetFeedback = null;
    });
    try {
      final message = await action();
      if (!mounted) return;
      setState(() {
        _isAnalyzingAsset = false;
        _assetFeedback = BorderAssetStepFeedback.success(message);
      });
    } on BorderProjectElementAssetException catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnalyzingAsset = false;
        _assetFeedback = BorderAssetStepFeedback.error(error.userMessage);
      });
    } on BorderAssetSnapshotException catch (error) {
      if (!mounted) return;
      setState(() {
        _isAnalyzingAsset = false;
        _assetFeedback = BorderAssetStepFeedback.error(error.userMessage);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAnalyzingAsset = false;
        _assetFeedback = const BorderAssetStepFeedback.error(
          'L’asset n’a pas pu être analysé. Vérifiez sa source dans la bibliothèque.',
        );
      });
    }
  }

  String? _resolveSelectedElementId(ProjectManifest manifest) {
    for (final element in manifest.elements) {
      if (element.id == _selectedAssetElementId) return element.id;
    }
    return manifest.elements.firstOrNull?.id;
  }

  String _nextPrimitiveId(List<BorderPrimitiveDraft> primitives) {
    final ids = <String>{for (final primitive in primitives) primitive.id};
    var ordinal = primitives.length + 1;
    var id = 'border-primitive-$ordinal';
    while (ids.contains(id)) {
      ordinal += 1;
      id = 'border-primitive-$ordinal';
    }
    return id;
  }

  Future<void> _saveDraft(BorderStudioDraftController controller) async {
    final updated = controller.saveDraft();
    final editor = ref.read(editorNotifierProvider.notifier);
    editor.applyInMemoryProjectManifest(
      updated,
      statusMessage: 'Brouillon Border prêt à être sauvegardé.',
    );
    setState(() {
      _publicationPreview = null;
      _feedback = 'Sauvegarde du brouillon…';
    });
    final saved = await editor.saveProjectManifest();
    if (!mounted) return;
    setState(() {
      _feedback = saved
          ? 'Brouillon enregistré. Régénérez ensuite l’aperçu canonique.'
          : 'Le brouillon reste en mémoire, mais son écriture sur disque a échoué.';
    });
  }

  void _changeRole(
    BorderStudioDraftController controller,
    BorderStudioDraftState state,
    String primitiveId,
    BorderPrimitiveRole role,
  ) {
    final definition = state.workingDraft!.blueprint.definition;
    controller.replacePrimitives(<BorderPrimitiveDraft>[
      for (final primitive in definition.primitives)
        primitive.id == primitiveId
            ? BorderPrimitiveDraft(
                id: primitive.id,
                sourceElementId: primitive.sourceElementId,
                role: role,
                authoredOrientation: primitive.authoredOrientation,
                weight: primitive.weight,
                anchorPx: primitive.anchorPx,
                transforms: primitive.transforms,
                currentMetrics: primitive.currentMetrics,
              )
            : primitive,
    ]);
  }

  void _changeAuthoredOrientation(
    BorderStudioDraftController controller,
    String primitiveId,
    BorderPrimitiveOrientation orientation,
  ) {
    controller.setPrimitiveAuthoredOrientation(primitiveId, orientation);
    setState(() {
      _publicationPreview = null;
      _feedback = 'Orientation mise à jour. Regénérez l’aperçu canonique.';
    });
  }

  BorderStudioPublicationPreview? _currentPublicationPreview({
    required ProjectManifest manifest,
    required BorderStudioDraftState state,
  }) {
    final prepared = _publicationPreview;
    final record = _workingRecord(manifest: manifest, state: state);
    if (prepared == null ||
        record == null ||
        prepared.previousManifest != manifest ||
        prepared.draftRecord != record) {
      return null;
    }
    return prepared;
  }

  BorderBlueprintRecord? _workingRecord({
    required ProjectManifest manifest,
    required BorderStudioDraftState state,
  }) {
    final working = state.workingDraft;
    if (working == null) return null;
    final persisted = manifest.borderCatalog.recordById(working.id);
    return BorderBlueprintRecord(
      id: working.id,
      draft: working.blueprint,
      latestPublished: persisted?.latestPublished,
      isDeprecated: persisted?.isDeprecated ?? false,
    );
  }

  Future<void> _preparePublication(
    BorderStudioDraftController controller,
  ) async {
    final coordinator = ref.read(borderStudioPublicationCoordinatorProvider);
    final manifest = ref.read(editorProjectManifestProvider);
    final projectRootPath = ref.read(editorProjectRootPathProvider);
    final state = ref.read(borderStudioDraftControllerProvider);
    final record = manifest == null
        ? null
        : _workingRecord(manifest: manifest, state: state);
    if (coordinator == null ||
        manifest == null ||
        projectRootPath == null ||
        record == null) {
      setState(() {
        _feedback =
            'Ouvrez un projet et sélectionnez un blueprint avant de générer la galerie.';
      });
      return;
    }
    setState(() {
      _isPreparingPublication = true;
      _publicationPreview = null;
      _feedback = null;
    });
    try {
      final ground = record.draft.definition.ground;
      final groundSnapshots = ground == null
          ? const <BorderGroundVariantRole, BorderAssetSnapshotPreparation>{}
          : await _groundSnapshotService.prepareAllRoles(
              manifest: manifest,
              projectRootPath: projectRootPath,
              sourceSmartTilePresetId: ground.sourceSmartTilePresetId,
            );
      final prepared = await coordinator.prepare(
        manifest: manifest,
        projectRootPath: projectRootPath,
        draftRecord: record,
        groundSnapshotsByRole: groundSnapshots,
      );
      if (!mounted) return;
      if (!_isPublicationTargetCurrent(
        expectedProjectRootPath: projectRootPath,
        expectedManifest: manifest,
        expectedRecord: record,
      )) {
        setState(() {
          _isPreparingPublication = false;
          _feedback =
              'Le projet a changé pendant la génération. Relancez l’aperçu.';
        });
        return;
      }
      controller.setDiagnostics(prepared.diagnostics);
      setState(() {
        _isPreparingPublication = false;
        _publicationPreview = prepared;
        _feedback = prepared.diagnostics.hasErrors
            ? 'La galerie a été générée avec des erreurs bloquantes.'
            : '${prepared.canonicalGalleryCases.length} cas canoniques ont été générés avec les pixels candidats.';
      });
    } on BorderStudioPublicationCoordinatorException catch (error) {
      if (!mounted) return;
      if (!_isPublicationTargetCurrent(
        expectedProjectRootPath: projectRootPath,
        expectedManifest: manifest,
        expectedRecord: record,
      )) {
        setState(() {
          _isPreparingPublication = false;
          _feedback =
              'Le résultat a été ignoré car le projet ou le blueprint a changé.';
        });
        return;
      }
      controller.setDiagnostics(error.diagnostics);
      setState(() {
        _isPreparingPublication = false;
        _feedback = error.userMessage;
      });
    } on BorderPublicationCandidateException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparingPublication = false;
        _feedback = error.userMessage;
      });
    } on BorderProjectElementAssetException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparingPublication = false;
        _feedback = error.userMessage;
      });
    } on BorderAssetSnapshotException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparingPublication = false;
        _feedback = error.userMessage;
      });
    } on BorderSmartTileGroundSnapshotException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPreparingPublication = false;
        _feedback = error.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPreparingPublication = false;
        _feedback =
            'La galerie canonique n’a pas pu être générée. Vérifiez les assets et les rôles.';
      });
    }
  }

  bool _isPublicationTargetCurrent({
    required String expectedProjectRootPath,
    required ProjectManifest expectedManifest,
    required BorderBlueprintRecord expectedRecord,
  }) {
    if (ref.read(editorProjectRootPathProvider) != expectedProjectRootPath) {
      return false;
    }
    final currentManifest = ref.read(editorProjectManifestProvider);
    if (currentManifest != expectedManifest) return false;
    final currentRecord = _workingRecord(
      manifest: expectedManifest,
      state: ref.read(borderStudioDraftControllerProvider),
    );
    return currentRecord == expectedRecord;
  }

  bool _isPublicationCompletionCurrent({
    required String expectedProjectRootPath,
    required ProjectManifest expectedManifest,
    required BorderBlueprintRecord expectedRecord,
    required ProjectManifest resultManifest,
  }) {
    if (ref.read(editorProjectRootPathProvider) != expectedProjectRootPath) {
      return false;
    }
    final currentManifest = ref.read(editorProjectManifestProvider);
    final currentState = ref.read(borderStudioDraftControllerProvider);
    if (currentManifest == expectedManifest) {
      return _workingRecord(
            manifest: expectedManifest,
            state: currentState,
          ) ==
          expectedRecord;
    }
    if (currentManifest != resultManifest) return false;
    final resultRecord = resultManifest.borderCatalog.recordById(
      expectedRecord.id,
    );
    return resultRecord != null &&
        _workingRecord(
              manifest: resultManifest,
              state: currentState,
            ) ==
            resultRecord;
  }

  Future<void> _newPreviewVariation(
    BorderStudioDraftController controller,
  ) async {
    controller.newPreviewVariation();
    setState(() {
      _publicationPreview = null;
      _feedback = 'Nouvelle graine appliquée. Régénération en cours…';
    });
    await _preparePublication(controller);
  }

  Future<void> _publish(BorderStudioDraftController controller) async {
    final coordinator = ref.read(borderStudioPublicationCoordinatorProvider);
    final manifest = ref.read(editorProjectManifestProvider);
    final projectRootPath = ref.read(editorProjectRootPathProvider);
    final state = ref.read(borderStudioDraftControllerProvider);
    final record = manifest == null
        ? null
        : _workingRecord(manifest: manifest, state: state);
    final prepared = manifest == null
        ? null
        : _currentPublicationPreview(manifest: manifest, state: state);
    final callback = widget.onPublishRequested;
    if ((coordinator == null && callback == null) ||
        manifest == null ||
        projectRootPath == null ||
        record == null ||
        prepared == null) {
      setState(() {
        _publicationPreview = null;
        _feedback =
            'L’aperçu n’est plus à jour. Régénérez les cas canoniques avant de publier.';
      });
      return;
    }
    setState(() {
      _isPublishing = true;
      _feedback = null;
    });
    try {
      if (callback != null) {
        await callback();
        if (!mounted) return;
        if (!_isPublicationTargetCurrent(
          expectedProjectRootPath: projectRootPath,
          expectedManifest: manifest,
          expectedRecord: record,
        )) {
          setState(() {
            _isPublishing = false;
            _publicationPreview = null;
            _feedback =
                'Le résultat a été ignoré car le projet ou le blueprint a changé.';
          });
          return;
        }
        setState(() {
          _isPublishing = false;
          _publicationPreview = null;
          _feedback = 'Révision publiée.';
        });
        return;
      }
      final result = await coordinator!.publish(
        preview: prepared,
        currentManifest: manifest,
        currentDraftRecord: record,
        acknowledgedWarningCodes: state.acknowledgedWarningCodes,
      );
      if (!mounted) return;
      if (!_isPublicationCompletionCurrent(
        expectedProjectRootPath: projectRootPath,
        expectedManifest: manifest,
        expectedRecord: record,
        resultManifest: result.manifest,
      )) {
        setState(() {
          _isPublishing = false;
          _publicationPreview = null;
          _feedback =
              'Le résultat a été ignoré car le projet ou le blueprint a changé.';
        });
        return;
      }
      if (ref.read(editorProjectManifestProvider) != result.manifest) {
        ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
              result.manifest,
              statusMessage: 'Blueprint de bordure publié.',
            );
      }
      controller.synchronizeFromManifest(
        result.manifest,
        projectIdentity: projectRootPath,
      );
      setState(() {
        _isPublishing = false;
        _publicationPreview = null;
        _feedback = 'Révision ${prepared.candidate.revision} publiée.';
      });
    } on BorderStudioPublicationCoordinatorException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        if (error.code ==
            BorderStudioPublicationCoordinatorErrorCode.stalePreview) {
          _publicationPreview = null;
        }
        _feedback = error.userMessage;
      });
    } on BorderPublicationTransactionException catch (error) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        if (error.manifestCommitted) _publicationPreview = null;
        _feedback = error.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPublishing = false;
        _feedback =
            'La publication a échoué. Le brouillon et la dernière révision restent disponibles.';
      });
    }
  }
}
