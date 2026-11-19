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
