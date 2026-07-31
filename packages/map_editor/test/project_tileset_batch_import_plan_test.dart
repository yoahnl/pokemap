import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/use_cases/project_tileset_batch_import_plan.dart';

void main() {
  test('plans every selected tileset once and preserves picker order', () {
    final plan = buildProjectTilesetBatchImportPlan([
      '/bundle/Tileset-Terrain-new grass.png',
      '/bundle/Atlas-Props-sheet1.png',
      '/bundle/Tileset-Terrain-new grass.png',
      '',
      '/bundle/platform - grass- coast - spritesheet.png',
    ]);

    expect(
      plan.map((item) => item.sourcePath),
      [
        '/bundle/Tileset-Terrain-new grass.png',
        '/bundle/Atlas-Props-sheet1.png',
        '/bundle/platform - grass- coast - spritesheet.png',
      ],
    );
    expect(
      plan.map((item) => item.suggestedName),
      [
        'Tileset-Terrain-new grass',
        'Atlas-Props-sheet1',
        'platform - grass- coast - spritesheet',
      ],
    );
  });
}
