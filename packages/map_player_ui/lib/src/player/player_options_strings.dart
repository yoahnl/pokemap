import 'package:flutter/widgets.dart';
import 'package:map_runtime/map_runtime.dart';

enum PlayerOptionsCategory {
  general,
  display,
  audio,
  controls,
  language,
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
        PlayerOptionsCategory.general => text(
            'Choisissez la vitesse d’affichage des dialogues.',
            'Choose how quickly dialogue text appears.'),
        PlayerOptionsCategory.display => text(
            'Les effets concernent les menus. Le mode Réduit limite leurs animations ; Sans transparence utilise des panneaux opaques.',
            'These effects apply to menus. Reduced limits their animations; Opaque uses solid panels.'),
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
  String resetTitle(PlayerOptionsCategory value) =>
      text('Rétablir ${category(value)} ?', 'Reset ${category(value)}?');
  String resetMessage(PlayerOptionsCategory value) => value ==
          PlayerOptionsCategory.controls
      ? text(
          'Les aides et l’opacité des commandes tactiles seront rétablies. Les touches restent inchangées ; utilisez Réinitialiser dans cette catégorie pour rétablir celles du périphérique affiché.',
          'Control hints and touch controls opacity will be reset. Bindings are kept; use Reset in this category to restore the displayed device’s bindings.')
      : text(
          'Seuls les réglages de la catégorie « ${category(value)} » seront rétablis. Votre sauvegarde et les autres catégories seront conservées.',
          'Only the settings in “${category(value)}” will be reset. Your save and other categories will be kept.');
}
