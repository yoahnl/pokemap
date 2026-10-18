import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';
import '../../design_system/design_system.dart';

class ScenePartyConditionEditor extends StatefulWidget {
  const ScenePartyConditionEditor({
    super.key,
    this.current,
    this.dimension = ProjectDimension.twoD,
    this.loadMoves,
    required this.onApply,
  });
  final SceneConditionSource? current;
  final ProjectDimension dimension;
  final Future<Map<String, String>> Function()? loadMoves;
  final Future<bool> Function(SceneConditionSource) onApply;
  @override
  State<ScenePartyConditionEditor> createState() =>
      _ScenePartyConditionEditorState();
}

class _ScenePartyConditionEditorState extends State<ScenePartyConditionEditor> {
  ScenePartyConditionKind kind = ScenePartyConditionKind.canReceivePokemon;
  String? moveId;
  FieldAbility? ability;
  bool expected = true, loading = false, saving = false;
  Map<String, String> moves = const {};
  String? error;
  int request = 0;
  @override
  void initState() {
    super.initState();
    reset();
  }

  @override
  void didUpdateWidget(ScenePartyConditionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current ||
        oldWidget.loadMoves != widget.loadMoves) {
      reset();
    }
  }

  void reset() {
    request++;
    final source = widget.current;
    kind =
        source?.partyConditionKind ?? ScenePartyConditionKind.canReceivePokemon;
    moveId = source?.partyMoveId;
    ability = source?.partyFieldAbility;
    expected = source?.partyExpected ?? true;
    moves = const {};
    loading = false;
    error = null;
    if (moveKind) load();
  }

  bool get moveKind =>
      kind == ScenePartyConditionKind.knowsMove ||
      kind == ScenePartyConditionKind.hasUsableMove;
  Future<void> load() async {
    final token = ++request;
    loading = true;
    error = null;
    try {
      final loader = widget.loadMoves;
      if (loader == null) throw StateError('Unavailable');
      final result = await loader();
      if (!mounted || token != request) return;
      setState(() => moves = result);
    } on Object {
      if (!mounted || token != request) return;
      setState(
        () => error =
            'Catalogue des capacités indisponible ou ambigu. La condition actuelle est conservée.',
      );
    } finally {
      if (mounted && token == request) setState(() => loading = false);
    }
  }

  SceneConditionSource? get prepared => switch (kind) {
    ScenePartyConditionKind.canReceivePokemon =>
      SceneConditionSource.partyCanReceivePokemon(
        expected: expected,
        label: kind.label,
      ),
    ScenePartyConditionKind.knowsMove =>
      !loading && moves.containsKey(moveId)
          ? SceneConditionSource.partyKnowsMove(
              moveId: moveId!,
              expected: expected,
              label: '${kind.label} : ${moves[moveId]}',
            )
          : null,
    ScenePartyConditionKind.hasUsableMove =>
      !loading && moves.containsKey(moveId)
          ? SceneConditionSource.partyHasUsableMove(
              moveId: moveId!,
              expected: expected,
              label: '${kind.label} : ${moves[moveId]}',
            )
          : null,
    ScenePartyConditionKind.canUseFieldAbility =>
      ability == null
          ? null
          : SceneConditionSource.partyCanUseFieldAbility(
              ability: ability!,
              expected: expected,
              label: '${kind.label} : ${_abilityLabel(ability!)}',
            ),
  };
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PokeMapDropdownField<String>(
        key: const ValueKey('scene-party-kind'),
        label: 'Condition d’équipe',
        value: kind.name,
        items: [
          for (final value in ScenePartyConditionKind.values)
            PokeMapDropdownItem(value: value.name, label: value.label),
        ],
        onChanged: (value) {
          setState(() {
            kind = ScenePartyConditionKind.values.byName(value);
            moveId = null;
            ability = null;
            moves = const {};
            request++;
            loading = false;
            error = null;
          });
          if (moveKind) load();
        },
      ),
      if (moveKind)
        PokeMapDropdownField<String>(
          key: const ValueKey('scene-party-move'),
          label: 'Capacité de l’équipe',
          value: moveId ?? '',
          items: [
            for (final entry in moves.entries)
              PokeMapDropdownItem(value: entry.key, label: entry.value),
          ],
          enabled: !loading && moves.isNotEmpty,
          onChanged: (value) => setState(() => moveId = value),
        ),
      if (kind == ScenePartyConditionKind.canUseFieldAbility)
        PokeMapDropdownField<String>(
          key: const ValueKey('scene-party-ability'),
          label: 'Capacité de terrain',
          value: ability?.moveId ?? '',
          items: [
            for (final value in FieldAbility.values)
              PokeMapDropdownItem(
                value: value.moveId,
                label: _abilityLabel(value),
              ),
          ],
          onChanged: (value) => setState(
            () => ability = FieldAbility.values.singleWhere(
              (ability) => ability.moveId == value,
            ),
          ),
        ),
      PokeMapDropdownField<String>(
        key: const ValueKey('scene-party-expected'),
        label: 'Condition remplie',
        value: '$expected',
        items: const [
          PokeMapDropdownItem(value: 'true', label: 'Oui'),
          PokeMapDropdownItem(value: 'false', label: 'Non'),
        ],
        onChanged: (value) => setState(() => expected = value == 'true'),
      ),
      if (moveKind &&
          !loading &&
          error == null &&
          moveId != null &&
          !moves.containsKey(moveId))
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.warning,
          message:
              'La capacité enregistrée est indisponible. Sa référence est conservée ; choisissez une capacité existante pour la remplacer.',
        ),
      if (loading) const Text('Chargement des capacités du projet…'),
      if (error != null)
        PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.warning,
          message: error!,
        ),
      Text(switch (kind) {
        ScenePartyConditionKind.canReceivePokemon =>
          'Vérifie une place dans l’équipe, puis dans le PC. Aucun Pokémon n’est reçu.',
        ScenePartyConditionKind.knowsMove =>
          'Inclut les membres K.O. et les capacités sans PP.',
        ScenePartyConditionKind.hasUsableMove =>
          'Un membre non K.O. doit connaître la capacité avec au moins un PP.',
        ScenePartyConditionKind.canUseFieldAbility =>
          'Capacité prise en charge et débloquée, connue d’un membre non K.O. Aucun PP requis, y compris à PP0 ; aucun PP n’est consommé.',
      }),
      if (kind == ScenePartyConditionKind.canUseFieldAbility &&
          widget.dimension == ProjectDimension.threeD)
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          message:
              'Les capacités de terrain sont actuellement disponibles dans le Player 2D ; elles ne sont pas disponibles dans les projets 3D. La condition est donc fausse en 3D, et sa négation reste utilisable.',
        ),
      PokeMapButton(
        key: const ValueKey('scene-party-apply'),
        onPressed: prepared == null || saving
            ? null
            : () async {
                final source = prepared;
                if (source == null) return;
                setState(() => saving = true);
                try {
                  final applied = await widget.onApply(source);
                  if (mounted && !applied) {
                    setState(
                      () => error =
                          'La condition n’a pas été appliquée. Vérifiez ses références.',
                    );
                  }
                } on Object {
                  if (mounted) {
                    setState(
                      () => error =
                          'La condition n’a pas été appliquée. Vérifiez ses références.',
                    );
                  }
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
        child: const Text('Appliquer la condition d’équipe'),
      ),
    ],
  );
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
