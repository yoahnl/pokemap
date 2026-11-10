import 'package:map_core/map_core_domain.dart';

class SceneConditionDraft {
  SceneConditionDraft({
    required this.project,
    required this.current,
    required this.changed,
    this.loadMoves,
    this.loadItems,
    this.loadMap,
  }) {
    _reset();
  }

  ProjectManifest project;
  SceneConditionPayload current;
  Future<Map<String, String>> Function()? loadMoves;
  Future<Map<String, String>> Function()? loadItems;
  Future<MapData> Function(String)? loadMap;
  final void Function() changed;
  bool _disposed = false;

  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void configure({
    required ProjectManifest project,
    required SceneConditionPayload current,
    required Future<Map<String, String>> Function()? loadMoves,
    required Future<Map<String, String>> Function()? loadItems,
    required Future<MapData> Function(String)? loadMap,
  }) {
    final reset =
        this.project != project ||
        this.current != current ||
        this.loadMoves != loadMoves ||
        this.loadItems != loadItems ||
        this.loadMap != loadMap;
    this.project = project;
    this.current = current;
    this.loadMoves = loadMoves;
    this.loadItems = loadItems;
    this.loadMap = loadMap;
    if (reset) _reset();
  }

  void dispose() {
    _disposed = true;
    _moveRequest++;
    _itemRequest++;
    _mapRequest++;
  }

  void selectMap(String id) => _update(() {
    selectedMapId = id;
    referenceId = null;
    loadReferenceMap();
  });

  void selectPartyKind(String value) {
    _update(() {
      partyKind = ScenePartyConditionKind.values.byName(value);
      referenceId = null;
      ability = null;
      _moveRequest++;
      movesLoading = false;
      moveOptions = const {};
    });
    if (partyKind == ScenePartyConditionKind.knowsMove ||
        partyKind == ScenePartyConditionKind.hasUsableMove) {
      loadPartyMoves();
    }
  }

  static const families = {
    'periodicRewardAvailable': 'Récompense quotidienne',
    'integerComparison': 'Comparer des nombres',
    'partyState': 'Équipe Pokémon',
    'fact': 'État du monde',
    'storyStepCompletion': 'Étape d’histoire',
    'consumedEvent': 'Interaction déjà jouée',
    'playerFacing': 'Orientation du joueur',
    'trainerDefeated': 'Dresseur vaincu',
    'pokedexCaughtCount': 'Pokédex : espèces capturées',
    'badge': 'Badge obtenu',
    'inventoryItem': 'Objet dans le sac',
    'playerAtEntityAnchor': 'Position du joueur',
    'factLikeStoryFlag': 'État d’histoire',
    'mapEventInstanceBoolean': 'État local d’une entité',
  };
  static const operators = {
    'equals': 'Est égal à',
    'notEquals': 'Est différent de',
    'greaterThan': 'Est supérieur à',
    'greaterThanOrEqual': 'Est supérieur ou égal à',
    'lessThan': 'Est inférieur à',
    'lessThanOrEqual': 'Est inférieur ou égal à',
  };
  String family = 'fact';
  String? referenceId;
  NarrativeFactOperator comparisonOperator = NarrativeFactOperator.equals;
  bool expected = true;
  String text = '';
  bool unsupported = false;
  ScenePartyConditionKind partyKind = ScenePartyConditionKind.canReceivePokemon;
  FieldAbility? ability;
  Map<String, String> moveOptions = const {};
  bool movesLoading = false;
  String? movesError;
  int _moveRequest = 0;
  String firstNational = '1';
  String lastNational = '151';
  String minimumCount = '20';
  String minimumQuantity = '1';
  String? selectedMapId;
  String instanceKey = '';
  MapData? stageMap;
  bool mapLoading = false;
  String? mapError;
  int _mapRequest = 0;
  Map<String, String> itemOptions = const {};
  bool itemsLoading = false;
  String? itemsError;
  int _itemRequest = 0;

  bool get isMapSource =>
      family == 'playerAtEntityAnchor' || family == 'mapEventInstanceBoolean';

