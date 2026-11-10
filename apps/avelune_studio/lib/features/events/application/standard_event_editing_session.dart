import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

class StandardEventEditingSession {
  StandardEventEditingSession({
    required this.project,
    required List<MapData> maps,
    required this.itemOptions,
    this.loadMapSource,
    this.changed,
    StandardEventTemplateSpec? initial,
    String? initialMapId,
    String? initialEntityId,
  }) : _initialMaps = maps {
    kind = initial?.kind ?? StandardEventTemplateKind.conditionalNpc;
    mapId = initialMapId ?? initial?.mapId ?? project.maps.firstOrNull?.id;
    entityId = initialEntityId ?? initial?.entityId;
    initial == null ? readOwner() : load(initial);
  }

  final ProjectManifest project;
  final List<MapData> _initialMaps;
  final Map<String, String> itemOptions;
  final Future<MapData> Function(String)? loadMapSource;
  final void Function()? changed;
  final _loadedMaps = <String, MapData>{};
  final parameters = <String, Object?>{};
  late StandardEventTemplateKind kind;
  String? mapId, entityId;
  String name = '';
  bool owned = false, reusing = false, busy = false, simulated = false;
  String? error;
  int _readingMaps = 0;
  bool _closed = false;

  List<MapData> get maps => {
    for (final map in _initialMaps) map.id: map,
    ..._loadedMaps,
  }.values.toList(growable: false);

  MapData? get selectedMap => maps.where((map) => map.id == mapId).firstOrNull;

  Future<void> initialize() async {
    await Future.wait([
      if (mapId case final id?) loadMap(id),
      if (parameters['destinationMapId'] case final String id) loadMap(id),
    ]);
  }

  Future<void> loadMap(String id) async {
    if (maps.any((map) => map.id == id)) return;
    final load = loadMapSource;
    if (load == null) return;
    _readingMaps++;
    busy = true;
    changed?.call();
    try {
      final loaded = await load(id);
      if (loaded.id != id) {
        throw StateError('La carte chargée ne correspond pas au choix.');
      }
      if (!_closed) {
        _loadedMaps[id] = loaded;
        error = null;
        if (mapId == id) readOwner();
        changed?.call();
      }
    } catch (failure) {
      if (!_closed) {
        error = failure.toString();
        changed?.call();
      }
    } finally {
      _readingMaps--;
      if (!_closed) {
        busy = _readingMaps > 0;
        changed?.call();
      }
    }
  }

  void load(StandardEventTemplateSpec spec) {
    kind = spec.kind;
    mapId = spec.mapId;
    entityId = spec.entityId;
    name = spec.name;
    parameters
      ..clear()
      ..addAll(spec.parameters);
    owned = true;
    reusing = false;
    simulated = false;
    error = null;
  }

  void readOwner() {
    final map = selectedMap;
    owned = false;
    error = null;
    if (map == null || entityId == null) return;
    final existing = readStandardEventTemplate(
      project: project,
      map: map,
      entityId: entityId!,
    );
    if (existing != null) {
      load(existing);
      return;
    }
    final entity = map.entities
        .where((entity) => entity.id == entityId)
        .firstOrNull;
    if (!reusing && entity != null) name = entity.name;
  }

  void selectKind(StandardEventTemplateKind value) {
    kind = value;
    parameters.clear();
    if (kind == StandardEventTemplateKind.pickup) parameters['quantity'] = 1;
    error = null;
  }

  Future<void> selectMap(String id) async {
    mapId = id;
    entityId = null;
    owned = false;
    error = null;
    await loadMap(id);
  }

  void selectEntity(String id) {
    entityId = id;
    readOwner();
  }

  void reuse() {
    entityId = null;
    owned = false;
    reusing = true;
    error = null;
  }

  StandardEventTemplateSpec get spec {
    if (mapId == null || entityId == null || name.trim().isEmpty) {
      throw StateError(
        'Choisissez une carte, une entité et un nom pour cet événement.',
      );
    }
    if (StandardEventTemplateSpec.requiredParameterFields[kind]!.any(
      (key) => !parameters.containsKey(key),
    )) {
      throw StateError(
        'Complétez les sélections nécessaires à ce comportement.',
      );
    }
    final item = parameters['itemId'];
    if (item != null && !itemOptions.containsKey(item)) {
      throw StateError(
        itemOptions.isEmpty
            ? 'Le catalogue des objets est indisponible. Rechargez-le avant d’enregistrer cet événement.'
            : 'L’objet choisi ne figure plus dans le catalogue. Sélectionnez un objet disponible.',
      );
    }
    return StandardEventTemplateSpec(
      kind: kind,
      mapId: mapId!,
      entityId: entityId!,
      name: name.trim(),
      parameters: Map.of(parameters),
    );
  }

  StandardEventTemplateProjection get projection =>
      compileStandardEventTemplate(project: project, maps: maps, spec: spec);

  GameState simulation(StandardEventTemplateProjection projection) {
    final factId = parameters['factId'] as String?;
    final itemId = parameters['itemId'] as String?;
    final trainerId = parameters['trainerId'] as String?;
    return GameState(
      saveId: 'standard-event-preview',
      currentMapId: mapId ?? '',
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: factId == null ? const {} : {factId: simulated},
      ),
      bag: Bag(
        entries: [
          if (itemId != null && simulated)
            BagEntry(itemId: itemId, quantity: 1),
        ],
      ),
      storyFlags: StoryFlags(
        activeFlags: {
          if (trainerId != null && simulated) 'trainer_defeated:$trainerId',
        },
      ),
      narrativeEventProgress: NarrativeEventProgress(
        consumedNarrativeEventIds:
            kind == StandardEventTemplateKind.pickup && simulated
            ? projection.events.map((event) => event.id)
            : const [],
      ),
    );
  }

  Future<bool> save({
    required Future<bool> Function(StandardEventTemplateSpec) publish,
    String? advancedSceneId,
    void Function(String)? openAdvanced,
  }) async {
    if (_closed || busy) return false;
    busy = true;
    error = null;
    changed?.call();
    try {
      final candidate = spec;
      compileStandardEventTemplate(
        project: project,
        maps: maps,
        spec: candidate,
      );
      final saved = await publish(candidate);
      if (!_closed && !saved) {
        error = 'L’enregistrement a été refusé. Vos réglages restent ici.';
      }
      if (!_closed && saved && advancedSceneId != null) {
        openAdvanced?.call(advancedSceneId);
      }
      return saved;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      if (!_closed) {
        busy = false;
        changed?.call();
      }
    }
  }

  void dispose() => _closed = true;
}
