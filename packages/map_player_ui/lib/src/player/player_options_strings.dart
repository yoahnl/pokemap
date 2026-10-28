import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

enum PlayerOptionsCategory {
  general,
  display,
  audio,
  controls,
  language,
  weather,
  time,
  accessibility
}

final class PlayerOptionsStrings {
  const PlayerOptionsStrings._(this.french);

  factory PlayerOptionsStrings.of(BuildContext context) =>
      PlayerOptionsStrings._(
          Localizations.localeOf(context).languageCode == 'fr');

  final bool french;

  String text(String fr, String en) => french ? fr : en;
  String category(PlayerOptionsCategory value) => switch (value) {
        PlayerOptionsCategory.general => text('Général', 'General'),
        PlayerOptionsCategory.weather => text('Météo', 'Weather'),
        PlayerOptionsCategory.time => text('Heure', 'Time'),
        PlayerOptionsCategory.display => text('Affichage', 'Display'),
        PlayerOptionsCategory.audio => text('Son', 'Sound'),
        PlayerOptionsCategory.controls => text('Commandes', 'Controls'),
        PlayerOptionsCategory.language => text('Langue', 'Language'),
        PlayerOptionsCategory.accessibility =>
          text('Accessibilité', 'Accessibility'),
      };

  String speed(RuntimeDialogueTextSpeed value) => switch (value) {
        RuntimeDialogueTextSpeed.slow => text('Lente', 'Slow'),
        RuntimeDialogueTextSpeed.normal => text('Normale', 'Normal'),
        RuntimeDialogueTextSpeed.fast => text('Rapide', 'Fast'),
        RuntimeDialogueTextSpeed.instant => text('Instantanée', 'Instant'),
      };

  String effects(RuntimePlayerMenuEffects value) => switch (value) {
        RuntimePlayerMenuEffects.full => text('Complet', 'Full'),
        RuntimePlayerMenuEffects.reduced => text('Réduit', 'Reduced'),
        RuntimePlayerMenuEffects.opaque => text('Sans transparence', 'Opaque'),
      };

  String help(PlayerOptionsCategory value) => switch (value) {
        PlayerOptionsCategory.weather => text('Choisissez la source de la météo réelle. Les scènes du jeu gardent la priorité.', 'Choose the source for real weather. Story scenes keep priority.'),
        PlayerOptionsCategory.time => text(
            'L’heure réelle suit l’horloge prévue par le jeu, souvent celle de l’appareil. Une heure choisie fige le jour et la nuit, et les événements liés à l’heure la suivent. Les scènes du jeu gardent la priorité.',
            'Real time follows the clock the game intends, usually the device clock. A chosen hour freezes day and night, and time-based events follow it. Story scenes keep priority.'),
        PlayerOptionsCategory.general => text(
            'Choisissez la vitesse d’affichage des dialogues.',
            'Choose how quickly dialogue text appears.'),
        PlayerOptionsCategory.display => text(
            'Une limite d’images plus basse réduit la consommation. La fréquence réelle dépend de l’écran et de l’appareil. Les effets du menu : Réduit limite leurs animations ; Sans transparence utilise des panneaux opaques. La résolution 3D garde le format de l’image ; plus basse, elle soulage l’appareil, et la mise à l’échelle choisit comment l’image est agrandie jusqu’à l’écran. Les effets du décor restent ceux du jeu tant que vous ne les désactivez pas.',
            'A lower frame rate limit reduces power use. The actual rate depends on the display and device. Menu effects: Reduced limits their animations; Opaque uses solid panels. 3D resolution keeps the image format; lower values lighten the load, and upscaling chooses how the image is enlarged to the screen. Scene effects stay as the game intends until you turn them off.'),
        PlayerOptionsCategory.audio => text(
            'Le volume principal règle tous les canaux. À 0 %, le son est coupé. Les touches gauche et droite ajustent le volume par pas de 5 %.',
            'Master volume controls every channel. At 0%, sound is muted. Left and right adjust volume in steps of 5%.'),
        PlayerOptionsCategory.controls => text(
            'Les repères suivent les commandes actuelles. Les doublons sont refusés pour garder chaque action accessible. L’opacité concerne les commandes tactiles affichées en jeu.',
            'Hints follow the current bindings. Duplicate inputs are rejected to keep every action accessible. Opacity affects the touch controls shown in game.'),
        PlayerOptionsCategory.language => text(
            'La langue de l’interface change les menus du Player. Les dialogues et la narration du projet conservent leur langue d’origine.',
            'Interface language changes the Player menus. The project’s dialogue and story keep their original language.'),
        PlayerOptionsCategory.accessibility => text(
            'Adaptez la lisibilité à votre confort. La réduction des animations demandée par le système reste prioritaire.',
            'Adjust readability for your comfort. Reduced motion requested by the system still takes priority.'),
      };

