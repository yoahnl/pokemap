import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/resource_port.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'resource_navigation.dart';
import 'border_discard_dialog.dart';
import 'border_pattern_panel.dart';
import 'border_source_panel.dart';

class BorderCreationDialog extends StatefulWidget {
  const BorderCreationDialog({
    super.key,
    required this.navigation,
    required this.project,
    required this.visuals,
    this.initialRecord,
  });

  final ResourceNavigation navigation;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final BorderBlueprintRecord? initialRecord;

  @override
  State<BorderCreationDialog> createState() => _BorderCreationDialogState();
}

class _BorderCreationDialogState extends State<BorderCreationDialog> {
  late final TextEditingController _name;
  final _chosen = <String, ProjectElementEntry>{};
  final _modifiedRoles = <String>{};
  ProjectElementEntry? _activeElement;
  String? _pendingId;
  bool _saving = false;
  bool _confirmingClose = false;
  String? _error;
  List<String> _warningCodes = const [];
  late final bool Function() _dirtyOwner;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _name = TextEditingController(text: record?.draft.definition.name ?? '');
    _pendingId = record?.id;
    _dirtyOwner = () => _hasChanges || _saving;
    if (_pendingId != null) {
      widget.navigation.borderEditorOwners[_pendingId!] = _dirtyOwner;
    }
    for (final primitive
        in record?.draft.definition.primitives ?? <BorderPrimitiveDraft>[]) {
      final element = widget.project.elements
          .where((candidate) => candidate.id == primitive.sourceElementId)
          .firstOrNull;
      if (element != null) _chosen[primitive.role.name] = element;
    }
  }

  @override
  void dispose() {
    if (widget.navigation.borderEditorOwners[_pendingId] == _dirtyOwner) {
      widget.navigation.borderEditorOwners.remove(_pendingId);
    }
    _name.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _name.text != (widget.initialRecord?.draft.definition.name ?? '') ||
      const ['lineCap', 'lineStraight', 'lineCorner'].any(
        (role) =>
            _sourceId(role) !=
            widget.initialRecord?.draft.definition.primitives
                .where((primitive) => primitive.role.name == role)
                .firstOrNull
                ?.sourceElementId,
      );

  String? _sourceId(String role) => _modifiedRoles.contains(role)
      ? _chosen[role]?.id
      : _chosen[role]?.id ??
            widget.initialRecord?.draft.definition.primitives
                .where((primitive) => primitive.role.name == role)
                .firstOrNull
                ?.sourceElementId;

  Future<void> _close() async {
    if (_saving || _confirmingClose) return;
    if (!_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }
    _confirmingClose = true;
    final discard = await confirmBorderDiscard(context);
    _confirmingClose = false;
    if (discard == true && mounted) Navigator.of(context).pop(false);
  }

  Future<void> _save(bool publish) async {
    if (_saving ||
        _name.text.trim().isEmpty ||
        (publish && _chosen.length != 3)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final request = BorderCreationRequest(
      name: _name.text.trim(),
      capElementId: _sourceId('lineCap'),
      straightElementId: _sourceId('lineStraight'),
      cornerElementId: _sourceId('lineCorner'),
      blueprintId: _pendingId,
      publish: publish,
      acceptedWarningCodes: _warningCodes,
    );
    try {
      final receipt = await widget.navigation.port.createBorder(request);
      await widget.navigation.accept(receipt);
      if (mounted) Navigator.of(context).pop(true);
    } on ResourceFailure catch (failure) {
      if (failure.partialReceipt case final partial?) {
        await widget.navigation.accept(partial);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
        _pendingId = failure.borderId ?? _pendingId;
        if (_pendingId != null) {
          widget.navigation.borderEditorOwners[_pendingId!] = _dirtyOwner;
        }
        _warningCodes = failure.warningCodes;
      });
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.toString();
      });
    }
  }

  Widget _sources() => BorderSourcePanel(
    project: widget.project,
    visuals: widget.visuals,
    active: _activeElement,
    onActive: (element) => setState(() => _activeElement = element),
  );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Dialog(
        child: SizedBox(
          width: (size.width - 48).clamp(300, 1320).toDouble(),
          height: (size.height - 48).clamp(300, 880).toDouble(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.initialRecord == null
                          ? 'Créer une bordure avec un patron'
                          : 'Modifier la bordure',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Déposez vos décors sur le patron. La bordure publiée sera disponible dans Carte › Bordures.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  key: const ValueKey('border-name'),
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la bordure',
                  ),
                  onChanged: (_) => setState(() => _warningCodes = const []),
                ),
              ),
              if (_error != null)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: size.height * .2),
                  child: SingleChildScrollView(
                    child: StudioNotice(_error!, isError: true),
                  ),
                ),
              if (_warningCodes.isNotEmpty)
                Text(
                  'Raccords à vérifier : ${_warningCodes.map(_warningLabel).join(', ')}.',
                ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, bounds) {
                      final pattern = BorderPatternPanel(
                        chosen: _chosen,
                        active: _activeElement,
                        visuals: widget.visuals,
                        onAssign: (role, element) => setState(() {
                          _modifiedRoles.add(role);
                          _chosen[role] = element;
                          _warningCodes = const [];
                        }),
                      );
                      if (bounds.maxWidth < 820) {
                        return ListView(
                          children: [
                            SizedBox(height: 450, child: _sources()),
                            const SizedBox(height: 12),
                            SizedBox(height: 680, child: pattern),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 300, child: _sources()),
                          const SizedBox(width: 12),
                          Expanded(child: pattern),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  runSpacing: 8,
                  children: [
                    StudioButton(
                      label: 'Fermer',
                      secondary: true,
                      onPressed: _saving ? null : _close,
                    ),
                    const SizedBox(width: 10),
                    StudioButton(
                      label: 'Enregistrer le brouillon',
                      icon: Icons.save_outlined,
                      secondary: true,
                      onPressed: _saving || _name.text.trim().isEmpty
                          ? null
                          : () => _save(false),
                    ),
                    const SizedBox(width: 10),
                    StudioButton(
                      key: const ValueKey('border-publish'),
                      label: _saving
                          ? 'Publication en cours…'
                          : _warningCodes.isNotEmpty
                          ? 'Publier avec ces avertissements'
                          : 'Publier la bordure',
                      icon: Icons.check,
                      onPressed:
                          _saving ||
                              _chosen.length != 3 ||
                              _name.text.trim().isEmpty
                          ? null
                          : () => _save(true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _warningLabel(String code) => switch (code) {
    'border.publication.coverage_gap_exceeded' => 'espaces entre les pièces',
    'border.publication.coverage_overlap_exceeded' =>
      'chevauchement entre les pièces',
    _ => code,
  };
}
