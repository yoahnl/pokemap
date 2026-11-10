import '../../resources/domain/resource_mutation_preparation.dart';

class CharacterRemovalController {
  CharacterRemovalController({
    required this.inspectOperation,
    required this.prepareOperation,
    required this.applyOperation,
    required this.canApply,
  });

  final Future<ResourceMutationPreparation> Function() inspectOperation;
  final Future<ResourceMutationPreparation> Function(
    Map<String, Object?> parameters,
    String revision,
  )
  prepareOperation;
  final Future<String?> Function(ResourceMutationPreparation plan)
  applyOperation;
  final bool Function() canApply;
  final _listeners = <void Function()>{};
  ResourceMutationPreparation? inspection, plan;
  bool working = false, confirmed = false, applying = false;
  String? resolution, replacementId, error;
  int _sequence = 0;
  bool _disposed = false;

  Map<String, Object?> get impact => inspection?.impact ?? const {};
  List<Map> get candidates =>
      (impact['replacementCandidates'] as List? ?? const [])
          .whereType<Map>()
          .toList();
  bool get requiresResolution => impact['requiresResolution'] == true;
  bool get canSubmit =>
      !_disposed &&
      !working &&
      !applying &&
      plan != null &&
      confirmed &&
      canApply();

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  Future<void> inspect() async {
    if (_disposed || applying) return;
    final sequence = ++_sequence;
    working = true;
    inspection = null;
    plan = null;
    confirmed = false;
    error = null;
    _notify();
    try {
      final result = await inspectOperation();
      if (_disposed || sequence != _sequence) return;
      inspection = result;
      working = false;
      if (!requiresResolution) {
        resolution = null;
        replacementId = null;
      } else if (resolution == 'clear' && impact['clearAllowed'] == false) {
        resolution = null;
      }
      if (!candidates.any(
        (candidate) =>
            candidate['id'] == replacementId &&
            candidate['compatible'] != false,
      )) {
        replacementId = null;
      }
      _notify();
      await prepare();
    } on Object catch (failure) {
      if (!_disposed && sequence == _sequence) {
        working = false;
        error = '$failure';
        _notify();
      }
    }
  }

  Future<void> selectResolution(String? value) async {
    if (_disposed || working || applying) return;
    resolution = value;
    await prepare();
  }

  Future<void> selectReplacement(String? value) async {
    if (_disposed || working || applying) return;
    replacementId = value;
    await prepare();
  }

  Future<void> prepare() async {
    if (_disposed || applying) return;
    final inspection = this.inspection;
    final sequence = ++_sequence;
    confirmed = false;
    plan = null;
    error = null;
    _notify();
    if (inspection == null ||
        requiresResolution &&
            (resolution == null ||
                resolution == 'replace' && replacementId == null)) {
      return;
    }
    working = true;
    _notify();
    try {
      final result = await prepareOperation({
        if (requiresResolution) 'resolution': resolution,
        if (resolution == 'replace') 'replacementId': replacementId,
      }, inspection.snapshotRevision);
      if (!_disposed && sequence == _sequence) {
        plan = result;
        _notify();
      }
    } on Object catch (failure) {
      if (!_disposed && sequence == _sequence) error = '$failure';
    } finally {
      if (!_disposed && sequence == _sequence) {
        working = false;
        _notify();
      }
    }
  }

  void confirm(bool value) {
    if (_disposed || working || applying || plan == null) return;
    confirmed = value;
    _notify();
  }

  Future<String?> submit() async {
    if (!canSubmit) return 'Le retrait doit être préparé et confirmé.';
    applying = true;
    _notify();
    try {
      return await applyOperation(plan!);
    } finally {
      applying = false;
      _notify();
    }
  }

  void dispose() {
    _disposed = true;
    _sequence++;
    _listeners.clear();
  }
}