  String get scope => text('Réglages enregistrés sur cet appareil.',
      'Settings saved on this device.');
  String get back => text('Retour', 'Back');
  String get categories => text('Catégories', 'Categories');
  String get defaults => text('Par défaut', 'Defaults');
  String get cancel => text('Annuler', 'Cancel');
  String get restore => text('Rétablir', 'Restore');
  String get saving => text('Enregistrement…', 'Saving…');
  String get error => text(
      'Impossible d’enregistrer les réglages. Les dernières valeurs enregistrées ont été conservées. Réessayez.',
      'Could not save settings. The last saved values have been kept. Please try again.');
  String get returnToTitle => text('Retour au titre', 'Return to title');
  String get textSpeed => text('Vitesse des textes', 'Text speed');
  String get menuEffects => text('Effets du menu', 'Menu effects');
  String get frameRateLimit => text('Images par seconde', 'Frames per second');
  String get renderScale => text('Résolution 3D', '3D resolution');
  String renderScaleValue(int? percent) => switch (percent) {
        final value? => '$value %',
        _ => text('Auto (selon l’appareil)', 'Auto (per device)'),
      };
  String get upscaling => text('Mise à l’échelle 3D', '3D upscaling');
  String upscalingValue(RuntimeUpscaling value) => switch (value) {
        RuntimeUpscaling.nearest => text('Pixels nets', 'Sharp pixels'),
        RuntimeUpscaling.fsr1 => 'FSR 1 (AMD)',
      };
  String get depthOfField => text('Profondeur de champ', 'Depth of field');
  String get shadows => text('Ombres', 'Shadows');
  String get fogAndHalos => text('Brouillard et halos', 'Fog and halos');
  String get ambientAnimation => text('Ambiance animée', 'Animated ambience');
  String get worldTime => text('Heure du monde', 'World time');
  String worldTimeValue(RuntimeWorldTimePreferences value) =>
      switch (value.chosenMinuteOfDay) {
        final minute? =>
          '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}',
        _ => text('Heure réelle', 'Real time'),
      };
  String frameRate(int value) => '$value FPS';
  String get master => text('Volume principal', 'Master volume');
  String get music => text('Musique', 'Music');
  String get soundEffects => text('Effets sonores', 'Sound effects');
  String get interfaceLanguage =>
      text('Langue de l’interface', 'Interface language');
  String get textSize => text('Taille du texte', 'Text size');
  String get reducedMotion => text('Réduire les animations', 'Reduce motion');
  String get highContrast =>
      text('Renforcer le contraste', 'Increase contrast');
  String get haptics => text('Vibrations', 'Vibration');
  String get hints =>
      text('Afficher les aides de commandes', 'Show control hints');
  String get touchOpacity =>
      text('Opacité des commandes tactiles', 'Touch controls opacity');
  String get leftHandedTouchControls =>
      text('Joystick tactile à droite', 'Touch joystick on the right');
  String get touchRunMode => text('Course tactile', 'Touch running');
  String runningMode(RuntimePlayerTouchRunMode mode) => switch (mode) {
        RuntimePlayerTouchRunMode.gesture =>
          text('Course au geste', 'Run with a wider gesture'),
        RuntimePlayerTouchRunMode.walkOnly =>
          text('Marche seule', 'Walk only'),
        RuntimePlayerTouchRunMode.automatic =>
          text('Course automatique si permise', 'Run automatically when allowed'),
      };
  String resetTitle(PlayerOptionsCategory value) =>
      text('Rétablir ${category(value)} ?', 'Reset ${category(value)}?');
  String resetMessage(PlayerOptionsCategory value) => value ==
          PlayerOptionsCategory.controls
      ? text(
          'La course tactile, le côté du joystick, les aides et l’opacité des commandes seront rétablis. Les raccourcis clavier et manette restent inchangés.',
          'Touch running, joystick side, control hints and opacity will be reset. Keyboard and controller bindings will be kept.')
      : text(
          'Seuls les réglages de la catégorie « ${category(value)} » seront rétablis. Votre sauvegarde et les autres catégories seront conservées.',
          'Only the settings in “${category(value)}” will be reset. Your save and other categories will be kept.');
}
