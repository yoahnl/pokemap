import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/project_library_organization.dart';
import '../../../features/resources/domain/resource_port.dart';
import '../../../features/resources/domain/studio_search_text.dart';

part 'project_library_batch_classify_dialog.dart';
part 'project_library_families_dialog.dart';

typedef ProjectLibraryOrganizationDialogResult<T> = ({
  T? edit,
  ResourceMutationReceipt? partialReceipt,
});

class _ProjectLibraryOrganizationForm<T> extends StatefulWidget {
  const _ProjectLibraryOrganizationForm({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.content,
    required this.commit,
    required this.prepareCatalog,
    this.onBack,
  });

  final String title;
  final String confirmLabel;
  final Widget Function(bool enabled) content;
  final Future<T> Function()? commit;
  final Future<void> Function() prepareCatalog;
  final VoidCallback? onBack;

  @override
  State<_ProjectLibraryOrganizationForm<T>> createState() =>
      _ProjectLibraryOrganizationFormState<T>();
}

class _ProjectLibraryOrganizationFormState<T>
    extends State<_ProjectLibraryOrganizationForm<T>> {
  bool _saving = false;
  bool _needsPreparation = false;
  String? _problem;
  ResourceMutationReceipt? _partial;

  Future<void> _run({required bool prepare}) async {
    if (_saving || _partial != null) return;
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      if (prepare) {
        await widget.prepareCatalog();
        if (!mounted) return;
        setState(() {
          _saving = false;
          _needsPreparation = false;
        });
      } else {
        final edit = await widget.commit!();
        if (mounted) _finish(edit);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _needsPreparation = prepare || error is ProjectLibraryNeedsPreparation;
        _partial = error is ResourceFailure ? error.partialReceipt : null;
        _problem = _partial != null
            ? 'Le changement est enregistré. Fermez cette fenêtre pour actualiser la bibliothèque.'
            : switch (error) {
                ProjectLibraryNeedsPreparation() =>
                  'Préparez le catalogue pour effectuer ce rangement.',
                ResourceFailure(:final message) => message,
                _ => 'Le rangement a échoué. Réessayez.',
              };
      });
    }
  }

  void _finish(T? edit) => Navigator.of(context)
      .pop<ProjectLibraryOrganizationDialogResult<T>>((
        edit: edit,
        partialReceipt: _partial,
      ));

  @override
  Widget build(BuildContext context) {
    final editable = !_saving && _partial == null;
    return PopScope(
      canPop: editable,
      child: StudioReviewDialog(
        title: widget.title,
        contentWidth: 460,
        confirmLabel: _saving ? 'En cours…' : widget.confirmLabel,
        confirmVariant: widget.onBack == null
            ? StudioButtonVariant.primary
            : StudioButtonVariant.destructive,
        onConfirmed: editable && !_needsPreparation && widget.commit != null
            ? () => _run(prepare: false)
            : null,
        secondaryActionLabel: _needsPreparation && editable
            ? 'Préparer le catalogue'
            : null,
        onSecondaryAction: _needsPreparation && editable
            ? () => _run(prepare: true)
            : null,
        cancelLabel: _partial == null ? 'Annuler' : 'Fermer',
        onCancelled: () {
          if (_saving) return;
          if (_partial == null && widget.onBack != null) {
            widget.onBack!();
          } else {
            _finish(null);
          }
        },
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.content(editable),
            if (_problem case final problem?) ...[
              const SizedBox(height: StudioSpacing.l),
              StudioNotice(problem, isError: _partial == null),
            ],
          ],
        ),
      ),
    );
  }
}
