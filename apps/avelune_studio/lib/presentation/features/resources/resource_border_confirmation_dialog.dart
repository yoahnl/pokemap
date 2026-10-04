import 'package:flutter/material.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_management_dialog.dart';

class ResourceBorderConfirmationDialog extends StatefulWidget {
  const ResourceBorderConfirmationDialog({
    super.key,
    required this.name,
    required this.title,
    required this.description,
    required this.prepare,
    required this.apply,
    required this.canApply,
  });
  final String name;
  final String title, description;
  final Future<ResourceMutationPreparation?> Function() prepare;
  final Future<String?> Function(ResourceMutationPreparation?) apply;
  final bool Function() canApply;
  @override
  State<ResourceBorderConfirmationDialog> createState() =>
      _ResourceBorderConfirmationDialogState();
}

class _ResourceBorderConfirmationDialogState
    extends State<ResourceBorderConfirmationDialog> {
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
    title: widget.title,
    submitLabel: widget.title,
    dirty: () => false,
    valid: () => _ready && !_working && _confirmed && widget.canApply(),
    submit: () => widget.apply(_preparation),
    fields: (refresh, busy) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.name, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Text(widget.description),
        if (_working) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            'Opération refusée : $_error',
            key: const ValueKey('resource-border-refusal'),
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
          key: const ValueKey('resource-border-confirm'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Je confirme cette opération sur la bordure.'),
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
