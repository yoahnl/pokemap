import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/project_model_replacement_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_model_replacement_dialog.dart';

typedef ModelReplacementPanelStatus = ({
  ProjectModelReplacementCommit commit,
  bool pending,
});

class ProjectModelReplacementPanel extends StatefulWidget {
  const ProjectModelReplacementPanel({
    super.key,
    required this.item,
    required this.models,
    required this.familyLabels,
    required this.port,
    required this.revision,
    required this.available,
    required this.showPreview,
    required this.pickFile,
    required this.prepareCatalog,
    required this.checkDrafts,
    required this.synchronize,
    required this.onRevision,
    required this.onPublished,
    required this.onBusyChanged,
    this.initialStatus,
    this.onStatusChanged,
  });

  final ProjectLibraryItem item;
  final Iterable<ProjectLibraryItem> models;
  final Map<String, String> familyLabels;
  final ProjectModelReplacementPort port;
  final String revision;
  final bool available;
  final bool showPreview;
  final Future<PickedProjectLibraryFile?> Function() pickFile;
  final Future<String> Function() prepareCatalog;
  final String? Function(Set<ModelReplacementResource>, Set<String>)
  checkDrafts;
  final Future<void> Function(ProjectModelReplacementCommit) synchronize;
  final ValueChanged<String> onRevision;
  final ValueChanged<ResourceMutationReceipt> onPublished;
  final ValueChanged<bool> onBusyChanged;
  final ModelReplacementPanelStatus? initialStatus;
  final ValueChanged<ModelReplacementPanelStatus?>? onStatusChanged;

  @override
  State<ProjectModelReplacementPanel> createState() =>
      _ProjectModelReplacementPanelState();
}

class _ProjectModelReplacementPanelState
    extends State<ProjectModelReplacementPanel> {
  ProjectModelReplacementCommit? _last;
  ProjectModelReplacementCommit? _pending;
  String? _message;
  bool _failure = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus case final status?) {
      if (status.pending) {
        _pending = status.commit;
        _message = 'La modification est enregistrée. Relisez-la pour actualiser le Studio.';
      } else {
        _last = status.commit;
      }
    }
  }

  Future<ProjectModelReplacementCommit?> _replaceFile() async {
    final file = await widget.pickFile();
    if (!mounted || file == null) return null;
    return _review<ProjectModelSourceReplacement>(
      title: 'Vérifier le nouveau fichier 3D',
      confirmLabel: 'Remplacer le fichier',
      prepare: (revision) => widget.port.prepareSource(
        modelId: widget.item.id,
        file: file,
        expectedRevision: revision,
      ),
      apply: (plan) => widget.port.apply(
        plan,
        checkDrafts: () => widget.checkDrafts(const {}, {widget.item.id}),
      ),
      review: (plan) =>
          modelSourceReplacementReview(plan, showPreview: widget.showPreview),
    );
  }

  Future<ProjectModelReplacementCommit?> _replaceUsages() async {
    final target = await showDialog<ProjectLibraryItem>(
      context: context,
      builder: (_) => ProjectModelTargetDialog(
        models: widget.models,
        familyLabels: widget.familyLabels,
      ),
    );
    if (!mounted || target == null) return null;
    return _review<ProjectModelUsageReplacement>(
      title: 'Vérifier les usages à rediriger',
      confirmLabel: 'Rediriger les usages',
      prepare: (revision) => widget.port.prepareUsages(
        modelId: widget.item.id,
        replacementId: target.id,
        expectedRevision: revision,
      ),
      apply: (plan) => widget.port.apply(
        plan,
        checkDrafts: () => widget.checkDrafts(
          {
            for (final map in plan.maps) (kind: 'map', id: map.id),
            for (final id in plan.borders.keys)
              (kind: 'borderBlueprint', id: id),
          },
          {plan.sourceId, plan.targetId},
        ),
      ),
      review: (plan) => modelUsageReplacementReview(
        plan,
        source: widget.item.name,
        target: target.name,
      ),
    );
  }

  Future<ProjectModelReplacementCommit?>
  _review<T extends ProjectModelReplacement>({
    required String title,
    required String confirmLabel,
    required Future<T> Function(String) prepare,
    required Future<ProjectModelReplacementCommit> Function(T) apply,
    required Widget Function(T) review,
  }) {
    var revision = widget.revision;
    return showDialog<ProjectModelReplacementCommit>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectModelReplacementDialog<T>(
        title: title,
        confirmLabel: confirmLabel,
        prepare: () => prepare(revision),
        prepareCatalog: () async {
          revision = await widget.prepareCatalog();
          if (mounted) widget.onRevision(revision);
        },
        apply: apply,
        release: widget.port.release,
        review: review,
      ),
    );
  }

  Future<void> _run(
    Future<ProjectModelReplacementCommit?> Function() operation,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    widget.onBusyChanged(true);
    try {
      final result = await operation();
      if (result == null || !mounted) return;
      setState(() => _pending = result);
      widget.onStatusChanged?.call((commit: result, pending: true));
      await widget.synchronize(result);
      if (!mounted) return;
      setState(() {
        _pending = null;
        _last = result.restored ? null : result;
        _failure = false;
        _message = switch ((
          result.restored,
          result.receipt.changedModels.isNotEmpty,
        )) {
          (true, true) => 'Fichier 3D restauré.',
          (true, false) => 'Usages précédents restaurés.',
          (false, true) => 'Nouveau fichier 3D enregistré.',
          (false, false) => 'Usages redirigés.',
        };
      });
      widget.onStatusChanged?.call(
        result.restored ? null : (commit: result, pending: false),
      );
      widget.onPublished(result.receipt);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = true;
        _message = _pending != null
            ? 'La modification est enregistrée. Relisez-la pour actualiser le Studio.'
            : error is ResourceFailure
            ? error.message
            : 'Cette opération n’a pas abouti. Relisez la fiche avant de réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previous = _last;
    final pending = _pending;
    final enabled = widget.available && !_busy && pending == null;
    return StudioPanel(
      title: 'Remplacement',
      children: [
        Wrap(
          spacing: StudioSpacing.m,
          runSpacing: StudioSpacing.s,
          children: [
            StudioButton(
              key: const ValueKey('model-workshop-replace-file'),
              label: 'Changer le fichier GLB',
              icon: Icons.upload_file_outlined,
              variant: StudioButtonVariant.secondary,
              onPressed: enabled ? () => _run(_replaceFile) : null,
            ),
            StudioButton(
              key: const ValueKey('model-workshop-replace-usages'),
              label: 'Rediriger les usages',
              icon: Icons.alt_route,
              variant: StudioButtonVariant.secondary,
              onPressed: enabled ? () => _run(_replaceUsages) : null,
            ),
          ],
        ),
        if (_message case final message?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(message, isError: _failure),
        ],
        if (pending != null || previous != null) ...[
          const SizedBox(height: StudioSpacing.s),
          if (pending != null)
            StudioButton(
              label: 'Relire la publication',
              onPressed: _busy ? null : () => _run(() async => pending),
            )
          else
            StudioButton(
              key: const ValueKey('model-workshop-undo-replacement'),
              label: 'Annuler le dernier remplacement',
              icon: Icons.undo,
              variant: StudioButtonVariant.quiet,
              onPressed: !enabled
                  ? null
                  : () => _run(
                      () => widget.port.undo(
                        previous!,
                        checkDrafts: () => widget.checkDrafts(
                          previous.resources,
                          previous.relatedModels,
                        ),
                      ),
                    ),
            ),
        ],
      ],
    );
  }
}
