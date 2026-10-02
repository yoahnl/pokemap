import 'package:flutter/material.dart';
import '../../../features/resources/domain/resource_mutation_preparation.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../resources/resource_management_dialog.dart';
part 'character_removal_fields.dart';

class CharacterRemovalDialog extends StatefulWidget {
  const CharacterRemovalDialog({
    super.key,
    required this.name,
    required this.inspect,
    required this.prepare,
    required this.apply,
    required this.canApply,
    required this.ownerLabel,
  });
  final String name;
  final Future<ResourceMutationPreparation> Function() inspect;
  final Future<ResourceMutationPreparation> Function(
    Map<String, Object?> parameters,
    String revision,
  )
  prepare;
  final Future<String?> Function(ResourceMutationPreparation plan) apply;
  final bool Function() canApply;
  final String Function(Map dependency) ownerLabel;

  @override
  State<CharacterRemovalDialog> createState() => _CharacterRemovalDialogState();
}

class _CharacterRemovalDialogState extends State<CharacterRemovalDialog> {
  ResourceMutationPreparation? _inspection, _plan;
  bool _working = false, _confirmed = false;
  String? _resolution, _replacementId, _error;
  int _sequence = 0;
  Map<String, Object?> get _impact => _inspection?.impact ?? const {};
  List<Map> get _candidates =>
      (_impact['replacementCandidates'] as List? ?? const [])
          .whereType<Map>()
          .toList();
  bool get _requiresResolution => _impact['requiresResolution'] == true;

  void _change(VoidCallback action) => setState(action);

  @override
  void initState() {
    super.initState();
    _inspect();
  }

  @override
  void dispose() {
    _sequence++;
    super.dispose();
  }

  Future<void> _inspect() async {
    final sequence = ++_sequence;
    setState(() {
      _working = true;
      _inspection = null;
      _plan = null;
      _confirmed = false;
      _error = null;
    });
    try {
      final inspection = await widget.inspect();
      if (!mounted || sequence != _sequence) return;
      setState(() {
        _inspection = inspection;
        _working = false;
        if (!_requiresResolution) {
          _resolution = null;
          _replacementId = null;
        } else if (_resolution == 'clear' && _impact['clearAllowed'] == false) {
          _resolution = null;
        }
        if (!_candidates.any(
          (candidate) =>
              candidate['id'] == _replacementId &&
              candidate['compatible'] != false,
        )) {
          _replacementId = null;
        }
      });
      await _prepare();
    } on Object catch (failure) {
      if (mounted && sequence == _sequence) {
        setState(() {
          _working = false;
          _error = '$failure';
        });
      }
    }
  }

  Future<void> _prepare() async {
    final inspection = _inspection;
    final sequence = ++_sequence;
    setState(() {
      _confirmed = false;
      _plan = null;
      _error = null;
    });
    if (inspection == null ||
        (_requiresResolution &&
            (_resolution == null ||
                (_resolution == 'replace' && _replacementId == null)))) {
      return;
    }
    setState(() => _working = true);
    try {
      final plan = await widget.prepare({
        if (_requiresResolution) 'resolution': _resolution,
        if (_resolution == 'replace') 'replacementId': _replacementId,
      }, inspection.snapshotRevision);
      if (!mounted || sequence != _sequence) return;
      setState(() => _plan = plan);
    } on Object catch (failure) {
      if (mounted && sequence == _sequence) setState(() => _error = '$failure');
    } finally {
      if (mounted && sequence == _sequence) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ResourceManagementDialog(
    title: 'Supprimer le personnage',
    submitLabel: 'Supprimer le personnage',
    maxWidth: 780,
    dirty: () => false,
    valid: () => !_working && _plan != null && _confirmed && widget.canApply(),
    submit: () => widget.apply(_plan!),
    fields: (refresh, busy) => _fields(busy),
  );
}
