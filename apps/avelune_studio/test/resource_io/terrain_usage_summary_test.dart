import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
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
}
