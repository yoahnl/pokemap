import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../design_system/design_system.dart';
import '../panels/encounter_tables_panel.dart';
import '../panels/trainer_library_panel.dart';

const encounterStudioPanelKey = ValueKey<String>(
  'encounter-studio-panel',
);
const encounterStudioWildEncountersTabKey = ValueKey<String>(
  'encounter-studio-tab-wild-encounters',
);
const encounterStudioTrainersTabKey = ValueKey<String>(
  'encounter-studio-tab-trainers',
);

class EncounterStudioPanel extends ConsumerWidget {
  const EncounterStudioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(editorEncounterStudioSectionProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);

    return PokeMapPageSurface(
      key: encounterStudioPanelKey,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PokeMapSectionHeader(
            title: 'Encounter Studio',
            description:
                'Créez les rencontres sauvages et les dresseurs de votre projet.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapSegmentedTabs(
              tabs: [
                PokeMapSegmentedTab(
                  key: encounterStudioWildEncountersTabKey,
                  label: 'Rencontres sauvages',
                  icon: Icons.grass,
                  selected: section == EncounterStudioSection.wildEncounters,
                  onTap: () => notifier.selectEncounterStudioSection(
                    EncounterStudioSection.wildEncounters,
                  ),
                ),
                PokeMapSegmentedTab(
                  key: encounterStudioTrainersTabKey,
                  label: 'Dresseurs',
                  icon: Icons.groups_2_outlined,
                  selected: section == EncounterStudioSection.trainers,
                  onTap: () => notifier.selectEncounterStudioSection(
                    EncounterStudioSection.trainers,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: switch (section) {
              EncounterStudioSection.wildEncounters =>
                const EncounterTablesPanel(),
              EncounterStudioSection.trainers => const TrainerLibraryPanel(),
            },
          ),
        ],
      ),
    );
  }
}
