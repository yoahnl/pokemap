import '../domain/resource_mutation_preparation.dart';
import 'resource_catalog.dart';
import 'resource_lifecycle_publication.dart';

class ResourceRemovalController {
  ResourceRemovalController({
    required this.item,
    required this.prepareOperation,
    required this.publish,
    required this.dirtyOwners,
    required this.canPublish,
  });

  final ResourceItem item;
  final Future<ResourceMutationPreparation> Function(bool) prepareOperation;
  final Future<ResourceLifecyclePublicationResult> Function(
    ResourceMutationPreparation,
  )
  publish;
  final List<String> Function() dirtyOwners;
  final bool Function() canPublish;
  ResourceMutationPreparation? preparation;
  bool working = false, applying = false;
  bool _removeSource = false, _confirmed = false;
  bool get removeSource => _removeSource;
  bool get confirmed => _confirmed;
  bool usagesRequested = false;
  bool sourceRemovalSupported = false;
  String? sourceRemovalReason, error;
  int _sequence = 0;
  bool _closed = false, _published = false;
  Future<void>? _preparing;
  Future<String?>? _applying;

  bool get canApply =>
      !_closed &&
      !_published &&
      !working &&
      !applying &&
      preparation != null &&
      confirmed &&
      dirtyOwners().isEmpty &&
      canPublish();

  Future<void> prepare() {
    if (_closed || _published || working || applying) return Future.value();
    return _preparing = _prepare();
  }

  Future<void> _prepare() async {
    final sequence = ++_sequence;
    preparation = null;
    working = true;
    _confirmed = false;
    error = null;
    sourceRemovalReason = null;
    try {
      final result = await prepareOperation(removeSource);
      if (!_closed && sequence == _sequence) {
        if (item.tileset != null &&
            (result.impact['sourceRemoved'] == true) != removeSource) {
          throw StateError(
            'Le plan ne correspond plus au choix de conservation de la source.',
          );
        }
        preparation = result;
        sourceRemovalSupported =
            result.impact['sourceRemovalSupported'] == true;
        sourceRemovalReason = result.impact['sourceRemovalReason'] as String?;
      }
    } on Object catch (failure) {
      if (!_closed && sequence == _sequence) {
        error = '$failure';
        sourceRemovalSupported = false;
      }
    } finally {
      working = false;
    }
  }

  Future<void> selectRemoveSource(bool value) async {
    if (_closed ||
        _published ||
        working ||
        applying ||
        (!sourceRemovalSupported && !removeSource)) {
      return;
    }
    _removeSource = value;
    await prepare();
  }

  void confirm(bool value) {
    if (_closed ||
        _published ||
        working ||
        applying ||
        preparation == null ||
        dirtyOwners().isNotEmpty) {
      return;
    }
    _confirmed = value;
  }

  Future<String?> apply() {
    if (!canApply) {
      return Future.value('Le retrait doit être préparé et confirmé.');
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

  void requestUsages() {
    if (_closed || _published || working || applying) return;
    usagesRequested = true;
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
