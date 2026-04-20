import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/panels/battle_background_path_utils.dart';

void main() {
  group('normalizeProjectLocalBattleBackgroundPath', () {
    test('returns a project-relative posix path for in-project files', () {
      final relativePath = normalizeProjectLocalBattleBackgroundPath(
        projectRootPath: '/tmp/project',
        pickedAbsolutePath: '/tmp/project/assets/battle/forest.png',
      );

      expect(relativePath, 'assets/battle/forest.png');
    });

    test('rejects files that live outside the project root', () {
      final relativePath = normalizeProjectLocalBattleBackgroundPath(
        projectRootPath: '/tmp/project',
        pickedAbsolutePath: '/tmp/outside/forest.png',
      );

      expect(relativePath, isNull);
    });
  });

  group('normalizeOptionalBattleBackgroundRelativePath', () {
    test('returns null for empty input', () {
      expect(normalizeOptionalBattleBackgroundRelativePath(null), isNull);
      expect(normalizeOptionalBattleBackgroundRelativePath('   '), isNull);
    });

    test('normalizes windows separators into project-local posix paths', () {
      expect(
        normalizeOptionalBattleBackgroundRelativePath(
          r'assets\battle\cave.png',
        ),
        'assets/battle/cave.png',
      );
    });
  });
}
