import '../domain/resource_mutation_preparation.dart';
import 'resource_lifecycle_publication.dart';

class ResourceTerrainLifecycleController {
  ResourceTerrainLifecycleController({
    required String name,
    required this.duplicate,
    required this.removing,
    required this.canPublish,
    required this.prepareOperation,
    required this.publish,
  }) : originalName = name,
       name = duplicate ? '$name — copie' : name;

  final String originalName;
  final bool duplicate, removing;
  final bool Function() canPublish;
  final Future<ResourceMutationPreparation?> Function(String) prepareOperation;
  final Future<ResourceLifecyclePublicationResult> Function(
    ResourceMutationPreparation?,
  )
  publish;
  String name;
  ResourceMutationPreparation? preparation;
  String? error;
  bool working = false, ready = false, confirmed = false;
  bool _closed = false, _published = false;
  int _sequence = 0;
  Future<void>? _preparing;
  Future<String?>? _applying;

  bool get dirty =>
      name != (duplicate ? '$originalName — copie' : originalName);
  bool get canApply =>
      !_closed &&
      !_published &&
      !working &&
      canPublish() &&
      (removing ? ready && confirmed : name.trim().isNotEmpty);

  Future<void> prepareRemoval() {
    if (_closed || _published || working || !removing || !canPublish()) {
      return Future.value();
    }
    return _preparing = _prepareRemoval();
  }

  Future<void> _prepareRemoval() async {
    final sequence = ++_sequence;
    working = true;
    ready = false;
    confirmed = false;
    error = null;
    preparation = null;
    try {
      final result = await prepareOperation(name);
      if (!_closed && sequence == _sequence) {
        preparation = result;
        ready = true;
      }
    } on Object catch (failure) {
      if (!_closed && sequence == _sequence) error = '$failure';
    } finally {
      working = false;
    }
  }

  void confirm(bool value) {
    if (!_closed && !_published && !working && ready) confirmed = value;
  }

  Future<String?> apply() {
    if (!canApply) {
      return Future.value(
        'Préparez et confirmez l’opération avant de continuer.',
      );
    }
    if (!removing && !duplicate && name.trim() == originalName.trim()) {
      return Future.value();
    }
    working = true;
    final requestedName = name;
    return _applying = () async {
      try {
        final selected = removing
            ? preparation
            : await prepareOperation(requestedName);
        if (_closed || !canPublish() || (!removing && name != requestedName)) {
          return 'Cette opération n’est plus active. Votre saisie est conservée.';
        }
        final result = await publish(selected);
        if (result.error == null || result.publicationCommitted) {
          _published = true;
        }
        return result.error;
      } on Object catch (failure) {
        return '$failure';
      } finally {
        working = false;
      }
    }();
  }

  Future<void> settle() async {
    await _preparing;
    await _applying;
  }

  void dispose() {
    _closed = true;
    _sequence++;
  }
}
