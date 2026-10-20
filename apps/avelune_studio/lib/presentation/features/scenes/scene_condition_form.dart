import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

class SceneConditionForm extends StatefulWidget {
  const SceneConditionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
    this.loadMoves,
    this.loadItems,
    this.loadMap,
  });
  final ProjectManifest project;
  final SceneConditionPayload current;
  final ValueChanged<SceneConditionSource> onApply;
  final Future<Map<String, String>> Function()? loadMoves;
  final Future<Map<String, String>> Function()? loadItems;
  final Future<MapData> Function(String)? loadMap;
  @override
  State<SceneConditionForm> createState() => _SceneConditionFormState();
}

class _SceneConditionFormState extends State<SceneConditionForm> {
  static const families = {
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
  String _family = 'fact';
  String? _id;
  NarrativeFactOperator _operator = NarrativeFactOperator.equals;
  bool _boolean = true;
  String _text = '';
  bool _unsupported = false;
  ScenePartyConditionKind _partyKind =
      ScenePartyConditionKind.canReceivePokemon;
  FieldAbility? _ability;
  Map<String, String> _moves = const {};
  bool _movesLoading = false;
  String? _movesError;
  int _moveRequest = 0;
  String _firstNational = '1';
  String _lastNational = '151';
  String _minimumCount = '20';
  String _minimumQuantity = '1';
  String? _mapId;
  String _instanceKey = '';
  MapData? _map;
  bool _mapLoading = false;
  String? _mapError;
  int _mapRequest = 0;
  Map<String, String> _items = const {};
  bool _itemsLoading = false;
  String? _itemsError;
  int _itemRequest = 0;

  bool get _isMapSource =>
      _family == 'playerAtEntityAnchor' || _family == 'mapEventInstanceBoolean';

  bool get _referencesLoading =>
      (_isMapSource && _mapLoading) ||
      (_family == 'inventoryItem' && _itemsLoading);

  Map<String, String> get _availableFamilies => {
    for (final entry in families.entries)
      if (!const {
            'pokedexCaughtCount',
            'playerAtEntityAnchor',
            'mapEventInstanceBoolean',
          }.contains(entry.key) ||
          widget.project.settings.dimension == ProjectDimension.twoD)
        entry.key: entry.value,
  };

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(SceneConditionForm old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current ||
        old.project != widget.project ||
        old.loadMoves != widget.loadMoves ||
        old.loadItems != widget.loadItems ||
        old.loadMap != widget.loadMap) {
      _reset();
    }
  }

  void _reset() {
    _moveRequest++;
    _itemRequest++;
    _mapRequest++;
    _moves = const {};
    _movesLoading = false;
    _movesError = null;
    _items = const {};
    _itemsLoading = false;
    _itemsError = null;
    _map = null;
    _mapLoading = false;
    _mapError = null;
    final source = widget.current.conditionSource;
    _family = source?.sourceKind.name ?? 'fact';
    _id = source?.sourceId;
    _operator = NarrativeFactOperator.equals;
    _boolean = true;
    _text = '';
    _minimumQuantity = '1';
    _mapId = source?.mapId;
    _instanceKey = source?.key ?? '';
    _unsupported = source != null && !_availableFamilies.containsKey(_family);
    if (_unsupported || source == null) return;
    if (_family == 'badge' && source.badgeOwnershipExpected == null) {
      _unsupported = true;
      return;
    }
    if (_family == 'factLikeStoryFlag' &&
        (source.field != null ||
            source.value != null ||
            source.operator == SceneConditionOperator.equals)) {
      _unsupported = true;
      return;
    }
    if (_family == 'inventoryItem') {
      final quantity = source.inventoryQuantityThreshold;
      if (quantity == null) {
        _unsupported = true;
        return;
      }
      _minimumQuantity = '$quantity';
      _loadInventoryItems();
    } else if (_isMapSource) {
      _loadReferenceMap();
    }
    if (_family == 'partyState') {
      _partyKind = source.partyConditionKind!;
      _id = source.partyMoveId;
      _ability = source.partyFieldAbility;
      _boolean = source.partyExpected!;
      if (source.partyMoveId != null) _loadPartyMoves();
    } else if (_family == 'pokedexCaughtCount') {
      final range = source.pokedexSpeciesRange;
      _firstNational = '${range!.firstNationalDex}';
      _lastNational = '${range.lastNationalDex}';
      _minimumCount = '${source.pokedexMinimumCaughtCount!}';
      _boolean = source.operator != SceneConditionOperator.isFalse;
    } else if (_family == 'fact') {
      try {
        _operator = source.resolvedFactOperator;
        final expected = source.resolvedExpectedFactValue;
        _boolean = expected.kind == NarrativeValueKind.boolean
            ? expected.boolValue
            : true;
        _text = expected.kind == NarrativeValueKind.boolean
            ? ''
            : '${expected.toJson()}';
      } catch (_) {
        _unsupported = true;
      }
    } else {
      _boolean = _family == 'storyStepCompletion'
          ? source.value == SceneConditionValues.completed
          : source.operator != SceneConditionOperator.isFalse;
    }
  }

