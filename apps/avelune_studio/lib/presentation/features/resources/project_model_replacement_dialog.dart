import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/project_model_replacement_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import '../../../features/resources/domain/studio_search_text.dart';
import 'model_resource_preview.dart';

class ProjectModelReplacementDialog<T extends ProjectModelReplacement>
    extends StatefulWidget {
  const ProjectModelReplacementDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.prepare,
    required this.prepareCatalog,
    required this.apply,
    required this.release,
    required this.review,
  });

  final String title;
  final String confirmLabel;
  final Future<T> Function() prepare;
  final Future<void> Function() prepareCatalog;
  final Future<ProjectModelReplacementCommit> Function(T) apply;
  final Future<void> Function(T) release;
  final Widget Function(T) review;

  @override
  State<ProjectModelReplacementDialog<T>> createState() =>
      _ProjectModelReplacementDialogState<T>();
}

class _ProjectModelReplacementDialogState<T extends ProjectModelReplacement>
    extends State<ProjectModelReplacementDialog<T>> {
  T? _plan;
  String? _problem;
  bool _preparing = true;
  bool _saving = false;
  bool _needsCatalog = false;

  @override
  void initState() {
    super.initState();
    unawaited(_inspect());
  }

  Future<void> _inspect({bool prepareCatalog = false}) async {
    try {
      if (prepareCatalog) await widget.prepareCatalog();
      final plan = await widget.prepare();
      if (!mounted) {
        await widget.release(plan);
        return;
      }
      setState(() {
        _plan = plan;
        _problem = null;
        _needsCatalog = false;
        _preparing = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _needsCatalog = error is ProjectLibraryNeedsPreparation;
        _problem = switch (error) {
          ProjectLibraryNeedsPreparation() =>
            'Préparez les usages du catalogue pour vérifier ce remplacement.',
          ResourceFailure(:final message) => message,
          _ => 'Impossible de vérifier ce remplacement.',
        };
        _preparing = false;
      });
    }
  }

  Future<void> _confirm(T plan) async {
    if (_saving || plan.noChange) return;
    setState(() => _saving = true);
    try {
      final result = await widget.apply(plan);
      if (mounted) Navigator.pop(context, result);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _plan = null;
        _saving = false;
        _problem = error is ResourceFailure
            ? error.message
            : 'Impossible d’enregistrer ce remplacement.';
      });
    } finally {
      await widget.release(plan);
    }
  }

  @override
  void dispose() {
    if (_plan case final plan?) unawaited(widget.release(plan));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return PopScope(
      canPop: !_saving,
      child: StudioReviewDialog(
        title: widget.title,
        contentWidth: 500,
        confirmLabel: _saving ? 'Enregistrement…' : widget.confirmLabel,
        onConfirmed: plan == null || plan.noChange || _saving
            ? null
            : () => _confirm(plan),
        cancelLabel: plan?.noChange == true ? 'Fermer' : 'Annuler',
        onCancelled: _saving ? null : () => Navigator.pop(context),
        secondaryActionLabel: _needsCatalog && !_preparing
            ? 'Préparer le catalogue'
            : null,
        onSecondaryAction: () {
          setState(() => _preparing = true);
          unawaited(_inspect(prepareCatalog: true));
        },
        content: _preparing
            ? const Text('Vérification du remplacement…')
            : switch (_problem) {
                final problem? => StudioNotice(
                  problem,
                  isError: !_needsCatalog,
                ),
                _ when plan != null => widget.review(plan),
                _ => const SizedBox.shrink(),
              },
      ),
    );
  }
}

class ProjectModelTargetDialog extends StatefulWidget {
  const ProjectModelTargetDialog({
    super.key,
    required this.models,
    required this.familyLabels,
  });

  final Iterable<ProjectLibraryItem> models;
  final Map<String, String> familyLabels;

  @override
  State<ProjectModelTargetDialog> createState() =>
      _ProjectModelTargetDialogState();
}

