import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  test('a scoped catalog loads its encounter tables when the rubric opens', () async {
    const table = ProjectEncounterTable(
      id: 'puits',
      name: 'Puits',
      encounterKind: EncounterKind.walk,
    );
    final port = ScopedTestMapPort(
      metadata: scopedMapMetadata.copyWith(encounterTables: const [table]),
    );
    final maps = MapWorkspaceController(scopedMapSession, port)
      ..project = scopedMapMetadata;
    addTearDown(maps.dispose);
    var changes = 0;
    final binding = MapBuilderGameplayBinding(
      maps: maps,
      view: () => null,
      port: null,
      isActive: () => true,
      changed: () => changes++,
      labels: () => lookupAppLocalizations(const Locale('fr')),
    );

    expect(binding.encounterTablesReady, isFalse);
    binding.openRubric('spawns');
    await pumpEventQueue();
    expect(port.workshops, isEmpty);

    binding.openRubric('encounters');
    await pumpEventQueue();

    expect(port.workshops, [MapWorkspaceWorkshop.pokemon]);
    expect(binding.encounterTablesReady, isTrue);
    expect(binding.encounterTablesError, isNull);
    expect(maps.project!.encounterTables, [table]);
    expect(changes, greaterThan(2));
  });
}