  bool get referencesLoading =>
      (isMapSource && mapLoading) ||
      (family == 'inventoryItem' && itemsLoading);

  Map<String, String> get availableFamilies => {
    for (final entry in families.entries)
      if (!const {
            'pokedexCaughtCount',
            'playerAtEntityAnchor',
            'mapEventInstanceBoolean',
          }.contains(entry.key) ||
          project.settings.dimension == ProjectDimension.twoD)
        entry.key: entry.value,
  };

  void _reset() {
    _moveRequest++;
    _itemRequest++;
    _mapRequest++;
    moveOptions = const {};
    movesLoading = false;
    movesError = null;
    itemOptions = const {};
    itemsLoading = false;
    itemsError = null;
    stageMap = null;
    mapLoading = false;
    mapError = null;
    final source = current.conditionSource;
    family = source?.sourceKind.name ?? 'fact';
    referenceId = source?.sourceId;
    comparisonOperator = NarrativeFactOperator.equals;
    expected = true;
    text = '';
    minimumQuantity = '1';
    selectedMapId = source?.mapId;
    instanceKey = source?.key ?? '';
    unsupported = source != null && !availableFamilies.containsKey(family);
    if (unsupported || source == null) return;
    if (family == 'badge' && source.badgeOwnershipExpected == null) {
      unsupported = true;
      return;
    }
    if (family == 'factLikeStoryFlag' &&
        (source.field != null ||
            source.value != null ||
            source.operator == SceneConditionOperator.equals)) {
      unsupported = true;
      return;
    }
    if (family == 'inventoryItem') {
      final quantity = source.inventoryQuantityThreshold;
      if (quantity == null) {
        unsupported = true;
        return;
      }
      minimumQuantity = '$quantity';
      _loadInventoryItems();
    } else if (isMapSource) {
      loadReferenceMap();
    }
    if (family == 'partyState') {
      partyKind = source.partyConditionKind!;
      referenceId = source.partyMoveId;
      ability = source.partyFieldAbility;
      expected = source.partyExpected!;
      if (source.partyMoveId != null) loadPartyMoves();
    } else if (family == 'pokedexCaughtCount') {
      final range = source.pokedexSpeciesRange;
      firstNational = '${range!.firstNationalDex}';
      lastNational = '${range.lastNationalDex}';
      minimumCount = '${source.pokedexMinimumCaughtCount!}';
      expected = source.operator != SceneConditionOperator.isFalse;
    } else if (family == 'fact') {
      try {
        comparisonOperator = source.resolvedFactOperator;
        final expectedValue = source.resolvedExpectedFactValue;
        expected = expectedValue.kind == NarrativeValueKind.boolean
            ? expectedValue.boolValue
            : true;
        text = expectedValue.kind == NarrativeValueKind.boolean
            ? ''
            : '${expectedValue.toJson()}';
      } catch (_) {
        unsupported = true;
      }
    } else {
      expected = family == 'storyStepCompletion'
          ? source.value == SceneConditionValues.completed
          : source.operator != SceneConditionOperator.isFalse;
    }
  }

  Map<String, String> get references => switch (family) {
    'badge' => {
      for (final badge in project.badges)
        if (badge.id.isNotEmpty &&
            badge.id.trim() == badge.id &&
            badge.label.trim().isNotEmpty &&
            project.badges.where((value) => value.id == badge.id).length == 1)
          badge.id: badge.label,
    },
    'inventoryItem' => itemOptions,
    'factLikeStoryFlag' => storyFlags,
    'playerAtEntityAnchor' || 'mapEventInstanceBoolean' => entityOptions,
    'playerFacing' => {
      'north': 'Nord',
      'south': 'Sud',
      'east': 'Est',
      'west': 'Ouest',
    },
    'trainerDefeated' => {
      for (final battle in buildBattlePublicContracts(project))
        if (battle.battleKind == BattlePublicContractKind.trainer &&
            battle.status == LinkedAssetContractStatus.available &&
            project.trainers
                    .where((trainer) => trainer.id == battle.trainerId)
                    .length ==
                1)
          battle.trainerId: battle.label,
    },
    'fact' => {for (final value in project.facts) value.id: value.label},
    'storyStepCompletion' => {
      for (final story in project.storylines)
        for (final chapter in story.chapters)
          for (final step in chapter.steps)
            step.id: '${story.title} · ${step.title}',
    },
    'consumedEvent' => {
      for (final record
          in project.eventRegistry?.records ?? <NarrativeEventRecord>[])
        record.id:
            record.definitionOrNull?.name ??
            record.draftOrNull?.name ??
            record.id,
    },
    _ => {},
  };

