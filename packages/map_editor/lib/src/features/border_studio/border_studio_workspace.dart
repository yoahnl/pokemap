import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../ui/design_system/design_system.dart';
import '../editor/state/editor_notifier.dart';
import '../editor/state/editor_selectors.dart';
import 'application/border_studio_draft.dart';
import 'application/border_studio_draft_controller.dart';
import 'presentation/border_assets_step.dart';
import 'presentation/border_preview_publication_step.dart';
import 'presentation/border_roles_step.dart';
import 'presentation/border_rules_step.dart';
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
  int _activeStep = 0;
  String? _feedback;

  static const _steps = <({String label, IconData icon})>[
    (label: 'Type', icon: CupertinoIcons.square_grid_2x2),
    (label: 'Assets', icon: CupertinoIcons.photo_on_rectangle),
    (label: 'Rôles', icon: CupertinoIcons.tag),
    (label: 'Règles', icon: CupertinoIcons.slider_horizontal_3),
    (label: 'Aperçu et publication', icon: CupertinoIcons.play_rectangle),
  ];

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
                  onPressed: state.isDirty
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
                            onTap: state.isDirty &&
                                    state.selectedBlueprintId != record.id
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
                            onTap: () {},
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PokeMapPanel(
              expandChild: true,
              header: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
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
                          onPressed: () => setState(() => _activeStep = index),
                          autofocus: index == 0,
                          variant: PokeMapButtonVariant.secondary,
                          size: PokeMapButtonSize.small,
                          isSelected: _activeStep == index,
                          leading: Icon(_steps[index].icon),
                          child: Text(_steps[index].label),
                        ),
                        if (index < _steps.length - 1) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ),
              child: switch (_activeStep) {
                0 => BorderTypeStep(
                    state: state,
                    onTemplateSelected: controller.setTemplate,
                  ),
                1 => BorderAssetsStep(state: state),
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
                    feedback: _feedback,
                    onNewVariation: controller.newPreviewVariation,
                    onSaveDraft: () => _saveDraft(controller),
                    onPublish: _publish,
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
    });
  }

  void _saveDraft(BorderStudioDraftController controller) {
    final updated = controller.saveDraft();
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: 'Brouillon Border enregistré dans le projet.',
        );
    setState(() => _feedback = 'Brouillon enregistré.');
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
                weight: primitive.weight,
                anchorPx: primitive.anchorPx,
                transforms: primitive.transforms,
                currentMetrics: primitive.currentMetrics,
              )
            : primitive,
    ]);
  }

  Future<void> _publish() async {
    final publish = widget.onPublishRequested;
    if (publish == null) {
      setState(() {
        _feedback =
            'La recette est prête. Préparez ses snapshots immuables pour finaliser la publication.';
      });
      return;
    }
    await publish();
    if (mounted) {
      setState(() => _feedback = 'Révision publiée.');
    }
  }
}
