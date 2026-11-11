import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_combat_controller.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../../features/pokemon/application/pokemon_trainer_stat_labels.dart';
import '../../../features/pokemon/coordination/pokemon_trainer_stats_preview.dart';

const _statLabels = pokemonStatLabels;

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
    final advanced = pokemonTrainerStatsAdvanced(member);
    final ivs = member.ivs ?? standardTrainerPokemonIvs;
    final evs = member.evs ?? standardTrainerPokemonEvs;
    final total = pokemonTrainerEvTotal(member, combat.fieldErrors.keys, index);
    final valid = pokemonTrainerStatsPreviewValid(
      member,
      combat.fieldErrors.keys,
      index,
    );
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
              for (final id in canonicalPokemonNatureIds) id: pokemonNatureLabel(id),
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
            'Total EV : ${total ?? '—'}/510',
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
            final calculated = pokemonTrainerStatsPreview(
              member: member,
              species: species,
              valid: valid,
            );
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
