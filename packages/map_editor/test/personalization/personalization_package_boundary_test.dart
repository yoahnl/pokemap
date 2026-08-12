import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/personalization_preview.dart';

void main() {
  test(
    'personalization feature uses only the dedicated player preview API',
    () {
      final feature = Directory('lib/src/features/personalization');
      final imports = feature
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .expand(
            (file) =>
                RegExp("import 'package:(map_player_ui|map_runtime)/[^']+';")
                    .allMatches(file.readAsStringSync())
                    .map((match) => match.group(0)),
          )
          .whereType<String>()
          .toSet()
          .toList();

      expect(imports, [
        "import 'package:map_player_ui/personalization_preview.dart';",
      ]);
    },
  );

  test(
    'player preview contract names every production surface composition',
    () {
      expect(
        PlayerPersonalizationPreviewContract.productionWidgetTypes.keys,
        PlayerPersonalizationPreviewScene.values,
      );
      expect(
        PlayerPersonalizationPreviewContract
            .productionWidgetTypes[PlayerPersonalizationPreviewScene
            .globalStyle],
        [
          PlayerTitleSurface,
          PlayerDialogueSurface,
          RuntimePlayerPauseShell,
          PlayerBattleScene,
        ],
      );
    },
  );
}
