import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final class PokeMapPlayerLocalizations {
  const PokeMapPlayerLocalizations._(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[Locale('fr'), Locale('en')];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _PokeMapPlayerLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static PokeMapPlayerLocalizations of(BuildContext context) =>
      Localizations.of<PokeMapPlayerLocalizations>(
        context,
        PokeMapPlayerLocalizations,
      ) ??
      lookup(const Locale('en'));

  static PokeMapPlayerLocalizations lookup(Locale locale) =>
      PokeMapPlayerLocalizations._(
        Locale(locale.languageCode == 'fr' ? 'fr' : 'en'),
      );

  bool get _fr => locale.languageCode == 'fr';

  String get appName => 'PokeMap Hub';
  String get home => _fr ? 'Accueil' : 'Home';
  String get library => _fr ? 'Bibliothèque' : 'Library';
  String get preferences => _fr ? 'Préférences' : 'Preferences';
  String get diagnostics => _fr ? 'Diagnostics' : 'Diagnostics';
  String get installedGames => _fr ? 'Jeux installés' : 'Installed games';
  String get recentGames => _fr ? 'Jeux récents' : 'Recent games';
  String get resumeLastGame =>
      _fr ? 'Reprendre la dernière partie' : 'Resume last game';
  String get importGame => _fr ? 'Importer un jeu' : 'Import a game';
  String get emptyLibraryTitle =>
      _fr ? 'Votre bibliothèque vous attend' : 'Your library is ready';
  String get emptyLibraryMessage => _fr
      ? 'Importez un package de jeu compatible pour commencer une aventure.'
      : 'Import a compatible game package to begin an adventure.';
  String get searchGames => _fr ? 'Rechercher un jeu' : 'Search games';
  String get continueGame => _fr ? 'Continuer' : 'Continue';
  String get newGame => _fr ? 'Nouveau jeu' : 'New game';
  String get load => _fr ? 'Charger' : 'Load';
  String get options => _fr ? 'Options' : 'Options';
  String get creditsAbout => _fr ? 'Crédits / À propos' : 'Credits / About';
  String get returnToHub => _fr ? 'Retour au Hub' : 'Back to Hub';
  String get pause => _fr ? 'Pause' : 'Pause';
  String get resume => _fr ? 'Reprendre' : 'Resume';
  String get party => _fr ? 'Équipe' : 'Party';
  String get bag => _fr ? 'Sac' : 'Bag';
  String get pokedex => 'Pokédex';
  String get map => _fr ? 'Carte' : 'Map';
  String get save => _fr ? 'Sauvegarder' : 'Save';
  String get returnToTitle => _fr ? 'Retour au titre' : 'Back to title';
  String get play => _fr ? 'Jouer' : 'Play';
  String get update => _fr ? 'Mettre à jour' : 'Update';
  String get repair => _fr ? 'Réparer' : 'Repair';
  String get manageSaves => _fr ? 'Gérer les sauvegardes' : 'Manage saves';
  String get uninstall => _fr ? 'Désinstaller' : 'Uninstall';
  String get version => _fr ? 'Version' : 'Version';
  String get author => _fr ? 'Auteur' : 'Author';
  String get lastSave => _fr ? 'Dernière sauvegarde' : 'Latest save';
  String get playTime => _fr ? 'Temps de jeu' : 'Play time';
  String get noSave => _fr ? 'Aucune sauvegarde' : 'No save';
  String get loading => _fr ? 'Chargement' : 'Loading';
  String get cancel => _fr ? 'Annuler' : 'Cancel';
  String get showCredits => _fr ? 'Voir les crédits' : 'View credits';
  String get retry => _fr ? 'Réessayer' : 'Retry';
  String get close => _fr ? 'Fermer' : 'Close';
  String get language => _fr ? 'Langue' : 'Language';
  String get appearance => _fr ? 'Apparence' : 'Appearance';
  String get accessibility => _fr ? 'Accessibilité' : 'Accessibility';
  String get audio => _fr ? 'Audio' : 'Audio';
  String get reducedMotion => _fr ? 'Réduire les animations' : 'Reduce motion';
  String get highContrast => _fr ? 'Contraste renforcé' : 'High contrast';
  String get haptics => _fr ? 'Vibrations' : 'Haptics';
  String get textSize => _fr ? 'Taille du texte' : 'Text size';
  String get inputHints => _fr ? 'Afficher les commandes' : 'Show controls';
  String get touchControlsOpacity =>
      _fr ? 'Opacité des commandes tactiles' : 'Touch controls opacity';
  String get launchMostRecentGameOnStartup => _fr
      ? 'Lancer directement le dernier jeu'
      : 'Launch the latest game directly';
  String get launchMostRecentGameOnStartupDescription => _fr
      ? 'Au démarrage, ouvre le jeu jouable le plus récent sans afficher '
          'l’accueil du Hub.'
      : 'At startup, open the most recent playable game without showing the '
          'Hub home screen.';
  String get healthy => _fr ? 'Installation vérifiée' : 'Installation verified';
  String get needsRepair => _fr ? 'Réparation requise' : 'Repair required';
  String get storage => _fr ? 'Espace disque' : 'Storage';
  String get usedStorage =>
      _fr ? 'Utilisé par l’application' : 'Used by the application';
  String get availableStorage => _fr ? 'Disponible' : 'Available';
  String get noDiagnostics =>
      _fr ? 'Aucun problème détecté' : 'No issue detected';
  String get actionUnavailable =>
      _fr ? 'Action indisponible' : 'Action unavailable';
  String get confirmShortcut => _fr ? 'Entrée / bouton A' : 'Enter / A button';
  String get choose => _fr ? 'Choisir' : 'Choose';
  String get validate => _fr ? 'Valider' : 'Confirm';
  String get noSaveAvailable =>
      _fr ? 'Aucune sauvegarde disponible' : 'No save available';
  String get noSaveToLoad =>
      _fr ? 'Aucune sauvegarde à charger' : 'No save to load';
  String get noPlayerDetailAvailable => _fr
      ? 'Aucune information à afficher pour le moment.'
      : 'No information is available yet.';
  String get unavailableInGame =>
      _fr ? 'Indisponible dans ce jeu' : 'Unavailable in this game';
  String get directReturnHub => _fr
      ? 'Cette fin retourne directement au Hub'
      : 'This ending returns directly to the Hub';
  String get directReturnTitle => _fr
      ? 'Cette fin retourne directement au titre'
      : 'This ending returns directly to the title';
  String get preparingSession =>
      _fr ? 'Préparation de la session' : 'Preparing session';
  String get sessionSuspended =>
      _fr ? 'Session suspendue' : 'Session suspended';
  String get resumeOnReturn =>
      _fr ? 'Reprise à votre retour' : 'Resumes when you return';
  String get validatingCompletion =>
      _fr ? 'Validation de la fin de partie' : 'Validating completion';
  String get closingSession =>
      _fr ? 'Fermeture de la session' : 'Closing session';
  String get returningHub => _fr ? 'Retour au Hub' : 'Returning to Hub';
  String get loadingGame => _fr ? 'Chargement du jeu' : 'Loading game';
  String get completionSaveIncomplete =>
      _fr ? 'Sauvegarde de fin incomplète' : 'Completion save incomplete';
  String get completionSaveMessage => _fr
      ? 'La fin ne peut pas encore être validée.'
      : 'The ending cannot be validated yet.';
  String get completionSaveRecommendation => _fr
      ? 'Réessayez sans quitter afin de préserver la progression.'
      : 'Retry without leaving to preserve your progress.';
  String get sessionErrorTitle =>
      _fr ? 'Le jeu a rencontré un problème' : 'The game encountered a problem';
  String get sessionCannotContinue => _fr
      ? 'La session ne peut pas continuer.'
      : 'The session cannot continue.';
  String get completedFallback => _fr ? 'Partie terminée' : 'Game completed';
  String get completedSummaryFallback =>
      _fr ? 'Votre aventure est terminée.' : 'Your adventure is complete.';
  String get retryKeepsSaves => _fr
      ? 'Réessayez. Vos sauvegardes existantes restent intactes.'
      : 'Retry. Your existing saves remain intact.';
  String get repairFromHub => _fr
      ? 'Retournez au Hub puis réparez l’installation.'
      : 'Return to the Hub and repair the installation.';
  String get returnTitleOrHub =>
      _fr ? 'Retournez au titre ou au Hub.' : 'Return to the title or Hub.';
  String get consultDiagnostics => _fr
      ? 'Retournez au Hub pour consulter les diagnostics.'
      : 'Return to the Hub to view diagnostics.';
  String get overwriteSaveTitle =>
      _fr ? 'Remplacer cette sauvegarde ?' : 'Replace this save?';
  String get overwriteSaveMessage => _fr
      ? 'La sauvegarde actuelle reste intacte tant que la nouvelle partie '
          'n’a pas créé son premier point de sauvegarde.'
      : 'The current save remains intact until the new game creates its first '
          'checkpoint.';
  String get hubSubtitle => _fr
      ? 'Vos aventures, prêtes à reprendre.'
      : 'Your adventures, ready to resume.';
  String get openingLibrary =>
      _fr ? 'Ouverture de la bibliothèque' : 'Opening library';
  String get hubAttentionTitle => _fr
      ? 'Le Hub a besoin de votre attention'
      : 'The Hub needs your attention';
  String get libraryUnavailable => _fr
      ? 'La bibliothèque ne peut pas être affichée.'
      : 'The library cannot be displayed.';
  String get installedDataPreserved => _fr
      ? 'Vos jeux et sauvegardes restent sur le disque.'
      : 'Your games and saves remain on disk.';
  String get installingGame => _fr ? 'Installation du jeu' : 'Installing game';
  String get importUnavailable => _fr
      ? 'Import indisponible sur cette plateforme'
      : 'Import unavailable on this platform';
  String get noSearchResult =>
      _fr ? 'Aucun jeu ne correspond' : 'No matching game';
  String get tryAnotherSearch =>
      _fr ? 'Essayez une autre recherche.' : 'Try another search.';
  String get globalSettingsSubtitle => _fr
      ? 'Réglages globaux du Hub et des jeux.'
      : 'Global settings for the Hub and games.';
  String get systemLanguage => _fr ? 'Langue du système' : 'System language';
  String get systemTheme => _fr ? 'Système' : 'System';
  String get lightTheme => _fr ? 'Clair' : 'Light';
  String get darkTheme => _fr ? 'Sombre' : 'Dark';
  String get theme => _fr ? 'Thème' : 'Theme';
  String get masterVolume => _fr ? 'Volume général' : 'Master volume';
  String get music => _fr ? 'Musique' : 'Music';
  String get effects => _fr ? 'Effets' : 'Effects';
  String get diagnosticsSubtitle => _fr
      ? 'État de la bibliothèque, des installations et du stockage.'
      : 'Library, installation, and storage status.';
  String get diagnosticsReady => _fr
      ? 'La bibliothèque et les installations sont prêtes.'
      : 'The library and installations are ready.';
  String get viewGameDetails =>
      _fr ? 'Ouvrir la fiche du jeu' : 'Open game details';
  String get repairRequired => _fr ? 'Réparation requise' : 'Repair required';
  String get launchUnavailable =>
      _fr ? 'Lancement indisponible' : 'Launch unavailable';
  String get noUpdateAvailable =>
      _fr ? 'Aucune mise à jour détectée' : 'No update available';
  String get updateUnavailable =>
      _fr ? 'Mise à jour indisponible' : 'Update unavailable';
  String get repairSourceMissing => _fr
      ? 'Aucune source de réparation sélectionnée'
      : 'No repair source selected';
  String get saveManagementUnavailable => _fr
      ? 'Gestion des sauvegardes indisponible'
      : 'Save management unavailable';
  String get uninstallUnavailable =>
      _fr ? 'Désinstallation indisponible' : 'Uninstall unavailable';
  String get repairBeforePlaying =>
      _fr ? 'Réparez le jeu avant de jouer' : 'Repair the game before playing';
  String get loadingPackage => _fr ? 'Lecture du package' : 'Reading package';
  String get checkingCompatibility =>
      _fr ? 'Vérification de la compatibilité' : 'Checking compatibility';
  String get checkingStorage =>
      _fr ? 'Vérification de l’espace disque' : 'Checking storage';
  String get protectingInstalledVersion => _fr
      ? 'Protection de la version installée'
      : 'Protecting installed version';
  String get secureExtraction =>
      _fr ? 'Extraction sécurisée' : 'Secure extraction';
  String get verifyingFiles =>
      _fr ? 'Vérification des fichiers' : 'Verifying files';
  String get validatingGame => _fr ? 'Validation du jeu' : 'Validating game';
  String get loadingTrial => _fr ? 'Essai de chargement' : 'Loading trial';
  String get preparingSaves =>
      _fr ? 'Préparation des sauvegardes' : 'Preparing saves';
  String get activatingVersion =>
      _fr ? 'Activation de la version' : 'Activating version';
  String get updatingLibrary =>
      _fr ? 'Mise à jour de la bibliothèque' : 'Updating library';
  String get installationComplete =>
      _fr ? 'Installation terminée' : 'Installation complete';
  String get estimatedTimeCalculating => _fr
      ? 'Temps restant estimé : calcul en cours…'
      : 'Estimated time remaining: calculating…';
  String estimatedTimeRemaining(String duration) => _fr
      ? 'Temps restant estimé : $duration'
      : 'Estimated time remaining: $duration';
  String shortSeconds(int seconds) => _fr ? '$seconds s' : '$seconds sec';
  String shortMinutes(int minutes) => '$minutes min';
  String get cancelling => _fr ? 'Annulation' : 'Cancelling';
  String get recovering => _fr ? 'Récupération' : 'Recovering';
  String get preparing => _fr ? 'Préparation' : 'Preparing';
  String get back => _fr ? 'Retour' : 'Back';
  String get mandatoryReplacement =>
      _fr ? 'Remplacement obligatoire' : 'Replacement required';
  String get levelAbbreviation => _fr ? 'N.' : 'Lv.';
  String get hpAbbreviation => _fr ? 'PV' : 'HP';
  String get showFullText => _fr ? 'Afficher' : 'Show';
  String get next => _fr ? 'Suite' : 'Next';
  String get yourChoice => _fr ? 'Votre choix' : 'Your choice';
  String get postBattle => _fr ? 'Après-combat' : 'Post-battle';
  String get progression => _fr ? 'Progression' : 'Progress';
  String get battleResult => _fr ? 'Résultat du combat' : 'Battle result';
  String get reward => _fr ? 'Récompense' : 'Reward';
  String get decision => _fr ? 'Décision' : 'Decision';
  String get shopItems => _fr ? 'Objets' : 'Items';
  String get shopBuy => _fr ? 'Acheter' : 'Buy';
  String get shopSell => _fr ? 'Vendre' : 'Sell';
  String get shopQuantity => _fr ? 'Quantité' : 'Quantity';
  String get shopDecreaseQuantity =>
      _fr ? 'Diminuer la quantité' : 'Decrease quantity';
  String get shopIncreaseQuantity =>
      _fr ? 'Augmenter la quantité' : 'Increase quantity';
  String get shopUnsellable => _fr ? 'Invendable' : 'Cannot be sold';
  String get shopEmpty =>
      _fr ? 'Cette boutique est vide.' : 'This shop is empty.';
  String get shopBagEmpty => _fr ? 'Le sac est vide.' : 'The bag is empty.';
  String get shopNoItems =>
      _fr ? 'Aucun objet disponible' : 'No items available';
  String get shopCannotDisplay => _fr
      ? 'La boutique ne peut pas être affichée.'
      : 'The shop cannot be displayed.';

  String shopStock(int quantity) =>
      _fr ? 'Stock : $quantity' : 'Stock: $quantity';

  String shopOwned(int quantity) =>
      _fr ? 'Possédé : $quantity' : 'Owned: $quantity';

  String shopTotal(int amount) =>
      _fr ? 'Total : $amount ₽' : 'Total: $amount ₽';

  String installedGameCount(int count) => _fr
      ? '$count jeu${count > 1 ? 'x' : ''} '
          'installé${count > 1 ? 's' : ''}'
      : '$count installed game${count == 1 ? '' : 's'}';

  String diagnosticsToReview(int count) => _fr
      ? '$count diagnostic${count > 1 ? 's' : ''} à consulter'
      : '$count diagnostic${count == 1 ? '' : 's'} to review';

  String levelLabel(int level) => '$levelAbbreviation $level';

  String hpLabel(int current, int maximum) =>
      '$current / $maximum $hpAbbreviation';

  String postBattleProgress(int current, int total) => '$current / $total';
}

extension PokeMapPlayerLocalizationContext on BuildContext {
  PokeMapPlayerLocalizations get playerL10n =>
      PokeMapPlayerLocalizations.of(this);
}

final class _PokeMapPlayerLocalizationsDelegate
    extends LocalizationsDelegate<PokeMapPlayerLocalizations> {
  const _PokeMapPlayerLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'fr' || locale.languageCode == 'en';

  @override
  Future<PokeMapPlayerLocalizations> load(Locale locale) =>
      SynchronousFuture(PokeMapPlayerLocalizations.lookup(locale));

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<PokeMapPlayerLocalizations> old,
  ) =>
      false;
}