  Map<String, String> get storyFlags => {
    for (final fact in project.facts)
      if (fact.valueKind == NarrativeValueKind.boolean &&
          project.facts.where((value) => value.id == fact.id).length == 1 &&
          project.facts
                  .where(
                    (value) =>
                        value.id == (fact.legacyFlagName ?? fact.id) ||
                        value.legacyFlagName ==
                            (fact.legacyFlagName ?? fact.id),
                  )
                  .length ==
              1)
        fact.legacyFlagName ?? fact.id: fact.label,
  };

  Map<String, String> get mapOptions => {
    for (final map in project.maps)
      if (map.id.isNotEmpty &&
          map.id.trim() == map.id &&
          project.maps.where((value) => value.id == map.id).length == 1)
        map.id: map.name,
  };

  Map<String, String> get entityOptions => {
    for (final entity in stageMap?.entities ?? <MapEntity>[])
      if (entity.id.isNotEmpty &&
          entity.id.trim() == entity.id &&
          stageMap!.entities.where((value) => value.id == entity.id).length ==
              1 &&
          (family != 'playerAtEntityAnchor' ||
              (entity.pos.x >= 0 &&
                  entity.pos.y >= 0 &&
                  entity.pos.x < stageMap!.size.width &&
                  entity.pos.y < stageMap!.size.height)))
        entity.id:
            '${entity.name.isEmpty ? 'Entité' : entity.name} · (${entity.pos.x}, ${entity.pos.y})',
  };

  NarrativeFactDefinition? get selectedFact =>
      project.facts.where((fact) => fact.id == referenceId).firstOrNull;

  Future<void> _loadInventoryItems() async {
    final request = ++_itemRequest;
    final project = this.project;
    itemOptions = const {};
    itemsLoading = true;
    itemsError = null;
    try {
      final load = loadItems;
      if (load == null) throw StateError('Catalogue indisponible.');
      final items = await load();
      if (_disposed ||
          request != _itemRequest ||
          project != this.project ||
          family != 'inventoryItem') {
        return;
      }
      if (items.keys.any((id) => id.isEmpty || id.trim() != id) ||
          items.values.any((label) => label.trim().isEmpty)) {
        throw StateError('Références d’objets invalides.');
      }
      _update(() => itemOptions = Map.unmodifiable(items));
    } on Object {
      if (_disposed ||
          request != _itemRequest ||
          project != this.project ||
          family != 'inventoryItem') {
        return;
      }
      _update(
        () => itemsError = 'Le catalogue des objets est indisponible ou ambigu. La condition actuelle est conservée.',
      );
    } finally {
      if (!_disposed &&
          request == _itemRequest &&
          project == this.project &&
          family == 'inventoryItem') {
        _update(() => itemsLoading = false);
      }
    }
  }

  Future<void> loadReferenceMap() async {
    final request = ++_mapRequest;
    final project = this.project;
    final id = selectedMapId;
    stageMap = null;
    mapLoading = false;
    mapError = null;
    if (id == null || !mapOptions.containsKey(id)) return;
    mapLoading = true;
    try {
      final load = loadMap;
      if (load == null) throw StateError('Carte indisponible.');
      final map = await load(id);
      if (_disposed ||
          request != _mapRequest ||
          project != this.project ||
          selectedMapId != id ||
          !isMapSource) {
        return;
      }
      if (map.id != id || map.spatialScene != null) {
        throw StateError(
          'La carte choisie doit être une carte 2D correspondante.',
        );
      }
      _update(() => stageMap = map);
    } on Object {
      if (_disposed ||
          request != _mapRequest ||
          project != this.project ||
          selectedMapId != id ||
          !isMapSource) {
        return;
      }
      _update(
        () => mapError = 'La carte est indisponible ou ne correspond pas à une carte 2D. La condition actuelle est conservée.',
      );
    } finally {
      if (!_disposed &&
          request == _mapRequest &&
          project == this.project &&
          selectedMapId == id &&
          isMapSource) {
        _update(() => mapLoading = false);
      }
    }
  }