  Map<String, String> get _references => switch (_family) {
    'badge' => {
      for (final badge in widget.project.badges)
        if (badge.id.isNotEmpty &&
            badge.id.trim() == badge.id &&
            badge.label.trim().isNotEmpty &&
            widget.project.badges
                    .where((value) => value.id == badge.id)
                    .length ==
                1)
          badge.id: badge.label,
    },
    'inventoryItem' => _items,
    'factLikeStoryFlag' => _storyFlags,
    'playerAtEntityAnchor' || 'mapEventInstanceBoolean' => _entities,
    'playerFacing' => {
      'north': 'Nord',
      'south': 'Sud',
      'east': 'Est',
      'west': 'Ouest',
    },
    'trainerDefeated' => {
      for (final battle in buildBattlePublicContracts(widget.project))
        if (battle.battleKind == BattlePublicContractKind.trainer &&
            battle.status == LinkedAssetContractStatus.available &&
            widget.project.trainers
                    .where((trainer) => trainer.id == battle.trainerId)
                    .length ==
                1)
          battle.trainerId: battle.label,
    },
    'fact' => {for (final value in widget.project.facts) value.id: value.label},
    'storyStepCompletion' => {
      for (final story in widget.project.storylines)
        for (final chapter in story.chapters)
          for (final step in chapter.steps)
            step.id: '${story.title} · ${step.title}',
    },
    'consumedEvent' => {
      for (final record
          in widget.project.eventRegistry?.records ?? <NarrativeEventRecord>[])
        record.id:
            record.definitionOrNull?.name ??
            record.draftOrNull?.name ??
            record.id,
    },
    _ => {},
  };

