import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_model_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'model_resource_preview.dart';

class ProjectModelWorkshop extends StatefulWidget {
  const ProjectModelWorkshop({
    super.key,
    required this.item,
    required this.loadModel,
    required this.visuals,
    required this.onBack,
    this.saveShadow,
    this.reconcileShadow,
    this.pendingReceipt,
  });

  final ProjectLibraryItem item;
  final Future<ProjectModelWorkshopRead> Function() loadModel;
  final MapWorkspaceVisuals? visuals;
  final Future<ResourceMutationReceipt> Function(bool enabled, String revision)?
  saveShadow;
  final Future<ResourceMutationReceipt> Function(
    ResourceMutationReceipt receipt,
  )?
  reconcileShadow;
  final ResourceMutationReceipt? pendingReceipt;
  final VoidCallback onBack;

  @override
  State<ProjectModelWorkshop> createState() => _ProjectModelWorkshopState();
}

class _ProjectModelWorkshopState extends State<ProjectModelWorkshop> {
  late Future<ProjectModelWorkshopRead> _reading;
  ProjectModelWorkshopRead? _published;
  bool? _shadowDraft;
  String? _problem;
  bool _saving = false;
  ResourceMutationReceipt? _pendingReceipt;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(ProjectModelWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.identity != widget.item.identity) _read();
  }

  void _read({bool keepDraft = false}) {
    _reading = Future.sync(widget.loadModel);
    _published = null;
    if (!keepDraft) {
      _shadowDraft = null;
      _pendingReceipt = widget.pendingReceipt;
    }
    _problem = null;
  }

  Future<void> _publish(
    ProjectModel3dEntry model,
    bool enabled,
    Future<ResourceMutationReceipt> Function() operation,
  ) async {
    if (_saving) return;
    final reading = _reading;
    final reconciling = _pendingReceipt != null;
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final receipt = await operation();
      if (!mounted || reading != _reading) return;
      final updated = receipt.changedModels[model.id];
      if (updated == null && !receipt.noChange) {
        throw ResourceFailure(
          'La définition enregistrée est indisponible.',
          partialReceipt: receipt,
        );
      }
      setState(() {
        _published = (
          model: updated ?? model.copyWith(castsShadowsByDefault: enabled),
          revision: receipt.revision,
        );
        _shadowDraft = null;
        _pendingReceipt = null;
        _saving = false;
      });
    } on Object catch (error) {
      if (!mounted || reading != _reading) return;
      setState(() {
        _saving = false;
        if (error is ResourceFailure && error.partialReceipt != null) {
          _pendingReceipt = error.partialReceipt;
        }
        _problem = _pendingReceipt != null
            ? (reconciling
                  ? 'Le Studio ne peut pas encore relire cet enregistrement.'
                  : null)
            : switch (error) {
                ResourceFailure(:final message) => message,
                _ => 'Enregistrement impossible. Votre réglage est conservé.',
              };
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          StudioSpacing.xl,
          StudioSpacing.l,
          StudioSpacing.xl,
          StudioSpacing.l,
        ),
        child: Wrap(
          spacing: StudioSpacing.l,
          runSpacing: StudioSpacing.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StudioButton(
              label: 'Retour à la bibliothèque',
              icon: Icons.arrow_back,
              onPressed: _saving ? null : widget.onBack,
              variant: StudioButtonVariant.quiet,
            ),
            Text('Modèles 3D', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: FutureBuilder<ProjectModelWorkshopRead>(
          future: _reading,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Chargement du modèle',
                ),
              );
            }
            if (snapshot.hasError) {
              return StudioEmptyState(
                title: 'Impossible de lire le modèle',
                description: 'Vérifiez le catalogue puis relancez la lecture.',
                action: StudioButton(
                  label: 'Réessayer',
                  onPressed: () => setState(() => _read(keepDraft: true)),
                ),
              );
            }
            final read = snapshot.data!;
            final model = read.model;
            if (model == null) {
              return const StudioEmptyState(
                title: 'Modèle introuvable',
                description:
                    'Actualisez la bibliothèque pour vérifier sa fiche.',
              );
            }
            return _editor(context, model, read.revision);
          },
        ),
      ),
    ],
  );

  Widget _editor(
    BuildContext context,
    ProjectModel3dEntry model,
    String? revision,
  ) => ListView(
    padding: const EdgeInsets.all(StudioSpacing.xl),
    children: [
      Wrap(
        spacing: StudioSpacing.l,
        runSpacing: StudioSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(model.name, style: Theme.of(context).textTheme.titleLarge),
          if (widget.saveShadow == null || revision == null)
            const StudioBadge('Lecture seule', icon: Icons.lock_outline),
        ],
      ),
      const SizedBox(height: StudioSpacing.xl),
      LayoutBuilder(
        builder: (context, bounds) {
          final preview = _preview(model);
          final settings = _settings(
            _published?.model ?? model,
            _published?.revision ?? revision,
          );
          if (bounds.maxWidth >= 680) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: preview),
                const SizedBox(width: StudioSpacing.xl),
                Expanded(flex: 2, child: settings),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              preview,
              const SizedBox(height: StudioSpacing.xl),
              settings,
            ],
          );
        },
      ),
    ],
  );

  Widget _preview(ProjectModel3dEntry model) {
    final visuals = widget.visuals;
    return StudioPanel(
      title: 'Aperçu du modèle',
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: visuals != null && visuals is SpatialWorkspaceVisuals
              ? ModelResourcePreview(model: model, visuals: visuals)
              : const StudioEmptyState(
                  title: 'Aperçu 3D indisponible',
                  icon: Icons.view_in_ar_outlined,
                ),
        ),
      ],
    );
  }

  Widget _settings(ProjectModel3dEntry model, String? revision) {
    final save = widget.saveShadow;
    final pending = _pendingReceipt;
    final reconcile = widget.reconcileShadow;
    final enabled = _shadowDraft ?? model.castsShadowsByDefault;
    final dirty = enabled != model.castsShadowsByDefault;
    final editable = save != null && revision != null && !_saving;
    return StudioPanel(
      title: 'Ombre du modèle',
      children: [
        StudioToggleRow(
          key: const ValueKey('model-workshop-shadow'),
          label: 'Projeter une ombre',
          description: 'Réglage partagé des placements qui héritent du modèle.',
          value: enabled,
          onChanged: editable && pending == null
              ? (checked) => setState(() => _shadowDraft = checked)
              : null,
        ),
        if (pending != null) ...[
          const SizedBox(height: StudioSpacing.m),
          const StudioNotice(
            'Le réglage est enregistré. Relisez l’enregistrement pour actualiser le Studio.',
          ),
          if (_problem case final problem?) ...[
            const SizedBox(height: StudioSpacing.m),
            StudioNotice(problem, isError: true),
          ],
          if (reconcile != null) ...[
            const SizedBox(height: StudioSpacing.m),
            StudioButton(
              label: _saving ? 'Relecture…' : 'Relire l’enregistrement',
              loading: _saving,
              onPressed: _saving
                  ? null
                  : () => _publish(model, enabled, () => reconcile(pending)),
            ),
          ],
        ] else if (_problem case final problem?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(problem, isError: true),
          const SizedBox(height: StudioSpacing.m),
          StudioButton(
            label: 'Relire le modèle',
            variant: StudioButtonVariant.quiet,
            onPressed: () => setState(() => _read(keepDraft: true)),
          ),
        ] else if (save != null && revision != null) ...[
          const SizedBox(height: StudioSpacing.l),
          Wrap(
            spacing: StudioSpacing.m,
            runSpacing: StudioSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StudioButton(
                key: const ValueKey('model-workshop-save'),
                label: _saving ? 'Enregistrement…' : 'Enregistrer',
                icon: Icons.save_outlined,
                loading: _saving,
                onPressed: editable && dirty
                    ? () => _publish(
                        model,
                        enabled,
                        () => save(enabled, revision),
                      )
                    : null,
              ),
              if (_published != null && !dirty && !_saving)
                const StudioBadge('Enregistré', icon: Icons.check),
            ],
          ),
        ],
      ],
    );
  }
}