  Future<void> loadPartyMoves() async {
    final request = ++_moveRequest;
    final project = this.project;
    moveOptions = const {};
    movesLoading = true;
    movesError = null;
    try {
      final load = loadMoves;
      if (load == null) throw StateError('Catalogue indisponible.');
      final moves = await load();
      if (_disposed || request != _moveRequest || project != this.project) {
        return;
      }
      _update(() => moveOptions = moves);
    } on Object {
      if (_disposed || request != _moveRequest || project != this.project) {
        return;
      }
      _update(
        () => movesError = 'Le catalogue des capacités est indisponible ou ambigu. La condition actuelle est conservée.',
      );
    } finally {
      if (!_disposed && request == _moveRequest && project == this.project) {
        _update(() => movesLoading = false);
      }
    }
  }

  SceneConditionSource? get prepared {
    if (family == 'partyState' && !unsupported) {
      final label = partyKind.label;
      return switch (partyKind) {
        ScenePartyConditionKind.canReceivePokemon =>
          SceneConditionSource.partyCanReceivePokemon(
            expected: expected,
            label: label,
          ),
        ScenePartyConditionKind.knowsMove =>
          !movesLoading && moveOptions.containsKey(referenceId)
              ? SceneConditionSource.partyKnowsMove(
                  moveId: referenceId!,
                  expected: expected,
                  label: '$label : ${moveOptions[referenceId]}',
                )
              : null,
        ScenePartyConditionKind.hasUsableMove =>
          !movesLoading && moveOptions.containsKey(referenceId)
              ? SceneConditionSource.partyHasUsableMove(
                  moveId: referenceId!,
                  expected: expected,
                  label: '$label : ${moveOptions[referenceId]}',
                )
              : null,
        ScenePartyConditionKind.canUseFieldAbility =>
          ability == null
              ? null
              : SceneConditionSource.partyCanUseFieldAbility(
                  ability: ability!,
                  expected: expected,
                  label: '$label : ${sceneFieldAbilityLabel(ability!)}',
                ),
      };
    }
    if (family == 'pokedexCaughtCount' && !unsupported) {
      try {
        final first = int.parse(firstNational);
        final last = int.parse(lastNational);
        final minimum = int.parse(minimumCount);
        if ('$first' != firstNational ||
            '$last' != lastNational ||
            '$minimum' != minimumCount) {
          return null;
        }
        return SceneConditionSource.pokedexCaughtAtLeast(
          range: PokedexSpeciesRange(
            firstNationalDex: first,
            lastNationalDex: last,
          ),
          minimum: minimum,
          expected: expected,
          label: 'Au moins $minimum espèces capturées (n° $first à $last)',
        );
      } on Object {
        return null;
      }
    }
    final id = referenceId;
    if (unsupported ||
        referencesLoading ||
        id == null ||
        !references.containsKey(id)) {
      return null;
    }
    final existing = current.conditionSource;
    final debug =
        existing?.sourceId == id &&
            existing?.sourceKind.name == family &&
            existing?.mapId == (isMapSource ? selectedMapId : null) &&
            existing?.key ==
                (family == 'mapEventInstanceBoolean' ? instanceKey : null)
        ? existing?.debugTechnicalLabel
        : null;
    if (family == 'inventoryItem') {
      final minimum = int.tryParse(minimumQuantity);
      if (minimum == null || minimum < 1 || '$minimum' != minimumQuantity) {
        return null;
      }
      return SceneConditionSource(
        sourceKind: SceneConditionSourceKind.inventoryItem,
        sourceId: id,
        operator: expected
            ? SceneConditionOperator.isTrue
            : SceneConditionOperator.isFalse,
        field: 'minimumQuantity',
        value: '$minimum',
        label: references[id],
        debugTechnicalLabel: debug,
      );
    }
    if (isMapSource) {
      final mapId = selectedMapId;
      if (mapId == null ||
          !mapOptions.containsKey(mapId) ||
          stageMap?.id != mapId) {
        return null;
      }
      if (family == 'mapEventInstanceBoolean') {
        if (instanceKey.isEmpty || instanceKey.trim() != instanceKey) {
          return null;
        }
        return SceneConditionSource.mapEventInstanceBoolean(
          mapId: mapId,
          eventId: id,
          key: instanceKey,
          expected: expected,
          label: '${references[id]} · $instanceKey',
          debugTechnicalLabel: debug,
        );
      }
      return SceneConditionSource.playerAtEntityAnchor(
        mapId: mapId,
        entityId: id,
        expected: expected,
        label: references[id],
        debugTechnicalLabel: debug,
      );
    }
    if (family != 'fact') {
      return SceneConditionSource(
        sourceKind: SceneConditionSourceKind.values.byName(family),
        sourceId: id,
        operator: family == 'storyStepCompletion'
            ? SceneConditionOperator.equals
            : expected
            ? SceneConditionOperator.isTrue
            : SceneConditionOperator.isFalse,
        value: family == 'storyStepCompletion'
            ? expected
                  ? SceneConditionValues.completed
                  : SceneConditionValues.notCompleted
            : null,
        label: references[id],
        debugTechnicalLabel: debug,
      );
    }
    final fact = selectedFact;
    if (fact == null ||
        !fact.valueKind.compatibleOperators.contains(comparisonOperator)) {
      return null;
    }
    try {
      final value = switch (fact.valueKind) {
        NarrativeValueKind.boolean => NarrativeValue.boolean(expected),
        NarrativeValueKind.integer => NarrativeValue.integer(int.parse(text)),
        NarrativeValueKind.string => NarrativeValue.string(text),
      };
      return SceneConditionSource.factValue(
        factId: id,
        operator: comparisonOperator,
        expectedValue: value,
        label: fact.label,
        debugTechnicalLabel: debug,
      );
    } catch (_) {
      return null;
    }
  }

