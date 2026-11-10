import '../domain/resource_mutation_preparation.dart';
import 'resource_lifecycle_publication.dart';

enum BorderResourceAction { usages, deleteDraft, deprecate, reactivate }

class ResourceBorderLifecycleController {
  ResourceBorderLifecycleController({
    required this.prepareOperation,
    required this.publish,
    required this.canPublish,
  });

  final Future<ResourceMutationPreparation> Function() prepareOperation;
  final Future<ResourceLifecyclePublicationResult> Function(
    ResourceMutationPreparation,
  )
  publish;
  final bool Function() canPublish;
  ResourceMutationPreparation? preparation;
  bool working = false, applying = false;
  bool _confirmed = false, _closed = false, _published = false;
  String? error;
  int _sequence = 0;
  Future<void>? _preparing;
  Future<String?>? _applying;

  bool get confirmed => _confirmed;
  bool get canApply =>
      !_closed &&
      !_published &&
      !working &&
      !applying &&
      preparation != null &&
      _confirmed &&
      canPublish();

  Future<void> prepare() {
    if (_closed || _published || working || applying) return Future.value();
    return _preparing = _prepare();
  }

  Future<void> _prepare() async {
    final sequence = ++_sequence;
    working = true;
    preparation = null;
    _confirmed = false;
    error = null;
    try {
      final result = await prepareOperation();
      if (!_closed && sequence == _sequence) preparation = result;
    } on Object catch (failure) {
      if (!_closed && sequence == _sequence) error = '$failure';
    } finally {
      working = false;
    }
  }

  void confirm(bool value) {
    if (_closed || _published || working || applying || preparation == null) {
      return;
    }
    _confirmed = value;
  }

  Future<String?> apply() {
    if (!canApply) {
      return Future.value('L’opération doit être préparée et confirmée.');
    }
    applying = true;
    final selected = preparation!;
    return _applying = () async {
      try {
        final result = await publish(selected);
        if (result.error == null || result.publicationCommitted) {
          _published = true;
        }
        return result.error;
      } finally {
        applying = false;
      }
    }();
  }

  Future<void> settle() async {
    if (working) await _preparing;
    if (applying) await _applying;
  }

  void dispose() {
    _closed = true;
    _sequence++;
  }
}
