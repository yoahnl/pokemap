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
import 'resource_navigation.dart';
import 'model_animation_controls.dart';

String modelDiagnosticLabel(String code) => switch (code) {
  'renderer.missing_material_magenta' =>
    'Ce modèle n’a pas de matériau. Les surfaces concernées sont affichées en rose.',
  'bounds.static_scene_only' =>
    'Les dimensions affichées correspondent à la pose de repos ; l’animation peut dépasser ce cadre.',
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
  _ =>
    'Ce modèle contient une propriété visuelle que cet aperçu ne reproduit pas.',
};

Future<void> importStudioModel(
  ResourceNavigation navigation, {
  PickModelSource picker = pickNativeModel,
}) async {
  if (navigation.busy || navigation.port is! ModelResourcePort) return;
  navigation.setImportBusy(true);
  try {
    final source = await picker();
    if (source == null || navigation.isDisposed) return;
    final receipt = await (navigation.port as ModelResourcePort).importModel(
      sourcePath: source.path,
      name: source.name,
    );
    await navigation.accept(receipt);
  } on ResourceFailure catch (failure) {
    navigation.pendingReceipt = failure.partialReceipt;
    if (!navigation.isDisposed) navigation.setImportError(failure.message);
  } on Object catch (failure) {
    if (!navigation.isDisposed) navigation.setImportError('$failure');
  } finally {
    if (!navigation.isDisposed) navigation.setImportBusy(false);
  }
}

class ModelResourceLibrary extends StatefulWidget {
  const ModelResourceLibrary({super.key, required this.navigation});
  final ResourceNavigation navigation;

  @override
  State<ModelResourceLibrary> createState() => _ModelResourceLibraryState();
}

class _ModelResourceLibraryState extends State<ModelResourceLibrary> {
  final controls = ModelPreviewController();
  String? selectedId;
  Future<Uint8List>? source;
  String? error;

  @override
  void dispose() {
    controls.dispose();
    super.dispose();
  }

  void select(ProjectModel3dEntry model) {
    selectedId = model.id;
    controls.play(null);
    controls.reset();
    source = (widget.navigation.port as ModelResourcePort).readModel(model.id);
  }

  Future<void> configure(
    ProjectModel3dEntry model,
    Map<String, Object?> fields,
  ) async {
    try {
      await widget.navigation.mutate('model3d.configure', {
        'modelId': model.id,
        ...fields,
      });
      if (mounted) setState(() => error = null);
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    }
  }

  Future<void> remove(ProjectModel3dEntry model) async {
    final problem = widget.navigation.modelRemovalProblem(model.id);
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
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
    if (confirmed != true || !mounted) return;
    final navigation = widget.navigation;
    final currentProblem = navigation.modelRemovalProblem(model.id);
    if (currentProblem != null || navigation.busy) {
      setState(
        () => error = currentProblem ?? 'Une opération est déjà en cours.',
      );
      return;
    }
    navigation.setImportBusy(true);
    try {
      await navigation.accept(
        await (navigation.port as ModelResourcePort).deleteModel(model.id),
      );
      if (mounted) {
        setState(() {
          selectedId = null;
          source = null;
        });
      }
    } on ResourceFailure catch (failure) {
      navigation.pendingReceipt = failure.partialReceipt;
      if (mounted) setState(() => error = failure.message);
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (!navigation.isDisposed) navigation.setImportBusy(false);
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
    final models = n.workspace.project!.models3d;
    var selected = models.where((m) => m.id == selectedId).firstOrNull;
    if (selected == null && models.isNotEmpty) {
      selected = models.first;
      select(selected);
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
            for (final item in models)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StudioChoice(
                  label: item.name,
                  subtitle:
                      '${item.inspection.triangleCount} triangles · ${item.inspection.animations.length} animations',
                  leading: const Icon(Icons.view_in_ar_outlined),
                  selected: item.id == model.id,
                  onTap: n.busy ? null : () => setState(() => select(item)),
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
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final box = model.inspection.bounds;
                    return ModelPreview(
                      key: ValueKey(model.id),
                      bytes: snapshot.data!,
                      controller: controls,
                      minimum: [box.min.x, box.min.y, box.min.z],
                      maximum: [box.max.x, box.max.y, box.max.z],
                      background: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
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
              StudioPanel(
                title: 'Dans votre jeu',
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
              if (model.inspection.animations.isNotEmpty) ...[
                const SizedBox(height: 16),
                ListenableBuilder(
                  listenable: controls,
                  builder: (context, _) => ModelAnimationControls(
                    clips: model.inspection.animations,
                    animationIndex: controls.animation,
                    loop: controls.animationLoop,
                    speed: controls.animationSpeed,
                    paused: controls.animationPaused,
                    onClip: controls.play,
                    onLoop: (value) => controls.configureAnimation(loop: value),
                    onSpeed: (value) =>
                        controls.configureAnimation(speed: value),
                    onPause: controls.toggleAnimationPause,
                    onReplay: controls.restartAnimation,
                  ),
                ),
              ],
              for (final diagnostic in model.inspection.diagnostics)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: StudioNotice(modelDiagnosticLabel(diagnostic)),
                ),
              const SizedBox(height: 16),
              StudioButton(
                label: 'Retirer de la bibliothèque',
                secondary: true,
                onPressed: n.busy ? null : () => remove(model),
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
