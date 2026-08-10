import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import '../design_system/design_system.dart';
import '../panels/encounter_tables_panel.dart';
import '../panels/trainer_library_panel.dart';

const encounterStudioPanelKey = ValueKey<String>('encounter-studio-panel');
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
    final selectedTableId = ref.watch(
      editorNotifierProvider.select((state) => state.encounterStudioTableId),
    );
    final notifier = ref.read(editorNotifierProvider.notifier);

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: PokeMapPageSurface(
        key: encounterStudioPanelKey,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                EncounterStudioSection.wildEncounters => EncounterTablesPanel(
                  selectedTableId: selectedTableId,
                ),
                EncounterStudioSection.trainers => const TrainerLibraryPanel(),
              },
            ),
          ],
        ),
      ),
    );
  }
}
