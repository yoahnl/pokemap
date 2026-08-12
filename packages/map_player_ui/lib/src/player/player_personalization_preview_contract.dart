import 'player_battle_scene.dart';
import 'player_dialogue_surface.dart';
import 'player_intro_video_surface.dart';
import 'player_title_surface.dart';
import 'runtime_player_pause_shell.dart';

enum PlayerPersonalizationPreviewScene {
  globalStyle,
  title,
  intro,
  pause,
  dialogue,
  battle,
}

abstract final class PlayerPersonalizationPreviewContract {
  static const Map<PlayerPersonalizationPreviewScene, List<Type>>
      productionWidgetTypes = <PlayerPersonalizationPreviewScene, List<Type>>{
    PlayerPersonalizationPreviewScene.globalStyle: <Type>[
      PlayerTitleSurface,
      PlayerDialogueSurface,
      RuntimePlayerPauseShell,
      PlayerBattleScene,
    ],
    PlayerPersonalizationPreviewScene.title: <Type>[PlayerTitleSurface],
    PlayerPersonalizationPreviewScene.intro: <Type>[
      PlayerIntroVideoSurface,
    ],
    PlayerPersonalizationPreviewScene.pause: <Type>[
      RuntimePlayerPauseShell,
    ],
    PlayerPersonalizationPreviewScene.dialogue: <Type>[
      PlayerDialogueSurface,
    ],
    PlayerPersonalizationPreviewScene.battle: <Type>[PlayerBattleScene],
  };
}
