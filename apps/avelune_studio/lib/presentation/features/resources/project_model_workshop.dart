import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_model_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'model_resource_preview.dart';

part 'project_model_workshop_collision.dart';
part 'project_model_workshop_shadow.dart';
part 'project_model_workshop_transform.dart';

typedef ModelReplacementPanelBuilder = Widget Function({
  required String revision,
  required bool enabled,
  required ValueChanged<bool> onBusyChanged,
  required ValueChanged<String> onRevision,
  required ValueChanged<ResourceMutationReceipt> onPublished,
});

class ProjectModelWorkshop extends StatefulWidget {
  const ProjectModelWorkshop({
    super.key,
    required this.item,
    required this.loadModel,
    required this.visuals,
    required this.onBack,
    this.saveShadow,
    this.saveSettings,
    this.reconcileShadow,
    this.pendingReceipt,
    this.buildReplacement,
    this.onDraftChanged,
  });

  final ProjectLibraryItem item;
  final Future<ProjectModelWorkshopRead> Function() loadModel;
  final MapWorkspaceVisuals? visuals;
  final Future<ResourceMutationReceipt> Function(bool enabled, String revision)?
  saveShadow;
  final Future<ResourceMutationReceipt> Function(
    ProjectModelWorkshopSettings settings,
    String revision,
  )?
  saveSettings;
  final Future<ResourceMutationReceipt> Function(
    ResourceMutationReceipt receipt,
  )?
  reconcileShadow;
  final ResourceMutationReceipt? pendingReceipt;
  final VoidCallback onBack;
  final ModelReplacementPanelBuilder? buildReplacement;
  final ValueChanged<bool>? onDraftChanged;

  @override
  State<ProjectModelWorkshop> createState() => _ProjectModelWorkshopState();
}

class _ProjectModelWorkshopState extends State<ProjectModelWorkshop> {
  late Future<ProjectModelWorkshopRead> _reading;
  ProjectModelWorkshopRead? _published;
  bool? _shadowDraft;
  _ModelCollisionDraft? _collisionDraft;
  _ModelTransformDraft? _transformDraft;
  String? _problem;
  bool _saving = false;
  bool _replacing = false;
  ResourceMutationReceipt? _pendingReceipt;

  bool get _hasDraft =>
      _shadowDraft != null ||
      _collisionDraft != null ||
      _transformDraft != null;

  void _update(VoidCallback change) {
    setState(change);
    widget.onDraftChanged?.call(_hasDraft);
  }

  Future<void> _leave() async {
    if (_hasDraft) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StudioReviewDialog(
          title: 'Abandonner les réglages du modèle ?',
          content: const Text('Vos réglages en cours seront effacés.'),
          confirmLabel: 'Abandonner',
          onConfirmed: () => Navigator.pop(dialogContext, true),
          onCancelled: () => Navigator.pop(dialogContext, false),
        ),
      );
      if (!mounted || discard != true) return;
      _update(() {
        _shadowDraft = null;
        _collisionDraft = null;
        _transformDraft = null;
      });
    }
    widget.onBack();
  }

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
      _collisionDraft = null;
      _transformDraft = null;
      _pendingReceipt = widget.pendingReceipt;
    }
    _problem = null;
  }

  Future<void> _publish(
    ProjectModel3dEntry model,
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
      _update(() {
        _published = (model: updated ?? model, revision: receipt.revision);
        _shadowDraft = null;
        _collisionDraft = null;
        _transformDraft = null;
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
              onPressed: _saving || _replacing ? null : _leave,
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
                child: StudioProgressIndicator(label: 'Chargement du modèle'),
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
            final read = _published ?? snapshot.data!;
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
          final settings = _settings(model, revision);
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
      if (widget.buildReplacement case final build? when revision != null) ...[
        const SizedBox(height: StudioSpacing.xl),
        build(
          revision: revision,
          enabled: !_saving && _pendingReceipt == null && !_hasDraft,
          onBusyChanged: (value) => setState(() => _replacing = value),
          onRevision: (value) =>
              setState(() => _published = (model: model, revision: value)),
          onPublished: (receipt) => setState(
            () => _published = (
              model: receipt.changedModels[model.id] ?? model,
              revision: receipt.revision,
            ),
          ),
        ),
      ],
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
}
