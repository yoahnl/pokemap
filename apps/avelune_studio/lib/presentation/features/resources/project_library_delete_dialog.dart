import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../../features/resources/domain/resource_port.dart';

typedef ProjectLibraryDeleteResult = ({
  ResourceMutationReceipt receipt,
  bool reload,
});

class ProjectLibraryDeleteDialog extends StatefulWidget {
  const ProjectLibraryDeleteDialog({
    super.key,
    required this.name,
    required this.prepare,
    required this.prepareCatalog,
    required this.remove,
    required this.release,
  });

  final String name;
  final Future<ResourceMutationPreparation> Function() prepare;
  final Future<void> Function() prepareCatalog;
  final Future<ResourceMutationReceipt> Function(ResourceMutationPreparation)
  remove;
  final Future<void> Function(ResourceMutationPreparation) release;

  @override
  State<ProjectLibraryDeleteDialog> createState() =>
      _ProjectLibraryDeleteDialogState();
}

class _ProjectLibraryDeleteDialogState
    extends State<ProjectLibraryDeleteDialog> {
  ResourceMutationPreparation? _plan;
  ResourceMutationReceipt? _published;
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
        _preparing = false;
        _needsCatalog = false;
        _problem = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _preparing = false;
        _needsCatalog = error is ProjectLibraryNeedsPreparation;
        _problem = switch (error) {
          ProjectLibraryNeedsPreparation() =>
            'Préparez les usages du projet pour vérifier ce retrait.',
          ResourceFailure(:final message) => message,
          _ => 'La vérification des usages a échoué.',
        };
      });
    }
  }

  Future<void> _confirm() async {
    final plan = _plan;
    if (plan == null || _saving || _published != null) return;
    setState(() => _saving = true);
    try {
      final receipt = await widget.remove(plan);
      if (mounted) _close(receipt, reload: false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _plan = null;
        _published = error is ResourceFailure ? error.partialReceipt : null;
        _problem = _published != null
            ? 'Le retrait est enregistré. Fermez cette fenêtre pour actualiser la bibliothèque.'
            : error is ResourceFailure
            ? error.message
            : 'Le retrait a échoué. Fermez cette fenêtre et vérifiez de nouveau les usages.';
      });
      await widget.release(plan);
    }
  }

  void _close(ResourceMutationReceipt? receipt, {required bool reload}) =>
      Navigator.of(context).pop<ProjectLibraryDeleteResult>(
        receipt == null ? null : (receipt: receipt, reload: reload),
      );

  @override
  void dispose() {
    if (_plan case final plan?) unawaited(widget.release(plan));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && _published == null,
    child: StudioReviewDialog(
      title: 'Supprimer la ressource',
      contentWidth: 440,
      confirmLabel: _saving ? 'Suppression…' : 'Supprimer la fiche',
      confirmVariant: StudioButtonVariant.destructive,
      onConfirmed: _plan == null || _saving ? null : _confirm,
      cancelLabel: _published == null ? 'Annuler' : 'Fermer',
      onCancelled: () {
        if (!_saving) _close(_published, reload: true);
      },
      secondaryActionLabel: _needsCatalog && !_preparing
          ? 'Préparer le catalogue'
          : null,
      onSecondaryAction: _needsCatalog && !_preparing
          ? () {
              setState(() => _preparing = true);
              unawaited(_inspect(prepareCatalog: true));
            }
          : null,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.name, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: StudioSpacing.l),
          if (_preparing)
            const Text('Vérification des usages…')
          else if (_problem case final problem?)
            StudioNotice(problem, isError: _published == null)
          else ...[
            const StudioBadge('Aucun usage relevé', icon: Icons.check),
            const SizedBox(height: StudioSpacing.m),
            const Text(
              'Le retrait porte sur la fiche et son classement. '
              'Les sources sont conservées et le retrait figure dans l’historique du projet.',
            ),
          ],
        ],
      ),
    ),
  );
}
