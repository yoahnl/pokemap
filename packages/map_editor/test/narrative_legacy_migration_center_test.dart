import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_legacy_migration_center.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';

void main() {
  testWidgets('shows every domain, blockers and backup gate', (tester) async {
    final opened = <NarrativeLegacyDomain>[];
    var backupCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            height: 700,
            child: NarrativeLegacyMigrationCenter(
              scan: _scan(),
              onCreateBackup: () => backupCount++,
              onOpenDomain: opened.add,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(narrativeLegacyMigrationCenterKey), findsOneWidget);
    for (final domain in NarrativeLegacyDomain.values) {
      expect(find.byKey(ValueKey('migration-domain-${domain.name}')),
          findsOneWidget);
    }
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('migration-center-backup')));
    final cinematicButton =
        find.byKey(const ValueKey('migration-open-cinematic'));
    await tester.ensureVisible(cinematicButton);
    await tester.pumpAndSettle();
    await tester.tap(cinematicButton);
    expect(backupCount, 1);
    expect(opened, [NarrativeLegacyDomain.cinematic]);
  });

  testWidgets('disables backup after complete retirement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: NarrativeLegacyMigrationCenter(
            scan: NarrativeLegacyMigrationScan(
              schemaVersion: 1,
              minimumProjectVersion: 'v1',
              domains: [
                for (final domain in NarrativeLegacyDomain.values)
                  NarrativeLegacyMigrationDomainScan(
                    domain: domain,
                    remainingCount: 0,
                    readyCount: 0,
                    blockerCount: 0,
                    lossRiskCount: 0,
                    dependencyCount: 0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final button = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey('migration-center-backup')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Readers legacy retirables'), findsOneWidget);
  });
}

NarrativeLegacyMigrationScan _scan() => NarrativeLegacyMigrationScan(
      schemaVersion: 1,
      minimumProjectVersion: 'v1',
      domains: const [
        NarrativeLegacyMigrationDomainScan(
          domain: NarrativeLegacyDomain.storyline,
          remainingCount: 1,
          readyCount: 1,
          blockerCount: 0,
          lossRiskCount: 0,
          dependencyCount: 0,
        ),
        NarrativeLegacyMigrationDomainScan(
          domain: NarrativeLegacyDomain.event,
          remainingCount: 2,
          readyCount: 0,
          blockerCount: 1,
          lossRiskCount: 1,
          dependencyCount: 3,
        ),
        NarrativeLegacyMigrationDomainScan(
          domain: NarrativeLegacyDomain.cinematic,
          remainingCount: 1,
          readyCount: 1,
          blockerCount: 0,
          lossRiskCount: 0,
          dependencyCount: 1,
        ),
      ],
    );
