import 'package:avelune_studio/presentation/features/terrains/terrain_usage_summary.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('each Smart Tile usage states its real map capability', () {
    expect(terrainUsageLabel(SmartTileUsage.path), 'Chemin automatique');
    expect(terrainUsageLabel(SmartTileUsage.terrain), 'Sol automatique');
    expect(terrainUsageLabel(SmartTileUsage.forestSurface), 'Surface de forêt');
    expect(
      terrainUsageExplanation(SmartTileUsage.path),
      contains('par-dessus le sol'),
    );
    expect(
      terrainUsageExplanation(SmartTileUsage.terrain),
      contains('un seul sol automatique'),
    );
    expect(
      terrainUsageExplanation(SmartTileUsage.forestSurface),
      contains('cartes 3D ne l’acceptent pas'),
    );
  });

  testWidgets('the workshop names the usage of the draft it edits', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: const Scaffold(
          body: TerrainUsageSummary(usage: SmartTileUsage.terrain),
        ),
      ),
    );
    expect(find.text('Sol automatique'), findsOneWidget);
    expect(find.textContaining('un seul sol automatique'), findsOneWidget);
    expect(find.text('Chemin automatique'), findsNothing);
  });
}
