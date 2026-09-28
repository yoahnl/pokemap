import 'package:avelune_studio/features/pokemon/data/local_pokemon_combat_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_combat_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart';
import 'm3_story_fixture.dart';

final class UiPokemonCombatPort implements PokemonCombatPort {
  const UiPokemonCombatPort(this.source, this.tester);

  factory UiPokemonCombatPort.forFixture(
    M3StoryFixture fixture,
    WidgetTester tester,
  ) => UiPokemonCombatPort(
    LocalPokemonCombatAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    ),
    tester,
  );

  final PokemonCombatPort source;
  final WidgetTester tester;

  @override
  Future<PokemonCombatSnapshot> load() async =>
      (await WidgetResourcePort.serial(tester, source.load))!;

  @override
  Future<void> saveTable(
    ProjectEncounterTable? before,
    ProjectEncounterTable after,
  ) => _write(() => source.saveTable(before, after));

  @override
  Future<void> deleteTable(ProjectEncounterTable before) =>
      _write(() => source.deleteTable(before));

  @override
  Future<void> saveTrainer(
    ProjectTrainerEntry? before,
    ProjectTrainerEntry after,
  ) => _write(() => source.saveTrainer(before, after));

  @override
  Future<void> deleteTrainer(ProjectTrainerEntry before) =>
      _write(() => source.deleteTrainer(before));

  Future<void> _write(Future<void> Function() operation) async {
    final outcome = await WidgetResourcePort.serial<Object?>(tester, () async {
      try {
        await operation();
        return null;
      } on Object catch (failure) {
        return failure;
      }
    });
    if (outcome != null) throw outcome;
  }
}
