import '../../../features/resources/coordination/model_resource_workflow.dart'
    as workflow;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../../features/resources/domain/model_resource_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import '../../../platform/files/native_model_picker.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/layout/studio_section.dart';
import 'resource_management_bindings.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'model_animation_controls.dart';
import 'model_shadow_controls.dart';
import 'model_light_controls.dart';
import 'model_light_gizmo.dart';

String modelDiagnosticLabel(String code) => switch (code) {
  'renderer.missing_material_magenta' => 'Ce modèle n’a pas de matériau. Les surfaces concernées sont affichées en rose.',
  'bounds.static_scene_only' => 'Les dimensions affichées correspondent à la pose de repos ; l’animation peut dépasser ce cadre.',
  'bounds.bind_pose_only' =>
    'Les dimensions correspondent à la pose initiale du squelette.',
  'renderer.ignored_color_0' =>
    'Les couleurs par sommet ne sont pas utilisées par cet aperçu.',
  'renderer.ignored_normalTexture' =>
    'La texture de relief fin n’est pas utilisée par cet aperçu.',
  'renderer.ignored_occlusionTexture' =>
    'La texture d’occlusion n’est pas utilisée par cet aperçu.',
  'renderer.ignored_emissiveTexture' || 'renderer.ignored_emissiveFactor' =>
    'L’effet lumineux du matériau n’est pas utilisé par cet aperçu.',
  'renderer.ignored_metallicRoughnessTexture' ||
  'renderer.ignored_metallicFactor' ||
  'renderer.ignored_roughnessFactor' =>
    'L’aspect métallique et la rugosité ne sont pas reproduits par cet aperçu.',
  _ => 'Ce modèle contient une propriété visuelle que cet aperçu ne reproduit pas.',
};

Future<void> importStudioModel(
  ResourceNavigation navigation, {
  PickModelSource picker = pickNativeModel,
}) => workflow.importStudioModel(navigation, picker: picker);

Future<ResourceMutationReceipt?> replaceStudioModelSource(
  ResourceNavigation navigation,
  String modelId, {
  PickModelSource picker = pickNativeModel,
}) => workflow.replaceStudioModelSource(navigation, modelId, picker: picker);

Map<String, int> openModelOccurrences(
  ResourceNavigation navigation,
  String modelId,
) => workflow.openModelOccurrences(navigation, modelId);

class ModelResourceLibrary extends StatefulWidget {
  const ModelResourceLibrary({
    super.key,
    required this.navigation,
    required this.items,
    this.previewBuilder,
  });
  final List<ResourceItem> items;
  final ResourceNavigation navigation;
  final Widget Function(ProjectModel3dEntry model, Uint8List bytes)?
  previewBuilder;

  @override
  State<ModelResourceLibrary> createState() => _ModelResourceLibraryState();
}

class _ModelResourceLibraryState extends State<ModelResourceLibrary> {
  final controls = ModelPreviewController();
  String? selectedId;
  Future<Uint8List>? source;
  String? error;
  late final _workflow = workflow.ModelDefinitionWorkflow(
    navigation: widget.navigation,
    isActive: () => mounted,
  );

