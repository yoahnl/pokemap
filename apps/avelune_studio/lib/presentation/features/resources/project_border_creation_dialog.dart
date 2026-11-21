import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_library_editor.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_library_edit_dialog.dart';
import 'project_model_replacement_dialog.dart';

class ProjectBorderCreationDialog extends StatefulWidget {
  const ProjectBorderCreationDialog({
    super.key,
    required this.models,
    required this.familyLabels,
    required this.save,
  });

  final List<ProjectLibraryItem> models;
  final Map<String, String> familyLabels;
  final Future<ProjectLibraryEdit> Function(BorderCreationRequest) save;

  @override
  State<ProjectBorderCreationDialog> createState() =>
      _ProjectBorderCreationDialogState();
}

class _ProjectBorderCreationDialogState
    extends State<ProjectBorderCreationDialog> {
  String _name = '';
  final _pieces = <BorderPrimitiveRole, ProjectLibraryItem>{};
  var _straightOnly = false;
  var _saving = false;
  String? _problem;
  ResourceMutationReceipt? _partialReceipt;

  List<BorderPrimitiveRole> get _roles => [
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    if (!_straightOnly) BorderPrimitiveRole.lineCorner,
  ];

  bool get _editable => !_saving && _partialReceipt == null;

  Future<void> _select(BorderPrimitiveRole role, String label) async {
    final selected = await showDialog<ProjectLibraryItem>(
      context: context,
      builder: (_) => ProjectModelTargetDialog(
        models: widget.models,
        familyLabels: widget.familyLabels,
        title: label,
        confirmLabel: 'Utiliser ce modèle',
      ),
    );
    if (selected != null && mounted) setState(() => _pieces[role] = selected);
  }

  Future<void> _save() async {
    if (!_editable) return;
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final edit = await widget.save(
        BorderCreationRequest(
          name: _name.trim(),
          template: BorderBlueprintTemplate.connectedLine,
          capModelId: _pieces[BorderPrimitiveRole.lineCap]?.id,
          straightModelId: _pieces[BorderPrimitiveRole.lineStraight]?.id,
          cornerModelId: _straightOnly
              ? null
              : _pieces[BorderPrimitiveRole.lineCorner]?.id,
          straightOnly: _straightOnly,
          publish: false,
        ),
      );
      if (mounted) {
        Navigator.pop<ProjectLibraryEditDialogResult>(context, (
          edit: edit,
          partialReceipt: null,
        ));
      }
    } on Object catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _partialReceipt = failure is ResourceFailure
            ? failure.partialReceipt
            : null;
        _problem = _partialReceipt != null
            ? 'Le brouillon est enregistré. Fermez pour le relire dans l’atelier.'
            : failure is ResourceFailure
            ? failure.message
            : 'La création a échoué. Votre saisie est conservée.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = _roles;
    final name = _name.trim();
    final pending = _partialReceipt;
    return PopScope(
      canPop: !_saving && pending == null,
      child: StudioReviewDialog(
        title: 'Nouvelle bordure 3D',
        cancelLabel: pending == null ? 'Annuler' : 'Fermer',
        onCancelled: _saving
            ? null
            : () {
                Navigator.pop<ProjectLibraryEditDialogResult>(context, (
                  edit: null,
                  partialReceipt: pending,
                ));
              },
        confirmLabel: _saving ? 'Enregistrement…' : 'Créer le brouillon',
        onConfirmed:
            _editable &&
                name.isNotEmpty &&
                name.length <= 512 &&
                roles.every(_pieces.containsKey)
            ? _save
            : null,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ligne connectée'),
            const SizedBox(height: StudioSpacing.m),
            StudioDraftField(
              key: const ValueKey('border-creation-name'),
              value: _name,
              label: 'Nom de la bordure',
              enabled: _editable,
              onChanged: (value) => setState(() => _name = value),
              errorText: name.length > 512
                  ? 'Le nom peut contenir jusqu’à 512 caractères.'
                  : null,
            ),
            StudioToggleRow(
              key: const ValueKey('border-creation-straight-only'),
              label: 'Tracés droits uniquement',
              value: _straightOnly,
              onChanged: _editable
                  ? (value) => setState(() => _straightOnly = value)
                  : null,
            ),
            if (widget.models.isEmpty)
              const StudioNotice(
                'Importez un modèle 3D disponible dans tout le projet pour choisir les pièces.',
              )
            else
              for (final role in roles) ...[
                const SizedBox(height: StudioSpacing.s),
                _piece(role),
              ],
            if (_problem case final problem?) ...[
              const SizedBox(height: StudioSpacing.m),
              StudioNotice(problem, isError: pending == null),
            ],
          ],
        ),
      ),
    );
  }

  Widget _piece(BorderPrimitiveRole role) {
    final label = switch (role) {
      BorderPrimitiveRole.lineCap => 'Extrémité',
      BorderPrimitiveRole.lineStraight => 'Segment droit',
      _ => 'Angle',
    };
    final selected = _pieces[role];
    return StudioButton(
      key: ValueKey('border-creation-${role.name}'),
      label: selected == null
          ? 'Choisir · $label'
          : '$label · ${selected.name}',
      icon: selected == null ? Icons.add : Icons.edit_outlined,
      variant: StudioButtonVariant.secondary,
      onPressed: _editable ? () => _select(role, label) : null,
    );
  }
}
