import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'player_catalog_en.dart';
import 'player_catalog_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PlayerCatalog
/// returned by `PlayerCatalog.of(context)`.
///
/// Applications need to include `PlayerCatalog.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/player_catalog.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PlayerCatalog.localizationsDelegates,
///   supportedLocales: PlayerCatalog.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the PlayerCatalog.supportedLocales
/// property.
abstract class PlayerCatalog {
  PlayerCatalog(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PlayerCatalog of(BuildContext context) {
    return Localizations.of<PlayerCatalog>(context, PlayerCatalog)!;
  }

  static const LocalizationsDelegate<PlayerCatalog> delegate =
      _PlayerCatalogDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PokeMap Hub'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @installedGames.
  ///
  /// In en, this message translates to:
  /// **'Installed games'**
  String get installedGames;

  /// No description provided for @recentGames.
  ///
  /// In en, this message translates to:
  /// **'Recent games'**
  String get recentGames;

  /// No description provided for @resumeLastGame.
  ///
  /// In en, this message translates to:
  /// **'Resume last game'**
  String get resumeLastGame;

  /// No description provided for @importGame.
  ///
  /// In en, this message translates to:
  /// **'Import a game'**
  String get importGame;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is ready'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryMessage.
  ///
  /// In en, this message translates to:
  /// **'Import a compatible game package to begin an adventure.'**
  String get emptyLibraryMessage;

  /// No description provided for @searchGames.
  ///
  /// In en, this message translates to:
  /// **'Search games'**
  String get searchGames;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New game'**
  String get newGame;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @creditsAbout.
  ///
  /// In en, this message translates to:
  /// **'Credits / About'**
  String get creditsAbout;

  /// No description provided for @returnToHub.
  ///
  /// In en, this message translates to:
  /// **'Back to Hub'**
  String get returnToHub;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @party.
  ///
  /// In en, this message translates to:
  /// **'Party'**
  String get party;

  /// No description provided for @bag.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get bag;

  /// No description provided for @pokedex.
  ///
  /// In en, this message translates to:
  /// **'Pokédex'**
  String get pokedex;

  /// No description provided for @searchPokedex.
  ///
  /// In en, this message translates to:
  /// **'Search species'**
  String get searchPokedex;

  /// No description provided for @noPokedexMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching species'**
  String get noPokedexMatch;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @quests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get quests;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @returnToTitle.
  ///
  /// In en, this message translates to:
  /// **'Back to title'**
  String get returnToTitle;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @repair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get repair;

  /// No description provided for @manageSaves.
  ///
  /// In en, this message translates to:
  /// **'Manage saves'**
  String get manageSaves;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @lastSave.
  ///
  /// In en, this message translates to:
  /// **'Latest save'**
  String get lastSave;

  /// No description provided for @playTime.
  ///
  /// In en, this message translates to:
  /// **'Play time'**
  String get playTime;

  /// No description provided for @noSave.
  ///
  /// In en, this message translates to:
  /// **'No save'**
  String get noSave;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @showCredits.
  ///
  /// In en, this message translates to:
  /// **'View credits'**
  String get showCredits;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reducedMotion;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @inputHints.
  ///
  /// In en, this message translates to:
  /// **'Show controls'**
  String get inputHints;

  /// No description provided for @touchControlsOpacity.
  ///
  /// In en, this message translates to:
  /// **'Touch controls opacity'**
  String get touchControlsOpacity;

  /// No description provided for @launchMostRecentGameOnStartup.
  ///
  /// In en, this message translates to:
  /// **'Launch the latest game directly'**
  String get launchMostRecentGameOnStartup;

  /// No description provided for @launchMostRecentGameOnStartupDescription.
  ///
  /// In en, this message translates to:
  /// **'At startup, open the most recent playable game without showing the Hub home screen.'**
  String get launchMostRecentGameOnStartupDescription;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Installation verified'**
  String get healthy;

  /// No description provided for @needsRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair required'**
  String get needsRepair;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @usedStorage.
  ///
  /// In en, this message translates to:
  /// **'Used by the application'**
  String get usedStorage;

  /// No description provided for @availableStorage.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availableStorage;

  /// No description provided for @noDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'No issue detected'**
  String get noDiagnostics;

  /// No description provided for @actionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Action unavailable'**
  String get actionUnavailable;

  /// No description provided for @menuBackgroundUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Menu background unavailable.'**
  String get menuBackgroundUnavailable;

  /// No description provided for @confirmShortcut.
  ///
  /// In en, this message translates to:
  /// **'Enter / A button'**
  String get confirmShortcut;

  /// No description provided for @interact.
  ///
  /// In en, this message translates to:
  /// **'Interact'**
  String get interact;

  /// No description provided for @talk.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get talk;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @collect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collect;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @pokemon.
  ///
  /// In en, this message translates to:
  /// **'Pokémon'**
  String get pokemon;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @battleChooseMove.
  ///
  /// In en, this message translates to:
  /// **'Choose a move'**
  String get battleChooseMove;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get validate;

  /// No description provided for @noSaveAvailable.
  ///
  /// In en, this message translates to:
  /// **'No save available'**
  String get noSaveAvailable;

  /// No description provided for @noSaveToLoad.
  ///
  /// In en, this message translates to:
  /// **'No save to load'**
  String get noSaveToLoad;

  /// No description provided for @noPlayerDetailAvailable.
  ///
  /// In en, this message translates to:
  /// **'No information is available yet.'**
  String get noPlayerDetailAvailable;

  /// No description provided for @unavailableInGame.
  ///
  /// In en, this message translates to:
  /// **'Unavailable in this game'**
  String get unavailableInGame;

  /// No description provided for @directReturnHub.
  ///
  /// In en, this message translates to:
  /// **'This ending returns directly to the Hub'**
  String get directReturnHub;

  /// No description provided for @directReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'This ending returns directly to the title'**
  String get directReturnTitle;

  /// No description provided for @preparingSession.
  ///
  /// In en, this message translates to:
  /// **'Preparing session'**
  String get preparingSession;

  /// No description provided for @sessionSuspended.
  ///
  /// In en, this message translates to:
  /// **'Session suspended'**
  String get sessionSuspended;

  /// No description provided for @resumeOnReturn.
  ///
  /// In en, this message translates to:
  /// **'Resumes when you return'**
  String get resumeOnReturn;

  /// No description provided for @validatingCompletion.
  ///
  /// In en, this message translates to:
  /// **'Validating completion'**
  String get validatingCompletion;

  /// No description provided for @closingSession.
  ///
  /// In en, this message translates to:
  /// **'Closing session'**
  String get closingSession;

  /// No description provided for @returningHub.
  ///
  /// In en, this message translates to:
  /// **'Returning to Hub'**
  String get returningHub;

  /// No description provided for @loadingGame.
  ///
  /// In en, this message translates to:
  /// **'Loading game'**
  String get loadingGame;

  /// No description provided for @completionSaveIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Completion save incomplete'**
  String get completionSaveIncomplete;

  /// No description provided for @completionSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'The ending cannot be validated yet.'**
  String get completionSaveMessage;

  /// No description provided for @completionSaveRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Retry without leaving to preserve your progress.'**
  String get completionSaveRecommendation;

  /// No description provided for @sessionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'The game encountered a problem'**
  String get sessionErrorTitle;

  /// No description provided for @sessionCannotContinue.
  ///
  /// In en, this message translates to:
  /// **'The session cannot continue.'**
  String get sessionCannotContinue;

  /// No description provided for @completedFallback.
  ///
  /// In en, this message translates to:
  /// **'Game completed'**
  String get completedFallback;

  /// No description provided for @completedSummaryFallback.
  ///
  /// In en, this message translates to:
  /// **'Your adventure is complete.'**
  String get completedSummaryFallback;

  /// No description provided for @retryKeepsSaves.
  ///
  /// In en, this message translates to:
  /// **'Retry. Your existing saves remain intact.'**
  String get retryKeepsSaves;

  /// No description provided for @repairFromHub.
  ///
  /// In en, this message translates to:
  /// **'Return to the Hub and repair the installation.'**
  String get repairFromHub;

  /// No description provided for @returnTitleOrHub.
  ///
  /// In en, this message translates to:
  /// **'Return to the title or Hub.'**
  String get returnTitleOrHub;

  /// No description provided for @consultDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Return to the Hub to view diagnostics.'**
  String get consultDiagnostics;

  /// No description provided for @overwriteSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace this save?'**
  String get overwriteSaveTitle;

  /// No description provided for @overwriteSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'The current save remains intact until the new game creates its first checkpoint.'**
  String get overwriteSaveMessage;

  /// No description provided for @hubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your adventures, ready to resume.'**
  String get hubSubtitle;

  /// No description provided for @openingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Opening library'**
  String get openingLibrary;

  /// No description provided for @hubAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'The Hub needs your attention'**
  String get hubAttentionTitle;

  /// No description provided for @libraryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The library cannot be displayed.'**
  String get libraryUnavailable;

  /// No description provided for @installedDataPreserved.
  ///
  /// In en, this message translates to:
  /// **'Your games and saves remain on disk.'**
  String get installedDataPreserved;

  /// No description provided for @installingGame.
  ///
  /// In en, this message translates to:
  /// **'Installing game'**
  String get installingGame;

  /// No description provided for @importUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Import unavailable on this platform'**
  String get importUnavailable;

  /// No description provided for @noSearchResult.
  ///
  /// In en, this message translates to:
  /// **'No matching game'**
  String get noSearchResult;

  /// No description provided for @tryAnotherSearch.
  ///
  /// In en, this message translates to:
  /// **'Try another search.'**
  String get tryAnotherSearch;

  /// No description provided for @globalSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Global settings for the Hub and games.'**
  String get globalSettingsSubtitle;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @masterVolume.
  ///
  /// In en, this message translates to:
  /// **'Master volume'**
  String get masterVolume;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Effects'**
  String get effects;

  /// No description provided for @diagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Library, installation, and storage status.'**
  String get diagnosticsSubtitle;

  /// No description provided for @diagnosticsReady.
  ///
  /// In en, this message translates to:
  /// **'The library and installations are ready.'**
  String get diagnosticsReady;

  /// No description provided for @viewGameDetails.
  ///
  /// In en, this message translates to:
  /// **'Open game details'**
  String get viewGameDetails;

  /// No description provided for @repairRequired.
  ///
  /// In en, this message translates to:
  /// **'Repair required'**
  String get repairRequired;

  /// No description provided for @launchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Launch unavailable'**
  String get launchUnavailable;

  /// No description provided for @noUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'No update available'**
  String get noUpdateAvailable;

  /// No description provided for @updateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Update unavailable'**
  String get updateUnavailable;

  /// No description provided for @repairSourceMissing.
  ///
  /// In en, this message translates to:
  /// **'No repair source selected'**
  String get repairSourceMissing;

  /// No description provided for @saveManagementUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Save management unavailable'**
  String get saveManagementUnavailable;

  /// No description provided for @uninstallUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Uninstall unavailable'**
  String get uninstallUnavailable;

  /// No description provided for @repairBeforePlaying.
  ///
  /// In en, this message translates to:
  /// **'Repair the game before playing'**
  String get repairBeforePlaying;

  /// No description provided for @loadingPackage.
  ///
  /// In en, this message translates to:
  /// **'Reading package'**
  String get loadingPackage;

  /// No description provided for @checkingCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Checking compatibility'**
  String get checkingCompatibility;

  /// No description provided for @checkingStorage.
  ///
  /// In en, this message translates to:
  /// **'Checking storage'**
  String get checkingStorage;

  /// No description provided for @protectingInstalledVersion.
  ///
  /// In en, this message translates to:
  /// **'Protecting installed version'**
  String get protectingInstalledVersion;

  /// No description provided for @secureExtraction.
  ///
  /// In en, this message translates to:
  /// **'Secure extraction'**
  String get secureExtraction;

  /// No description provided for @verifyingFiles.
  ///
  /// In en, this message translates to:
  /// **'Verifying files'**
  String get verifyingFiles;

  /// No description provided for @validatingGame.
  ///
  /// In en, this message translates to:
  /// **'Validating game'**
  String get validatingGame;

  /// No description provided for @loadingTrial.
  ///
  /// In en, this message translates to:
  /// **'Loading trial'**
  String get loadingTrial;

  /// No description provided for @preparingSaves.
  ///
  /// In en, this message translates to:
  /// **'Preparing saves'**
  String get preparingSaves;

  /// No description provided for @activatingVersion.
  ///
  /// In en, this message translates to:
  /// **'Activating version'**
  String get activatingVersion;

  /// No description provided for @updatingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Updating library'**
  String get updatingLibrary;

  /// No description provided for @installationComplete.
  ///
  /// In en, this message translates to:
  /// **'Installation complete'**
  String get installationComplete;

  /// No description provided for @estimatedTimeCalculating.
  ///
  /// In en, this message translates to:
  /// **'Estimated time remaining: calculating…'**
  String get estimatedTimeCalculating;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling'**
  String get cancelling;

  /// No description provided for @recovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get recovering;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @mandatoryReplacement.
  ///
  /// In en, this message translates to:
  /// **'Replacement required'**
  String get mandatoryReplacement;

  /// No description provided for @levelAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'Lv.'**
  String get levelAbbreviation;

  /// No description provided for @hpAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get hpAbbreviation;

  /// No description provided for @experienceAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get experienceAbbreviation;

  /// No description provided for @showFullText.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showFullText;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @yourChoice.
  ///
  /// In en, this message translates to:
  /// **'Your choice'**
  String get yourChoice;

  /// No description provided for @postBattle.
  ///
  /// In en, this message translates to:
  /// **'Post-battle'**
  String get postBattle;

  /// No description provided for @progression.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progression;

  /// No description provided for @battleResult.
  ///
  /// In en, this message translates to:
  /// **'Battle result'**
  String get battleResult;

  /// No description provided for @battleCommands.
  ///
  /// In en, this message translates to:
  /// **'COMMANDS'**
  String get battleCommands;

  /// No description provided for @battleFight.
  ///
  /// In en, this message translates to:
  /// **'FIGHT'**
  String get battleFight;

  /// No description provided for @battleRun.
  ///
  /// In en, this message translates to:
  /// **'RUN'**
  String get battleRun;

  /// No description provided for @battleMoveInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get battleMoveInfo;

  /// No description provided for @battleMoves.
  ///
  /// In en, this message translates to:
  /// **'MOVES'**
  String get battleMoves;

  /// No description provided for @battleBag.
  ///
  /// In en, this message translates to:
  /// **'BAG'**
  String get battleBag;

  /// No description provided for @battleBagMedicine.
  ///
  /// In en, this message translates to:
  /// **'HEALING'**
  String get battleBagMedicine;

  /// No description provided for @battleBagCapture.
  ///
  /// In en, this message translates to:
  /// **'CAPTURE'**
  String get battleBagCapture;

  /// No description provided for @battleBagOther.
  ///
  /// In en, this message translates to:
  /// **'ITEM'**
  String get battleBagOther;

  /// No description provided for @battleTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get battleTarget;

  /// No description provided for @battlePokemon.
  ///
  /// In en, this message translates to:
  /// **'POKÉMON'**
  String get battlePokemon;

  /// No description provided for @battleContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get battleContinue;

  /// No description provided for @battleDecision.
  ///
  /// In en, this message translates to:
  /// **'CHOICE'**
  String get battleDecision;

  /// No description provided for @reward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get reward;

  /// No description provided for @decision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get decision;

  /// No description provided for @shopItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get shopItems;

  /// No description provided for @shopBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get shopBuy;

  /// No description provided for @shopSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get shopSell;

  /// No description provided for @shopQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get shopQuantity;

  /// No description provided for @shopDecreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get shopDecreaseQuantity;

  /// No description provided for @shopIncreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get shopIncreaseQuantity;

  /// No description provided for @shopUnsellable.
  ///
  /// In en, this message translates to:
  /// **'Cannot be sold'**
  String get shopUnsellable;

  /// No description provided for @shopEmpty.
  ///
  /// In en, this message translates to:
  /// **'This shop is empty.'**
  String get shopEmpty;

  /// No description provided for @shopBagEmpty.
  ///
  /// In en, this message translates to:
  /// **'The bag is empty.'**
  String get shopBagEmpty;

  /// No description provided for @shopNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items available'**
  String get shopNoItems;

  /// No description provided for @shopCannotDisplay.
  ///
  /// In en, this message translates to:
  /// **'The shop cannot be displayed.'**
  String get shopCannotDisplay;

  /// No description provided for @confirmOverwrite.
  ///
  /// In en, this message translates to:
  /// **'This save already exists. Do you want to replace it?'**
  String get confirmOverwrite;

  /// No description provided for @dialogueChoicePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a reply.'**
  String get dialogueChoicePrompt;

  /// No description provided for @estimatedTimeRemainingMessage.
  ///
  /// In en, this message translates to:
  /// **'Estimated time remaining: {duration}'**
  String estimatedTimeRemainingMessage({required String duration});

  /// No description provided for @shortSecondsMessage.
  ///
  /// In en, this message translates to:
  /// **'{seconds} sec'**
  String shortSecondsMessage({required int seconds});

  /// No description provided for @shortMinutesMessage.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String shortMinutesMessage({required int minutes});

  /// No description provided for @shopStockMessage.
  ///
  /// In en, this message translates to:
  /// **'Stock: {quantity}'**
  String shopStockMessage({required int quantity});

  /// No description provided for @shopOwnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Owned: {quantity}'**
  String shopOwnedMessage({required int quantity});

  /// No description provided for @shopTotalMessage.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount} ₽'**
  String shopTotalMessage({required int amount});

  /// No description provided for @installedGameCountMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 installed games} one{{count} installed game} other{{count} installed games}}'**
  String installedGameCountMessage({required int count});

  /// No description provided for @diagnosticsToReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 diagnostics to review} one{{count} diagnostic to review} other{{count} diagnostics to review}}'**
  String diagnosticsToReviewMessage({required int count});

  /// No description provided for @levelLabelMessage.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String levelLabelMessage({required int level});

  /// No description provided for @hpLabelMessage.
  ///
  /// In en, this message translates to:
  /// **'{current} / {maximum} HP'**
  String hpLabelMessage({required int current, required int maximum});

  /// No description provided for @hpFractionMessage.
  ///
  /// In en, this message translates to:
  /// **'{current}/{maximum}'**
  String hpFractionMessage({required int current, required int maximum});

  /// No description provided for @experienceProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'Progress to the next level: {percent}%'**
  String experienceProgressMessage({required int percent});

  /// No description provided for @postBattleProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String postBattleProgressMessage({required int current, required int total});

  /// No description provided for @confirmOverwriteUnusableMessage.
  ///
  /// In en, this message translates to:
  /// **'This save cannot be continued: {reason} Replacing it will permanently erase its progress.'**
  String confirmOverwriteUnusableMessage({required String reason});

  /// No description provided for @battleMoveCategorySpecial.
  ///
  /// In en, this message translates to:
  /// **'SPECIAL'**
  String get battleMoveCategorySpecial;

  /// No description provided for @battleMoveCategoryPhysical.
  ///
  /// In en, this message translates to:
  /// **'PHYSICAL'**
  String get battleMoveCategoryPhysical;

  /// No description provided for @battleMoveCategoryStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get battleMoveCategoryStatus;

  /// No description provided for @saveUnavailablePostGameContinuationRefused.
  ///
  /// In en, this message translates to:
  /// **'This ending does not allow post-game continuation.'**
  String get saveUnavailablePostGameContinuationRefused;

  /// No description provided for @saveUnavailableMigrationRequired.
  ///
  /// In en, this message translates to:
  /// **'This save must be migrated before it can be loaded.'**
  String get saveUnavailableMigrationRequired;

  /// No description provided for @saveUnavailableIncompatibleVersion.
  ///
  /// In en, this message translates to:
  /// **'This save is not compatible with the installed game version.'**
  String get saveUnavailableIncompatibleVersion;

  /// No description provided for @saveUnavailableCorrupt.
  ///
  /// In en, this message translates to:
  /// **'This save is damaged and could not be recovered from its backup.'**
  String get saveUnavailableCorrupt;

  /// No description provided for @saveUnavailableMissing.
  ///
  /// In en, this message translates to:
  /// **'No save exists in this slot.'**
  String get saveUnavailableMissing;

  /// No description provided for @saveUnavailableTemporarilyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This save is temporarily unavailable.'**
  String get saveUnavailableTemporarilyUnavailable;

  /// No description provided for @battleMoveTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'{type, select, other{{fallback}}}'**
  String battleMoveTypeMessage({
    required String type,
    required String fallback,
  });

  /// No description provided for @bagUse.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get bagUse;

  /// No description provided for @bagChooseTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose a target'**
  String get bagChooseTarget;

  /// No description provided for @bagManageHeldItem.
  ///
  /// In en, this message translates to:
  /// **'Manage held item'**
  String get bagManageHeldItem;

  /// No description provided for @bagHeldItemSummary.
  ///
  /// In en, this message translates to:
  /// **'Held item: {item}'**
  String bagHeldItemSummary({required String item});

  /// No description provided for @bagGiveHeldItem.
  ///
  /// In en, this message translates to:
  /// **'Give {item}'**
  String bagGiveHeldItem({required String item});

  /// No description provided for @bagReplaceHeldItem.
  ///
  /// In en, this message translates to:
  /// **'Replace with {item}'**
  String bagReplaceHeldItem({required String item});

  /// No description provided for @bagTakeHeldItem.
  ///
  /// In en, this message translates to:
  /// **'Take {item}'**
  String bagTakeHeldItem({required String item});

  /// No description provided for @bagUseOn.
  ///
  /// In en, this message translates to:
  /// **'Use on {pokemon}'**
  String bagUseOn({required String pokemon});

  /// No description provided for @bagUseOnMove.
  ///
  /// In en, this message translates to:
  /// **'Use on {pokemon} — {move}'**
  String bagUseOnMove({required String pokemon, required String move});

  /// No description provided for @bagTeachTo.
  ///
  /// In en, this message translates to:
  /// **'Teach to {pokemon}'**
  String bagTeachTo({required String pokemon});

  /// No description provided for @bagTeachReplacing.
  ///
  /// In en, this message translates to:
  /// **'Teach to {pokemon} and forget {move}'**
  String bagTeachReplacing({required String pokemon, required String move});

  /// No description provided for @optionsCategoryControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get optionsCategoryControls;

  /// No description provided for @controlsConflict.
  ///
  /// In en, this message translates to:
  /// **'This input is already assigned.'**
  String get controlsConflict;

  /// No description provided for @controlsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get controlsReset;

  /// No description provided for @controlsSwapTouch.
  ///
  /// In en, this message translates to:
  /// **'Swap A / B'**
  String get controlsSwapTouch;

  /// No description provided for @controlsDeviceKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get controlsDeviceKeyboard;

  /// No description provided for @controlsDeviceGamepad.
  ///
  /// In en, this message translates to:
  /// **'Gamepad'**
  String get controlsDeviceGamepad;

  /// No description provided for @controlsDeviceTouch.
  ///
  /// In en, this message translates to:
  /// **'Touch'**
  String get controlsDeviceTouch;

  /// No description provided for @controlsControlUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get controlsControlUp;

  /// No description provided for @controlsControlDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get controlsControlDown;

  /// No description provided for @controlsControlLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get controlsControlLeft;

  /// No description provided for @controlsControlRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get controlsControlRight;

  /// No description provided for @controlsControlSprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get controlsControlSprint;

  /// No description provided for @controlsControlPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary action'**
  String get controlsControlPrimary;

  /// No description provided for @controlsControlSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary action'**
  String get controlsControlSecondary;

  /// No description provided for @controlsControlBicycle.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get controlsControlBicycle;

  /// No description provided for @controlsControlPreviousTab.
  ///
  /// In en, this message translates to:
  /// **'Previous tab'**
  String get controlsControlPreviousTab;

  /// No description provided for @controlsControlNextTab.
  ///
  /// In en, this message translates to:
  /// **'Next tab'**
  String get controlsControlNextTab;

  /// No description provided for @displayTitle.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displayTitle;

  /// No description provided for @displayMode.
  ///
  /// In en, this message translates to:
  /// **'Display mode'**
  String get displayMode;

  /// No description provided for @displayWindowed.
  ///
  /// In en, this message translates to:
  /// **'Windowed'**
  String get displayWindowed;

  /// No description provided for @displayFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get displayFullscreen;

  /// No description provided for @displayWindowSize.
  ///
  /// In en, this message translates to:
  /// **'Window size'**
  String get displayWindowSize;

  /// No description provided for @displayCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get displayCompact;

  /// No description provided for @displayBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get displayBalanced;

  /// No description provided for @displaySpacious.
  ///
  /// In en, this message translates to:
  /// **'Spacious'**
  String get displaySpacious;

  /// No description provided for @displayUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Window settings are available on desktop.'**
  String get displayUnsupported;

  /// No description provided for @displayApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'The display setting could not be applied.'**
  String get displayApplyFailed;

  /// No description provided for @healStatusNeedsHealing.
  ///
  /// In en, this message translates to:
  /// **'Status needs healing'**
  String get healStatusNeedsHealing;

  /// No description provided for @healStatusHealthy.
  ///
  /// In en, this message translates to:
  /// **'Status healthy'**
  String get healStatusHealthy;

  /// No description provided for @healPpToRestore.
  ///
  /// In en, this message translates to:
  /// **'PP to restore: {count}'**
  String healPpToRestore({required int count});

  /// No description provided for @healPpFull.
  ///
  /// In en, this message translates to:
  /// **'PP full'**
  String get healPpFull;

  /// No description provided for @noPokemon.
  ///
  /// In en, this message translates to:
  /// **'No Pokémon'**
  String get noPokemon;

  /// No description provided for @emptyPartyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your party is empty.'**
  String get emptyPartyMessage;

  /// No description provided for @returnToGame.
  ///
  /// In en, this message translates to:
  /// **'Return to game'**
  String get returnToGame;

  /// No description provided for @healRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get healRetry;

  /// No description provided for @healHealParty.
  ///
  /// In en, this message translates to:
  /// **'Heal'**
  String get healHealParty;

  /// No description provided for @healUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The healing service cannot be displayed.'**
  String get healUnavailable;

  /// No description provided for @healHp.
  ///
  /// In en, this message translates to:
  /// **'HP {current} / {maximum}'**
  String healHp({required int current, required int maximum});

  /// No description provided for @introVideoSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get introVideoSkip;

  /// No description provided for @introVideoReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get introVideoReplay;

  /// No description provided for @introVideoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video playback is unavailable.'**
  String get introVideoUnavailable;

  /// No description provided for @introVideoReducedMotionSkipped.
  ///
  /// In en, this message translates to:
  /// **'Intro skipped with reduced motion'**
  String get introVideoReducedMotionSkipped;

  /// No description provided for @pcSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'{pokemon} summary'**
  String pcSummaryTitle({required String pokemon});

  /// No description provided for @pcSummaryTooltip.
  ///
  /// In en, this message translates to:
  /// **'View summary'**
  String get pcSummaryTooltip;

  /// No description provided for @pcSwapTooltip.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get pcSwapTooltip;

  /// No description provided for @pcEmptyBox.
  ///
  /// In en, this message translates to:
  /// **'This Box is empty.'**
  String get pcEmptyBox;

  /// No description provided for @pcDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get pcDeposit;

  /// No description provided for @pcWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get pcWithdraw;

  /// No description provided for @pcUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The PC cannot be displayed.'**
  String get pcUnavailable;

  /// No description provided for @pokemonLevel.
  ///
  /// In en, this message translates to:
  /// **'Lv. {level}'**
  String pokemonLevel({required int level});

  /// No description provided for @pcSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get pcSpecies;

  /// No description provided for @pcLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get pcLevel;

  /// No description provided for @pcCurrentHp.
  ///
  /// In en, this message translates to:
  /// **'Current HP'**
  String get pcCurrentHp;

  /// No description provided for @pcAbility.
  ///
  /// In en, this message translates to:
  /// **'Ability'**
  String get pcAbility;

  /// No description provided for @pcGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get pcGender;

  /// No description provided for @pcStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pcStatus;

  /// No description provided for @pcShiny.
  ///
  /// In en, this message translates to:
  /// **'Shiny'**
  String get pcShiny;

  /// No description provided for @pcHeldItem.
  ///
  /// In en, this message translates to:
  /// **'Held item'**
  String get pcHeldItem;

  /// No description provided for @pcMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get pcMoves;

  /// No description provided for @pcNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get pcNickname;

  /// No description provided for @pcFriendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get pcFriendship;

  /// No description provided for @pcOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get pcOrigin;

  /// No description provided for @pcMetLocation.
  ///
  /// In en, this message translates to:
  /// **'Met location'**
  String get pcMetLocation;

  /// No description provided for @pcMetSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get pcMetSource;

  /// No description provided for @pcMetLevel.
  ///
  /// In en, this message translates to:
  /// **'Met level'**
  String get pcMetLevel;

  /// No description provided for @pcCaptureBall.
  ///
  /// In en, this message translates to:
  /// **'Capture Ball'**
  String get pcCaptureBall;

  /// No description provided for @pcNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pcNone;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @pokemonOriginCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get pokemonOriginCaptured;

  /// No description provided for @pokemonOriginGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get pokemonOriginGift;

  /// No description provided for @pokemonOriginStarter.
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get pokemonOriginStarter;

  /// No description provided for @pokemonOriginTrade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get pokemonOriginTrade;

  /// No description provided for @pokemonOriginScripted.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get pokemonOriginScripted;

  /// No description provided for @pokemonOriginUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get pokemonOriginUnknown;

  /// No description provided for @pcSwapWith.
  ///
  /// In en, this message translates to:
  /// **'Swap with {pokemon}'**
  String pcSwapWith({required String pokemon});

  /// No description provided for @pokemonPpValue.
  ///
  /// In en, this message translates to:
  /// **'PP {current}/{max}'**
  String pokemonPpValue({required int current, required int max});

  /// No description provided for @pokemonSpecies.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get pokemonSpecies;

  /// No description provided for @pokemonForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get pokemonForm;

  /// No description provided for @pokemonExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get pokemonExperience;

  /// No description provided for @pokemonNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get pokemonNature;

  /// No description provided for @pokemonAbility.
  ///
  /// In en, this message translates to:
  /// **'Ability'**
  String get pokemonAbility;

  /// No description provided for @pokemonGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get pokemonGender;

  /// No description provided for @pokemonShiny.
  ///
  /// In en, this message translates to:
  /// **'Shiny'**
  String get pokemonShiny;

  /// No description provided for @pokemonHeldItem.
  ///
  /// In en, this message translates to:
  /// **'Held item'**
  String get pokemonHeldItem;

  /// No description provided for @pokemonFriendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get pokemonFriendship;

  /// No description provided for @pokemonStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get pokemonStats;

  /// No description provided for @pokemonAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get pokemonAttack;

  /// No description provided for @pokemonDefense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get pokemonDefense;

  /// No description provided for @pokemonSpecialAttack.
  ///
  /// In en, this message translates to:
  /// **'Sp. Attack'**
  String get pokemonSpecialAttack;

  /// No description provided for @pokemonSpecialDefense.
  ///
  /// In en, this message translates to:
  /// **'Sp. Defense'**
  String get pokemonSpecialDefense;

  /// No description provided for @pokemonSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get pokemonSpeed;

  /// No description provided for @pokemonMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get pokemonMoves;

  /// No description provided for @pokemonProvenance.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get pokemonProvenance;

  /// No description provided for @pokemonOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get pokemonOrigin;

  /// No description provided for @pokemonMetLocation.
  ///
  /// In en, this message translates to:
  /// **'Met location'**
  String get pokemonMetLocation;

  /// No description provided for @pokemonMetSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get pokemonMetSource;

  /// No description provided for @pokemonMetLevel.
  ///
  /// In en, this message translates to:
  /// **'Met level'**
  String get pokemonMetLevel;

  /// No description provided for @pokemonCaptureBall.
  ///
  /// In en, this message translates to:
  /// **'Capture Ball'**
  String get pokemonCaptureBall;

  /// No description provided for @pokemonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get pokemonNone;

  /// No description provided for @pokemonViewSummary.
  ///
  /// In en, this message translates to:
  /// **'View summary'**
  String get pokemonViewSummary;

  /// No description provided for @pokemonFriendshipValue.
  ///
  /// In en, this message translates to:
  /// **'{friendship}/255'**
  String pokemonFriendshipValue({required int friendship});

  /// No description provided for @pokemonPpUnavailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get pokemonPpUnavailable;

  /// No description provided for @saveRecoveryCauseUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The save file cannot be read.'**
  String get saveRecoveryCauseUnreadable;

  /// No description provided for @saveRecoveryCauseUnsupportedSchema.
  ///
  /// In en, this message translates to:
  /// **'This save comes from another version of the game.'**
  String get saveRecoveryCauseUnsupportedSchema;

  /// No description provided for @saveRecoveryCauseInvalidState.
  ///
  /// In en, this message translates to:
  /// **'The save is incomplete or inconsistent.'**
  String get saveRecoveryCauseInvalidState;

  /// No description provided for @saveRecoveryExpectedVersion.
  ///
  /// In en, this message translates to:
  /// **'This game expects version {expected}.'**
  String saveRecoveryExpectedVersion({required int expected});

  /// No description provided for @saveRecoveryVersionMismatch.
  ///
  /// In en, this message translates to:
  /// **'Save is version {detected}, this game expects version {expected}.'**
  String saveRecoveryVersionMismatch({
    required int detected,
    required int expected,
  });

  /// No description provided for @saveRecoveryActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get saveRecoveryActionRetry;

  /// No description provided for @saveRecoveryActionRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore the previous save'**
  String get saveRecoveryActionRestoreBackup;

  /// No description provided for @saveRecoveryActionMigrate.
  ///
  /// In en, this message translates to:
  /// **'Update the save'**
  String get saveRecoveryActionMigrate;

  /// No description provided for @saveRecoveryActionDeleteSave.
  ///
  /// In en, this message translates to:
  /// **'Delete the save'**
  String get saveRecoveryActionDeleteSave;

  /// No description provided for @saveRecoveryDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently?'**
  String get saveRecoveryDeleteConfirmTitle;

  /// No description provided for @saveRecoveryDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This game will be erased and cannot be recovered.'**
  String get saveRecoveryDeleteConfirmBody;

  /// No description provided for @saveRecoveryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get saveRecoveryDeleteConfirm;

  /// No description provided for @saveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save game?'**
  String get saveTitle;

  /// No description provided for @saveSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saveSaving;

  /// No description provided for @saveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Game saved'**
  String get saveSuccess;

  /// No description provided for @saveFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to save'**
  String get saveFailure;

  /// No description provided for @saveExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Return to title?'**
  String get saveExitTitle;

  /// No description provided for @saveStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get saveStay;

  /// No description provided for @saveDiscard.
  ///
  /// In en, this message translates to:
  /// **'Return to title without saving'**
  String get saveDiscard;

  /// No description provided for @saveSaveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save and quit'**
  String get saveSaveAndExit;

  /// No description provided for @saveExiting.
  ///
  /// In en, this message translates to:
  /// **'Returning to title…'**
  String get saveExiting;

  /// No description provided for @saveExitFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to return to title'**
  String get saveExitFailure;

  /// No description provided for @saveExitWarning.
  ///
  /// In en, this message translates to:
  /// **'Unsaved progress will be lost if you leave without saving.'**
  String get saveExitWarning;

  /// No description provided for @saveDiscardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This player cannot leave without saving.'**
  String get saveDiscardUnavailable;

  /// No description provided for @saveSaveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No active save slot is available.'**
  String get saveSaveUnavailable;

  /// No description provided for @saveSaveAndExitUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This player cannot save and then quit.'**
  String get saveSaveAndExitUnavailable;

  /// No description provided for @saveMissingReceipt.
  ///
  /// In en, this message translates to:
  /// **'The save was not confirmed. Please retry.'**
  String get saveMissingReceipt;

  /// No description provided for @saveUnexpectedFailure.
  ///
  /// In en, this message translates to:
  /// **'The operation could not be completed. Please retry.'**
  String get saveUnexpectedFailure;

  /// No description provided for @savePlayer.
  ///
  /// In en, this message translates to:
  /// **'Player: {name}'**
  String savePlayer({required String name});

  /// No description provided for @saveLocation.
  ///
  /// In en, this message translates to:
  /// **'Location: {name}'**
  String saveLocation({required String name});

  /// No description provided for @savePlaytime.
  ///
  /// In en, this message translates to:
  /// **'Play time: {hours} h {minutes} min'**
  String savePlaytime({required String minutes, required int hours});

  /// No description provided for @saveLastSave.
  ///
  /// In en, this message translates to:
  /// **'Last save: {date} at {time}'**
  String saveLastSave({required String date, required String time});

  /// No description provided for @saveTarget.
  ///
  /// In en, this message translates to:
  /// **'Profile “{profile}”, slot “{slot}”.'**
  String saveTarget({required String profile, required String slot});

  /// No description provided for @saveSaved.
  ///
  /// In en, this message translates to:
  /// **'Game saved — profile “{profile}”, slot “{slot}”.'**
  String saveSaved({required String profile, required String slot});

  /// No description provided for @interactionSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get interactionSubmit;

  /// No description provided for @interactionTextFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get interactionTextFieldLabel;

  /// No description provided for @interactionSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get interactionSelected;

  /// No description provided for @interactionOptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This option is unavailable.'**
  String get interactionOptionUnavailable;

  /// No description provided for @interactionMaximumReached.
  ///
  /// In en, this message translates to:
  /// **'The maximum number of choices is reached.'**
  String get interactionMaximumReached;

  /// No description provided for @interactionCharacterCount.
  ///
  /// In en, this message translates to:
  /// **'{current, plural, =0{0 characters} one{{current} character} other{{current} characters}}'**
  String interactionCharacterCount({required int current});

  /// No description provided for @interactionSelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{current} selected, between {minimum} and {maximum} required'**
  String interactionSelectionCount({
    required int current,
    required int minimum,
    required int maximum,
  });

  /// No description provided for @interactionIntegerOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Enter an integer between {minimum} and {maximum}.'**
  String interactionIntegerOutOfRange({
    required String minimum,
    required String maximum,
  });

  /// No description provided for @interactionCancellationForbidden.
  ///
  /// In en, this message translates to:
  /// **'Submit this input to continue.'**
  String get interactionCancellationForbidden;

  /// No description provided for @interactionTextTooShort.
  ///
  /// In en, this message translates to:
  /// **'{minimum, plural, one{Enter at least {minimum} character.} other{Enter at least {minimum} characters.}}'**
  String interactionTextTooShort({required int minimum});

  /// No description provided for @interactionTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'{maximum, plural, one{Enter at most {maximum} character.} other{Enter at most {maximum} characters.}}'**
  String interactionTextTooLong({required int maximum});

  /// No description provided for @interactionTooFewSelections.
  ///
  /// In en, this message translates to:
  /// **'{minimum, plural, one{Select at least {minimum} option.} other{Select at least {minimum} options.}}'**
  String interactionTooFewSelections({required int minimum});

  /// No description provided for @interactionTooManySelections.
  ///
  /// In en, this message translates to:
  /// **'{maximum, plural, one{Select at most {maximum} option.} other{Select at most {maximum} options.}}'**
  String interactionTooManySelections({required int maximum});

  /// No description provided for @interactionCannotSubmit.
  ///
  /// In en, this message translates to:
  /// **'This answer cannot be submitted.'**
  String get interactionCannotSubmit;

  /// No description provided for @startupPressStart.
  ///
  /// In en, this message translates to:
  /// **'Press Start'**
  String get startupPressStart;

  /// No description provided for @startupReplayIntro.
  ///
  /// In en, this message translates to:
  /// **'Replay intro'**
  String get startupReplayIntro;

  /// No description provided for @startupReplaceSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace the current game?'**
  String get startupReplaceSaveTitle;

  /// No description provided for @startupReplaceSaveBody.
  ///
  /// In en, this message translates to:
  /// **'A new game will replace the current save the next time it is saved.'**
  String get startupReplaceSaveBody;

  /// No description provided for @startupBegin.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startupBegin;

  /// No description provided for @startupStartupUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The game could not finish starting.'**
  String get startupStartupUnavailable;

  /// No description provided for @startupPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get startupPreparing;

  /// No description provided for @optionsCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get optionsCategoryGeneral;

  /// No description provided for @optionsCategoryWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get optionsCategoryWeather;

  /// No description provided for @optionsCategoryTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get optionsCategoryTime;

  /// No description provided for @optionsCategoryDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get optionsCategoryDisplay;

  /// No description provided for @optionsCategoryAudio.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get optionsCategoryAudio;

  /// No description provided for @optionsSpeedSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get optionsSpeedSlow;

  /// No description provided for @optionsSpeedNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get optionsSpeedNormal;

  /// No description provided for @optionsSpeedFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get optionsSpeedFast;

  /// No description provided for @optionsSpeedInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get optionsSpeedInstant;

  /// No description provided for @optionsEffectsFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get optionsEffectsFull;

  /// No description provided for @optionsEffectsReduced.
  ///
  /// In en, this message translates to:
  /// **'Reduced'**
  String get optionsEffectsReduced;

  /// No description provided for @optionsEffectsOpaque.
  ///
  /// In en, this message translates to:
  /// **'Opaque'**
  String get optionsEffectsOpaque;

  /// No description provided for @optionsHelpWeather.
  ///
  /// In en, this message translates to:
  /// **'Choose the source for real weather. Story scenes keep priority.'**
  String get optionsHelpWeather;

  /// No description provided for @optionsHelpTime.
  ///
  /// In en, this message translates to:
  /// **'Real time follows the clock the game intends, usually the device clock. A chosen hour freezes day and night, and time-based events follow it. Story scenes keep priority.'**
  String get optionsHelpTime;

  /// No description provided for @optionsHelpGeneral.
  ///
  /// In en, this message translates to:
  /// **'Choose how quickly dialogue text appears.'**
  String get optionsHelpGeneral;

  /// No description provided for @optionsHelpDisplay.
  ///
  /// In en, this message translates to:
  /// **'A lower frame rate limit reduces power use. The actual rate depends on the display and device. Menu effects: Reduced limits their animations; Opaque uses solid panels. 3D resolution keeps the image format; lower values lighten the load, and upscaling chooses how the image is enlarged to the screen. Scene effects stay as the game intends until you turn them off.'**
  String get optionsHelpDisplay;

  /// No description provided for @optionsHelpAudio.
  ///
  /// In en, this message translates to:
  /// **'Master volume controls every channel. At 0%, sound is muted. Left and right adjust volume in steps of 5%.'**
  String get optionsHelpAudio;

  /// No description provided for @optionsHelpControls.
  ///
  /// In en, this message translates to:
  /// **'Hints follow the current bindings. Duplicate inputs are rejected to keep every action accessible. Opacity affects the touch controls shown in game.'**
  String get optionsHelpControls;

  /// No description provided for @optionsHelpLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface language changes the Player menus. Dialogue follows the translations available in the game.'**
  String get optionsHelpLanguage;

  /// No description provided for @optionsHelpAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Adjust readability for your comfort. Reduced motion requested by the system still takes priority.'**
  String get optionsHelpAccessibility;

  /// No description provided for @optionsScope.
  ///
  /// In en, this message translates to:
  /// **'Settings saved on this device.'**
  String get optionsScope;

  /// No description provided for @optionsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get optionsCategories;

  /// No description provided for @optionsDefaults.
  ///
  /// In en, this message translates to:
  /// **'Defaults'**
  String get optionsDefaults;

  /// No description provided for @optionsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get optionsRestore;

  /// No description provided for @optionsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get optionsSaving;

  /// No description provided for @optionsError.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. The last saved values have been kept. Please try again.'**
  String get optionsError;

  /// No description provided for @optionsReturnToTitle.
  ///
  /// In en, this message translates to:
  /// **'Return to title'**
  String get optionsReturnToTitle;

  /// No description provided for @optionsTextSpeed.
  ///
  /// In en, this message translates to:
  /// **'Text speed'**
  String get optionsTextSpeed;

  /// No description provided for @optionsBattleSpeed.
  ///
  /// In en, this message translates to:
  /// **'Battle speed'**
  String get optionsBattleSpeed;

  /// No description provided for @optionsBattleEffectIntensity.
  ///
  /// In en, this message translates to:
  /// **'Battle effect intensity'**
  String get optionsBattleEffectIntensity;

  /// No description provided for @optionsMenuEffects.
  ///
  /// In en, this message translates to:
  /// **'Menu effects'**
  String get optionsMenuEffects;

  /// No description provided for @optionsFrameRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Frames per second'**
  String get optionsFrameRateLimit;

  /// No description provided for @optionsRenderScale.
  ///
  /// In en, this message translates to:
  /// **'3D resolution'**
  String get optionsRenderScale;

  /// No description provided for @optionsRenderScaleValue.
  ///
  /// In en, this message translates to:
  /// **'Auto (per device)'**
  String get optionsRenderScaleValue;

  /// No description provided for @optionsUpscaling.
  ///
  /// In en, this message translates to:
  /// **'3D upscaling'**
  String get optionsUpscaling;

  /// No description provided for @optionsUpscalingValueNearest.
  ///
  /// In en, this message translates to:
  /// **'Sharp pixels'**
  String get optionsUpscalingValueNearest;

  /// No description provided for @optionsDepthOfField.
  ///
  /// In en, this message translates to:
  /// **'Depth of field'**
  String get optionsDepthOfField;

  /// No description provided for @optionsShadows.
  ///
  /// In en, this message translates to:
  /// **'Shadows'**
  String get optionsShadows;

  /// No description provided for @optionsFogAndHalos.
  ///
  /// In en, this message translates to:
  /// **'Fog and halos'**
  String get optionsFogAndHalos;

  /// No description provided for @optionsAmbientAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animated ambience'**
  String get optionsAmbientAnimation;

  /// No description provided for @optionsWorldTime.
  ///
  /// In en, this message translates to:
  /// **'World time'**
  String get optionsWorldTime;

  /// No description provided for @optionsWorldTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Real time'**
  String get optionsWorldTimeValue;

  /// No description provided for @optionsMaster.
  ///
  /// In en, this message translates to:
  /// **'Master volume'**
  String get optionsMaster;

  /// No description provided for @optionsSoundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get optionsSoundEffects;

  /// No description provided for @optionsInterfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get optionsInterfaceLanguage;

  /// No description provided for @optionsFollowApplicationLanguage.
  ///
  /// In en, this message translates to:
  /// **'Follow the app'**
  String get optionsFollowApplicationLanguage;

  /// No description provided for @optionsHighContrast.
  ///
  /// In en, this message translates to:
  /// **'Increase contrast'**
  String get optionsHighContrast;

  /// No description provided for @optionsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get optionsHaptics;

  /// No description provided for @optionsHints.
  ///
  /// In en, this message translates to:
  /// **'Show control hints'**
  String get optionsHints;

  /// No description provided for @optionsLeftHandedTouchControls.
  ///
  /// In en, this message translates to:
  /// **'Touch joystick on the right'**
  String get optionsLeftHandedTouchControls;

  /// No description provided for @optionsTouchRunMode.
  ///
  /// In en, this message translates to:
  /// **'Touch running'**
  String get optionsTouchRunMode;

  /// No description provided for @optionsRunningModeGesture.
  ///
  /// In en, this message translates to:
  /// **'Run with a wider gesture'**
  String get optionsRunningModeGesture;

  /// No description provided for @optionsRunningModeWalkOnly.
  ///
  /// In en, this message translates to:
  /// **'Walk only'**
  String get optionsRunningModeWalkOnly;

  /// No description provided for @optionsRunningModeAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Run automatically when allowed'**
  String get optionsRunningModeAutomatic;

  /// No description provided for @optionsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset {category}?'**
  String optionsResetTitle({required String category});

  /// No description provided for @optionsResetControlsMessage.
  ///
  /// In en, this message translates to:
  /// **'Touch running, joystick side, control hints and opacity will be reset. Keyboard and controller bindings will be kept.'**
  String get optionsResetControlsMessage;

  /// No description provided for @optionsResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Only the settings in “{category}” will be reset. Your save and other categories will be kept.'**
  String optionsResetMessage({required String category});

  /// No description provided for @optionsRenderScalePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent} %'**
  String optionsRenderScalePercent({required int percent});

  /// No description provided for @optionsFsr.
  ///
  /// In en, this message translates to:
  /// **'FSR 1 (AMD)'**
  String get optionsFsr;

  /// No description provided for @optionsFrameRateValue.
  ///
  /// In en, this message translates to:
  /// **'{rate} FPS'**
  String optionsFrameRateValue({required int rate});

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @partyTradeWithItself.
  ///
  /// In en, this message translates to:
  /// **'With itself'**
  String get partyTradeWithItself;

  /// No description provided for @partyTradeChoosePartner.
  ///
  /// In en, this message translates to:
  /// **'Choose a partner'**
  String get partyTradeChoosePartner;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @partyTradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Party trade'**
  String get partyTradeTitle;

  /// No description provided for @partyTradeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trade completed.'**
  String get partyTradeCompleted;

  /// No description provided for @partyTradeConfirmTrade.
  ///
  /// In en, this message translates to:
  /// **'Confirm this trade?'**
  String get partyTradeConfirmTrade;

  /// No description provided for @partyTradeSelectPartner.
  ///
  /// In en, this message translates to:
  /// **'Choose its partner from your party.'**
  String get partyTradeSelectPartner;

  /// No description provided for @partyTradeChooseAnotherPartner.
  ///
  /// In en, this message translates to:
  /// **'Choose another Pokémon as partner?'**
  String get partyTradeChooseAnotherPartner;

  /// No description provided for @partyTradeSelectPokemon.
  ///
  /// In en, this message translates to:
  /// **'Choose the Pokémon to trade.'**
  String get partyTradeSelectPokemon;

  /// No description provided for @partyTradeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Trade is unavailable.'**
  String get partyTradeUnavailable;

  /// No description provided for @pcNextBox.
  ///
  /// In en, this message translates to:
  /// **'Next box'**
  String get pcNextBox;

  /// No description provided for @pcPreviousBox.
  ///
  /// In en, this message translates to:
  /// **'Previous box'**
  String get pcPreviousBox;

  /// No description provided for @pokemonSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get pokemonSummary;

  /// No description provided for @giftSentToPc.
  ///
  /// In en, this message translates to:
  /// **'{nickname} will be sent to the PC.'**
  String giftSentToPc({required String nickname});

  /// No description provided for @giftJoinsParty.
  ///
  /// In en, this message translates to:
  /// **'{nickname} will join your party.'**
  String giftJoinsParty({required String nickname});

  /// No description provided for @giftNewPokedexEntry.
  ///
  /// In en, this message translates to:
  /// **'New Pokédex entry to add'**
  String get giftNewPokedexEntry;

  /// No description provided for @giftTitle.
  ///
  /// In en, this message translates to:
  /// **'A new companion'**
  String get giftTitle;

  /// No description provided for @giftEgg.
  ///
  /// In en, this message translates to:
  /// **'The Egg'**
  String get giftEgg;

  /// No description provided for @pokemonEggEntrusted.
  ///
  /// In en, this message translates to:
  /// **'An Egg entrusted to your party.'**
  String get pokemonEggEntrusted;

  /// No description provided for @keyboardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get keyboardDelete;

  /// No description provided for @keyboardSpace.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get keyboardSpace;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @bagTargetIncompatible.
  ///
  /// In en, this message translates to:
  /// **'Not compatible.'**
  String get bagTargetIncompatible;

  /// No description provided for @bagActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action failed. Try again.'**
  String get bagActionFailed;

  /// No description provided for @bagNoEligibleTarget.
  ///
  /// In en, this message translates to:
  /// **'No companion can receive this item.'**
  String get bagNoEligibleTarget;

  /// No description provided for @bagAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get bagAddFavorite;

  /// No description provided for @bagRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get bagRemoveFavorite;

  /// No description provided for @bagFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get bagFavorite;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @bagCannotUse.
  ///
  /// In en, this message translates to:
  /// **'This item cannot be used here.'**
  String get bagCannotUse;

  /// No description provided for @bagPocketEmpty.
  ///
  /// In en, this message translates to:
  /// **'This pocket is empty.'**
  String get bagPocketEmpty;

  /// No description provided for @bagEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bag is empty.'**
  String get bagEmpty;

  /// No description provided for @bagPreviousPockets.
  ///
  /// In en, this message translates to:
  /// **'Previous pockets'**
  String get bagPreviousPockets;

  /// No description provided for @bagNextPockets.
  ///
  /// In en, this message translates to:
  /// **'Next pockets'**
  String get bagNextPockets;

  /// No description provided for @bagFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get bagFavorites;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @optionsResetBindings.
  ///
  /// In en, this message translates to:
  /// **'Only {device} bindings will be reset. Other settings will be kept.'**
  String optionsResetBindings({required String device});

  /// No description provided for @optionsResetCategory.
  ///
  /// In en, this message translates to:
  /// **'Reset this category'**
  String get optionsResetCategory;

  /// No description provided for @optionsNextCategory.
  ///
  /// In en, this message translates to:
  /// **'Next category'**
  String get optionsNextCategory;

  /// No description provided for @optionsPreviousCategory.
  ///
  /// In en, this message translates to:
  /// **'Previous category'**
  String get optionsPreviousCategory;

  /// No description provided for @optionsTouchSettings.
  ///
  /// In en, this message translates to:
  /// **'Touch settings'**
  String get optionsTouchSettings;

  /// No description provided for @optionsCategoriesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Options categories'**
  String get optionsCategoriesTooltip;

  /// No description provided for @partyNoCompatibleItem.
  ///
  /// In en, this message translates to:
  /// **'No compatible item in the bag.'**
  String get partyNoCompatibleItem;

  /// No description provided for @partyHeldItemsHelp.
  ///
  /// In en, this message translates to:
  /// **'Giving takes one item from the bag. Replacing or taking returns the current item to the bag.'**
  String get partyHeldItemsHelp;

  /// No description provided for @partyMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get partyMove;

  /// No description provided for @bagItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get bagItem;

  /// No description provided for @partyLead.
  ///
  /// In en, this message translates to:
  /// **'Lead'**
  String get partyLead;

  /// No description provided for @pokemonFainted.
  ///
  /// In en, this message translates to:
  /// **'Fainted'**
  String get pokemonFainted;

  /// No description provided for @partySwapPositions.
  ///
  /// In en, this message translates to:
  /// **'The two Pokémon will swap places.'**
  String get partySwapPositions;

  /// No description provided for @partyChooseNewPosition.
  ///
  /// In en, this message translates to:
  /// **'Choose the new position'**
  String get partyChooseNewPosition;

  /// No description provided for @partyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your party is empty'**
  String get partyEmpty;

  /// No description provided for @partyActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The action could not be completed. Try again.'**
  String get partyActionFailed;

  /// No description provided for @pokedexNotEncountered.
  ///
  /// In en, this message translates to:
  /// **'This Pokémon has not been encountered yet.'**
  String get pokedexNotEncountered;

  /// No description provided for @pokedexDescriptionHeading.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get pokedexDescriptionHeading;

  /// No description provided for @pokedexSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'Try another name, number or filter.'**
  String get pokedexSearchNoResults;

  /// No description provided for @pokedexEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No entries available.'**
  String get pokedexEmptyMessage;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @pokedexEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty Pokédex'**
  String get pokedexEmpty;

  /// No description provided for @pokedexCaughtFilter.
  ///
  /// In en, this message translates to:
  /// **'Caught'**
  String get pokedexCaughtFilter;

  /// No description provided for @pokedexSeenFilter.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get pokedexSeenFilter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @pokedexSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name or number'**
  String get pokedexSearchHint;

  /// No description provided for @pokedexCaught.
  ///
  /// In en, this message translates to:
  /// **'Caught'**
  String get pokedexCaught;

  /// No description provided for @pokedexSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get pokedexSeen;

  /// No description provided for @pokedexUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get pokedexUnknown;

  /// No description provided for @profileCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get profileCurrentLocation;

  /// No description provided for @profileEarnedBadges.
  ///
  /// In en, this message translates to:
  /// **'Earned badges'**
  String get profileEarnedBadges;

  /// No description provided for @profilePokemonCaught.
  ///
  /// In en, this message translates to:
  /// **'Pokémon caught'**
  String get profilePokemonCaught;

  /// No description provided for @profilePokemonSeen.
  ///
  /// In en, this message translates to:
  /// **'Pokémon seen'**
  String get profilePokemonSeen;

  /// No description provided for @profilePokedexTotal.
  ///
  /// In en, this message translates to:
  /// **'Pokédex total'**
  String get profilePokedexTotal;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @profilePortrait.
  ///
  /// In en, this message translates to:
  /// **'{name}’s portrait'**
  String profilePortrait({required String name});

  /// No description provided for @profileCardHeading.
  ///
  /// In en, this message translates to:
  /// **'PLAYER CARD'**
  String get profileCardHeading;

  /// No description provided for @mapPositionMissing.
  ///
  /// In en, this message translates to:
  /// **'Position not provided.'**
  String get mapPositionMissing;

  /// No description provided for @mapLocationNotDiscovered.
  ///
  /// In en, this message translates to:
  /// **'This location has not been discovered yet.'**
  String get mapLocationNotDiscovered;

  /// No description provided for @mapSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select a location.'**
  String get mapSelectLocation;

  /// No description provided for @mapLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Choose another location.'**
  String get mapLocationUnavailable;

  /// No description provided for @mapCloseSelection.
  ///
  /// In en, this message translates to:
  /// **'Close selection'**
  String get mapCloseSelection;

  /// No description provided for @mapMultipleLocations.
  ///
  /// In en, this message translates to:
  /// **'Several locations here'**
  String get mapMultipleLocations;

  /// No description provided for @backToMap.
  ///
  /// In en, this message translates to:
  /// **'Back to map'**
  String get backToMap;

  /// No description provided for @mapNoLocations.
  ///
  /// In en, this message translates to:
  /// **'No locations available in this region.'**
  String get mapNoLocations;

  /// No description provided for @mapUndiscoveredLocation.
  ///
  /// In en, this message translates to:
  /// **'Undiscovered'**
  String get mapUndiscoveredLocation;

  /// No description provided for @mapDiscoveredLocation.
  ///
  /// In en, this message translates to:
  /// **'Discovered'**
  String get mapDiscoveredLocation;

  /// No description provided for @mapCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get mapCurrentLocation;

  /// No description provided for @loadingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get loadingReady;

  /// No description provided for @loadingPlacingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Placing player'**
  String get loadingPlacingPlayer;

  /// No description provided for @loadingMountingMap.
  ///
  /// In en, this message translates to:
  /// **'Mounting map'**
  String get loadingMountingMap;

  /// No description provided for @loadingAssets.
  ///
  /// In en, this message translates to:
  /// **'Loading assets'**
  String get loadingAssets;

  /// No description provided for @loadingBuildingScene.
  ///
  /// In en, this message translates to:
  /// **'Building scene'**
  String get loadingBuildingScene;

  /// No description provided for @loadingPreparingWorld.
  ///
  /// In en, this message translates to:
  /// **'Preparing world'**
  String get loadingPreparingWorld;

  /// No description provided for @loadingReadingSave.
  ///
  /// In en, this message translates to:
  /// **'Reading save'**
  String get loadingReadingSave;

  /// No description provided for @loadingOpeningGame.
  ///
  /// In en, this message translates to:
  /// **'Opening game'**
  String get loadingOpeningGame;

  /// No description provided for @weatherNoCityFound.
  ///
  /// In en, this message translates to:
  /// **'No city found.'**
  String get weatherNoCityFound;

  /// No description provided for @weatherSearchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable. Please try later.'**
  String get weatherSearchUnavailable;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @weatherSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get weatherSearching;

  /// No description provided for @weatherLocationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'City, region or country'**
  String get weatherLocationSearchHint;

  /// No description provided for @weatherLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather location'**
  String get weatherLocationTitle;

  /// No description provided for @weatherDataAdapted.
  ///
  /// In en, this message translates to:
  /// **'Weather data adapted for game rendering.'**
  String get weatherDataAdapted;

  /// No description provided for @linkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Link unavailable.'**
  String get linkUnavailable;

  /// No description provided for @weatherRefreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Refresh every 20 minutes'**
  String get weatherRefreshInterval;

  /// No description provided for @weatherOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline · cached or game weather'**
  String get weatherOffline;

  /// No description provided for @weatherRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get weatherRefreshing;

  /// No description provided for @weatherDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Detected by IP when gameplay starts'**
  String get weatherDetectLocation;

  /// No description provided for @weatherIpDisclosure.
  ///
  /// In en, this message translates to:
  /// **'GeoJS and Open-Meteo receive your IP.'**
  String get weatherIpDisclosure;

  /// No description provided for @weatherApproximateLocation.
  ///
  /// In en, this message translates to:
  /// **'Approximate IP location, without GPS.'**
  String get weatherApproximateLocation;

  /// No description provided for @weatherCompatibleGames.
  ///
  /// In en, this message translates to:
  /// **'Real weather for supported games.'**
  String get weatherCompatibleGames;

  /// No description provided for @weatherUseIpLocation.
  ///
  /// In en, this message translates to:
  /// **'Use IP location again'**
  String get weatherUseIpLocation;

  /// No description provided for @weatherChooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose another city'**
  String get weatherChooseCity;

  /// No description provided for @weatherMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Weather at my location'**
  String get weatherMyLocation;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @loadingActivatingMap.
  ///
  /// In en, this message translates to:
  /// **'Activating the map'**
  String get loadingActivatingMap;

  /// No description provided for @cancelFishing.
  ///
  /// In en, this message translates to:
  /// **'Cancel fishing'**
  String get cancelFishing;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @pagePosition.
  ///
  /// In en, this message translates to:
  /// **'{label} {current} / {total}'**
  String pagePosition({
    required String label,
    required int current,
    required int total,
  });

  /// No description provided for @previousPageWithPosition.
  ///
  /// In en, this message translates to:
  /// **'Previous page · {position}'**
  String previousPageWithPosition({required String position});

  /// No description provided for @nextPageWithPosition.
  ///
  /// In en, this message translates to:
  /// **'Next page · {position}'**
  String nextPageWithPosition({required String position});

  /// No description provided for @pokemonNameAndLevel.
  ///
  /// In en, this message translates to:
  /// **'{name} · Lv. {level}'**
  String pokemonNameAndLevel({required String name, required int level});

  /// No description provided for @pokemonNameAndNickname.
  ///
  /// In en, this message translates to:
  /// **'{nickname} · {name}'**
  String pokemonNameAndNickname({
    required String nickname,
    required String name,
  });

  /// No description provided for @partyTradePokemon.
  ///
  /// In en, this message translates to:
  /// **'Pokémon: {name}'**
  String partyTradePokemon({required String name});

  /// No description provided for @partyTradePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner: {name}'**
  String partyTradePartner({required String name});

  /// No description provided for @pokemonTabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get pokemonTabStats;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @shopUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price : {amount} ₽'**
  String shopUnitPrice({required int amount});

  /// No description provided for @shopMoney.
  ///
  /// In en, this message translates to:
  /// **'Money : {amount} ₽'**
  String shopMoney({required int amount});

  /// No description provided for @shopBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after : {amount} ₽'**
  String shopBalanceAfter({required int amount});

  /// No description provided for @bagLearnMove.
  ///
  /// In en, this message translates to:
  /// **'Learn {move}'**
  String bagLearnMove({required String move});

  /// No description provided for @bagLearnReplacingMove.
  ///
  /// In en, this message translates to:
  /// **'Learn {move} — forget {forgottenMove}'**
  String bagLearnReplacingMove({
    required String move,
    required String forgottenMove,
  });

  /// No description provided for @regionalMapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Regional map unavailable.'**
  String get regionalMapUnavailable;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get mapRecenter;

  /// No description provided for @mapLocations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get mapLocations;

  /// No description provided for @bagMoney.
  ///
  /// In en, this message translates to:
  /// **'Money : {amount}'**
  String bagMoney({required String amount});

  /// No description provided for @bagMoneyWithCurrency.
  ///
  /// In en, this message translates to:
  /// **'Money : {amount} {currency}'**
  String bagMoneyWithCurrency({
    required String amount,
    required String currency,
  });

  /// No description provided for @pokedexProgress.
  ///
  /// In en, this message translates to:
  /// **'Seen {seen} · Caught {caught} / {total}'**
  String pokedexProgress({
    required String seen,
    required String caught,
    required String total,
  });

  /// No description provided for @weatherClear.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get weatherClear;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get weatherDrizzle;

  /// No description provided for @weatherRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// No description provided for @weatherDownpour.
  ///
  /// In en, this message translates to:
  /// **'Downpour'**
  String get weatherDownpour;

  /// No description provided for @weatherStorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherStorm;

  /// No description provided for @weatherSnow.
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get weatherSnow;

  /// No description provided for @weatherBlizzard.
  ///
  /// In en, this message translates to:
  /// **'Blizzard'**
  String get weatherBlizzard;

  /// No description provided for @weatherHail.
  ///
  /// In en, this message translates to:
  /// **'Hail'**
  String get weatherHail;

  /// No description provided for @weatherMist.
  ///
  /// In en, this message translates to:
  /// **'Mist'**
  String get weatherMist;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// No description provided for @weatherDust.
  ///
  /// In en, this message translates to:
  /// **'Dust'**
  String get weatherDust;

  /// No description provided for @weatherSandstorm.
  ///
  /// In en, this message translates to:
  /// **'Sandstorm'**
  String get weatherSandstorm;

  /// No description provided for @weatherPetals.
  ///
  /// In en, this message translates to:
  /// **'Petals'**
  String get weatherPetals;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherWindy.
  ///
  /// In en, this message translates to:
  /// **'Windy'**
  String get weatherWindy;

  /// No description provided for @weatherHeavySnow.
  ///
  /// In en, this message translates to:
  /// **'Heavy snow'**
  String get weatherHeavySnow;

  /// No description provided for @weatherSleet.
  ///
  /// In en, this message translates to:
  /// **'Sleet'**
  String get weatherSleet;

  /// No description provided for @weatherTempest.
  ///
  /// In en, this message translates to:
  /// **'Severe thunderstorm'**
  String get weatherTempest;

  /// No description provided for @weatherLeaves.
  ///
  /// In en, this message translates to:
  /// **'Autumn leaves'**
  String get weatherLeaves;

  /// No description provided for @weatherReceived.
  ///
  /// In en, this message translates to:
  /// **'Received weather : {weather}'**
  String weatherReceived({required String weather});

  /// No description provided for @weatherCity.
  ///
  /// In en, this message translates to:
  /// **'City : {city}'**
  String weatherCity({required String city});

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @craftCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get craftCollect;

  /// No description provided for @craftConfirmDeposit.
  ///
  /// In en, this message translates to:
  /// **'Confirm deposit'**
  String get craftConfirmDeposit;

  /// No description provided for @craftReviewOrder.
  ///
  /// In en, this message translates to:
  /// **'Review order'**
  String get craftReviewOrder;

  /// No description provided for @craftDecreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get craftDecreaseQuantity;

  /// No description provided for @craftIncreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get craftIncreaseQuantity;

  /// No description provided for @puzzleTray.
  ///
  /// In en, this message translates to:
  /// **'Tray'**
  String get puzzleTray;

  /// No description provided for @puzzleTitle.
  ///
  /// In en, this message translates to:
  /// **'Image puzzle'**
  String get puzzleTitle;

  /// No description provided for @puzzleInstructions.
  ///
  /// In en, this message translates to:
  /// **'Select a piece, then its destination. Press R to rotate the piece.'**
  String get puzzleInstructions;

  /// No description provided for @puzzleImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The image could not be displayed. Exit and reopen the puzzle.'**
  String get puzzleImageUnavailable;

  /// No description provided for @puzzleRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get puzzleRotate;

  /// No description provided for @puzzleReset.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get puzzleReset;

  /// No description provided for @puzzleCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get puzzleCheck;

  /// No description provided for @puzzleFixed.
  ///
  /// In en, this message translates to:
  /// **'fixed'**
  String get puzzleFixed;

  /// No description provided for @puzzleSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get puzzleSelected;

  /// No description provided for @quit.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get quit;

  /// No description provided for @mapFly.
  ///
  /// In en, this message translates to:
  /// **'Fly'**
  String get mapFly;

  /// No description provided for @mapZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get mapZoom;

  /// No description provided for @englishLanguageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguageName;

  /// No description provided for @frenchLanguageName.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get frenchLanguageName;

  /// No description provided for @controllerSouthButton.
  ///
  /// In en, this message translates to:
  /// **'South button'**
  String get controllerSouthButton;

  /// No description provided for @controllerEastButton.
  ///
  /// In en, this message translates to:
  /// **'East button'**
  String get controllerEastButton;

  /// No description provided for @controllerWestButton.
  ///
  /// In en, this message translates to:
  /// **'West button'**
  String get controllerWestButton;

  /// No description provided for @controllerNorthButton.
  ///
  /// In en, this message translates to:
  /// **'North button'**
  String get controllerNorthButton;

  /// No description provided for @controllerSelectButton.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get controllerSelectButton;

  /// No description provided for @controllerMenuButton.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get controllerMenuButton;

  /// No description provided for @keyboardEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get keyboardEnter;

  /// No description provided for @craftPendingOrder.
  ///
  /// In en, this message translates to:
  /// **'Your order is being prepared: {quantity} × {item}. Come back another day.'**
  String craftPendingOrder({required int quantity, required String item});

  /// No description provided for @craftReadyOrder.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready: {quantity} × {item}.'**
  String craftReadyOrder({required int quantity, required String item});

  /// No description provided for @craftRecipe.
  ///
  /// In en, this message translates to:
  /// **'{recipe} · {exchange} · Bag: {owned}'**
  String craftRecipe({
    required String recipe,
    required String exchange,
    required int owned,
  });

  /// No description provided for @craftExchange.
  ///
  /// In en, this message translates to:
  /// **'{inputQuantity} × {input} → {outputQuantity} × {output}'**
  String craftExchange({
    required int inputQuantity,
    required String input,
    required int outputQuantity,
    required String output,
  });

  /// No description provided for @craftQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {quantity} · Maximum available: {maximum}'**
  String craftQuantity({required int quantity, required int maximum});

  /// No description provided for @puzzleEmptySlot.
  ///
  /// In en, this message translates to:
  /// **'Empty slot {index}'**
  String puzzleEmptySlot({required int index});

  /// No description provided for @puzzlePiece.
  ///
  /// In en, this message translates to:
  /// **'Piece {index}'**
  String puzzlePiece({required int index});

  /// No description provided for @puzzleFixedPiece.
  ///
  /// In en, this message translates to:
  /// **'Piece {index}, fixed'**
  String puzzleFixedPiece({required int index});

  /// No description provided for @dialogueSpeakerPortrait.
  ///
  /// In en, this message translates to:
  /// **'Portrait of {speaker}'**
  String dialogueSpeakerPortrait({required String speaker});

  /// No description provided for @startupReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get startupReady;

  /// No description provided for @startupPreparingJourney.
  ///
  /// In en, this message translates to:
  /// **'PREPARING THE JOURNEY'**
  String get startupPreparingJourney;

  /// No description provided for @startupPlayerPreferences.
  ///
  /// In en, this message translates to:
  /// **'PLAYER PREFERENCES'**
  String get startupPlayerPreferences;

  /// No description provided for @startupFindingSave.
  ///
  /// In en, this message translates to:
  /// **'FINDING THE SAVE'**
  String get startupFindingSave;

  /// No description provided for @startupWorldAssets.
  ///
  /// In en, this message translates to:
  /// **'MAPS AND WORLD ASSETS'**
  String get startupWorldAssets;

  /// No description provided for @startupPresentationProfile.
  ///
  /// In en, this message translates to:
  /// **'PRESENTATION PROFILE'**
  String get startupPresentationProfile;

  /// No description provided for @startupSplashBranding.
  ///
  /// In en, this message translates to:
  /// **'PREPARING THE SPLASH'**
  String get startupSplashBranding;

  /// No description provided for @startupPreparingScene.
  ///
  /// In en, this message translates to:
  /// **'PREPARING THE SCENE'**
  String get startupPreparingScene;

  /// No description provided for @startupMenuAndMusic.
  ///
  /// In en, this message translates to:
  /// **'MENU AND MUSIC'**
  String get startupMenuAndMusic;

  /// No description provided for @craftPending.
  ///
  /// In en, this message translates to:
  /// **'Your order is being prepared. Come back another day.'**
  String get craftPending;

  /// No description provided for @craftReady.
  ///
  /// In en, this message translates to:
  /// **'Your order is ready.'**
  String get craftReady;

  /// No description provided for @battleNarrationPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get battleNarrationPlayer;

  /// No description provided for @battleNarrationEnemy.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get battleNarrationEnemy;

  /// No description provided for @battleWildAppeared.
  ///
  /// In en, this message translates to:
  /// **'A wild {target} appeared!'**
  String battleWildAppeared({required String target});

  /// No description provided for @battleTrainerChallenges.
  ///
  /// In en, this message translates to:
  /// **'Trainer {actor} challenges you!'**
  String battleTrainerChallenges({required String actor});

  /// No description provided for @battleUnknownTrainerChallenges.
  ///
  /// In en, this message translates to:
  /// **'A Trainer challenges you!'**
  String get battleUnknownTrainerChallenges;

  /// No description provided for @battleTrainerSends.
  ///
  /// In en, this message translates to:
  /// **'Trainer {actor} sent out {target}!'**
  String battleTrainerSends({required String actor, required String target});

  /// No description provided for @battleUnknownTrainerSends.
  ///
  /// In en, this message translates to:
  /// **'The Trainer sent out {target}!'**
  String battleUnknownTrainerSends({required String target});

  /// No description provided for @battleSendOut.
  ///
  /// In en, this message translates to:
  /// **'Go, {target}!'**
  String battleSendOut({required String target});

  /// No description provided for @battleJoined.
  ///
  /// In en, this message translates to:
  /// **'{target} joined the battle!'**
  String battleJoined({required String target});

  /// No description provided for @battleConfusionHurt.
  ///
  /// In en, this message translates to:
  /// **'It hurt itself in its confusion!'**
  String get battleConfusionHurt;

  /// No description provided for @battleMoveUsed.
  ///
  /// In en, this message translates to:
  /// **'{actor} used {move}!'**
  String battleMoveUsed({required String actor, required String move});

  /// No description provided for @battleMoveDodged.
  ///
  /// In en, this message translates to:
  /// **'{target} avoided the attack!'**
  String battleMoveDodged({required String target});

  /// No description provided for @battleMoveImmune.
  ///
  /// In en, this message translates to:
  /// **'It doesn’t affect {target}…'**
  String battleMoveImmune({required String target});

  /// No description provided for @battleCriticalHit.
  ///
  /// In en, this message translates to:
  /// **'A critical hit!'**
  String get battleCriticalHit;

  /// No description provided for @battleSuperEffective.
  ///
  /// In en, this message translates to:
  /// **'It’s super effective!'**
  String get battleSuperEffective;

  /// No description provided for @battleNotVeryEffective.
  ///
  /// In en, this message translates to:
  /// **'It’s not very effective…'**
  String get battleNotVeryEffective;

  /// No description provided for @battleFainted.
  ///
  /// In en, this message translates to:
  /// **'{target} fainted!'**
  String battleFainted({required String target});

  /// No description provided for @battleItemUsed.
  ///
  /// In en, this message translates to:
  /// **'{actor} used {item} on {target}!'**
  String battleItemUsed({
    required String actor,
    required String item,
    required String target,
  });

  /// No description provided for @battleHpRecovered.
  ///
  /// In en, this message translates to:
  /// **'{target} recovered {amount} HP.'**
  String battleHpRecovered({required String target, required int amount});

  /// No description provided for @battleStatusCured.
  ///
  /// In en, this message translates to:
  /// **'{target} recovered from its status condition.'**
  String battleStatusCured({required String target});

  /// No description provided for @battlePpRecovered.
  ///
  /// In en, this message translates to:
  /// **'{move} recovered {amount} PP.'**
  String battlePpRecovered({required String move, required int amount});

  /// No description provided for @battleCaptureThrown.
  ///
  /// In en, this message translates to:
  /// **'A Poké Ball was thrown at {target}!'**
  String battleCaptureThrown({required String target});

  /// No description provided for @battleCaptureCaught.
  ///
  /// In en, this message translates to:
  /// **'{target} was caught!'**
  String battleCaptureCaught({required String target});

  /// No description provided for @battleCaptureEscaped.
  ///
  /// In en, this message translates to:
  /// **'{target} broke free from the Poké Ball!'**
  String battleCaptureEscaped({required String target});

  /// No description provided for @battleParalyzed.
  ///
  /// In en, this message translates to:
  /// **'{target} was paralyzed! It may be unable to move!'**
  String battleParalyzed({required String target});

  /// No description provided for @battleBurned.
  ///
  /// In en, this message translates to:
  /// **'{target} was burned!'**
  String battleBurned({required String target});

  /// No description provided for @battlePoisoned.
  ///
  /// In en, this message translates to:
  /// **'{target} was poisoned!'**
  String battlePoisoned({required String target});

  /// No description provided for @battleBadlyPoisoned.
  ///
  /// In en, this message translates to:
  /// **'{target} was badly poisoned!'**
  String battleBadlyPoisoned({required String target});

  /// No description provided for @battleFellAsleep.
  ///
  /// In en, this message translates to:
  /// **'{target} fell asleep!'**
  String battleFellAsleep({required String target});

  /// No description provided for @battleFrozen.
  ///
  /// In en, this message translates to:
  /// **'{target} was frozen solid!'**
  String battleFrozen({required String target});

  /// No description provided for @battleAlreadyHasStatus.
  ///
  /// In en, this message translates to:
  /// **'{target} already has a status condition.'**
  String battleAlreadyHasStatus({required String target});

  /// No description provided for @battleCannotAct.
  ///
  /// In en, this message translates to:
  /// **'{target} can’t move!'**
  String battleCannotAct({required String target});

  /// No description provided for @battleBurnDamage.
  ///
  /// In en, this message translates to:
  /// **'{target} was hurt by its burn!'**
  String battleBurnDamage({required String target});

  /// No description provided for @battlePoisonDamage.
  ///
  /// In en, this message translates to:
  /// **'{target} was hurt by poison!'**
  String battlePoisonDamage({required String target});

  /// No description provided for @battleStatusDamage.
  ///
  /// In en, this message translates to:
  /// **'{target} took damage!'**
  String battleStatusDamage({required String target});

  /// No description provided for @battleProtectActivated.
  ///
  /// In en, this message translates to:
  /// **'{actor} protected itself!'**
  String battleProtectActivated({required String actor});

  /// No description provided for @battleProtectBlocked.
  ///
  /// In en, this message translates to:
  /// **'The target protected itself from the attack!'**
  String get battleProtectBlocked;

  /// No description provided for @battleProtectBroken.
  ///
  /// In en, this message translates to:
  /// **'The protection was broken!'**
  String get battleProtectBroken;

  /// No description provided for @battleRechargeRequired.
  ///
  /// In en, this message translates to:
  /// **'{actor} must recharge!'**
  String battleRechargeRequired({required String actor});

  /// No description provided for @battleRechargeTurnSpent.
  ///
  /// In en, this message translates to:
  /// **'{actor} is catching its breath.'**
  String battleRechargeTurnSpent({required String actor});

  /// No description provided for @battleChargeStarted.
  ///
  /// In en, this message translates to:
  /// **'{actor} began charging!'**
  String battleChargeStarted({required String actor});

  /// No description provided for @battleChargeReleased.
  ///
  /// In en, this message translates to:
  /// **'{actor} unleashed its attack!'**
  String battleChargeReleased({required String actor});

  /// No description provided for @battleConfusionApplied.
  ///
  /// In en, this message translates to:
  /// **'{actor} became confused!'**
  String battleConfusionApplied({required String actor});

  /// No description provided for @battleConfusionActive.
  ///
  /// In en, this message translates to:
  /// **'{actor} is confused!'**
  String battleConfusionActive({required String actor});

  /// No description provided for @battleConfusionEnded.
  ///
  /// In en, this message translates to:
  /// **'{actor} snapped out of confusion!'**
  String battleConfusionEnded({required String actor});

  /// No description provided for @battleRainStarted.
  ///
  /// In en, this message translates to:
  /// **'It started to rain.'**
  String get battleRainStarted;

  /// No description provided for @battleSandstormStarted.
  ///
  /// In en, this message translates to:
  /// **'A sandstorm kicked up.'**
  String get battleSandstormStarted;

  /// No description provided for @battleSandstormDamage.
  ///
  /// In en, this message translates to:
  /// **'{target} was buffeted by the sandstorm!'**
  String battleSandstormDamage({required String target});

  /// No description provided for @battleWeatherExpired.
  ///
  /// In en, this message translates to:
  /// **'The weather subsided.'**
  String get battleWeatherExpired;

  /// No description provided for @battleTrickRoomStarted.
  ///
  /// In en, this message translates to:
  /// **'The dimensions twisted.'**
  String get battleTrickRoomStarted;

  /// No description provided for @battleFieldCleared.
  ///
  /// In en, this message translates to:
  /// **'The field effect was cleared.'**
  String get battleFieldCleared;

  /// No description provided for @battleFieldExpired.
  ///
  /// In en, this message translates to:
  /// **'The field effect wore off.'**
  String get battleFieldExpired;

  /// No description provided for @battleStealthRockSet.
  ///
  /// In en, this message translates to:
  /// **'Pointed stones float around the opposing team!'**
  String get battleStealthRockSet;

  /// No description provided for @battleStealthRockAlreadyPresent.
  ///
  /// In en, this message translates to:
  /// **'Pointed stones are already in place.'**
  String get battleStealthRockAlreadyPresent;

  /// No description provided for @battleStealthRockDamage.
  ///
  /// In en, this message translates to:
  /// **'Pointed stones hurt the incoming Pokémon!'**
  String get battleStealthRockDamage;

  /// No description provided for @battleSpikesSet.
  ///
  /// In en, this message translates to:
  /// **'Spikes were scattered around the opposing team!'**
  String get battleSpikesSet;

  /// No description provided for @battleSpikesAlreadyPresent.
  ///
  /// In en, this message translates to:
  /// **'Spikes are already at their maximum.'**
  String get battleSpikesAlreadyPresent;

  /// No description provided for @battleSpikesDamage.
  ///
  /// In en, this message translates to:
  /// **'Spikes hurt the incoming Pokémon!'**
  String get battleSpikesDamage;

  /// No description provided for @battleSwitched.
  ///
  /// In en, this message translates to:
  /// **'{actor} withdrew {target} and sent out {replacement}!'**
  String battleSwitched({
    required String actor,
    required String target,
    required String replacement,
  });

  /// No description provided for @battleReplacementRequired.
  ///
  /// In en, this message translates to:
  /// **'{actor} must replace {target}!'**
  String battleReplacementRequired({
    required String actor,
    required String target,
  });

  /// No description provided for @battleStatRaised.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{{target}’s {stat} rose!} =2{{target}’s {stat} rose sharply!} other{{target}’s {stat} rose drastically!}}'**
  String battleStatRaised({
    required String target,
    required String stat,
    required int amount,
  });

  /// No description provided for @battleStatLowered.
  ///
  /// In en, this message translates to:
  /// **'{amount, plural, =1{{target}’s {stat} fell!} =2{{target}’s {stat} fell sharply!} other{{target}’s {stat} fell drastically!}}'**
  String battleStatLowered({
    required String target,
    required String stat,
    required int amount,
  });

  /// No description provided for @battleStatCannotRaise.
  ///
  /// In en, this message translates to:
  /// **'{target}’s {stat} won’t go any higher!'**
  String battleStatCannotRaise({required String target, required String stat});

  /// No description provided for @battleStatCannotLower.
  ///
  /// In en, this message translates to:
  /// **'{target}’s {stat} won’t go any lower!'**
  String battleStatCannotLower({required String target, required String stat});

  /// No description provided for @battleStatName.
  ///
  /// In en, this message translates to:
  /// **'{stat, select, attack{Attack} defense{Defense} specialAttack{Special Attack} specialDefense{Special Defense} speed{Speed} accuracy{Accuracy} other{Evasion}}'**
  String battleStatName({required String stat});

  /// No description provided for @battleMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'But it failed!'**
  String get battleMoveFailed;

  /// No description provided for @battleFleeFailed.
  ///
  /// In en, this message translates to:
  /// **'You couldn’t get away.'**
  String get battleFleeFailed;

  /// No description provided for @battleNarrationVictory.
  ///
  /// In en, this message translates to:
  /// **'You won the battle!'**
  String get battleNarrationVictory;

  /// No description provided for @battleNarrationDefeat.
  ///
  /// In en, this message translates to:
  /// **'You have no Pokémon left that can fight!'**
  String get battleNarrationDefeat;

  /// No description provided for @battleNarrationFled.
  ///
  /// In en, this message translates to:
  /// **'You got away safely!'**
  String get battleNarrationFled;

  /// No description provided for @postBattleVictoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get postBattleVictoryMessage;

  /// No description provided for @postBattleDefeatMessage.
  ///
  /// In en, this message translates to:
  /// **'All your Pokémon fainted.'**
  String get postBattleDefeatMessage;

  /// No description provided for @postBattleFledMessage.
  ///
  /// In en, this message translates to:
  /// **'You got away safely!'**
  String get postBattleFledMessage;

  /// No description provided for @postBattleCapturedMessage.
  ///
  /// In en, this message translates to:
  /// **'{target} was caught.'**
  String postBattleCapturedMessage({required String target});

  /// No description provided for @postBattleCaptureParty.
  ///
  /// In en, this message translates to:
  /// **'{target} joined your party.'**
  String postBattleCaptureParty({required String target});

  /// No description provided for @postBattleCaptureStorage.
  ///
  /// In en, this message translates to:
  /// **'{target} was sent to storage.'**
  String postBattleCaptureStorage({required String target});

  /// No description provided for @postBattleCaptureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'There’s nowhere to send the captured Pokémon.'**
  String get postBattleCaptureUnavailable;

  /// No description provided for @postBattleExperienceMessage.
  ///
  /// In en, this message translates to:
  /// **'{target} gained {amount} Exp. Points!'**
  String postBattleExperienceMessage({
    required String target,
    required int amount,
  });

  /// No description provided for @postBattleLevelUpMessage.
  ///
  /// In en, this message translates to:
  /// **'{target} grew to Lv. {amount}!'**
  String postBattleLevelUpMessage({
    required String target,
    required int amount,
  });

  /// No description provided for @postBattleMoveLearningMessage.
  ///
  /// In en, this message translates to:
  /// **'{target} can learn {move}.'**
  String postBattleMoveLearningMessage({
    required String target,
    required String move,
  });

  /// No description provided for @postBattleMoveReplacementMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a move to replace with {move}.'**
  String postBattleMoveReplacementMessage({required String move});

  /// No description provided for @postBattleMoveLearnedMessage.
  ///
  /// In en, this message translates to:
  /// **'{move} was learned.'**
  String postBattleMoveLearnedMessage({required String move});

  /// No description provided for @postBattleMoveReplacedMessage.
  ///
  /// In en, this message translates to:
  /// **'{previousMove} was replaced with {move}.'**
  String postBattleMoveReplacedMessage({
    required String previousMove,
    required String move,
  });

  /// No description provided for @postBattleMoveDeclinedMessage.
  ///
  /// In en, this message translates to:
  /// **'{move} wasn’t learned.'**
  String postBattleMoveDeclinedMessage({required String move});

  /// No description provided for @postBattleEvolutionPrompt.
  ///
  /// In en, this message translates to:
  /// **'{target} wants to evolve into {replacement}.'**
  String postBattleEvolutionPrompt({
    required String target,
    required String replacement,
  });

  /// No description provided for @postBattleEvolutionAccepted.
  ///
  /// In en, this message translates to:
  /// **'{target} evolved into {replacement}.'**
  String postBattleEvolutionAccepted({
    required String target,
    required String replacement,
  });

  /// No description provided for @postBattleEvolutionRefused.
  ///
  /// In en, this message translates to:
  /// **'{target} didn’t evolve.'**
  String postBattleEvolutionRefused({required String target});

  /// No description provided for @postBattleTrainerDefeated.
  ///
  /// In en, this message translates to:
  /// **'You defeated {actor}!'**
  String postBattleTrainerDefeated({required String actor});

  /// No description provided for @postBattleMoneyMessage.
  ///
  /// In en, this message translates to:
  /// **'You won ₽{amount}!'**
  String postBattleMoneyMessage({required int amount});

  /// No description provided for @postBattleItemMessage.
  ///
  /// In en, this message translates to:
  /// **'You received {item} ×{amount}.'**
  String postBattleItemMessage({required String item, required int amount});

  /// No description provided for @postBattleFlagMessage.
  ///
  /// In en, this message translates to:
  /// **'{target} was unlocked.'**
  String postBattleFlagMessage({required String target});

  /// No description provided for @postBattleBadgeMessage.
  ///
  /// In en, this message translates to:
  /// **'You received the {target} Badge.'**
  String postBattleBadgeMessage({required String target});

  /// No description provided for @postBattleAbilityMessage.
  ///
  /// In en, this message translates to:
  /// **'You can now use {move}.'**
  String postBattleAbilityMessage({required String move});

  /// No description provided for @postBattleLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get postBattleLearn;

  /// No description provided for @postBattleDeclineMove.
  ///
  /// In en, this message translates to:
  /// **'Don’t learn'**
  String get postBattleDeclineMove;

  /// No description provided for @postBattleEvolve.
  ///
  /// In en, this message translates to:
  /// **'Evolve'**
  String get postBattleEvolve;

  /// No description provided for @postBattleDeclineEvolution.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get postBattleDeclineEvolution;

  /// No description provided for @postBattleChoose.
  ///
  /// In en, this message translates to:
  /// **'What will you do?'**
  String get postBattleChoose;

  /// No description provided for @postBattleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Done.'**
  String get postBattleCompleted;

  /// No description provided for @postBattleNoResult.
  ///
  /// In en, this message translates to:
  /// **'No battle result is available.'**
  String get postBattleNoResult;

  /// No description provided for @postBattleDecisionError.
  ///
  /// In en, this message translates to:
  /// **'The post-battle decision couldn’t be applied.'**
  String get postBattleDecisionError;

  /// No description provided for @postBattleMissingTransaction.
  ///
  /// In en, this message translates to:
  /// **'The battle has no transaction ID.'**
  String get postBattleMissingTransaction;

  /// No description provided for @postBattleAlreadyApplied.
  ///
  /// In en, this message translates to:
  /// **'This battle result was already applied.'**
  String get postBattleAlreadyApplied;

  /// No description provided for @postBattleApplyFailed.
  ///
  /// In en, this message translates to:
  /// **'The battle result couldn’t be applied.'**
  String get postBattleApplyFailed;

  /// No description provided for @postBattleMoveNotPending.
  ///
  /// In en, this message translates to:
  /// **'There’s no move learning decision to make.'**
  String get postBattleMoveNotPending;

  /// No description provided for @postBattleMoveInvalid.
  ///
  /// In en, this message translates to:
  /// **'The move learning decision was invalid.'**
  String get postBattleMoveInvalid;

  /// No description provided for @postBattleEvolutionNotPending.
  ///
  /// In en, this message translates to:
  /// **'There’s no evolution decision to make.'**
  String get postBattleEvolutionNotPending;

  /// No description provided for @postBattleEvolutionInvalid.
  ///
  /// In en, this message translates to:
  /// **'The evolution decision was invalid.'**
  String get postBattleEvolutionInvalid;

  /// No description provided for @postBattleRewardBagCapacity.
  ///
  /// In en, this message translates to:
  /// **'Your Bag can’t hold all the rewards. The battle was cancelled. Make room before retrying it.'**
  String get postBattleRewardBagCapacity;

  /// No description provided for @postBattleRewardQuantity.
  ///
  /// In en, this message translates to:
  /// **'Your Bag can’t hold that many rewards. The battle was cancelled.'**
  String get postBattleRewardQuantity;

  /// No description provided for @postBattleRewardMissingItemCatalog.
  ///
  /// In en, this message translates to:
  /// **'The reward catalog is unavailable. The battle was cancelled.'**
  String get postBattleRewardMissingItemCatalog;

  /// No description provided for @postBattleRewardUnknownItem.
  ///
  /// In en, this message translates to:
  /// **'Unknown item reward: {item}.'**
  String postBattleRewardUnknownItem({required String item});

  /// No description provided for @postBattleRewardInvalid.
  ///
  /// In en, this message translates to:
  /// **'The item reward is invalid. The battle was cancelled.'**
  String get postBattleRewardInvalid;

  /// No description provided for @postBattleRewardMissingTrainer.
  ///
  /// In en, this message translates to:
  /// **'The Trainer’s rewards couldn’t be found.'**
  String get postBattleRewardMissingTrainer;

  /// No description provided for @postBattleRewardInvalidBattle.
  ///
  /// In en, this message translates to:
  /// **'This type of battle can’t award rewards.'**
  String get postBattleRewardInvalidBattle;

  /// No description provided for @postBattleRewardMissingData.
  ///
  /// In en, this message translates to:
  /// **'The post-battle progression data is incomplete.'**
  String get postBattleRewardMissingData;

  /// No description provided for @runtimeFeedbackBicycleMissing.
  ///
  /// In en, this message translates to:
  /// **'You do not have a bicycle you can use.'**
  String get runtimeFeedbackBicycleMissing;

  /// No description provided for @runtimeFeedbackTextVariableInvalid.
  ///
  /// In en, this message translates to:
  /// **'This scene variable does not accept text.'**
  String get runtimeFeedbackTextVariableInvalid;

  /// No description provided for @runtimeFeedbackRequestClosed.
  ///
  /// In en, this message translates to:
  /// **'This request has already ended.'**
  String get runtimeFeedbackRequestClosed;

  /// No description provided for @runtimeFeedbackRequestChanged.
  ///
  /// In en, this message translates to:
  /// **'The request changed before this response arrived.'**
  String get runtimeFeedbackRequestChanged;

  /// No description provided for @runtimeFeedbackResponseNotText.
  ///
  /// In en, this message translates to:
  /// **'This response does not contain text.'**
  String get runtimeFeedbackResponseNotText;

  /// No description provided for @runtimeFeedbackResponseLengthInvalid.
  ///
  /// In en, this message translates to:
  /// **'This response does not meet the text length requirements.'**
  String get runtimeFeedbackResponseLengthInvalid;

  /// No description provided for @runtimeFeedbackTextSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The response could not be saved.'**
  String get runtimeFeedbackTextSaveFailed;

  /// No description provided for @runtimeFeedbackFlyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Fly is disabled in this game.'**
  String get runtimeFeedbackFlyDisabled;

  /// No description provided for @runtimeFeedbackFlyUnderwater.
  ///
  /// In en, this message translates to:
  /// **'Use Dive to return to the surface before using Fly.'**
  String get runtimeFeedbackFlyUnderwater;

  /// No description provided for @runtimeFeedbackFlyIndoors.
  ///
  /// In en, this message translates to:
  /// **'You cannot use Fly indoors or in caves.'**
  String get runtimeFeedbackFlyIndoors;

  /// No description provided for @runtimeFeedbackFlyDestinationUnvisited.
  ///
  /// In en, this message translates to:
  /// **'Visit this location before flying there.'**
  String get runtimeFeedbackFlyDestinationUnvisited;

  /// No description provided for @runtimeFeedbackFlyPokemonRequired.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon that can battle must know Fly.'**
  String get runtimeFeedbackFlyPokemonRequired;

  /// No description provided for @runtimeFeedbackFlyLocked.
  ///
  /// In en, this message translates to:
  /// **'You have not unlocked Fly yet.'**
  String get runtimeFeedbackFlyLocked;

  /// No description provided for @runtimeFeedbackFlyMapUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Fly is only available on supported 2D maps.'**
  String get runtimeFeedbackFlyMapUnsupported;

  /// No description provided for @runtimeFeedbackFlyArrivalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The arrival point for this location is unavailable.'**
  String get runtimeFeedbackFlyArrivalUnavailable;

  /// No description provided for @runtimeFeedbackFlyDestinationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'You cannot fly to this destination.'**
  String get runtimeFeedbackFlyDestinationUnavailable;

  /// No description provided for @runtimeFeedbackFlyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Fly to {place}?'**
  String runtimeFeedbackFlyConfirm({required String place});

  /// No description provided for @runtimeFeedbackFlyRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Travel failed and recovery could not be confirmed. Restart the game.'**
  String get runtimeFeedbackFlyRecoveryFailed;

  /// No description provided for @runtimeFeedbackFlyCancelled.
  ///
  /// In en, this message translates to:
  /// **'Fly was cancelled. Your progress was kept.'**
  String get runtimeFeedbackFlyCancelled;

  /// No description provided for @runtimeFeedbackPartyBusy.
  ///
  /// In en, this message translates to:
  /// **'The party is busy right now.'**
  String get runtimeFeedbackPartyBusy;

  /// No description provided for @runtimeFeedbackTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This target is no longer available.'**
  String get runtimeFeedbackTargetUnavailable;

  /// No description provided for @runtimeFeedbackPartyLeadSaved.
  ///
  /// In en, this message translates to:
  /// **'The new lead Pokémon was saved.'**
  String get runtimeFeedbackPartyLeadSaved;

  /// No description provided for @runtimeFeedbackPartyReorderSaved.
  ///
  /// In en, this message translates to:
  /// **'Party reordered and progress saved.'**
  String get runtimeFeedbackPartyReorderSaved;

  /// No description provided for @runtimeFeedbackPartyCommandInvalid.
  ///
  /// In en, this message translates to:
  /// **'This command is unavailable in the party menu.'**
  String get runtimeFeedbackPartyCommandInvalid;

  /// No description provided for @runtimeFeedbackPartyReorderFailed.
  ///
  /// In en, this message translates to:
  /// **'The party could not be reordered and saved.'**
  String get runtimeFeedbackPartyReorderFailed;

  /// No description provided for @runtimeFeedbackBagBusy.
  ///
  /// In en, this message translates to:
  /// **'The bag is busy right now.'**
  String get runtimeFeedbackBagBusy;

  /// No description provided for @runtimeFeedbackBagItemDefinitionInvalid.
  ///
  /// In en, this message translates to:
  /// **'This item’s definition is missing or invalid.'**
  String get runtimeFeedbackBagItemDefinitionInvalid;

  /// No description provided for @runtimeFeedbackBagStateChanged.
  ///
  /// In en, this message translates to:
  /// **'The game state changed. Reopen the bag.'**
  String get runtimeFeedbackBagStateChanged;

  /// No description provided for @runtimeFeedbackBagItemRemoved.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer in the bag.'**
  String get runtimeFeedbackBagItemRemoved;

  /// No description provided for @runtimeFeedbackBagContextualUse.
  ///
  /// In en, this message translates to:
  /// **'Using the item in the world.'**
  String get runtimeFeedbackBagContextualUse;

  /// No description provided for @runtimeFeedbackBagContextualCancelled.
  ///
  /// In en, this message translates to:
  /// **'Use cancelled. You kept the item.'**
  String get runtimeFeedbackBagContextualCancelled;

  /// No description provided for @runtimeFeedbackBagContextualUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item cannot be used in the current situation. You kept it.'**
  String get runtimeFeedbackBagContextualUnavailable;

  /// No description provided for @runtimeFeedbackBagContextualFailed.
  ///
  /// In en, this message translates to:
  /// **'The item could not be used here. You kept it.'**
  String get runtimeFeedbackBagContextualFailed;

  /// No description provided for @runtimeFeedbackBagContextualStateChanged.
  ///
  /// In en, this message translates to:
  /// **'The game state changed. You kept the item.'**
  String get runtimeFeedbackBagContextualStateChanged;

  /// No description provided for @runtimeFeedbackFishingUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Fishing is unsupported in this game mode.'**
  String get runtimeFeedbackFishingUnsupported;

  /// No description provided for @runtimeFeedbackFishingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Fishing is unavailable right now.'**
  String get runtimeFeedbackFishingUnavailable;

  /// No description provided for @runtimeFeedbackFishingPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting ready to fish.'**
  String get runtimeFeedbackFishingPreparing;

  /// No description provided for @runtimeFeedbackFishingMapUnsupported.
  ///
  /// In en, this message translates to:
  /// **'You cannot fish on this map.'**
  String get runtimeFeedbackFishingMapUnsupported;

  /// No description provided for @runtimeFeedbackFishingRodInvalid.
  ///
  /// In en, this message translates to:
  /// **'This item is not a usable fishing rod.'**
  String get runtimeFeedbackFishingRodInvalid;

  /// No description provided for @runtimeFeedbackFishingRodMissing.
  ///
  /// In en, this message translates to:
  /// **'This fishing rod is no longer in the bag.'**
  String get runtimeFeedbackFishingRodMissing;

  /// No description provided for @runtimeFeedbackFishingFaceWater.
  ///
  /// In en, this message translates to:
  /// **'Face the water to fish.'**
  String get runtimeFeedbackFishingFaceWater;

  /// No description provided for @runtimeFeedbackFishingNoEncounter.
  ///
  /// In en, this message translates to:
  /// **'You cannot catch anything here with this rod.'**
  String get runtimeFeedbackFishingNoEncounter;

  /// No description provided for @runtimeFeedbackFishingDismountSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Getting off the bicycle could not be saved.'**
  String get runtimeFeedbackFishingDismountSaveFailed;

  /// No description provided for @runtimeFeedbackFishingStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Fishing could not be started.'**
  String get runtimeFeedbackFishingStartFailed;

  /// No description provided for @runtimeFeedbackBicycleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The bicycle is only available on supported 2D maps.'**
  String get runtimeFeedbackBicycleUnsupported;

  /// No description provided for @runtimeFeedbackBicycleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The bicycle is unavailable right now.'**
  String get runtimeFeedbackBicycleUnavailable;

  /// No description provided for @runtimeFeedbackBicycleChanged.
  ///
  /// In en, this message translates to:
  /// **'Movement change saved.'**
  String get runtimeFeedbackBicycleChanged;

  /// No description provided for @runtimeFeedbackBicycleChangeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The bicycle is unavailable here, its animations are incomplete, or saving failed.'**
  String get runtimeFeedbackBicycleChangeUnavailable;

  /// No description provided for @runtimeFeedbackBicycleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The movement change could not be saved.'**
  String get runtimeFeedbackBicycleSaveFailed;

  /// No description provided for @runtimeFeedbackEscapeRopeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The Escape Rope is unsupported in this game mode.'**
  String get runtimeFeedbackEscapeRopeUnsupported;

  /// No description provided for @runtimeFeedbackEscapeRopeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Escape Rope is unavailable right now.'**
  String get runtimeFeedbackEscapeRopeUnavailable;

  /// No description provided for @runtimeFeedbackEscapeRopeReturned.
  ///
  /// In en, this message translates to:
  /// **'You returned to the entrance. Progress saved.'**
  String get runtimeFeedbackEscapeRopeReturned;

  /// No description provided for @runtimeFeedbackEscapeRopeExitBlocked.
  ///
  /// In en, this message translates to:
  /// **'The exit is unavailable or blocked. You kept the Escape Rope.'**
  String get runtimeFeedbackEscapeRopeExitBlocked;

  /// No description provided for @runtimeFeedbackEscapeRopeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The return could not be completed and saved.'**
  String get runtimeFeedbackEscapeRopeSaveFailed;

  /// No description provided for @runtimeFeedbackRepelUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Repel is unavailable in this game mode.'**
  String get runtimeFeedbackRepelUnsupported;

  /// No description provided for @runtimeFeedbackRepelAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'A Repel is already active.'**
  String get runtimeFeedbackRepelAlreadyActive;

  /// No description provided for @runtimeFeedbackRepelApplied.
  ///
  /// In en, this message translates to:
  /// **'Repel is active. Progress saved.'**
  String get runtimeFeedbackRepelApplied;

  /// No description provided for @runtimeFeedbackRepelSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Repel could not be used and saved.'**
  String get runtimeFeedbackRepelSaveFailed;

  /// No description provided for @runtimeFeedbackHeldItemNoEffect.
  ///
  /// In en, this message translates to:
  /// **'This item has no effect when held.'**
  String get runtimeFeedbackHeldItemNoEffect;

  /// No description provided for @runtimeFeedbackHeldItemUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This held item’s effect is unsupported in battle.'**
  String get runtimeFeedbackHeldItemUnsupported;

  /// No description provided for @runtimeFeedbackTargetDataIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This target’s data is incomplete.'**
  String get runtimeFeedbackTargetDataIncomplete;

  /// No description provided for @runtimeFeedbackBagItemUsed.
  ///
  /// In en, this message translates to:
  /// **'Item used and progress saved.'**
  String get runtimeFeedbackBagItemUsed;

  /// No description provided for @runtimeFeedbackBagItemSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The item could not be used and saved.'**
  String get runtimeFeedbackBagItemSaveFailed;

  /// No description provided for @runtimeFeedbackHeldItemTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This target or item is no longer available.'**
  String get runtimeFeedbackHeldItemTargetUnavailable;

  /// No description provided for @runtimeFeedbackHeldItemMissing.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer in the bag.'**
  String get runtimeFeedbackHeldItemMissing;

  /// No description provided for @runtimeFeedbackHeldItemNone.
  ///
  /// In en, this message translates to:
  /// **'This Pokémon is holding no item.'**
  String get runtimeFeedbackHeldItemNone;

  /// No description provided for @runtimeFeedbackHeldItemUnchanged.
  ///
  /// In en, this message translates to:
  /// **'This Pokémon is already holding this item.'**
  String get runtimeFeedbackHeldItemUnchanged;

  /// No description provided for @runtimeFeedbackHeldItemBagCannotReceive.
  ///
  /// In en, this message translates to:
  /// **'The currently held item cannot be returned to the bag.'**
  String get runtimeFeedbackHeldItemBagCannotReceive;

  /// No description provided for @runtimeFeedbackHeldItemBagFull.
  ///
  /// In en, this message translates to:
  /// **'There is no room for this item in the bag. Make room before taking it.'**
  String get runtimeFeedbackHeldItemBagFull;

  /// No description provided for @runtimeFeedbackHeldItemBagCapacityUnknown.
  ///
  /// In en, this message translates to:
  /// **'The item catalogue could not verify how much room is left in the bag.'**
  String get runtimeFeedbackHeldItemBagCapacityUnknown;

  /// No description provided for @runtimeFeedbackHeldItemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Held item removed and progress saved.'**
  String get runtimeFeedbackHeldItemRemoved;

  /// No description provided for @runtimeFeedbackHeldItemChanged.
  ///
  /// In en, this message translates to:
  /// **'Held item changed and progress saved.'**
  String get runtimeFeedbackHeldItemChanged;

  /// No description provided for @runtimeFeedbackHeldItemSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The held item could not be changed and saved.'**
  String get runtimeFeedbackHeldItemSaveFailed;

  /// No description provided for @runtimeFeedbackMoveMachineIncompatible.
  ///
  /// In en, this message translates to:
  /// **'This Pokémon cannot learn a move from this machine.'**
  String get runtimeFeedbackMoveMachineIncompatible;

  /// No description provided for @runtimeFeedbackMoveMachineReplaced.
  ///
  /// In en, this message translates to:
  /// **'Move replaced and progress saved.'**
  String get runtimeFeedbackMoveMachineReplaced;

  /// No description provided for @runtimeFeedbackMoveMachineLearned.
  ///
  /// In en, this message translates to:
  /// **'Move learned and progress saved.'**
  String get runtimeFeedbackMoveMachineLearned;

  /// No description provided for @runtimeFeedbackMoveMachineForgetPrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a move to forget.'**
  String get runtimeFeedbackMoveMachineForgetPrompt;

  /// No description provided for @runtimeFeedbackMoveMachineCancelled.
  ///
  /// In en, this message translates to:
  /// **'Learning cancelled.'**
  String get runtimeFeedbackMoveMachineCancelled;

  /// No description provided for @runtimeFeedbackMoveMachineCannotUse.
  ///
  /// In en, this message translates to:
  /// **'This machine cannot be used here.'**
  String get runtimeFeedbackMoveMachineCannotUse;

  /// No description provided for @runtimeFeedbackMoveMachineSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The move could not be learned and saved.'**
  String get runtimeFeedbackMoveMachineSaveFailed;

  /// No description provided for @runtimeFeedbackEvolutionHeldItemInvalid.
  ///
  /// In en, this message translates to:
  /// **'The held item does not allow this evolution.'**
  String get runtimeFeedbackEvolutionHeldItemInvalid;

  /// No description provided for @runtimeFeedbackEvolutionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item does not trigger an evolution here.'**
  String get runtimeFeedbackEvolutionUnavailable;

  /// No description provided for @runtimeFeedbackEvolutionAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'This combination can trigger multiple evolutions.'**
  String get runtimeFeedbackEvolutionAmbiguous;

  /// No description provided for @runtimeFeedbackEvolutionSaved.
  ///
  /// In en, this message translates to:
  /// **'Evolution complete and progress saved.'**
  String get runtimeFeedbackEvolutionSaved;

  /// No description provided for @runtimeFeedbackEvolutionSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The evolution could not be applied and saved.'**
  String get runtimeFeedbackEvolutionSaveFailed;

  /// No description provided for @runtimeFeedbackHealCapsIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The party’s recovery data is incomplete.'**
  String get runtimeFeedbackHealCapsIncomplete;

  /// No description provided for @runtimeFeedbackHealApplying.
  ///
  /// In en, this message translates to:
  /// **'Healing…'**
  String get runtimeFeedbackHealApplying;

  /// No description provided for @runtimeFeedbackHealDisplayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The healing display is unavailable on this map.'**
  String get runtimeFeedbackHealDisplayUnavailable;

  /// No description provided for @runtimeFeedbackServiceUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This service is unsupported in this game.'**
  String get runtimeFeedbackServiceUnsupported;

  /// No description provided for @runtimeFeedbackServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This service is unavailable right now.'**
  String get runtimeFeedbackServiceUnavailable;

  /// No description provided for @runtimeFeedbackServiceClosed.
  ///
  /// In en, this message translates to:
  /// **'The player service is closed.'**
  String get runtimeFeedbackServiceClosed;

  /// No description provided for @runtimeFeedbackServiceNotOpen.
  ///
  /// In en, this message translates to:
  /// **'No contextual service is open.'**
  String get runtimeFeedbackServiceNotOpen;

  /// No description provided for @runtimeFeedbackServiceChanged.
  ///
  /// In en, this message translates to:
  /// **'The service changed before this action arrived.'**
  String get runtimeFeedbackServiceChanged;

  /// No description provided for @runtimeFeedbackServiceWrongRequest.
  ///
  /// In en, this message translates to:
  /// **'This response belongs to a different request.'**
  String get runtimeFeedbackServiceWrongRequest;

  /// No description provided for @runtimeFeedbackServiceActionInvalid.
  ///
  /// In en, this message translates to:
  /// **'This service does not accept this action.'**
  String get runtimeFeedbackServiceActionInvalid;

  /// No description provided for @runtimeFeedbackPcBoxUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This Box is no longer available.'**
  String get runtimeFeedbackPcBoxUnavailable;

  /// No description provided for @runtimeFeedbackPokemonUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This Pokémon is no longer available.'**
  String get runtimeFeedbackPokemonUnavailable;

  /// No description provided for @runtimeFeedbackTradeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This trade is no longer available.'**
  String get runtimeFeedbackTradeUnavailable;

  /// No description provided for @runtimeFeedbackPcCommandInvalid.
  ///
  /// In en, this message translates to:
  /// **'This command is unavailable on the PC.'**
  String get runtimeFeedbackPcCommandInvalid;

  /// No description provided for @runtimeFeedbackPcSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving PC changes…'**
  String get runtimeFeedbackPcSaving;

  /// No description provided for @runtimeFeedbackPcDeposited.
  ///
  /// In en, this message translates to:
  /// **'Pokémon deposited in the Box.'**
  String get runtimeFeedbackPcDeposited;

  /// No description provided for @runtimeFeedbackPcWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Pokémon added to the party.'**
  String get runtimeFeedbackPcWithdrawn;

  /// No description provided for @runtimeFeedbackPcSwapped.
  ///
  /// In en, this message translates to:
  /// **'Pokémon swapped.'**
  String get runtimeFeedbackPcSwapped;

  /// No description provided for @runtimeFeedbackPcMoved.
  ///
  /// In en, this message translates to:
  /// **'Pokémon moved to another Box.'**
  String get runtimeFeedbackPcMoved;

  /// No description provided for @runtimeFeedbackPcSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The PC changes could not be saved.'**
  String get runtimeFeedbackPcSaveFailed;

  /// No description provided for @runtimeFeedbackPcTitle.
  ///
  /// In en, this message translates to:
  /// **'Pokémon PC'**
  String get runtimeFeedbackPcTitle;

  /// No description provided for @runtimeFeedbackPcHelp.
  ///
  /// In en, this message translates to:
  /// **'Organize your party and Boxes.'**
  String get runtimeFeedbackPcHelp;

  /// No description provided for @runtimeFeedbackPcNoDeposit.
  ///
  /// In en, this message translates to:
  /// **'No Pokémon can be deposited.'**
  String get runtimeFeedbackPcNoDeposit;

  /// No description provided for @runtimeFeedbackPcNoWithdraw.
  ///
  /// In en, this message translates to:
  /// **'No Pokémon can be withdrawn.'**
  String get runtimeFeedbackPcNoWithdraw;

  /// No description provided for @runtimeFeedbackPcNoSwap.
  ///
  /// In en, this message translates to:
  /// **'No valid swap is available.'**
  String get runtimeFeedbackPcNoSwap;

  /// No description provided for @runtimeFeedbackPcNoMove.
  ///
  /// In en, this message translates to:
  /// **'There are no Pokémon to move from this Box.'**
  String get runtimeFeedbackPcNoMove;

  /// No description provided for @runtimeFeedbackPcNoDestination.
  ///
  /// In en, this message translates to:
  /// **'No other Box is available.'**
  String get runtimeFeedbackPcNoDestination;

  /// No description provided for @runtimeFeedbackHealInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Healing was interrupted before it could be saved.'**
  String get runtimeFeedbackHealInterrupted;

  /// No description provided for @runtimeFeedbackHealAlreadyHealthy.
  ///
  /// In en, this message translates to:
  /// **'Your party is already fully healed.'**
  String get runtimeFeedbackHealAlreadyHealthy;

  /// No description provided for @runtimeFeedbackHealPartyHealed.
  ///
  /// In en, this message translates to:
  /// **'Your party is fully healed.'**
  String get runtimeFeedbackHealPartyHealed;

  /// No description provided for @runtimeFeedbackHealSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Healing could not be saved.'**
  String get runtimeFeedbackHealSaveFailed;

  /// No description provided for @runtimeFeedbackHealCommandInvalid.
  ///
  /// In en, this message translates to:
  /// **'This command is unavailable at the healing service.'**
  String get runtimeFeedbackHealCommandInvalid;

  /// No description provided for @runtimeFeedbackHealTitle.
  ///
  /// In en, this message translates to:
  /// **'Pokémon Center'**
  String get runtimeFeedbackHealTitle;

  /// No description provided for @runtimeFeedbackHealCompleted.
  ///
  /// In en, this message translates to:
  /// **'Healing is complete.'**
  String get runtimeFeedbackHealCompleted;

  /// No description provided for @runtimeFeedbackHealHelp.
  ///
  /// In en, this message translates to:
  /// **'Restore HP and PP, and clear status conditions.'**
  String get runtimeFeedbackHealHelp;

  /// No description provided for @runtimeFeedbackShopItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get runtimeFeedbackShopItemUnavailable;

  /// No description provided for @runtimeFeedbackShopCommandInvalid.
  ///
  /// In en, this message translates to:
  /// **'This command is unavailable at the shop.'**
  String get runtimeFeedbackShopCommandInvalid;

  /// No description provided for @runtimeFeedbackShopChooseItem.
  ///
  /// In en, this message translates to:
  /// **'Select an item.'**
  String get runtimeFeedbackShopChooseItem;

  /// No description provided for @runtimeFeedbackShopPurchaseBonus.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete. Bonus: {quantity} × {item}.'**
  String runtimeFeedbackShopPurchaseBonus({
    required int quantity,
    required String item,
  });

  /// No description provided for @runtimeFeedbackShopPurchaseComplete.
  ///
  /// In en, this message translates to:
  /// **'Purchase complete.'**
  String get runtimeFeedbackShopPurchaseComplete;

  /// No description provided for @runtimeFeedbackShopSaleComplete.
  ///
  /// In en, this message translates to:
  /// **'Sale complete.'**
  String get runtimeFeedbackShopSaleComplete;

  /// No description provided for @runtimeFeedbackShopClosed.
  ///
  /// In en, this message translates to:
  /// **'This shop is closed.'**
  String get runtimeFeedbackShopClosed;

  /// No description provided for @runtimeFeedbackShopInsufficientQuantity.
  ///
  /// In en, this message translates to:
  /// **'You do not own enough of this item.'**
  String get runtimeFeedbackShopInsufficientQuantity;

  /// No description provided for @runtimeFeedbackShopMinimumQuantity.
  ///
  /// In en, this message translates to:
  /// **'The minimum quantity is 1.'**
  String get runtimeFeedbackShopMinimumQuantity;

  /// No description provided for @runtimeFeedbackShopMaximumQuantity.
  ///
  /// In en, this message translates to:
  /// **'The maximum quantity has been reached.'**
  String get runtimeFeedbackShopMaximumQuantity;

  /// No description provided for @runtimeFeedbackShopSaleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This sale is unavailable.'**
  String get runtimeFeedbackShopSaleUnavailable;

  /// No description provided for @runtimeFeedbackShopPurchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This purchase is unavailable.'**
  String get runtimeFeedbackShopPurchaseUnavailable;

  /// No description provided for @runtimeFeedbackShopPurchaseInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid purchase.'**
  String get runtimeFeedbackShopPurchaseInvalid;

  /// No description provided for @runtimeFeedbackShopItemUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown item.'**
  String get runtimeFeedbackShopItemUnknown;

  /// No description provided for @runtimeFeedbackShopFundsInsufficient.
  ///
  /// In en, this message translates to:
  /// **'You do not have enough money.'**
  String get runtimeFeedbackShopFundsInsufficient;

  /// No description provided for @runtimeFeedbackShopStockInsufficient.
  ///
  /// In en, this message translates to:
  /// **'There is not enough in stock.'**
  String get runtimeFeedbackShopStockInsufficient;

  /// No description provided for @runtimeFeedbackShopOwnedLimit.
  ///
  /// In en, this message translates to:
  /// **'You already own the maximum quantity.'**
  String get runtimeFeedbackShopOwnedLimit;

  /// No description provided for @runtimeFeedbackShopBagFull.
  ///
  /// In en, this message translates to:
  /// **'There is no room for this purchase in the bag. Make room and try again.'**
  String get runtimeFeedbackShopBagFull;

  /// No description provided for @runtimeFeedbackShopStateChanged.
  ///
  /// In en, this message translates to:
  /// **'The shop changed. Its stock was refreshed.'**
  String get runtimeFeedbackShopStateChanged;

  /// No description provided for @runtimeFeedbackShopSaleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid sale.'**
  String get runtimeFeedbackShopSaleInvalid;

  /// No description provided for @runtimeFeedbackShopItemUnsellable.
  ///
  /// In en, this message translates to:
  /// **'This item cannot be sold.'**
  String get runtimeFeedbackShopItemUnsellable;

  /// No description provided for @runtimeFeedbackShopItemImportant.
  ///
  /// In en, this message translates to:
  /// **'Key items cannot be sold.'**
  String get runtimeFeedbackShopItemImportant;

  /// No description provided for @runtimeFeedbackShopItemNotAccepted.
  ///
  /// In en, this message translates to:
  /// **'This shop does not buy this item.'**
  String get runtimeFeedbackShopItemNotAccepted;

  /// No description provided for @runtimeFeedbackPcOperationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid PC operation.'**
  String get runtimeFeedbackPcOperationInvalid;

  /// No description provided for @runtimeFeedbackPcPartySlotInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid party slot.'**
  String get runtimeFeedbackPcPartySlotInvalid;

  /// No description provided for @runtimeFeedbackPcBoxUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown Box.'**
  String get runtimeFeedbackPcBoxUnknown;

  /// No description provided for @runtimeFeedbackPcBoxSlotInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Box slot.'**
  String get runtimeFeedbackPcBoxSlotInvalid;

  /// No description provided for @runtimeFeedbackPcPartyFull.
  ///
  /// In en, this message translates to:
  /// **'The party is full.'**
  String get runtimeFeedbackPcPartyFull;

  /// No description provided for @runtimeFeedbackPcBoxFull.
  ///
  /// In en, this message translates to:
  /// **'This Box is full.'**
  String get runtimeFeedbackPcBoxFull;

  /// No description provided for @runtimeFeedbackPcFull.
  ///
  /// In en, this message translates to:
  /// **'The PC is full.'**
  String get runtimeFeedbackPcFull;

  /// No description provided for @runtimeFeedbackPcLastUsablePokemon.
  ///
  /// In en, this message translates to:
  /// **'You cannot deposit your last Pokémon that can battle.'**
  String get runtimeFeedbackPcLastUsablePokemon;

  /// No description provided for @runtimeFeedbackBagItemMissing.
  ///
  /// In en, this message translates to:
  /// **'You no longer have this item.'**
  String get runtimeFeedbackBagItemMissing;

  /// No description provided for @runtimeFeedbackBagItemWrongTarget.
  ///
  /// In en, this message translates to:
  /// **'This item cannot be used on this target.'**
  String get runtimeFeedbackBagItemWrongTarget;

  /// No description provided for @runtimeFeedbackBagItemNoEffect.
  ///
  /// In en, this message translates to:
  /// **'This item would have no effect.'**
  String get runtimeFeedbackBagItemNoEffect;

  /// No description provided for @runtimeFeedbackBagItemUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This item’s effect is unsupported.'**
  String get runtimeFeedbackBagItemUnsupported;

  /// No description provided for @runtimeFeedbackBagKeyItemProtected.
  ///
  /// In en, this message translates to:
  /// **'This key item cannot be consumed.'**
  String get runtimeFeedbackBagKeyItemProtected;

  /// No description provided for @runtimeFeedbackTradeCatalogRequired.
  ///
  /// In en, this message translates to:
  /// **'The party and its Pokémon catalogue are required for this trade.'**
  String get runtimeFeedbackTradeCatalogRequired;

  /// No description provided for @runtimeFeedbackTradePokemonMismatch.
  ///
  /// In en, this message translates to:
  /// **'This Pokémon does not match the trade request.'**
  String get runtimeFeedbackTradePokemonMismatch;

  /// No description provided for @runtimeFeedbackTradeSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The trade could not be saved.'**
  String get runtimeFeedbackTradeSaveFailed;

  /// No description provided for @runtimeFeedbackTradeEvolution.
  ///
  /// In en, this message translates to:
  /// **'{name} evolved into {species}.'**
  String runtimeFeedbackTradeEvolution({
    required String name,
    required String species,
  });

  /// No description provided for @runtimeFeedbackCraftSaveRequired.
  ///
  /// In en, this message translates to:
  /// **'This workshop requires a save slot.'**
  String get runtimeFeedbackCraftSaveRequired;

  /// No description provided for @runtimeFeedbackCraftInventoryChanged.
  ///
  /// In en, this message translates to:
  /// **'The bag changed. Close and reopen the workshop.'**
  String get runtimeFeedbackCraftInventoryChanged;

  /// No description provided for @runtimeFeedbackCraftConfirmIngredients.
  ///
  /// In en, this message translates to:
  /// **'Hand over the ingredients?'**
  String get runtimeFeedbackCraftConfirmIngredients;

  /// No description provided for @runtimeFeedbackCraftCollectBagFull.
  ///
  /// In en, this message translates to:
  /// **'The bag is full. Your order is still available.'**
  String get runtimeFeedbackCraftCollectBagFull;

  /// No description provided for @runtimeFeedbackCraftKeyItemProtected.
  ///
  /// In en, this message translates to:
  /// **'This key item cannot be used as an ingredient.'**
  String get runtimeFeedbackCraftKeyItemProtected;

  /// No description provided for @runtimeFeedbackCraftUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This order is unavailable.'**
  String get runtimeFeedbackCraftUnavailable;

  /// No description provided for @runtimeFeedbackCraftCollected.
  ///
  /// In en, this message translates to:
  /// **'Order collected.'**
  String get runtimeFeedbackCraftCollected;

  /// No description provided for @runtimeFeedbackCraftOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Order placed. Come back another day.'**
  String get runtimeFeedbackCraftOrderSaved;

  /// No description provided for @runtimeFeedbackCraftSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Saving failed. Your bag and order were kept.'**
  String get runtimeFeedbackCraftSaveFailed;

  /// No description provided for @runtimeFeedbackCraftInventoryBusy.
  ///
  /// In en, this message translates to:
  /// **'The bag is being updated. Finish this interaction and try again.'**
  String get runtimeFeedbackCraftInventoryBusy;

  /// No description provided for @runtimeFeedbackCraftSceneRequired.
  ///
  /// In en, this message translates to:
  /// **'This workshop requires an active scene.'**
  String get runtimeFeedbackCraftSceneRequired;

  /// No description provided for @runtimeFeedbackPuzzleSaveRequired.
  ///
  /// In en, this message translates to:
  /// **'This puzzle requires a save slot.'**
  String get runtimeFeedbackPuzzleSaveRequired;

  /// No description provided for @runtimeFeedbackPuzzleMediaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The game’s media library is unavailable.'**
  String get runtimeFeedbackPuzzleMediaUnavailable;

  /// No description provided for @runtimeFeedbackPuzzleImageTooSmall.
  ///
  /// In en, this message translates to:
  /// **'The image must have at least one pixel per puzzle tile.'**
  String get runtimeFeedbackPuzzleImageTooSmall;

  /// No description provided for @runtimeFeedbackPuzzleChangedOnOpening.
  ///
  /// In en, this message translates to:
  /// **'The puzzle changed as it opened. Open it again.'**
  String get runtimeFeedbackPuzzleChangedOnOpening;

  /// No description provided for @runtimeFeedbackPuzzleDefinitionChanged.
  ///
  /// In en, this message translates to:
  /// **'The puzzle definition changed. Restore its original configuration.'**
  String get runtimeFeedbackPuzzleDefinitionChanged;

  /// No description provided for @runtimeFeedbackPuzzleChanged.
  ///
  /// In en, this message translates to:
  /// **'The puzzle changed. Close this interaction and open it again.'**
  String get runtimeFeedbackPuzzleChanged;

  /// No description provided for @runtimeFeedbackPuzzleIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The image is incomplete. Check each piece’s position and rotation.'**
  String get runtimeFeedbackPuzzleIncomplete;

  /// No description provided for @runtimeFeedbackPuzzleDestinationOccupied.
  ///
  /// In en, this message translates to:
  /// **'Move this piece to a free space or back to the tray.'**
  String get runtimeFeedbackPuzzleDestinationOccupied;

  /// No description provided for @runtimeFeedbackPuzzlePieceFixed.
  ///
  /// In en, this message translates to:
  /// **'This piece is fixed in place.'**
  String get runtimeFeedbackPuzzlePieceFixed;

  /// No description provided for @runtimeFeedbackPuzzleActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This action is unavailable for this puzzle.'**
  String get runtimeFeedbackPuzzleActionUnavailable;

  /// No description provided for @runtimeFeedbackPuzzleSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Saving failed. Your last saved layout was kept. Try again or quit.'**
  String get runtimeFeedbackPuzzleSaveFailed;

  /// No description provided for @runtimeFeedbackActionInProgress.
  ///
  /// In en, this message translates to:
  /// **'An action is already in progress.'**
  String get runtimeFeedbackActionInProgress;

  /// No description provided for @runtimeFeedbackSaveInProgress.
  ///
  /// In en, this message translates to:
  /// **'A save is already in progress.'**
  String get runtimeFeedbackSaveInProgress;

  /// No description provided for @runtimeFeedbackFavoritesBagChanged.
  ///
  /// In en, this message translates to:
  /// **'The bag changed before this action arrived.'**
  String get runtimeFeedbackFavoritesBagChanged;

  /// No description provided for @runtimeFeedbackFavoritesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item cannot be added to favourites.'**
  String get runtimeFeedbackFavoritesUnavailable;

  /// No description provided for @runtimeFeedbackFavoritesSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Favourites could not be saved. Try again.'**
  String get runtimeFeedbackFavoritesSaveFailed;

  /// No description provided for @runtimeFeedbackPlayerActionStale.
  ///
  /// In en, this message translates to:
  /// **'This screen changed before the action arrived.'**
  String get runtimeFeedbackPlayerActionStale;

  /// No description provided for @runtimeFeedbackRegionalMapCloseFirst.
  ///
  /// In en, this message translates to:
  /// **'Close the regional map before using the menu.'**
  String get runtimeFeedbackRegionalMapCloseFirst;

  /// No description provided for @runtimeFeedbackPlayerActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This player action is unavailable.'**
  String get runtimeFeedbackPlayerActionUnavailable;

  /// No description provided for @runtimeFeedbackNewGameSlotRequired.
  ///
  /// In en, this message translates to:
  /// **'A profile and slot are required to start a new game.'**
  String get runtimeFeedbackNewGameSlotRequired;

  /// No description provided for @runtimeFeedbackNoCompatibleSave.
  ///
  /// In en, this message translates to:
  /// **'No compatible save is available to continue.'**
  String get runtimeFeedbackNoCompatibleSave;

  /// No description provided for @runtimeFeedbackLoadSlotRequired.
  ///
  /// In en, this message translates to:
  /// **'A profile and slot are required to load a save.'**
  String get runtimeFeedbackLoadSlotRequired;

  /// No description provided for @runtimeFeedbackSelectedSaveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected save is unavailable or incompatible.'**
  String get runtimeFeedbackSelectedSaveUnavailable;

  /// No description provided for @runtimeFeedbackFinalSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The final save could not be written.'**
  String get runtimeFeedbackFinalSaveFailed;

  /// No description provided for @runtimeFeedbackPartyMembersRequired.
  ///
  /// In en, this message translates to:
  /// **'Select two available party members.'**
  String get runtimeFeedbackPartyMembersRequired;

  /// No description provided for @runtimeFeedbackPlayerCommandUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This command is unavailable on this screen.'**
  String get runtimeFeedbackPlayerCommandUnavailable;

  /// No description provided for @runtimeFeedbackPlayerPreferencesRequired.
  ///
  /// In en, this message translates to:
  /// **'Valid player preferences are required.'**
  String get runtimeFeedbackPlayerPreferencesRequired;

  /// No description provided for @runtimeFeedbackSaveWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'The save could not be written.'**
  String get runtimeFeedbackSaveWriteFailed;

  /// No description provided for @runtimeFeedbackCreditsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No end credits are available.'**
  String get runtimeFeedbackCreditsUnavailable;

  /// No description provided for @runtimeFeedbackSurfaceActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This action is not available on the current surface.'**
  String get runtimeFeedbackSurfaceActionUnavailable;

  /// No description provided for @runtimeFeedbackPlayerResponseStale.
  ///
  /// In en, this message translates to:
  /// **'This screen changed before the response arrived.'**
  String get runtimeFeedbackPlayerResponseStale;

  /// No description provided for @runtimeFeedbackReturnToHostFailed.
  ///
  /// In en, this message translates to:
  /// **'The game could not return to the library.'**
  String get runtimeFeedbackReturnToHostFailed;

  /// No description provided for @runtimeFeedbackPlayerDataRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Player data could not be refreshed.'**
  String get runtimeFeedbackPlayerDataRefreshFailed;

  /// No description provided for @runtimeFeedbackSessionCloseFailed.
  ///
  /// In en, this message translates to:
  /// **'The game session could not close cleanly.'**
  String get runtimeFeedbackSessionCloseFailed;

  /// No description provided for @runtimeFeedbackExplorationMapChanged.
  ///
  /// In en, this message translates to:
  /// **'The map changed while loading. Restart exploration.'**
  String get runtimeFeedbackExplorationMapChanged;

  /// No description provided for @runtimeFeedbackNewGamePreparationChanged.
  ///
  /// In en, this message translates to:
  /// **'The game content changed during setup. Start the new game again.'**
  String get runtimeFeedbackNewGamePreparationChanged;

  /// No description provided for @runtimeFeedbackNewGameSetupInvalid.
  ///
  /// In en, this message translates to:
  /// **'The starting configuration is incomplete or inconsistent. The new game could not be started.'**
  String get runtimeFeedbackNewGameSetupInvalid;

  /// No description provided for @runtimeFeedbackNewGameContentChanged.
  ///
  /// In en, this message translates to:
  /// **'The game content changed while loading. Start the new game again.'**
  String get runtimeFeedbackNewGameContentChanged;

  /// No description provided for @runtimeFeedbackNewGameResourceLimit.
  ///
  /// In en, this message translates to:
  /// **'This map’s graphics exceed the Player’s resource budget. Report this code to the game creator.'**
  String get runtimeFeedbackNewGameResourceLimit;

  /// No description provided for @runtimeFeedbackNewGameSaveReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read saves. Check that the app can access its storage.'**
  String get runtimeFeedbackNewGameSaveReadFailed;

  /// No description provided for @runtimeFeedbackNewGamePreloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The starting map’s data or assets could not be loaded. Reinstall the game if the issue persists.'**
  String get runtimeFeedbackNewGamePreloadFailed;

  /// No description provided for @runtimeFeedbackNewGameSceneFailed.
  ///
  /// In en, this message translates to:
  /// **'The opening scene could not run. Report the code below to the game creator.'**
  String get runtimeFeedbackNewGameSceneFailed;

  /// No description provided for @runtimeFeedbackNewGameSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'The starting configuration could not be applied. Report the code below to the game creator.'**
  String get runtimeFeedbackNewGameSetupFailed;

  /// No description provided for @runtimeFeedbackSaveOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The selected save could not be opened safely.'**
  String get runtimeFeedbackSaveOpenFailed;

  /// No description provided for @runtimeFeedbackSessionLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'The game session could not launch.'**
  String get runtimeFeedbackSessionLaunchFailed;

  /// No description provided for @runtimeFeedbackPlayerDataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Player data could not be loaded.'**
  String get runtimeFeedbackPlayerDataLoadFailed;

  /// No description provided for @runtimeFeedbackSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'The player session failed.'**
  String get runtimeFeedbackSessionFailed;

  /// No description provided for @runtimeFeedbackExplorationSaveUnavailable.
  ///
  /// In en, this message translates to:
  /// **'3D exploration mode does not support saves yet.'**
  String get runtimeFeedbackExplorationSaveUnavailable;

  /// No description provided for @runtimeFeedbackNoCompatibleGameSave.
  ///
  /// In en, this message translates to:
  /// **'No compatible save is available for this game.'**
  String get runtimeFeedbackNoCompatibleGameSave;

  /// No description provided for @runtimeFeedbackPlayerMapUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This game does not provide a player map.'**
  String get runtimeFeedbackPlayerMapUnavailable;

  /// No description provided for @runtimeFeedbackUnusableSaveNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No save has been selected for recovery.'**
  String get runtimeFeedbackUnusableSaveNotSelected;

  /// No description provided for @runtimeFeedbackServiceNotActive.
  ///
  /// In en, this message translates to:
  /// **'No contextual service is active.'**
  String get runtimeFeedbackServiceNotActive;

  /// No description provided for @runtimeFeedbackBagRequiresPause.
  ///
  /// In en, this message translates to:
  /// **'The bag is only available from the pause menu.'**
  String get runtimeFeedbackBagRequiresPause;

  /// No description provided for @runtimeFeedbackBagItemCheckpointFailed.
  ///
  /// In en, this message translates to:
  /// **'The item was used, but saving failed.'**
  String get runtimeFeedbackBagItemCheckpointFailed;

  /// No description provided for @runtimeFeedbackSessionEventStreamFailed.
  ///
  /// In en, this message translates to:
  /// **'The game’s event channel failed.'**
  String get runtimeFeedbackSessionEventStreamFailed;

  /// No description provided for @runtimeFeedbackSessionPrepareTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The game session took too long to prepare.'**
  String get runtimeFeedbackSessionPrepareTimedOut;

  /// No description provided for @runtimeFeedbackSessionPrepareFailed.
  ///
  /// In en, this message translates to:
  /// **'The game session could not be prepared.'**
  String get runtimeFeedbackSessionPrepareFailed;

  /// No description provided for @runtimeFeedbackSessionStartTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The game session took too long to start.'**
  String get runtimeFeedbackSessionStartTimedOut;

  /// No description provided for @runtimeFeedbackSessionStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The game session could not start.'**
  String get runtimeFeedbackSessionStartFailed;

  /// No description provided for @runtimeFeedbackSessionSignalInvalid.
  ///
  /// In en, this message translates to:
  /// **'The game sent an invalid session signal.'**
  String get runtimeFeedbackSessionSignalInvalid;

  /// No description provided for @runtimeFeedbackSessionEndingMismatch.
  ///
  /// In en, this message translates to:
  /// **'The ending event does not match this game session.'**
  String get runtimeFeedbackSessionEndingMismatch;

  /// No description provided for @runtimeFeedbackSessionEndingInvalid.
  ///
  /// In en, this message translates to:
  /// **'The ending event arrived before the game was ready.'**
  String get runtimeFeedbackSessionEndingInvalid;

  /// No description provided for @runtimeFeedbackPreviousSessionCloseFailed.
  ///
  /// In en, this message translates to:
  /// **'The previous game session did not close cleanly.'**
  String get runtimeFeedbackPreviousSessionCloseFailed;

  /// No description provided for @runtimeFeedbackStartupGamePreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'The game could not be prepared.'**
  String get runtimeFeedbackStartupGamePreparationFailed;

  /// No description provided for @runtimeFeedbackStartupPreparationStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Game preparation could not start.'**
  String get runtimeFeedbackStartupPreparationStartFailed;

  /// No description provided for @runtimeFeedbackStartupIdentityPreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'The game’s identity could not be prepared.'**
  String get runtimeFeedbackStartupIdentityPreparationFailed;

  /// No description provided for @runtimeFeedbackStartupMapPreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'The first map could not be prepared.'**
  String get runtimeFeedbackStartupMapPreparationFailed;

  /// No description provided for @runtimeFeedbackStartupPresentationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The game’s presentation could not be loaded.'**
  String get runtimeFeedbackStartupPresentationLoadFailed;

  /// No description provided for @runtimeFeedbackStartupSaveDiscoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved games could not be checked safely.'**
  String get runtimeFeedbackStartupSaveDiscoveryFailed;

  /// No description provided for @runtimeFeedbackStartupPreferencesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Player preferences could not be loaded.'**
  String get runtimeFeedbackStartupPreferencesLoadFailed;

  /// No description provided for @runtimeFeedbackStartupInstalledGamePreparationFailed.
  ///
  /// In en, this message translates to:
  /// **'The installed game could not be prepared.'**
  String get runtimeFeedbackStartupInstalledGamePreparationFailed;

  /// No description provided for @runtimeFeedbackOverworldBagFull.
  ///
  /// In en, this message translates to:
  /// **'The bag is full…'**
  String get runtimeFeedbackOverworldBagFull;

  /// No description provided for @runtimeFeedbackOverworldItemReceived.
  ///
  /// In en, this message translates to:
  /// **'Received {quantity} × {item}!'**
  String runtimeFeedbackOverworldItemReceived({
    required int quantity,
    required String item,
  });

  /// No description provided for @runtimeFeedbackGiftReceived.
  ///
  /// In en, this message translates to:
  /// **'You received a Pokémon!'**
  String get runtimeFeedbackGiftReceived;

  /// No description provided for @runtimeFeedbackGiftNicknamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Choose a nickname.'**
  String get runtimeFeedbackGiftNicknamePrompt;

  /// No description provided for @runtimeFeedbackGiftNicknameAction.
  ///
  /// In en, this message translates to:
  /// **'Give a nickname'**
  String get runtimeFeedbackGiftNicknameAction;

  /// No description provided for @battleChooseAction.
  ///
  /// In en, this message translates to:
  /// **'What will {actor} do?'**
  String battleChooseAction({required String actor});

  /// No description provided for @battleChooseReplacementAfterFaint.
  ///
  /// In en, this message translates to:
  /// **'{actor} fainted. Choose a replacement.'**
  String battleChooseReplacementAfterFaint({required String actor});

  /// No description provided for @battleContinuePrompt.
  ///
  /// In en, this message translates to:
  /// **'Press to continue.'**
  String get battleContinuePrompt;

  /// No description provided for @battleFinished.
  ///
  /// In en, this message translates to:
  /// **'The battle is over.'**
  String get battleFinished;

  /// No description provided for @battleResolvingTurn.
  ///
  /// In en, this message translates to:
  /// **'Resolving the turn…'**
  String get battleResolvingTurn;

  /// No description provided for @battleNoReplacement.
  ///
  /// In en, this message translates to:
  /// **'No replacement available.'**
  String get battleNoReplacement;

  /// No description provided for @battleNoLegalChoice.
  ///
  /// In en, this message translates to:
  /// **'No action is available.'**
  String get battleNoLegalChoice;

  /// No description provided for @battleChooseAttackTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose a target for {actor}.'**
  String battleChooseAttackTarget({required String actor});

  /// No description provided for @battleChoosePokemon.
  ///
  /// In en, this message translates to:
  /// **'Choose a Pokémon.'**
  String get battleChoosePokemon;

  /// No description provided for @battleChooseReplacement.
  ///
  /// In en, this message translates to:
  /// **'Choose a replacement.'**
  String get battleChooseReplacement;

  /// No description provided for @battleNoSwitch.
  ///
  /// In en, this message translates to:
  /// **'No Pokémon can switch in.'**
  String get battleNoSwitch;

  /// No description provided for @battleActiveOrFainted.
  ///
  /// In en, this message translates to:
  /// **'Active and fainted Pokémon are unavailable.'**
  String get battleActiveOrFainted;

  /// No description provided for @battleChooseItem.
  ///
  /// In en, this message translates to:
  /// **'Choose an item.'**
  String get battleChooseItem;

  /// No description provided for @battleNoUsableItem.
  ///
  /// In en, this message translates to:
  /// **'No item can be used this turn.'**
  String get battleNoUsableItem;

  /// No description provided for @battleItemsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Unavailable items are dimmed.'**
  String get battleItemsDisabled;

  /// No description provided for @battleChooseItemTarget.
  ///
  /// In en, this message translates to:
  /// **'Choose a target for {item}.'**
  String battleChooseItemTarget({required String item});

  /// No description provided for @battleChooseItemMove.
  ///
  /// In en, this message translates to:
  /// **'Choose a move for {item}.'**
  String battleChooseItemMove({required String item});

  /// No description provided for @battleNoItemTarget.
  ///
  /// In en, this message translates to:
  /// **'There is no valid target for this item.'**
  String get battleNoItemTarget;

  /// No description provided for @battleFaintedOrFullHp.
  ///
  /// In en, this message translates to:
  /// **'Fainted Pokémon and Pokémon at full HP are unavailable.'**
  String get battleFaintedOrFullHp;

  /// No description provided for @battleFullPpDisabled.
  ///
  /// In en, this message translates to:
  /// **'Moves with full PP are dimmed.'**
  String get battleFullPpDisabled;

  /// No description provided for @battleWildTitle.
  ///
  /// In en, this message translates to:
  /// **'Wild battle'**
  String get battleWildTitle;

  /// No description provided for @battleTrainerTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainer battle'**
  String get battleTrainerTitle;

  /// No description provided for @runtimeFeedbackFishingInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Fishing was interrupted.'**
  String get runtimeFeedbackFishingInterrupted;

  /// No description provided for @runtimeFeedbackFishingCasting.
  ///
  /// In en, this message translates to:
  /// **'Casting the line…'**
  String get runtimeFeedbackFishingCasting;

  /// No description provided for @runtimeFeedbackFishingWaiting.
  ///
  /// In en, this message translates to:
  /// **'The line is in the water… Press Back to cancel.'**
  String get runtimeFeedbackFishingWaiting;

  /// No description provided for @runtimeFeedbackFishingBite.
  ///
  /// In en, this message translates to:
  /// **'You got a bite!'**
  String get runtimeFeedbackFishingBite;

  /// No description provided for @runtimeFeedbackFishingNoBite.
  ///
  /// In en, this message translates to:
  /// **'Nothing bit…'**
  String get runtimeFeedbackFishingNoBite;

  /// No description provided for @runtimeFeedbackFishingEncounterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This fishing encounter is no longer available.'**
  String get runtimeFeedbackFishingEncounterUnavailable;

  /// No description provided for @runtimeFeedbackFishingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Fishing cancelled.'**
  String get runtimeFeedbackFishingCancelled;

  /// No description provided for @runtimeFeedbackFieldActionChanged.
  ///
  /// In en, this message translates to:
  /// **'This action is no longer available.'**
  String get runtimeFeedbackFieldActionChanged;

  /// No description provided for @runtimeFeedbackFieldCrossingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This crossing is no longer available.'**
  String get runtimeFeedbackFieldCrossingUnavailable;

  /// No description provided for @runtimeFeedbackFieldFlashUsed.
  ///
  /// In en, this message translates to:
  /// **'Your Pokémon used Flash! The area is lit.'**
  String get runtimeFeedbackFieldFlashUsed;

  /// No description provided for @runtimeFeedbackFieldCutUsed.
  ///
  /// In en, this message translates to:
  /// **'Your Pokémon used Cut!'**
  String get runtimeFeedbackFieldCutUsed;

  /// No description provided for @runtimeFeedbackFieldStrengthActive.
  ///
  /// In en, this message translates to:
  /// **'Strength is active on this map. Walk toward a boulder to push it.'**
  String get runtimeFeedbackFieldStrengthActive;

  /// No description provided for @runtimeFeedbackFieldRockSmashUsed.
  ///
  /// In en, this message translates to:
  /// **'Your Pokémon used Rock Smash!'**
  String get runtimeFeedbackFieldRockSmashUsed;

  /// No description provided for @runtimeFeedbackFieldDivePassageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This Dive passage is no longer available.'**
  String get runtimeFeedbackFieldDivePassageUnavailable;

  /// No description provided for @runtimeFeedbackWaterRequiresSurf.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon that knows Surf is needed to travel on water.'**
  String get runtimeFeedbackWaterRequiresSurf;

  /// No description provided for @runtimeFeedbackUnderwaterRequiresDive.
  ///
  /// In en, this message translates to:
  /// **'Use Dive to reach this underwater terrain.'**
  String get runtimeFeedbackUnderwaterRequiresDive;

  /// No description provided for @runtimeFeedbackDiveRequiresUnderwater.
  ///
  /// In en, this message translates to:
  /// **'Dive is available on underwater terrain.'**
  String get runtimeFeedbackDiveRequiresUnderwater;

  /// No description provided for @runtimeFeedbackIncompatibleMovementTerrain.
  ///
  /// In en, this message translates to:
  /// **'This terrain has incompatible movement modes.'**
  String get runtimeFeedbackIncompatibleMovementTerrain;

  /// No description provided for @runtimeFeedbackSurfMissingPokemon.
  ///
  /// In en, this message translates to:
  /// **'It looks like you could surf on this water.'**
  String get runtimeFeedbackSurfMissingPokemon;

  /// No description provided for @runtimeFeedbackSurfLocked.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon in your party knows Surf. You have yet to unlock it outside battle.'**
  String get runtimeFeedbackSurfLocked;

  /// No description provided for @runtimeFeedbackSurfConfirm.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use Surf?'**
  String get runtimeFeedbackSurfConfirm;

  /// No description provided for @runtimeFeedbackNarrativePending.
  ///
  /// In en, this message translates to:
  /// **'The story outcome is still pending.'**
  String get runtimeFeedbackNarrativePending;

  /// No description provided for @runtimeFeedbackNarrativeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The event could not start.'**
  String get runtimeFeedbackNarrativeUnavailable;

  /// No description provided for @runtimeFeedbackNarrativeResultUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The story outcome could not be applied.'**
  String get runtimeFeedbackNarrativeResultUnavailable;

  /// No description provided for @runtimeFeedbackCannotEndGame.
  ///
  /// In en, this message translates to:
  /// **'The game could not finish.'**
  String get runtimeFeedbackCannotEndGame;

  /// No description provided for @runtimeFeedbackGiftFailed.
  ///
  /// In en, this message translates to:
  /// **'The Pokémon gift could not be received.'**
  String get runtimeFeedbackGiftFailed;

  /// No description provided for @runtimeFeedbackTransitionFailed.
  ///
  /// In en, this message translates to:
  /// **'The transition could not complete.'**
  String get runtimeFeedbackTransitionFailed;

  /// No description provided for @runtimeFeedbackTransitionPassageMissing.
  ///
  /// In en, this message translates to:
  /// **'The transition could not complete. The passage is missing.'**
  String get runtimeFeedbackTransitionPassageMissing;

  /// No description provided for @runtimeFeedbackInvalidMapConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection invalid'**
  String get runtimeFeedbackInvalidMapConnection;

  /// No description provided for @runtimeFeedbackMapConnectionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Connection blocked'**
  String get runtimeFeedbackMapConnectionBlocked;

  /// No description provided for @runtimeFeedbackSceneUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Scene V1 impossible.'**
  String get runtimeFeedbackSceneUnavailable;

  /// No description provided for @runtimeFeedbackSceneCannotContinue.
  ///
  /// In en, this message translates to:
  /// **'The scene cannot continue.'**
  String get runtimeFeedbackSceneCannotContinue;

  /// No description provided for @runtimeFeedbackDialogueMissing.
  ///
  /// In en, this message translates to:
  /// **'The dialogue could not be found.'**
  String get runtimeFeedbackDialogueMissing;

  /// No description provided for @runtimeFeedbackMapPassageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This passage is unavailable right now.'**
  String get runtimeFeedbackMapPassageUnavailable;

  /// No description provided for @runtimeFeedbackTeleportFailed.
  ///
  /// In en, this message translates to:
  /// **'Teleportation failed.'**
  String get runtimeFeedbackTeleportFailed;

  /// No description provided for @runtimeFeedbackNeighboringMapTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'Travel to the neighboring map failed.'**
  String get runtimeFeedbackNeighboringMapTransferFailed;

  /// No description provided for @runtimeFeedbackContactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This contact is unavailable.'**
  String get runtimeFeedbackContactUnavailable;

  /// No description provided for @runtimeFeedbackPuzzleSceneRequired.
  ///
  /// In en, this message translates to:
  /// **'This puzzle requires an active scene.'**
  String get runtimeFeedbackPuzzleSceneRequired;

  /// No description provided for @battleMoveDamageSummary.
  ///
  /// In en, this message translates to:
  /// **'{actor} used {move} and dealt {amount} damage.'**
  String battleMoveDamageSummary({
    required String actor,
    required String move,
    required int amount,
  });

  /// No description provided for @runtimeFeedbackFieldMoveCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get runtimeFeedbackFieldMoveCut;

  /// No description provided for @runtimeFeedbackFieldMoveStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get runtimeFeedbackFieldMoveStrength;

  /// No description provided for @runtimeFeedbackFieldMoveRockSmash.
  ///
  /// In en, this message translates to:
  /// **'Rock Smash'**
  String get runtimeFeedbackFieldMoveRockSmash;

  /// No description provided for @runtimeFeedbackFieldMoveWaterfall.
  ///
  /// In en, this message translates to:
  /// **'Waterfall'**
  String get runtimeFeedbackFieldMoveWaterfall;

  /// No description provided for @runtimeFeedbackFieldMoveWhirlpool.
  ///
  /// In en, this message translates to:
  /// **'Whirlpool'**
  String get runtimeFeedbackFieldMoveWhirlpool;

  /// No description provided for @runtimeFeedbackFieldObstacleCutConfirm.
  ///
  /// In en, this message translates to:
  /// **'This tree can be cut down. Would you like to use Cut?'**
  String get runtimeFeedbackFieldObstacleCutConfirm;

  /// No description provided for @runtimeFeedbackFieldObstacleStrengthConfirm.
  ///
  /// In en, this message translates to:
  /// **'This boulder can be pushed. Would you like to use Strength?'**
  String get runtimeFeedbackFieldObstacleStrengthConfirm;

  /// No description provided for @runtimeFeedbackFieldObstacleRockSmashConfirm.
  ///
  /// In en, this message translates to:
  /// **'This rock can be smashed. Would you like to use Rock Smash?'**
  String get runtimeFeedbackFieldObstacleRockSmashConfirm;

  /// No description provided for @runtimeFeedbackFieldObstacleCutMissing.
  ///
  /// In en, this message translates to:
  /// **'This tree blocks the way. A Pokémon that can use Cut is needed.'**
  String get runtimeFeedbackFieldObstacleCutMissing;

  /// No description provided for @runtimeFeedbackFieldObstacleStrengthMissing.
  ///
  /// In en, this message translates to:
  /// **'This boulder blocks the way. A Pokémon that can use Strength is needed.'**
  String get runtimeFeedbackFieldObstacleStrengthMissing;

  /// No description provided for @runtimeFeedbackFieldObstacleRockSmashMissing.
  ///
  /// In en, this message translates to:
  /// **'This rock blocks the way. A Pokémon that can use Rock Smash is needed.'**
  String get runtimeFeedbackFieldObstacleRockSmashMissing;

  /// No description provided for @runtimeFeedbackFieldObstacleMoveLocked.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon in your party knows {move}. You have yet to unlock it outside battle.'**
  String runtimeFeedbackFieldObstacleMoveLocked({required String move});

  /// No description provided for @runtimeFeedbackFieldObstacleStrengthReady.
  ///
  /// In en, this message translates to:
  /// **'Strength is active. Walk toward this boulder to push it.'**
  String get runtimeFeedbackFieldObstacleStrengthReady;

  /// No description provided for @runtimeFeedbackFieldTraversalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use {move} to cross here?'**
  String runtimeFeedbackFieldTraversalConfirm({required String move});

  /// No description provided for @runtimeFeedbackFieldTraversalMoveMissing.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon that can use {move} is needed.'**
  String runtimeFeedbackFieldTraversalMoveMissing({required String move});

  /// No description provided for @runtimeFeedbackFieldTraversalMoveLocked.
  ///
  /// In en, this message translates to:
  /// **'You have yet to unlock {move} outside battle.'**
  String runtimeFeedbackFieldTraversalMoveLocked({required String move});

  /// No description provided for @runtimeFeedbackFieldTraversalSurfRequired.
  ///
  /// In en, this message translates to:
  /// **'Use Surf before crossing here.'**
  String get runtimeFeedbackFieldTraversalSurfRequired;

  /// No description provided for @runtimeFeedbackFieldTraversalWrongDirection.
  ///
  /// In en, this message translates to:
  /// **'Face the direction of the passage to cross it.'**
  String get runtimeFeedbackFieldTraversalWrongDirection;

  /// No description provided for @runtimeFeedbackFieldTraversalObstructed.
  ///
  /// In en, this message translates to:
  /// **'The passage or its exit is blocked.'**
  String get runtimeFeedbackFieldTraversalObstructed;

  /// No description provided for @runtimeFeedbackFieldTraversalWaterRequired.
  ///
  /// In en, this message translates to:
  /// **'This passage must be on water.'**
  String get runtimeFeedbackFieldTraversalWaterRequired;

  /// No description provided for @runtimeFeedbackFieldDiveConfirmDown.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use Dive to go underwater?'**
  String get runtimeFeedbackFieldDiveConfirmDown;

  /// No description provided for @runtimeFeedbackFieldDiveConfirmUp.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use Dive to return to the surface?'**
  String get runtimeFeedbackFieldDiveConfirmUp;

  /// No description provided for @runtimeFeedbackFieldDiveDisabled.
  ///
  /// In en, this message translates to:
  /// **'Dive is disabled in this game.'**
  String get runtimeFeedbackFieldDiveDisabled;

  /// No description provided for @runtimeFeedbackFieldDiveMoveMissing.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon that can use Dive is needed.'**
  String get runtimeFeedbackFieldDiveMoveMissing;

  /// No description provided for @runtimeFeedbackFieldDiveMoveLocked.
  ///
  /// In en, this message translates to:
  /// **'You have yet to unlock Dive outside battle.'**
  String get runtimeFeedbackFieldDiveMoveLocked;

  /// No description provided for @runtimeFeedbackFieldDiveSurfRequired.
  ///
  /// In en, this message translates to:
  /// **'Use Surf to dive from the surface.'**
  String get runtimeFeedbackFieldDiveSurfRequired;

  /// No description provided for @runtimeFeedbackFieldDiveObstructed.
  ///
  /// In en, this message translates to:
  /// **'The Dive destination or return point is blocked.'**
  String get runtimeFeedbackFieldDiveObstructed;

  /// No description provided for @runtimeFeedbackFieldDiveDestinationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This Dive spot is not connected to an available destination.'**
  String get runtimeFeedbackFieldDiveDestinationUnavailable;

  /// No description provided for @runtimeFeedbackFieldFlashConfirm.
  ///
  /// In en, this message translates to:
  /// **'It’s dark here. Would you like to use Flash to light the area?'**
  String get runtimeFeedbackFieldFlashConfirm;

  /// No description provided for @runtimeFeedbackFieldFlashMoveMissing.
  ///
  /// In en, this message translates to:
  /// **'It’s dark here. A Pokémon that can use Flash is needed.'**
  String get runtimeFeedbackFieldFlashMoveMissing;

  /// No description provided for @runtimeFeedbackFieldFlashMoveLocked.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon knows Flash. You have yet to unlock it outside battle.'**
  String get runtimeFeedbackFieldFlashMoveLocked;

  /// No description provided for @runtimeFeedbackHeadbuttMoveMissing.
  ///
  /// In en, this message translates to:
  /// **'A Pokémon that can use Headbutt is needed.'**
  String get runtimeFeedbackHeadbuttMoveMissing;

  /// No description provided for @runtimeFeedbackHeadbuttTreeConsumed.
  ///
  /// In en, this message translates to:
  /// **'No more Pokémon are hiding in this tree right now.'**
  String get runtimeFeedbackHeadbuttTreeConsumed;

  /// No description provided for @runtimeFeedbackHeadbuttWrongPosition.
  ///
  /// In en, this message translates to:
  /// **'Stand on foot in front of this tree to use Headbutt.'**
  String get runtimeFeedbackHeadbuttWrongPosition;

  /// No description provided for @runtimeFeedbackHeadbuttMapUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Object encounters are available on supported 2D maps.'**
  String get runtimeFeedbackHeadbuttMapUnsupported;

  /// No description provided for @runtimeFeedbackHeadbuttUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No encounter is available at this tree right now.'**
  String get runtimeFeedbackHeadbuttUnavailable;

  /// No description provided for @runtimeFeedbackHeadbuttConfirm.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use Headbutt on this tree?'**
  String get runtimeFeedbackHeadbuttConfirm;

  /// No description provided for @runtimeFeedbackInteractiveEncounterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Pokémon appeared…'**
  String get runtimeFeedbackInteractiveEncounterEmpty;

  /// No description provided for @runtimeFeedbackInteractiveEncounterUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This encounter is no longer available.'**
  String get runtimeFeedbackInteractiveEncounterUnavailable;

  /// No description provided for @runtimeFeedbackRepelExpired.
  ///
  /// In en, this message translates to:
  /// **'The Repel wore off.'**
  String get runtimeFeedbackRepelExpired;

  /// No description provided for @runtimeFeedbackRepelRenew.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use another Repel of the same kind?'**
  String get runtimeFeedbackRepelRenew;

  /// No description provided for @runtimeFeedbackRepelRenewed.
  ///
  /// In en, this message translates to:
  /// **'Repel is active again.'**
  String get runtimeFeedbackRepelRenewed;

  /// No description provided for @runtimeFeedbackRepelStockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This Repel is no longer available.'**
  String get runtimeFeedbackRepelStockUnavailable;

  /// No description provided for @runtimeFeedbackRepelProgressSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Progress could not be saved.'**
  String get runtimeFeedbackRepelProgressSaveFailed;

  /// No description provided for @runtimeFeedbackSpatialNeighborUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A neighboring map could not be displayed.'**
  String get runtimeFeedbackSpatialNeighborUnavailable;

  /// No description provided for @runtimeFeedbackSpatialInteractionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This passage or dialogue could not be opened.'**
  String get runtimeFeedbackSpatialInteractionUnavailable;

  /// No description provided for @runtimeFeedbackMovingPlatformUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The platform could not be moved.'**
  String get runtimeFeedbackMovingPlatformUnavailable;

  /// No description provided for @runtimeFeedbackEntranceAnimationMissing.
  ///
  /// In en, this message translates to:
  /// **'This entrance has no animation.'**
  String get runtimeFeedbackEntranceAnimationMissing;

  /// No description provided for @runtimeFeedbackEntranceAnimationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This entrance’s animation is unavailable.'**
  String get runtimeFeedbackEntranceAnimationUnavailable;

  /// No description provided for @runtimeFeedbackElementAnimationUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'The animation could not be updated.'**
  String get runtimeFeedbackElementAnimationUpdateFailed;

  /// No description provided for @runtimeFeedbackSpatialSceneTextInputUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Scene text input is unavailable in 3D.'**
  String get runtimeFeedbackSpatialSceneTextInputUnsupported;

  /// No description provided for @runtimeFeedbackSpatialSceneRegionalMapUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The regional map is unavailable during 3D scenes.'**
  String get runtimeFeedbackSpatialSceneRegionalMapUnsupported;

  /// No description provided for @runtimeFeedbackSceneRewardCalendarUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The calendar for this reward is unavailable. Reopen the game and try again.'**
  String get runtimeFeedbackSceneRewardCalendarUnavailable;
}

class _PlayerCatalogDelegate extends LocalizationsDelegate<PlayerCatalog> {
  const _PlayerCatalogDelegate();

  @override
  Future<PlayerCatalog> load(Locale locale) {
    return SynchronousFuture<PlayerCatalog>(lookupPlayerCatalog(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_PlayerCatalogDelegate old) => false;
}

PlayerCatalog lookupPlayerCatalog(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PlayerCatalogEn();
    case 'fr':
      return PlayerCatalogFr();
  }

  throw FlutterError(
    'PlayerCatalog.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