class _ProjectModelTargetDialogState extends State<ProjectModelTargetDialog> {
  final _search = TextEditingController();
  ProjectLibraryItem? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = studioSearchText(_search.text).trim();
    final models = [
      for (final model in widget.models)
        if (model.searchText.contains(query)) model,
    ];
    return StudioReviewDialog(
      title: 'Choisir le modèle de destination',
      confirmLabel: 'Vérifier les usages',
      onConfirmed: _selected == null
          ? null
          : () => Navigator.pop(context, _selected),
      onCancelled: () => Navigator.pop(context),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioSearchField(
            label: 'Chercher un modèle 3D',
            controller: _search,
            onChanged: (_) => setState(() => _selected = null),
          ),
          const SizedBox(height: StudioSpacing.m),
          SizedBox(
            height: 240,
            child: models.isEmpty
                ? const StudioEmptyState(title: 'Aucun autre modèle trouvé')
                : ListView.builder(
                    itemCount: models.length,
                    itemBuilder: (context, index) {
                      final model = models[index];
                      final family = widget.familyLabels[model.familyId];
                      final selected = _selected == model;
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: StudioButton(
                          key: ValueKey('model-replacement-target-${model.id}'),
                          label: family == null
                              ? model.name
                              : '${model.name} · $family',
                          icon: selected
                              ? Icons.check_circle_outline
                              : Icons.view_in_ar_outlined,
                          variant: selected
                              ? StudioButtonVariant.secondary
                              : StudioButtonVariant.quiet,
                          onPressed: () => setState(() => _selected = model),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

Widget modelSourceReplacementReview(
  ProjectModelSourceReplacement plan, {
  required bool showPreview,
}) {
  String summary(Model3dInspection inspection) {
    final size = inspection.bounds.size;
    String number(double value) =>
        value.toStringAsFixed(2).replaceFirst('.', ',');
    final dimensions = [size.x, size.y, size.z].map(number).join(' × ');
    return '$dimensions · ${_count(inspection.triangleCount, 'triangle', 'triangles')} · '
        '${_count(inspection.animations.length, 'animation', 'animations')}';
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (plan.noChange)
        const StudioNotice(
          'Le fichier choisi est déjà utilisé par cette fiche.',
        )
      else ...[
        Text('Fiche · ${plan.before.name}'),
        Text('Fichier vérifié · ${plan.fileName}'),
        const SizedBox(height: StudioSpacing.m),
        Text('Actuel · ${summary(plan.before.inspection)}'),
        Text('Nouveau · ${summary(plan.after.inspection)}'),
        if (showPreview) ...[
          const SizedBox(height: StudioSpacing.m),
          SizedBox(
            height: 200,
            child: ModelResourcePreview.prepared(
              model: plan.after,
              preparedBytes: plan.inspectedBytes,
            ),
          ),
        ],
        const SizedBox(height: StudioSpacing.m),
        const Text(
          'Les placements et les réglages de la fiche sont conservés.',
        ),
      ],
    ],
  );
}

Widget modelUsageReplacementReview(
  ProjectModelUsageReplacement plan, {
  required String source,
  required String target,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('$source → $target'),
    const SizedBox(height: StudioSpacing.m),
    if (plan.noChange)
      const StudioNotice('Aucun usage à rediriger.')
    else ...[
      Text(
        '${_count(plan.maps.length, 'carte', 'cartes')} · '
        '${_count(plan.borders.length, 'bordure', 'bordures')}',
      ),
      Text(
        '${_count(plan.redirected, 'placement redirigé', 'placements redirigés')} · '
        '${_count(plan.recalculated, 'recalculé', 'recalculés')}',
      ),
      for (final map in plan.maps)
        Padding(
          padding: const EdgeInsets.only(top: StudioSpacing.s),
          child: Text(
            '${map.name} · ${_count(map.redirected, 'redirigé', 'redirigés')} · '
            '${_count(map.recalculated, 'recalculé', 'recalculés')}',
          ),
        ),
      for (final border in plan.borders.values)
        Padding(
          padding: const EdgeInsets.only(top: StudioSpacing.s),
          child: Text('Bordure · $border'),
        ),
      const SizedBox(height: StudioSpacing.m),
      const Text('Les deux fiches et leurs fichiers sont conservés.'),
    ],
  ],
);

String _count(int count, String singular, String plural) =>
    '$count ${count > 1 ? plural : singular}';
