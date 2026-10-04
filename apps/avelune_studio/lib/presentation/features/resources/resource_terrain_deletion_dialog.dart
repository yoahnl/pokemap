import 'package:flutter/material.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_management_dialog.dart';

class ResourceTerrainDeletionDialog extends StatefulWidget {
  const ResourceTerrainDeletionDialog({
    super.key,
    required this.name,
    required this.draft,
    required this.prepare,
    required this.apply,
    required this.canApply,
  });
  final String name;
  final bool draft;
  final Future<ResourceMutationPreparation?> Function() prepare;
  final Future<String?> Function(ResourceMutationPreparation?) apply;
  final bool Function() canApply;
  @override
  State<ResourceTerrainDeletionDialog> createState() =>
      _ResourceTerrainDeletionDialogState();
}

class _ResourceTerrainDeletionDialogState
    extends State<ResourceTerrainDeletionDialog> {
  ResourceMutationPreparation? _preparation;
  bool _working = true, _ready = false, _confirmed = false;
  String? _error;
  int _sequence = 0;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _sequence++;
    super.dispose();
  }

  Future<void> _prepare() async {
    final sequence = ++_sequence;
    setState(() {
      _working = true;
      _ready = false;
      _confirmed = false;
      _error = null;
      _preparation = null;
    });
    try {
      final preparation = await widget.prepare();
      if (!mounted || sequence != _sequence) return;
      setState(() {
        _preparation = preparation;
        _ready = true;
      });
    } on Object catch (failure) {
      if (mounted && sequence == _sequence) {
        setState(() => _error = '$failure');
      }
    } finally {
      if (mounted && sequence == _sequence) {
        setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => ResourceManagementDialog(
    title: widget.draft ? 'Supprimer le brouillon' : 'Supprimer le terrain',
    submitLabel: widget.draft
        ? 'Supprimer le brouillon'
        : 'Supprimer le terrain',
    dirty: () => false,
    valid: () => _ready && !_working && _confirmed && widget.canApply(),
    submit: () => widget.apply(_preparation),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(
          widget.draft
              ? 'Cette préparation sera retirée ; sa publication reste disponible si elle existe. Les sources partagées sont conservées.'
              : 'Seul ce terrain est retiré. Les cartes, cases et sources partagées ne sont jamais supprimées pour libérer ses usages.',
        ),
        if (_working) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            'Retrait refusé : $_error',
            key: const ValueKey('resource-terrain-refusal'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_preparation != null) ...[
          const SizedBox(height: 12),
          Text('${_preparation!.changedPaths.length} document(s) concernés.'),
          SelectableText('Révision : ${_preparation!.snapshotRevision}'),
        ],
        const SizedBox(height: 12),
        StudioButton(
          label: 'Réanalyser',
          secondary: true,
          onPressed: busy || _working ? null : _prepare,
        ),
        CheckboxListTile(
          key: const ValueKey('resource-terrain-confirm'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Je confirme le retrait de cet objet.'),
          value: _confirmed,
          onChanged: busy || _working || !_ready
              ? null
              : (value) {
                  _confirmed = value == true;
                  refresh();
                },
        ),
      ],
    ),
  );
}