  Future<bool> confirmSharedEdit(
    ProjectModel3dEntry model,
    Map<String, int> occurrences,
  ) async {
    final total = occurrences.values.fold(0, (sum, count) => sum + count);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const ValueKey('model-scope-review'),
        title: const Text('Modifier la définition partagée ?'),
        content: Text(
          '« ${model.name} » est posé $total fois sur les cartes ouvertes : '
          '${occurrences.entries.map((entry) => '${entry.key} (${entry.value})').join(', ')}.\n\n'
          'Le changement s’appliquera à toutes ses occurrences, y compris sur '
          'les cartes fermées. Chaque occurrence garde son identité, sa '
          'position et ses propres réglages.',
        ),
        actions: [
          StudioButton(
            key: const ValueKey('model-scope-cancel'),
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          StudioButton(
            key: const ValueKey('model-scope-confirm'),
            label: 'Modifier toutes les occurrences',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Widget sharedScope(ProjectModel3dEntry model) {
    final occurrences = openModelOccurrences(widget.navigation, model.id);
    final total = occurrences.values.fold(0, (sum, count) => sum + count);
    final maps = occurrences.length;
    return StudioPanel(
      key: const ValueKey('model-shared-scope'),
      compact: true,
      icon: Icons.share_outlined,
      title: 'Définition partagée',
      children: [
        Text(
          total == 0
              ? 'Aucune occurrence sur les cartes ouvertes. Les réglages ci-dessous '
                    's’appliqueront à chaque futur placement.'
              : '$total occurrence${total == 1 ? '' : 's'} sur $maps carte'
                    '${maps == 1 ? '' : 's'} ouverte${maps == 1 ? '' : 's'}. '
                    'Les réglages ci-dessous s’appliquent à toutes ; position, '
                    'rotation et réglages propres restent édités sur la carte.',
        ),
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('model-usages'),
          label: 'Voir tous les usages',
          icon: Icons.travel_explore,
          secondary: true,
          onPressed: widget.navigation.busy
              ? null
              : () => openResourceUsages(
                  context,
                  widget.navigation,
                  ResourceItem(
                    id: model.id,
                    name: model.name,
                    kind: ResourceKind.decors,
                    model3d: model,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> shared(
    ProjectModel3dEntry model,
    Map<String, Object?> fields,
  ) async {
    await _workflow.configure(
      model,
      fields,
      confirmShared: (occurrences) => confirmSharedEdit(model, occurrences),
    );
  }

  @override
  void dispose() {
    controls.dispose();
    super.dispose();
  }

  void select(ProjectModel3dEntry model) {
    selectedId = model.id;
    controls.play(null);
    controls.reset();
    controls.setLight(model.light);
    source = (widget.navigation.port as ModelResourcePort).readModel(model.id);
  }

  Future<void> configure(
    ProjectModel3dEntry model,
    Map<String, Object?> fields,
  ) async {
    try {
      await shared(model, fields);
      if (mounted) setState(() => error = null);
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    }
  }

  Future<void> remove(ProjectModel3dEntry model) async {
    Future<bool> confirm() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Retirer « ${model.name} » ?'),
          content: const Text(
            'Le modèle et sa source seront retirés de la bibliothèque. Un modèle utilisé sur une carte ne peut pas être retiré.',
          ),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(context, false),
            ),
            StudioButton(
              label: 'Retirer',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      return confirmed == true;
    }

    try {
      final removed = await _workflow.remove(model, confirm: confirm);
      if (mounted && removed) {
        setState(() {
          selectedId = null;
          source = null;
        });
      }
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.navigation;
    if (n.port is! ModelResourcePort) {
      return const StudioNotice(
        'L’import 3D est indisponible dans cette session.',
      );
    }
    final models = widget.items.map((item) => item.model3d!).toList();
    final preferred = selectedId ?? n.library.selectedId;
    var selected = models.where((m) => m.id == preferred).firstOrNull;
    if (selected == null && models.isNotEmpty) {
      selected = models.first;
      select(selected);
    }
    if (selected != null && selectedId != selected.id) select(selected);
    if (models.isEmpty && n.workspace.project!.models3d.isNotEmpty) {
      return const Center(
        child: StudioNotice('Aucun modèle ne correspond aux filtres.'),
      );
    }
    if (models.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 460,
          child: StudioPanel(
            title: 'Votre bibliothèque 3D',
            children: [
              Text(
                'Importez un fichier GLB contenant le modèle et ses textures. Vous pourrez vérifier ses proportions et ses animations avant de le poser sur une carte.',
              ),
            ],
          ),
        ),
      );
    }
    final model = selected!;
    return LayoutBuilder(
      builder: (context, bounds) {
        final list = ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final resource in widget.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StudioChoice(
                  key: ValueKey('model-resource-${resource.model3d!.id}'),
                  label: resource.model3d!.name,
                  subtitle:
                      '${resource.model3d!.inspection.triangleCount} triangles · ${resource.model3d!.inspection.animations.length} animations · ${resourceCatalogContextLabel(n.workspace.project!, resource)}',
                  leading: const Icon(Icons.view_in_ar_outlined),
                  selected: resource.model3d!.id == model.id,
                  onTap: n.busy
                      ? null
                      : () => setState(() => select(resource.model3d!)),
                ),
              ),
          ],
        );
        final detail = SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (error != null) StudioNotice(error!, isError: true),
              sharedScope(model),
              const SizedBox(height: 12),
              SizedBox(
                height: bounds.maxHeight < 600 ? 240 : 360,
                child: FutureBuilder<Uint8List>(
                  future: source,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return StudioNotice(
                        'Aperçu indisponible : ${snapshot.error}',
                        isError: true,
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done ||
                        !snapshot.hasData) {
                      return const Center(
                        key: ValueKey('model-preview-loading'),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final box = model.inspection.bounds;
                    if (widget.previewBuilder case final build?) {
                      return build(model, snapshot.data!);
                    }
                    return ModelPreview(
                      key: ValueKey(model.id),
                      bytes: snapshot.data!,
                      controller: controls,
                      lightOverlayBuilder: (context, controller) =>
                          ModelLightGizmo(controller: controller),
                      minimum: [box.min.x, box.min.y, box.min.z],
                      maximum: [box.max.x, box.max.y, box.max.z],
                      background: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest,
                      loadingBuilder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, failure) => StudioNotice(
                        'Le modèle ne peut pas être affiché : $failure',
                        isError: true,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Glisser pour tourner · molette pour zoomer'),
                  StudioButton(
                    label: 'Recentrer',
                    secondary: true,
                    onPressed: controls.reset,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StudioSection(
                title: 'Général',
                children: [
                  IgnorePointer(
                    ignoring: n.busy,
                    child: StudioCommitField(
                      key: ValueKey('name-${model.id}'),
                      label: 'Nom',
                      value: model.name,
                      onCommit: (value) => configure(model, {'name': value}),
                    ),
                  ),
                  const SizedBox(height: 12),
                  IgnorePointer(
                    ignoring: n.busy,
                    child: StudioCommitField(
                      key: ValueKey('scale-${model.id}'),
                      label: 'Échelle · 1 unité = 1 case',
                      value: '${model.scale}',
                      tryCommit: (value) {
                        final scale = double.tryParse(
                          value.replaceAll(',', '.'),
                        );
                        if (scale == null || !scale.isFinite || scale <= 0) {
                          setState(
                            () => error =
                                'L’échelle doit être un nombre positif.',
                          );
                          return false;
                        }
                        configure(model, {'scale': scale});
                        return true;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dimensions : ${(model.inspection.bounds.size.x * model.scale).toStringAsFixed(2)} × ${(model.inspection.bounds.size.y * model.scale).toStringAsFixed(2)} × ${(model.inspection.bounds.size.z * model.scale).toStringAsFixed(2)} cases (largeur, hauteur, profondeur)',
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  StudioButton(
                    label: 'Placer l’origine au centre du pied',
                    secondary: true,
                    onPressed: n.busy
                        ? null
                        : () => configure(model, {
                            'pivot': {
                              'x':
                                  (model.inspection.bounds.min.x +
                                      model.inspection.bounds.max.x) /
                                  2,
                              'y': model.inspection.bounds.min.y,
                              'z':
                                  (model.inspection.bounds.min.z +
                                      model.inspection.bounds.max.z) /
                                  2,
                            },
                          }),
                  ),
                  Text(
                    'Origine : ${model.pivot.x.toStringAsFixed(2)}, ${model.pivot.y.toStringAsFixed(2)}, ${model.pivot.z.toStringAsFixed(2)}',
                  ),
                ],
              ),
              StudioSection(
                title: 'Ombres et lumière',
                children: [
                  ModelShadowControls(
                    key: ValueKey('model-shadows-${model.id}'),
                    model: model,
                    busy: n.busy,
                    onChanged: (value) =>
                        shared(model, {'castsShadowsByDefault': value}),
                  ),
                  const SizedBox(height: 12),
                  ModelLightControls(
                    key: ValueKey('model-light-${model.id}'),
                    previewController: controls,
                    model: model,
                    busy: n.busy,
                    onSave: (light) =>
                        shared(model, {'light': light?.toJson()}),
                  ),
                ],
              ),
              StudioSection(
                title: 'Collision et passage',
                children: const [
                  StudioNotice(
                    'Les réglages de collision et d’escalier sont temporairement indisponibles. Les paramètres enregistrés sont conservés.',
                    key: ValueKey('model-collision-ramp-unavailable'),
                  ),
                ],
              ),
              if (model.inspection.animations.isNotEmpty)
                StudioSection(
                  title: 'Animation',
                  children: [
                    ListenableBuilder(
                      listenable: controls,
                      builder: (context, _) => ModelAnimationControls(
                        clips: model.inspection.animations,
                        animationIndex: controls.animation,
                        loop: controls.animationLoop,
                        speed: controls.animationSpeed,
                        paused: controls.animationPaused,
                        onClip: controls.play,
                        onLoop: (value) =>
                            controls.configureAnimation(loop: value),
                        onSpeed: (value) =>
                            controls.configureAnimation(speed: value),
                        onPause: controls.toggleAnimationPause,
                        onReplay: controls.restartAnimation,
                      ),
                    ),
                  ],
                ),
              StudioSection(
                title: 'Source',
                children: [
                  for (final diagnostic in model.inspection.diagnostics)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: StudioNotice(modelDiagnosticLabel(diagnostic)),
                    ),
                  StudioButton(
                    label: 'Remplacer le modèle GLB',
                    secondary: true,
                    onPressed: n.busy
                        ? null
                        : () async {
                            await replaceStudioModelSource(n, model.id);
                            if (!mounted) return;
                            final current = n.workspace.project!.models3d
                                .where((entry) => entry.id == model.id)
                                .firstOrNull;
                            if (current != null) {
                              setState(() => select(current));
                            }
                          },
                  ),
                ],
              ),
              StudioSection(
                key: PageStorageKey('model-advanced-${model.id}'),
                title: 'Avancé',
                collapsible: true,
                initiallyExpanded: false,
                children: [
                  StudioButton(
                    label: 'Retirer de la bibliothèque',
                    secondary: true,
                    onPressed: n.busy ? null : () => remove(model),
                  ),
                ],
              ),
            ],
          ),
        );
        return bounds.maxWidth < 800
            ? Column(
                children: [
                  SizedBox(height: 130, child: list),
                  Expanded(child: detail),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 250, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(child: detail),
                ],
              );
      },
    );
  }
}
