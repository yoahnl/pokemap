import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_gameplay/map_gameplay.dart' as gameplay;

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';

const _statLabels = {
  'hp': 'PV',
  'attack': 'Attaque',
  'defense': 'Défense',
  'specialAttack': 'Attaque Spé.',
  'specialDefense': 'Défense Spé.',
  'speed': 'Vitesse',
};

String _natureLabel(String id) {
  final effect = canonicalPokemonNatureEffect(id);
  final name = '${id[0].toUpperCase()}${id.substring(1)}';
  if (effect.increasedStat == null) return '$name — neutre';
  return '$name — ${_statLabels[effect.increasedStat!.name]} +10%, ${_statLabels[effect.decreasedStat!.name]} −10%';
}

class PokemonCombatTrainerStats extends StatefulWidget {
  const PokemonCombatTrainerStats({
    super.key,
    required this.trainerId,
    required this.indexInTeam,
    required this.member,
    required this.combat,
    this.loadSpecies,
  });

  final String trainerId;
  final int indexInTeam;
  final ProjectTrainerPokemonEntry member;
  final PokemonCombatController combat;
  final Future<PokemonSpeciesFile?> Function(String id)? loadSpecies;

  @override
  State<PokemonCombatTrainerStats> createState() =>
      _PokemonCombatTrainerStatsState();
}

class _PokemonCombatTrainerStatsState extends State<PokemonCombatTrainerStats> {
  Future<PokemonSpeciesFile?>? _species;

  @override
  void initState() {
    super.initState();
    _loadSpecies();
  }

  @override
  void didUpdateWidget(covariant PokemonCombatTrainerStats oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member.speciesId != widget.member.speciesId) _loadSpecies();
  }

  void _loadSpecies() {
    _species = widget.loadSpecies?.call(widget.member.speciesId);
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final combat = widget.combat;
    final index = widget.indexInTeam;
    final prefix = '${widget.trainerId}:$index';
    final advanced =
        member.natureId != null || member.ivs != null || member.evs != null;
    final ivs = member.ivs ?? standardTrainerPokemonIvs;
    final evs = member.evs ?? standardTrainerPokemonEvs;
    final total = evs.toJson().values.cast<int>().fold(0, (a, b) => a + b);
    final hasDraftError = combat.fieldErrors.keys.any(
      (key) => key.startsWith('team$index:'),
    );
    final invalidEvDraft = combat.fieldErrors.keys.any(
      (key) =>
          key.startsWith('team$index:evs:') && key != 'team$index:evs:total',
    );
    final valid =
        !hasDraftError &&
        validateTrainerPokemonStats(member).isEmpty &&
        member.level >= 1 &&
        member.level <= 100;
    return StudioPanel(
      title: 'Statistiques individuelles',
      compact: true,
      children: [
        StudioSelect(
          key: ValueKey('$prefix:stats-mode'),
          label: 'Mode',
          value: advanced ? 'advanced' : 'standard',
          options: const {
            'standard': 'Standard',
            'advanced': 'Personnaliser (avancé)',
          },
          onChanged: combat.saving
              ? null
              : (mode) => combat.setTrainerStatsMode(index, mode == 'advanced'),
        ),
        if (advanced) ...[
          const SizedBox(height: 12),
          StudioSelect(
            key: ValueKey('$prefix:nature'),
            label: 'Nature',
            value: member.natureId ?? standardTrainerPokemonNatureId,
            options: {
              for (final id in canonicalPokemonNatureIds) id: _natureLabel(id),
            },
            onChanged: combat.saving
                ? null
                : (id) => combat.setTrainerNature(index, id),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final group in {
                'ivs': (ivs, 'IV'),
                'evs': (evs, 'EV'),
              }.entries)
                for (final stat in trainerPokemonStatKeys)
                  SizedBox(
                    width: 160,
                    child: StudioDraftField(
                      key: ValueKey('$prefix:${group.key}:$stat'),
                      label: '${group.value.$2} ${_statLabels[stat]}',
                      value: combat.numericValue(
                        'team$index:${group.key}:$stat',
                        group.value.$1.toJson()[stat] as int,
                      ),
                      errorText:
                          combat.fieldErrors['team$index:${group.key}:$stat'],
                      keyboardType: TextInputType.number,
                      enabled: !combat.saving,
                      onChanged: (raw) =>
                          combat.editTrainerStat(index, group.key, stat, raw),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total EV : ${invalidEvDraft ? '—' : total}/510',
            key: ValueKey('$prefix:ev-total'),
          ),
          if (combat.fieldErrors['team$index:evs:total'] case final error?)
            Text(error),
        ],
        const SizedBox(height: 12),
        FutureBuilder<PokemonSpeciesFile?>(
          future: _species,
          builder: (context, snapshot) {
            final species =
                snapshot.connectionState == ConnectionState.done &&
                    snapshot.data?.id == member.speciesId
                ? snapshot.data
                : null;
            gameplay.PokemonCalculatedStats? stats;
            if (valid && species != null) {
              final base = species.baseStats;
              try {
                stats = gameplay.calculateTrainerPokemonStats(
                  member: member,
                  baseStats: gameplay.PokemonBaseStats(
                    hp: base.hp,
                    attack: base.atk,
                    defense: base.def,
                    specialAttack: base.spa,
                    specialDefense: base.spd,
                    speed: base.spe,
                  ),
                );
              } on ArgumentError {
                stats = null;
              }
            }
            final calculated = stats;
            if (calculated == null) {
              return Text(
                valid
                    ? 'Aperçu indisponible : statistiques de base de l’espèce non chargées.'
                    : 'Aperçu indisponible : corrigez les valeurs saisies.',
              );
            }
            return Wrap(
              key: ValueKey('$prefix:stats-preview'),
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final stat in {
                  'hp': calculated.maxHp,
                  'attack': calculated.attack,
                  'defense': calculated.defense,
                  'specialAttack': calculated.specialAttack,
                  'specialDefense': calculated.specialDefense,
                  'speed': calculated.speed,
                }.entries)
                  Text(
                    '${_statLabels[stat.key]} : ${stat.value}',
                    key: ValueKey('$prefix:preview:${stat.key}'),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
