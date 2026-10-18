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
  });
  final ProjectManifest project;
  final SceneConditionPayload current;
  final ValueChanged<SceneConditionSource> onApply;
  final Future<Map<String, String>> Function()? loadMoves;
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

  Map<String, String> get _availableFamilies => {
    for (final entry in families.entries)
      if (entry.key != 'pokedexCaughtCount' ||
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
        old.loadMoves != widget.loadMoves) {
      _reset();
    }
  }

  void _reset() {
    final source = widget.current.conditionSource;
    _family = source?.sourceKind.name ?? 'fact';
    _id = source?.sourceId;
    _operator = NarrativeFactOperator.equals;
    _boolean = true;
    _text = '';
    _unsupported = source != null && !_availableFamilies.containsKey(_family);
    if (_unsupported || source == null) return;
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

  NarrativeFactDefinition? get _fact =>
      widget.project.facts.where((fact) => fact.id == _id).firstOrNull;

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
    if (_unsupported || id == null || !_references.containsKey(id)) return null;
    final existing = widget.current.conditionSource;
    final debug =
        existing?.sourceId == id && existing?.sourceKind.name == _family
        ? existing?.debugTechnicalLabel
        : null;
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
          onChanged: (value) => setState(() {
            _family = value;
            _id = null;
            _unsupported = false;
          }),
        ),
        const SizedBox(height: 12),
        if (_family != 'pokedexCaughtCount' && _family != 'partyState')
          StudioSelect(
            label: 'Référence',
            value: _id,
            options: references,
            onChanged: _selectReference,
          ),
        if (_family != 'pokedexCaughtCount' &&
            _family != 'partyState' &&
            references.isEmpty) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'Aucune référence disponible dans ce projet. La condition actuelle reste conservée.',
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
  FieldAbility.dive => 'Plongée',
  FieldAbility.fly => 'Vol',
};