  void selectReference(String id) {
    _update(() {
      referenceId = id;
      unsupported = false;
      comparisonOperator = NarrativeFactOperator.equals;
      final value = family == 'fact' ? selectedFact?.initialValue : null;
      expected = value?.kind == NarrativeValueKind.boolean
          ? value!.boolValue
          : true;
      text = value == null || value.kind == NarrativeValueKind.boolean
          ? ''
          : '${value.toJson()}';
    });
  }

  void selectFamily(String value) {
    _update(() {
      family = value;
      referenceId = null;
      selectedMapId = null;
      instanceKey = '';
      minimumQuantity = '1';
      expected = true;
      unsupported = false;
      _moveRequest++;
      movesLoading = false;
      movesError = null;
      moveOptions = const {};
      partyKind = ScenePartyConditionKind.canReceivePokemon;
      ability = null;
      _itemRequest++;
      itemsLoading = false;
      itemsError = null;
      itemOptions = const {};
      _mapRequest++;
      mapLoading = false;
      mapError = null;
      stageMap = null;
      if (value == 'inventoryItem') _loadInventoryItems();
    });
  }
}

String sceneFieldAbilityLabel(FieldAbility ability) => switch (ability) {
  FieldAbility.surf => 'Surf',
  FieldAbility.cut => 'Coupe',
  FieldAbility.strength => 'Force',
  FieldAbility.flash => 'Flash',
  FieldAbility.rockSmash => 'Éclate-Roc',
  FieldAbility.waterfall => 'Cascade',
  FieldAbility.whirlpool => 'Tourbillon',
  FieldAbility.dive => 'Plongée',
  FieldAbility.fly => 'Vol',
};
