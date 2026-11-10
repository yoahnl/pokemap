import '../domain/resource_mutation_preparation.dart';
import 'resource_catalog.dart';
import 'resource_lifecycle_publication.dart';

class ResourceUsageReplacementController {
  ResourceUsageReplacementController({
    required this.name,
    required this.spatial,
    required List<ResourceItem> choices,
    required this.canPublish,
    required this.prepareOperation,
    required this.publish,
  }) : choices = List.unmodifiable(choices);

  final String name;
  final bool spatial;
  final List<ResourceItem> choices;
  final bool Function() canPublish;
  final Future<ResourceMutationPreparation> Function(String) prepareOperation;
  final Future<ResourceLifecyclePublicationResult> Function(
    ResourceMutationPreparation,
  )
  publish;
  ResourceItem? replacement;
  ResourceMutationPreparation? preparation;
  String? error, notice;
  bool preparing = false, applying = false;
  bool _confirmed = false, _closed = false, _published = false;
  int _sequence = 0;
  Future<void>? _preparing;
  Future<String?>? _applying;

  bool get confirmed => _confirmed;
  bool get canApply =>
      !_closed &&
      !_published &&
      !preparing &&
      !applying &&
      preparation != null &&
      !preparation!.noChange &&
      _confirmed &&
      canPublish();

  List<({String mapId, int count})> get scope => [
    for (final entry in (preparation?.impact['maps'] as List? ?? const []))
      if (entry case {
        'mapId': final String mapId,
        'instanceIds': final List ids,
      })
        (mapId: mapId, count: ids.length),
  ];

  String get summary {
    final occurrences = preparation?.impact['occurrenceCount'] ?? 0;
    final maps = preparation?.impact['mapCount'] ?? 0;
    return '$occurrences ${occurrences == 1 ? 'occurrence' : 'occurrences'} '
        'sur $maps ${maps == 1 ? 'carte' : 'cartes'}';
  }

  Future<void> choose(ResourceItem choice) {
    if (_closed || _published || preparing || applying) return Future.value();
    final selected = choices
        .where((entry) => entry.identity == choice.identity)
        .firstOrNull;
    if (selected == null) return Future.value();
    return _preparing = _choose(selected);
  }

  Future<void> _choose(ResourceItem choice) async {
    final sequence = ++_sequence;
    replacement = choice;
    preparation = null;
    _confirmed = false;
    error = null;
    preparing = true;
    try {
      final prepared = await prepareOperation(choice.id);
      if (!_closed && sequence == _sequence) preparation = prepared;
    } on Object catch (failure) {
      if (!_closed && sequence == _sequence) error = '$failure';
    } finally {
      preparing = false;
    }
  }

  void confirm(bool value) {
    if (_closed || _published || preparing || applying || preparation == null) {
      return;
    }
    _confirmed = value;
  }

  Future<String?> apply() {
    if (!canApply) {
      return Future.value('Le remplacement doit être préparé et confirmé.');
    }
    applying = true;
    final selected = preparation!;
    final completed =
        'Usages remplacés : $summary vers « ${replacement!.name} ».';
    return _applying = () async {
      try {
        final result = await publish(selected);
        if (result.error == null || result.publicationCommitted) {
          _published = true;
        }
        if (result.error == null) notice = completed;
        return result.error;
      } finally {
        applying = false;
      }
    }();
  }

  Future<void> settle() async {
    if (preparing) await _preparing;
    if (applying) await _applying;
  }

  void dispose() {
    _closed = true;
    _sequence++;
  }
}