  Map<String, String> get _storyFlags => {
    for (final fact in widget.project.facts)
      if (fact.valueKind == NarrativeValueKind.boolean &&
          widget.project.facts.where((value) => value.id == fact.id).length ==
              1 &&
          widget.project.facts
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

  Map<String, String> get _maps => {
    for (final map in widget.project.maps)
      if (map.id.isNotEmpty &&
          map.id.trim() == map.id &&
          widget.project.maps.where((value) => value.id == map.id).length == 1)
        map.id: map.name,
  };

  Map<String, String> get _entities => {
    for (final entity in _map?.entities ?? <MapEntity>[])
      if (entity.id.isNotEmpty &&
          entity.id.trim() == entity.id &&
          _map!.entities.where((value) => value.id == entity.id).length == 1 &&
          (_family != 'playerAtEntityAnchor' ||
              (entity.pos.x >= 0 &&
                  entity.pos.y >= 0 &&
                  entity.pos.x < _map!.size.width &&
                  entity.pos.y < _map!.size.height)))
        entity.id:
            '${entity.name.isEmpty ? 'Entité' : entity.name} · (${entity.pos.x}, ${entity.pos.y})',
  };

  NarrativeFactDefinition? get _fact =>
      widget.project.facts.where((fact) => fact.id == _id).firstOrNull;

  Future<void> _loadInventoryItems() async {
    final request = ++_itemRequest;
    final project = widget.project;
    _items = const {};
    _itemsLoading = true;
    _itemsError = null;
    try {
      final load = widget.loadItems;
      if (load == null) throw StateError('Catalogue indisponible.');
      final items = await load();
      if (!mounted ||
          request != _itemRequest ||
          project != widget.project ||
          _family != 'inventoryItem') {
        return;
      }
      if (items.keys.any((id) => id.isEmpty || id.trim() != id) ||
          items.values.any((label) => label.trim().isEmpty)) {
        throw StateError('Références d’objets invalides.');
      }
      setState(() => _items = Map.unmodifiable(items));
    } on Object {
      if (!mounted ||
          request != _itemRequest ||
          project != widget.project ||
          _family != 'inventoryItem') {
        return;
      }
      setState(
        () => _itemsError = 'Le catalogue des objets est indisponible ou ambigu. La condition actuelle est conservée.',
      );
    } finally {
      if (mounted &&
          request == _itemRequest &&
          project == widget.project &&
          _family == 'inventoryItem') {
        setState(() => _itemsLoading = false);
      }
    }
  }

  Future<void> _loadReferenceMap() async {
    final request = ++_mapRequest;
    final project = widget.project;
    final id = _mapId;
    _map = null;
    _mapLoading = false;
    _mapError = null;
    if (id == null || !_maps.containsKey(id)) return;
    _mapLoading = true;
    try {
      final load = widget.loadMap;
      if (load == null) throw StateError('Carte indisponible.');
      final map = await load(id);
      if (!mounted ||
          request != _mapRequest ||
          project != widget.project ||
          _mapId != id ||
          !_isMapSource) {
        return;
      }
      if (map.id != id || map.spatialScene != null) {
        throw StateError(
          'La carte choisie doit être une carte 2D correspondante.',
        );
      }
      setState(() => _map = map);
    } on Object {
      if (!mounted ||
          request != _mapRequest ||
          project != widget.project ||
          _mapId != id ||
          !_isMapSource) {
        return;
      }
      setState(
        () => _mapError = 'La carte est indisponible ou ne correspond pas à une carte 2D. La condition actuelle est conservée.',
      );
    } finally {
      if (mounted &&
          request == _mapRequest &&
          project == widget.project &&
          _mapId == id &&
          _isMapSource) {
        setState(() => _mapLoading = false);
      }
    }
  }

  Future<void> _loadPartyMoves() async {
    final request = ++_moveRequest;
    final project = widget.project;
    _moves = const {};
    _movesLoading = true;
    _movesError = null;
    try {
      final load = widget.loadMoves;
      if (load == null) throw StateError('Catalogue indisponible.');
      final moves = await load();
      if (!mounted || request != _moveRequest || project != widget.project) {
        return;
      }
      setState(() => _moves = moves);
    } on Object {
      if (!mounted || request != _moveRequest || project != widget.project) {
        return;
      }
      setState(
        () => _movesError = 'Le catalogue des capacités est indisponible ou ambigu. La condition actuelle est conservée.',
      );
    } finally {
      if (mounted && request == _moveRequest && project == widget.project) {
        setState(() => _movesLoading = false);
      }
    }
  }

  SceneConditionSource? get _prepared {
    if (_family == 'partyState' && !_unsupported) {
      final label = _partyKind.label;
      return switch (_partyKind) {
        ScenePartyConditionKind.canReceivePokemon =>
          SceneConditionSource.partyCanReceivePokemon(
            expected: _boolean,
            label: label,
          ),
        ScenePartyConditionKind.knowsMove =>
          !_movesLoading && _moves.containsKey(_id)
              ? SceneConditionSource.partyKnowsMove(
                  moveId: _id!,
                  expected: _boolean,
                  label: '$label : ${_moves[_id]}',
                )
              : null,
        ScenePartyConditionKind.hasUsableMove =>
          !_movesLoading && _moves.containsKey(_id)
              ? SceneConditionSource.partyHasUsableMove(
                  moveId: _id!,
                  expected: _boolean,
                  label: '$label : ${_moves[_id]}',
                )
              : null,
        ScenePartyConditionKind.canUseFieldAbility =>
          _ability == null
              ? null
              : SceneConditionSource.partyCanUseFieldAbility(
                  ability: _ability!,
                  expected: _boolean,
                  label: '$label : ${_abilityLabel(_ability!)}',
                ),
      };
    }
    if (_family == 'pokedexCaughtCount' && !_unsupported) {
      try {
        final first = int.parse(_firstNational);
        final last = int.parse(_lastNational);
        final minimum = int.parse(_minimumCount);
        if ('$first' != _firstNational ||
            '$last' != _lastNational ||
            '$minimum' != _minimumCount) {
          return null;
        }
        return SceneConditionSource.pokedexCaughtAtLeast(
          range: PokedexSpeciesRange(
            firstNationalDex: first,
            lastNationalDex: last,
          ),
          minimum: minimum,
          expected: _boolean,
          label: 'Au moins $minimum espèces capturées (n° $first à $last)',
        );
      } on Object {
        return null;
      }
    }
    final id = _id;
    if (_unsupported ||
        _referencesLoading ||
        id == null ||
        !_references.containsKey(id)) {
      return null;
    }
    final existing = widget.current.conditionSource;
    final debug =
        existing?.sourceId == id &&
            existing?.sourceKind.name == _family &&
            existing?.mapId == (_isMapSource ? _mapId : null) &&
            existing?.key ==
                (_family == 'mapEventInstanceBoolean' ? _instanceKey : null)
        ? existing?.debugTechnicalLabel
        : null;
    if (_family == 'inventoryItem') {
      final minimum = int.tryParse(_minimumQuantity);
      if (minimum == null || minimum < 1 || '$minimum' != _minimumQuantity) {
        return null;
      }
      return SceneConditionSource(
        sourceKind: SceneConditionSourceKind.inventoryItem,
        sourceId: id,
        operator: _boolean
            ? SceneConditionOperator.isTrue
            : SceneConditionOperator.isFalse,
        field: 'minimumQuantity',
        value: '$minimum',
        label: _references[id],
        debugTechnicalLabel: debug,
      );
    }
    if (_isMapSource) {
      final mapId = _mapId;
      if (mapId == null || !_maps.containsKey(mapId) || _map?.id != mapId) {
        return null;
      }
      if (_family == 'mapEventInstanceBoolean') {
        if (_instanceKey.isEmpty || _instanceKey.trim() != _instanceKey) {
          return null;
        }
        return SceneConditionSource.mapEventInstanceBoolean(
          mapId: mapId,
          eventId: id,
          key: _instanceKey,
          expected: _boolean,
          label: '${_references[id]} · $_instanceKey',
          debugTechnicalLabel: debug,
        );
      }
      return SceneConditionSource.playerAtEntityAnchor(
        mapId: mapId,
        entityId: id,
        expected: _boolean,
        label: _references[id],
        debugTechnicalLabel: debug,
      );
    }
    if (_family != 'fact') {
      return SceneConditionSource(
        sourceKind: SceneConditionSourceKind.values.byName(_family),
        sourceId: id,
        operator: _family == 'storyStepCompletion'
            ? SceneConditionOperator.equals
            : _boolean
            ? SceneConditionOperator.isTrue
            : SceneConditionOperator.isFalse,
        value: _family == 'storyStepCompletion'
            ? _boolean
                  ? SceneConditionValues.completed
                  : SceneConditionValues.notCompleted
            : null,
        label: _references[id],
        debugTechnicalLabel: debug,
      );
    }
    final fact = _fact;
    if (fact == null ||
        !fact.valueKind.compatibleOperators.contains(_operator)) {
      return null;
    }
    try {
      final value = switch (fact.valueKind) {
        NarrativeValueKind.boolean => NarrativeValue.boolean(_boolean),
        NarrativeValueKind.integer => NarrativeValue.integer(int.parse(_text)),
        NarrativeValueKind.string => NarrativeValue.string(_text),
      };
      return SceneConditionSource.factValue(
        factId: id,
        operator: _operator,
        expectedValue: value,
        label: fact.label,
        debugTechnicalLabel: debug,
      );
    } catch (_) {
      return null;
    }
  }

  void _selectReference(String id) {
    setState(() {
      _id = id;
      _unsupported = false;
      _operator = NarrativeFactOperator.equals;
      final value = _family == 'fact' ? _fact?.initialValue : null;
      _boolean = value?.kind == NarrativeValueKind.boolean
          ? value!.boolValue
          : true;
      _text = value == null || value.kind == NarrativeValueKind.boolean
          ? ''
          : '${value.toJson()}';
    });
  }

  void _selectFamily(String value) {
    setState(() {
      _family = value;
      _id = null;
      _mapId = null;
      _instanceKey = '';
      _minimumQuantity = '1';
      _boolean = true;
      _unsupported = false;
      _moveRequest++;
      _movesLoading = false;
      _movesError = null;
      _moves = const {};
      _partyKind = ScenePartyConditionKind.canReceivePokemon;
      _ability = null;
      _itemRequest++;
      _itemsLoading = false;
      _itemsError = null;
      _items = const {};
      _mapRequest++;
      _mapLoading = false;
      _mapError = null;
      _map = null;
      if (value == 'inventoryItem') _loadInventoryItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fact = _family == 'fact' ? _fact : null;
    final references = _references;
    final source = _prepared;
    final current = widget.current.conditionSource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_unsupported) ...[
          StudioNotice(
            'Condition avancée conservée : ${current?.label ?? widget.current.conditionLabel ?? current?.sourceId ?? 'référence existante'}. Pour la remplacer, choisissez une source puis appliquez explicitement.',
          ),
          const SizedBox(height: 12),
        ],
        StudioSelect(
          label: 'Source de la condition',
          value: _family,
          options: _availableFamilies,
          onChanged: _selectFamily,
        ),
        const SizedBox(height: 12),
        if (_isMapSource) ...[
          StudioSelect(
            key: const ValueKey('scene-condition-map'),
            label: 'Carte',
            value: _mapId,
            options: _maps,
            onChanged: (value) => setState(() {
              _mapId = value;
              _id = null;
              _loadReferenceMap();
            }),
          ),
          if (_mapLoading)
            const StudioNotice('Chargement des entités de la carte…'),
          if (_mapError != null) StudioNotice(_mapError!, isError: true),
          if (_mapId != null && !_maps.containsKey(_mapId))
            const StudioNotice(
              'La carte référencée est absente ou ambiguë. La condition actuelle est conservée.',
              isError: true,
            ),
          const SizedBox(height: 12),
        ],
        if (_family == 'inventoryItem') ...[
          if (_itemsLoading)
            const StudioNotice('Chargement des objets du projet…'),
          if (_itemsError != null) StudioNotice(_itemsError!, isError: true),
        ],
        if (_family != 'pokedexCaughtCount' && _family != 'partyState')
          StudioSelect(
            label: 'Référence',
            value: _id,
            options: references,
            onChanged: _selectReference,
          ),
        if (_family != 'pokedexCaughtCount' &&
            _family != 'partyState' &&
            !_referencesLoading &&
            references.isEmpty) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'Aucune référence disponible dans ce projet. La condition actuelle reste conservée.',
          ),
        ],
        if (_id != null &&
            !_referencesLoading &&
            _family != 'partyState' &&
            _family != 'pokedexCaughtCount' &&
            !references.containsKey(_id)) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'La référence actuelle est absente ou ambiguë. Elle reste conservée tant qu’aucune nouvelle condition n’est appliquée.',
            isError: true,
          ),
        ],
        if (_family == 'inventoryItem' && !_unsupported) ...[
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-inventory-minimum'),
            label: 'Quantité minimale',
            value: _minimumQuantity,
            onChanged: (value) => setState(() => _minimumQuantity = value),
          ),
          if (int.tryParse(_minimumQuantity) case final minimum?
              when minimum < 1 || '$minimum' != _minimumQuantity)
            const StudioNotice(
              'Choisissez un nombre entier positif.',
              isError: true,
            ),
          if (int.tryParse(_minimumQuantity) == null)
            const StudioNotice(
              'Choisissez un nombre entier positif.',
              isError: true,
            ),
        ],
        if (_family == 'mapEventInstanceBoolean' && !_unsupported) ...[
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('scene-instance-boolean-key'),
            label: 'Nom de l’état local',
            value: _instanceKey,
            onChanged: (value) => setState(() => _instanceKey = value),
          ),
          const SizedBox(height: 8),
          const StudioNotice(
            'Cet état appartient à l’entité choisie dans l’instance courante de la carte. Son nom doit correspondre à celui utilisé par les actions qui le modifient.',
          ),
          if (_instanceKey.isEmpty || _instanceKey.trim() != _instanceKey)
            const StudioNotice(
              'Choisissez un nom non vide, sans espace au début ni à la fin.',
              isError: true,
            ),
        ],
        const SizedBox(height: 12),
        if (_family == 'partyState' && !_unsupported) ...[
          StudioSelect(
            key: const ValueKey('scene-party-kind'),
            label: 'Condition d’équipe',
            value: _partyKind.name,
            options: {
              for (final kind in ScenePartyConditionKind.values)
                kind.name: kind.label,
            },
            onChanged: (value) {
              setState(() {
                _partyKind = ScenePartyConditionKind.values.byName(value);
                _id = null;
                _ability = null;
                _moveRequest++;
                _movesLoading = false;
                _moves = const {};
              });
              if (_partyKind == ScenePartyConditionKind.knowsMove ||
                  _partyKind == ScenePartyConditionKind.hasUsableMove) {
                _loadPartyMoves();
              }
            },
          ),
          const SizedBox(height: 12),
          if (_partyKind == ScenePartyConditionKind.knowsMove ||
              _partyKind == ScenePartyConditionKind.hasUsableMove) ...[
            StudioSelect(
              key: const ValueKey('scene-party-move'),
              label: 'Capacité de l’équipe',
              value: _id,
              options: _moves,
              onChanged: (value) => setState(() => _id = value),
            ),
            if (_movesLoading)
              const StudioNotice('Chargement des capacités du projet…'),
            if (_movesError != null) StudioNotice(_movesError!, isError: true),
            if (!_movesLoading && _movesError == null && _moves.isEmpty)
              const StudioNotice(
                'Aucune capacité disponible dans le catalogue du projet.',
              ),
          ],
          if (_partyKind == ScenePartyConditionKind.canUseFieldAbility)
            StudioSelect(
              key: const ValueKey('scene-party-ability'),
              label: 'Capacité de terrain',
              value: _ability?.moveId,
              options: {
                for (final ability in FieldAbility.values)
                  ability.moveId: _abilityLabel(ability),
              },
              onChanged: (value) => setState(
                () => _ability = FieldAbility.values.singleWhere(
                  (ability) => ability.moveId == value,
                ),
              ),
            ),
          const SizedBox(height: 12),
          StudioSelect(
            key: const ValueKey('scene-party-expected'),
            label: 'Condition remplie',
            value: '$_boolean',
            options: const {'true': 'Oui', 'false': 'Non'},
            onChanged: (value) => setState(() => _boolean = value == 'true'),
          ),
          const SizedBox(height: 8),
          StudioNotice(switch (_partyKind) {
            ScenePartyConditionKind.canReceivePokemon => 'Vérifie une place dans l’équipe, puis dans le PC. Aucun Pokémon n’est reçu par cette condition.',
            ScenePartyConditionKind.knowsMove =>
              'Un membre connaît cette capacité, même K.O. ou sans PP.',
            ScenePartyConditionKind.hasUsableMove => 'Un membre non K.O. connaît cette capacité et possède au moins un PP.',
            ScenePartyConditionKind.canUseFieldAbility => 'La capacité de terrain doit être prise en charge et débloquée ; un membre non K.O. doit la connaître. Aucun PP requis, y compris à PP0 ; aucun PP n’est consommé.',
          }),
          if (_partyKind == ScenePartyConditionKind.canUseFieldAbility &&
              widget.project.settings.dimension == ProjectDimension.threeD)
            const StudioNotice(
              'Les capacités de terrain sont actuellement disponibles dans le Player 2D ; elles ne sont pas disponibles dans les projets 3D. La condition est donc fausse en 3D, et sa négation reste utilisable.',
            ),
        ] else if (_family == 'pokedexCaughtCount' && !_unsupported) ...[
          StudioDraftField(
            key: const ValueKey('pokedex-first-national'),
            label: 'Premier numéro du Pokédex national',
            value: _firstNational,
            onChanged: (value) => setState(() => _firstNational = value),
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('pokedex-last-national'),
            label: 'Dernier numéro du Pokédex national',
            value: _lastNational,
            onChanged: (value) => setState(() => _lastNational = value),
          ),
          const SizedBox(height: 12),
          StudioDraftField(
            key: const ValueKey('pokedex-minimum-count'),
            label: 'Nombre d’espèces capturées',
            value: _minimumCount,
            onChanged: (value) => setState(() => _minimumCount = value),
          ),
          const SizedBox(height: 12),
          StudioSelect(
            label: 'Comparaison',
            value: '$_boolean',
            options: const {
              'true': 'Au moins ce nombre',
              'false': 'Moins que ce nombre',
            },
            onChanged: (value) => setState(() => _boolean = value == 'true'),
          ),
          if (source == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: StudioNotice(
                'Choisissez des numéros ordonnés et un nombre entier positif, au plus 65 535.',
                isError: true,
              ),
            ),
        ] else if (fact != null) ...[
          StudioSelect(
            label: 'Comparaison',
            value: _operator.name,
            options: {
              for (final value in fact.valueKind.compatibleOperators)
                value.name: operators[value.name]!,
            },
            onChanged: (value) => setState(
              () => _operator = NarrativeFactOperator.values.byName(value),
            ),
          ),
          const SizedBox(height: 12),
          if (fact.valueKind == NarrativeValueKind.boolean)
            StudioSelect(
              label: 'Valeur attendue',
              value: '$_boolean',
              options: const {'true': 'Oui', 'false': 'Non'},
              onChanged: (value) => setState(() => _boolean = value == 'true'),
            )
          else
            StudioDraftField(
              label: fact.valueKind == NarrativeValueKind.integer
                  ? 'Nombre entier attendu'
                  : 'Texte attendu',
              value: _text,
              onChanged: (value) => setState(() => _text = value),
            ),
          if (source == null && !_unsupported)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: StudioNotice(
                'Saisissez une valeur compatible avec cet état.',
                isError: true,
              ),
            ),
        ] else if (_id != null && references.containsKey(_id))
          StudioSelect(
            label: _family == 'storyStepCompletion'
                ? 'État de l’étape'
                : _family == 'playerFacing'
                ? 'Regarde dans cette direction'
                : _family == 'trainerDefeated'
                ? 'Dresseur déjà vaincu'
                : _family == 'badge'
                ? 'Badge obtenu'
                : _family == 'inventoryItem'
                ? 'Présent en quantité suffisante'
                : _family == 'playerAtEntityAnchor'
                ? 'Joueur à cette position'
                : _family == 'mapEventInstanceBoolean' ||
                      _family == 'factLikeStoryFlag'
                ? 'État activé'
                : 'Déjà jouée',
            value: '$_boolean',
            options: _family == 'storyStepCompletion'
                ? const {'true': 'Terminée', 'false': 'Non terminée'}
                : const {'true': 'Oui', 'false': 'Non'},
            onChanged: (value) => setState(() => _boolean = value == 'true'),
          ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Appliquer la condition',
          onPressed: source == null
              ? null
              : () {
                  final latest = _prepared;
                  if (latest != null) widget.onApply(latest);
                },
        ),
        const SizedBox(height: 8),
        const Text('Oui : condition remplie\nNon : condition non remplie'),
      ],
    );
  }
}

String _abilityLabel(FieldAbility ability) => switch (ability) {
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
