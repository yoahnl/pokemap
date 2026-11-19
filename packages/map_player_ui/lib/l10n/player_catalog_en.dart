// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'player_catalog.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PlayerCatalogEn extends PlayerCatalog {
  PlayerCatalogEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PokeMap Hub';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get preferences => 'Preferences';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get installedGames => 'Installed games';

  @override
  String get recentGames => 'Recent games';

  @override
  String get resumeLastGame => 'Resume last game';

  @override
  String get importGame => 'Import a game';

  @override
  String get emptyLibraryTitle => 'Your library is ready';

  @override
  String get emptyLibraryMessage =>
      'Import a compatible game package to begin an adventure.';

  @override
  String get searchGames => 'Search games';

  @override
  String get continueGame => 'Continue';

  @override
  String get newGame => 'New game';

  @override
  String get load => 'Load';

  @override
  String get options => 'Options';

  @override
  String get creditsAbout => 'Credits / About';

  @override
  String get returnToHub => 'Back to Hub';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get party => 'Party';

  @override
  String get bag => 'Bag';

  @override
  String get pokedex => 'Pokédex';

  @override
  String get searchPokedex => 'Search species';

  @override
  String get noPokedexMatch => 'No matching species';

  @override
  String get map => 'Map';

  @override
  String get quests => 'Quests';

  @override
  String get profile => 'Profile';

  @override
  String get save => 'Save';

  @override
  String get returnToTitle => 'Back to title';

  @override
  String get play => 'Play';

  @override
  String get update => 'Update';

  @override
  String get repair => 'Repair';

  @override
  String get manageSaves => 'Manage saves';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get version => 'Version';

  @override
  String get author => 'Author';

  @override
  String get lastSave => 'Latest save';

  @override
  String get playTime => 'Play time';

  @override
  String get noSave => 'No save';

  @override
  String get loading => 'Loading';

  @override
  String get cancel => 'Cancel';

  @override
  String get showCredits => 'View credits';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get audio => 'Audio';

  @override
  String get reducedMotion => 'Reduce motion';

  @override
  String get highContrast => 'High contrast';

  @override
  String get haptics => 'Haptics';

  @override
  String get textSize => 'Text size';

  @override
  String get inputHints => 'Show controls';

  @override
  String get touchControlsOpacity => 'Touch controls opacity';

  @override
  String get launchMostRecentGameOnStartup => 'Launch the latest game directly';

  @override
  String get launchMostRecentGameOnStartupDescription =>
      'At startup, open the most recent playable game without showing the Hub home screen.';

  @override
  String get healthy => 'Installation verified';

  @override
  String get needsRepair => 'Repair required';

  @override
  String get storage => 'Storage';

  @override
  String get usedStorage => 'Used by the application';

  @override
  String get availableStorage => 'Available';

  @override
  String get noDiagnostics => 'No issue detected';

  @override
  String get actionUnavailable => 'Action unavailable';

  @override
  String get menuBackgroundUnavailable => 'Menu background unavailable.';

  @override
  String get confirmShortcut => 'Enter / A button';

  @override
  String get interact => 'Interact';

  @override
  String get talk => 'Talk';

  @override
  String get read => 'Read';

  @override
  String get collect => 'Collect';

  @override
  String get enter => 'Enter';

  @override
  String get run => 'Run';

  @override
  String get badges => 'Badges';

  @override
  String get menu => 'Menu';

  @override
  String get pokemon => 'Pokémon';

  @override
  String get choose => 'Choose';

  @override
  String get battleChooseMove => 'Choose a move';

  @override
  String get validate => 'Confirm';

  @override
  String get noSaveAvailable => 'No save available';

  @override
  String get noSaveToLoad => 'No save to load';

  @override
  String get noPlayerDetailAvailable => 'No information is available yet.';

  @override
  String get unavailableInGame => 'Unavailable in this game';

  @override
  String get directReturnHub => 'This ending returns directly to the Hub';

  @override
  String get directReturnTitle => 'This ending returns directly to the title';

  @override
  String get preparingSession => 'Preparing session';

  @override
  String get sessionSuspended => 'Session suspended';

  @override
  String get resumeOnReturn => 'Resumes when you return';

  @override
  String get validatingCompletion => 'Validating completion';

  @override
  String get closingSession => 'Closing session';

  @override
  String get returningHub => 'Returning to Hub';

  @override
  String get loadingGame => 'Loading game';

  @override
  String get completionSaveIncomplete => 'Completion save incomplete';

  @override
  String get completionSaveMessage => 'The ending cannot be validated yet.';

  @override
  String get completionSaveRecommendation =>
      'Retry without leaving to preserve your progress.';

  @override
  String get sessionErrorTitle => 'The game encountered a problem';

  @override
  String get sessionCannotContinue => 'The session cannot continue.';

  @override
  String get completedFallback => 'Game completed';

  @override
  String get completedSummaryFallback => 'Your adventure is complete.';

  @override
  String get retryKeepsSaves => 'Retry. Your existing saves remain intact.';

  @override
  String get repairFromHub => 'Return to the Hub and repair the installation.';

  @override
  String get returnTitleOrHub => 'Return to the title or Hub.';

  @override
  String get consultDiagnostics => 'Return to the Hub to view diagnostics.';

  @override
  String get overwriteSaveTitle => 'Replace this save?';

  @override
  String get overwriteSaveMessage =>
      'The current save remains intact until the new game creates its first checkpoint.';

  @override
  String get hubSubtitle => 'Your adventures, ready to resume.';

  @override
  String get openingLibrary => 'Opening library';

  @override
  String get hubAttentionTitle => 'The Hub needs your attention';

  @override
  String get libraryUnavailable => 'The library cannot be displayed.';

  @override
  String get installedDataPreserved => 'Your games and saves remain on disk.';

  @override
  String get installingGame => 'Installing game';

  @override
  String get importUnavailable => 'Import unavailable on this platform';

  @override
  String get noSearchResult => 'No matching game';

  @override
  String get tryAnotherSearch => 'Try another search.';

  @override
  String get globalSettingsSubtitle => 'Global settings for the Hub and games.';

  @override
  String get systemLanguage => 'System language';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get theme => 'Theme';

  @override
  String get masterVolume => 'Master volume';

  @override
  String get music => 'Music';

  @override
  String get effects => 'Effects';

  @override
  String get diagnosticsSubtitle =>
      'Library, installation, and storage status.';

  @override
  String get diagnosticsReady => 'The library and installations are ready.';

  @override
  String get viewGameDetails => 'Open game details';

  @override
  String get repairRequired => 'Repair required';

  @override
  String get launchUnavailable => 'Launch unavailable';

  @override
  String get noUpdateAvailable => 'No update available';

  @override
  String get updateUnavailable => 'Update unavailable';

  @override
  String get repairSourceMissing => 'No repair source selected';

  @override
  String get saveManagementUnavailable => 'Save management unavailable';

  @override
  String get uninstallUnavailable => 'Uninstall unavailable';

  @override
  String get repairBeforePlaying => 'Repair the game before playing';

  @override
  String get loadingPackage => 'Reading package';

  @override
  String get checkingCompatibility => 'Checking compatibility';

  @override
  String get checkingStorage => 'Checking storage';

  @override
  String get protectingInstalledVersion => 'Protecting installed version';

  @override
  String get secureExtraction => 'Secure extraction';

  @override
  String get verifyingFiles => 'Verifying files';

  @override
  String get validatingGame => 'Validating game';

  @override
  String get loadingTrial => 'Loading trial';

  @override
  String get preparingSaves => 'Preparing saves';

  @override
  String get activatingVersion => 'Activating version';

  @override
  String get updatingLibrary => 'Updating library';

  @override
  String get installationComplete => 'Installation complete';

  @override
  String get estimatedTimeCalculating =>
      'Estimated time remaining: calculating…';

  @override
  String get cancelling => 'Cancelling';

  @override
  String get recovering => 'Recovering';

  @override
  String get preparing => 'Preparing';

  @override
  String get back => 'Back';

  @override
  String get mandatoryReplacement => 'Replacement required';

  @override
  String get levelAbbreviation => 'Lv.';

  @override
  String get hpAbbreviation => 'HP';

  @override
  String get experienceAbbreviation => 'XP';

  @override
  String get showFullText => 'Show';

  @override
  String get next => 'Next';

  @override
  String get yourChoice => 'Your choice';

  @override
  String get postBattle => 'Post-battle';

  @override
  String get progression => 'Progress';

  @override
  String get battleResult => 'Battle result';

  @override
  String get battleCommands => 'COMMANDS';

  @override
  String get battleFight => 'FIGHT';

  @override
  String get battleRun => 'RUN';

  @override
  String get battleMoveInfo => 'Info';

  @override
  String get battleMoves => 'MOVES';

  @override
  String get battleBag => 'BAG';

  @override
  String get battleBagMedicine => 'HEALING';

  @override
  String get battleBagCapture => 'CAPTURE';

  @override
  String get battleBagOther => 'ITEM';

  @override
  String get battleTarget => 'TARGET';

  @override
  String get battlePokemon => 'POKÉMON';

  @override
  String get battleContinue => 'CONTINUE';

  @override
  String get battleDecision => 'CHOICE';

  @override
  String get reward => 'Reward';

  @override
  String get decision => 'Decision';

  @override
  String get shopItems => 'Items';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopSell => 'Sell';

  @override
  String get shopQuantity => 'Quantity';

  @override
  String get shopDecreaseQuantity => 'Decrease quantity';

  @override
  String get shopIncreaseQuantity => 'Increase quantity';

  @override
  String get shopUnsellable => 'Cannot be sold';

  @override
  String get shopEmpty => 'This shop is empty.';

  @override
  String get shopBagEmpty => 'The bag is empty.';

  @override
  String get shopNoItems => 'No items available';

  @override
  String get shopCannotDisplay => 'The shop cannot be displayed.';

  @override
  String get confirmOverwrite =>
      'This save already exists. Do you want to replace it?';

  @override
  String get dialogueChoicePrompt => 'Choose a reply.';

  @override
  String estimatedTimeRemainingMessage({required String duration}) {
    return 'Estimated time remaining: $duration';
  }

  @override
  String shortSecondsMessage({required int seconds}) {
    return '$seconds sec';
  }

  @override
  String shortMinutesMessage({required int minutes}) {
    return '$minutes min';
  }

  @override
  String shopStockMessage({required int quantity}) {
    return 'Stock: $quantity';
  }

  @override
  String shopOwnedMessage({required int quantity}) {
    return 'Owned: $quantity';
  }

  @override
  String shopTotalMessage({required int amount}) {
    return 'Total: $amount ₽';
  }

  @override
  String installedGameCountMessage({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count installed games',
      one: '$count installed game',
      zero: '0 installed games',
    );
    return '$_temp0';
  }

  @override
  String diagnosticsToReviewMessage({required int count}) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count diagnostics to review',
      one: '$count diagnostic to review',
      zero: '0 diagnostics to review',
    );
    return '$_temp0';
  }

  @override
  String levelLabelMessage({required int level}) {
    return 'Lv. $level';
  }

  @override
  String hpLabelMessage({required int current, required int maximum}) {
    return '$current / $maximum HP';
  }

  @override
  String hpFractionMessage({required int current, required int maximum}) {
    return '$current/$maximum';
  }

  @override
  String experienceProgressMessage({required int percent}) {
    return 'Progress to the next level: $percent%';
  }

  @override
  String postBattleProgressMessage({required int current, required int total}) {
    return '$current / $total';
  }

  @override
  String confirmOverwriteUnusableMessage({required String reason}) {
    return 'This save cannot be continued: $reason Replacing it will permanently erase its progress.';
  }

  @override
  String get battleMoveCategorySpecial => 'SPECIAL';

  @override
  String get battleMoveCategoryPhysical => 'PHYSICAL';

  @override
  String get battleMoveCategoryStatus => 'STATUS';

  @override
  String get saveUnavailablePostGameContinuationRefused =>
      'This ending does not allow post-game continuation.';

  @override
  String get saveUnavailableMigrationRequired =>
      'This save must be migrated before it can be loaded.';

  @override
  String get saveUnavailableIncompatibleVersion =>
      'This save is not compatible with the installed game version.';

  @override
  String get saveUnavailableCorrupt =>
      'This save is damaged and could not be recovered from its backup.';

  @override
  String get saveUnavailableMissing => 'No save exists in this slot.';

  @override
  String get saveUnavailableTemporarilyUnavailable =>
      'This save is temporarily unavailable.';

  @override
  String battleMoveTypeMessage({
    required String type,
    required String fallback,
  }) {
    String _temp0 = intl.Intl.selectLogic(type, {'other': '$fallback'});
    return '$_temp0';
  }

  @override
  String get bagUse => 'Use';

  @override
  String get bagChooseTarget => 'Choose a target';

  @override
  String get bagManageHeldItem => 'Manage held item';

  @override
  String bagHeldItemSummary({required String item}) {
    return 'Held item: $item';
  }

  @override
  String bagGiveHeldItem({required String item}) {
    return 'Give $item';
  }

  @override
  String bagReplaceHeldItem({required String item}) {
    return 'Replace with $item';
  }

  @override
  String bagTakeHeldItem({required String item}) {
    return 'Take $item';
  }

  @override
  String bagUseOn({required String pokemon}) {
    return 'Use on $pokemon';
  }

  @override
  String bagUseOnMove({required String pokemon, required String move}) {
    return 'Use on $pokemon — $move';
  }

  @override
  String bagTeachTo({required String pokemon}) {
    return 'Teach to $pokemon';
  }

  @override
  String bagTeachReplacing({required String pokemon, required String move}) {
    return 'Teach to $pokemon and forget $move';
  }

  @override
  String get optionsCategoryControls => 'Controls';

  @override
  String get controlsConflict => 'This input is already assigned.';

  @override
  String get controlsReset => 'Reset';

  @override
  String get controlsSwapTouch => 'Swap A / B';

  @override
  String get controlsDeviceKeyboard => 'Keyboard';

  @override
  String get controlsDeviceGamepad => 'Gamepad';

  @override
  String get controlsDeviceTouch => 'Touch';

  @override
  String get controlsControlUp => 'Up';

  @override
  String get controlsControlDown => 'Down';

  @override
  String get controlsControlLeft => 'Left';

  @override
  String get controlsControlRight => 'Right';

  @override
  String get controlsControlSprint => 'Sprint';

  @override
  String get controlsControlPrimary => 'Primary action';

  @override
  String get controlsControlSecondary => 'Secondary action';

  @override
  String get controlsControlBicycle => 'Bicycle';

  @override
  String get controlsControlPreviousTab => 'Previous tab';

  @override
  String get controlsControlNextTab => 'Next tab';

  @override
  String get displayTitle => 'Display';

  @override
  String get displayMode => 'Display mode';

  @override
  String get displayWindowed => 'Windowed';

  @override
  String get displayFullscreen => 'Fullscreen';

  @override
  String get displayWindowSize => 'Window size';

  @override
  String get displayCompact => 'Compact';

  @override
  String get displayBalanced => 'Balanced';

  @override
  String get displaySpacious => 'Spacious';

  @override
  String get displayUnsupported => 'Window settings are available on desktop.';

  @override
  String get displayApplyFailed => 'The display setting could not be applied.';

  @override
  String get healStatusNeedsHealing => 'Status needs healing';

  @override
  String get healStatusHealthy => 'Status healthy';

  @override
  String healPpToRestore({required int count}) {
    return 'PP to restore: $count';
  }

  @override
  String get healPpFull => 'PP full';

  @override
  String get noPokemon => 'No Pokémon';

  @override
  String get emptyPartyMessage => 'Your party is empty.';

  @override
  String get returnToGame => 'Return to game';

  @override
  String get healRetry => 'Try again';

  @override
  String get healHealParty => 'Heal';

  @override
  String get healUnavailable => 'The healing service cannot be displayed.';

  @override
  String healHp({required int current, required int maximum}) {
    return 'HP $current / $maximum';
  }

  @override
  String get introVideoSkip => 'Skip';

  @override
  String get introVideoReplay => 'Replay';

  @override
  String get introVideoUnavailable => 'Video playback is unavailable.';

  @override
  String get introVideoReducedMotionSkipped =>
      'Intro skipped with reduced motion';

  @override
  String pcSummaryTitle({required String pokemon}) {
    return '$pokemon summary';
  }

  @override
  String get pcSummaryTooltip => 'View summary';

  @override
  String get pcSwapTooltip => 'Swap';

  @override
  String get pcEmptyBox => 'This Box is empty.';

  @override
  String get pcDeposit => 'Deposit';

  @override
  String get pcWithdraw => 'Withdraw';

  @override
  String get pcUnavailable => 'The PC cannot be displayed.';

  @override
  String pokemonLevel({required int level}) {
    return 'Lv. $level';
  }

  @override
  String get pcSpecies => 'Species';

  @override
  String get pcLevel => 'Level';

  @override
  String get pcCurrentHp => 'Current HP';

  @override
  String get pcAbility => 'Ability';

  @override
  String get pcGender => 'Gender';

  @override
  String get pcStatus => 'Status';

  @override
  String get pcShiny => 'Shiny';

  @override
  String get pcHeldItem => 'Held item';

  @override
  String get pcMoves => 'Moves';

  @override
  String get pcNickname => 'Nickname';

  @override
  String get pcFriendship => 'Friendship';

  @override
  String get pcOrigin => 'Origin';

  @override
  String get pcMetLocation => 'Met location';

  @override
  String get pcMetSource => 'Source';

  @override
  String get pcMetLevel => 'Met level';

  @override
  String get pcCaptureBall => 'Capture Ball';

  @override
  String get pcNone => 'None';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get pokemonOriginCaptured => 'Captured';

  @override
  String get pokemonOriginGift => 'Gift';

  @override
  String get pokemonOriginStarter => 'Starter';

  @override
  String get pokemonOriginTrade => 'Trade';

  @override
  String get pokemonOriginScripted => 'Event';

  @override
  String get pokemonOriginUnknown => 'Unknown';

  @override
  String pcSwapWith({required String pokemon}) {
    return 'Swap with $pokemon';
  }

  @override
  String pokemonPpValue({required int current, required int max}) {
    return 'PP $current/$max';
  }

  @override
  String get pokemonSpecies => 'Species';

  @override
  String get pokemonForm => 'Form';

  @override
  String get pokemonExperience => 'Experience';

  @override
  String get pokemonNature => 'Nature';

  @override
  String get pokemonAbility => 'Ability';

  @override
  String get pokemonGender => 'Gender';

  @override
  String get pokemonShiny => 'Shiny';

  @override
  String get pokemonHeldItem => 'Held item';

  @override
  String get pokemonFriendship => 'Friendship';

  @override
  String get pokemonStats => 'Stats';

  @override
  String get pokemonAttack => 'Attack';

  @override
  String get pokemonDefense => 'Defense';

  @override
  String get pokemonSpecialAttack => 'Sp. Attack';

  @override
  String get pokemonSpecialDefense => 'Sp. Defense';

  @override
  String get pokemonSpeed => 'Speed';

  @override
  String get pokemonMoves => 'Moves';

  @override
  String get pokemonProvenance => 'Origin';

  @override
  String get pokemonOrigin => 'Origin';

  @override
  String get pokemonMetLocation => 'Met location';

  @override
  String get pokemonMetSource => 'Source';

  @override
  String get pokemonMetLevel => 'Met level';

  @override
  String get pokemonCaptureBall => 'Capture Ball';

  @override
  String get pokemonNone => 'None';

  @override
  String get pokemonViewSummary => 'View summary';

  @override
  String pokemonFriendshipValue({required int friendship}) {
    return '$friendship/255';
  }

  @override
  String get pokemonPpUnavailable => '—';

  @override
  String get saveRecoveryCauseUnreadable => 'The save file cannot be read.';

  @override
  String get saveRecoveryCauseUnsupportedSchema =>
      'This save comes from another version of the game.';

  @override
  String get saveRecoveryCauseInvalidState =>
      'The save is incomplete or inconsistent.';

  @override
  String saveRecoveryExpectedVersion({required int expected}) {
    return 'This game expects version $expected.';
  }

  @override
  String saveRecoveryVersionMismatch({
    required int detected,
    required int expected,
  }) {
    return 'Save is version $detected, this game expects version $expected.';
  }

  @override
  String get saveRecoveryActionRetry => 'Try again';

  @override
  String get saveRecoveryActionRestoreBackup => 'Restore the previous save';

  @override
  String get saveRecoveryActionMigrate => 'Update the save';

  @override
  String get saveRecoveryActionDeleteSave => 'Delete the save';

  @override
  String get saveRecoveryDeleteConfirmTitle => 'Delete permanently?';

  @override
  String get saveRecoveryDeleteConfirmBody =>
      'This game will be erased and cannot be recovered.';

  @override
  String get saveRecoveryDeleteConfirm => 'Delete permanently';

  @override
  String get saveTitle => 'Save game?';

  @override
  String get saveSaving => 'Saving…';

  @override
  String get saveSuccess => 'Game saved';

  @override
  String get saveFailure => 'Unable to save';

  @override
  String get saveExitTitle => 'Return to title?';

  @override
  String get saveStay => 'Stay';

  @override
  String get saveDiscard => 'Return to title without saving';

  @override
  String get saveSaveAndExit => 'Save and quit';

  @override
  String get saveExiting => 'Returning to title…';

  @override
  String get saveExitFailure => 'Unable to return to title';

  @override
  String get saveExitWarning =>
      'Unsaved progress will be lost if you leave without saving.';

  @override
  String get saveDiscardUnavailable =>
      'This player cannot leave without saving.';

  @override
  String get saveSaveUnavailable => 'No active save slot is available.';

  @override
  String get saveSaveAndExitUnavailable =>
      'This player cannot save and then quit.';

  @override
  String get saveMissingReceipt => 'The save was not confirmed. Please retry.';

  @override
  String get saveUnexpectedFailure =>
      'The operation could not be completed. Please retry.';

  @override
  String savePlayer({required String name}) {
    return 'Player: $name';
  }

  @override
  String saveLocation({required String name}) {
    return 'Location: $name';
  }

  @override
  String savePlaytime({required String minutes, required int hours}) {
    return 'Play time: $hours h $minutes min';
  }

  @override
  String saveLastSave({required String date, required String time}) {
    return 'Last save: $date at $time';
  }

  @override
  String saveTarget({required String profile, required String slot}) {
    return 'Profile “$profile”, slot “$slot”.';
  }

  @override
  String saveSaved({required String profile, required String slot}) {
    return 'Game saved — profile “$profile”, slot “$slot”.';
  }

  @override
  String get interactionSubmit => 'Submit';

  @override
  String get interactionTextFieldLabel => 'Your answer';

  @override
  String get interactionSelected => 'Selected';

  @override
  String get interactionOptionUnavailable => 'This option is unavailable.';

  @override
  String get interactionMaximumReached =>
      'The maximum number of choices is reached.';

  @override
  String interactionCharacterCount({required int current}) {
    String _temp0 = intl.Intl.pluralLogic(
      current,
      locale: localeName,
      other: '$current characters',
      one: '$current character',
      zero: '0 characters',
    );
    return '$_temp0';
  }

  @override
  String interactionSelectionCount({
    required int current,
    required int minimum,
    required int maximum,
  }) {
    return '$current selected, between $minimum and $maximum required';
  }

  @override
  String interactionIntegerOutOfRange({
    required String minimum,
    required String maximum,
  }) {
    return 'Enter an integer between $minimum and $maximum.';
  }

  @override
  String get interactionCancellationForbidden =>
      'Submit this input to continue.';

  @override
  String interactionTextTooShort({required int minimum}) {
    String _temp0 = intl.Intl.pluralLogic(
      minimum,
      locale: localeName,
      other: 'Enter at least $minimum characters.',
      one: 'Enter at least $minimum character.',
    );
    return '$_temp0';
  }

  @override
  String interactionTextTooLong({required int maximum}) {
    String _temp0 = intl.Intl.pluralLogic(
      maximum,
      locale: localeName,
      other: 'Enter at most $maximum characters.',
      one: 'Enter at most $maximum character.',
    );
    return '$_temp0';
  }

  @override
  String interactionTooFewSelections({required int minimum}) {
    String _temp0 = intl.Intl.pluralLogic(
      minimum,
      locale: localeName,
      other: 'Select at least $minimum options.',
      one: 'Select at least $minimum option.',
    );
    return '$_temp0';
  }

  @override
  String interactionTooManySelections({required int maximum}) {
    String _temp0 = intl.Intl.pluralLogic(
      maximum,
      locale: localeName,
      other: 'Select at most $maximum options.',
      one: 'Select at most $maximum option.',
    );
    return '$_temp0';
  }

  @override
  String get interactionCannotSubmit => 'This answer cannot be submitted.';

  @override
  String get startupPressStart => 'Press Start';

  @override
  String get startupReplayIntro => 'Replay intro';

  @override
  String get startupReplaceSaveTitle => 'Replace the current game?';

  @override
  String get startupReplaceSaveBody =>
      'A new game will replace the current save the next time it is saved.';

  @override
  String get startupBegin => 'Start';

  @override
  String get startupStartupUnavailable => 'The game could not finish starting.';

  @override
  String get startupPreparing => 'Preparing…';

  @override
  String get optionsCategoryGeneral => 'General';

  @override
  String get optionsCategoryWeather => 'Weather';

  @override
  String get optionsCategoryTime => 'Time';

  @override
  String get optionsCategoryDisplay => 'Display';

  @override
  String get optionsCategoryAudio => 'Sound';

  @override
  String get optionsSpeedSlow => 'Slow';

  @override
  String get optionsSpeedNormal => 'Normal';

  @override
  String get optionsSpeedFast => 'Fast';

  @override
  String get optionsSpeedInstant => 'Instant';

  @override
  String get optionsEffectsFull => 'Full';

  @override
  String get optionsEffectsReduced => 'Reduced';

  @override
  String get optionsEffectsOpaque => 'Opaque';

  @override
  String get optionsHelpWeather =>
      'Choose the source for real weather. Story scenes keep priority.';

  @override
  String get optionsHelpTime =>
      'Real time follows the clock the game intends, usually the device clock. A chosen hour freezes day and night, and time-based events follow it. Story scenes keep priority.';

  @override
  String get optionsHelpGeneral => 'Choose how quickly dialogue text appears.';

  @override
  String get optionsHelpDisplay =>
      'A lower frame rate limit reduces power use. The actual rate depends on the display and device. Menu effects: Reduced limits their animations; Opaque uses solid panels. 3D resolution keeps the image format; lower values lighten the load, and upscaling chooses how the image is enlarged to the screen. Scene effects stay as the game intends until you turn them off.';

  @override
  String get optionsHelpAudio =>
      'Master volume controls every channel. At 0%, sound is muted. Left and right adjust volume in steps of 5%.';

  @override
  String get optionsHelpControls =>
      'Hints follow the current bindings. Duplicate inputs are rejected to keep every action accessible. Opacity affects the touch controls shown in game.';

  @override
  String get optionsHelpLanguage =>
      'Interface language changes the Player menus. Dialogue follows the translations available in the game.';

  @override
  String get optionsHelpAccessibility =>
      'Adjust readability for your comfort. Reduced motion requested by the system still takes priority.';

  @override
  String get optionsScope => 'Settings saved on this device.';

  @override
  String get optionsCategories => 'Categories';

  @override
  String get optionsDefaults => 'Defaults';

  @override
  String get optionsRestore => 'Restore';

  @override
  String get optionsSaving => 'Saving…';

  @override
  String get optionsError =>
      'Could not save settings. The last saved values have been kept. Please try again.';

  @override
  String get optionsReturnToTitle => 'Return to title';

  @override
  String get optionsTextSpeed => 'Text speed';

  @override
  String get optionsBattleSpeed => 'Battle speed';

  @override
  String get optionsBattleEffectIntensity => 'Battle effect intensity';

  @override
  String get optionsMenuEffects => 'Menu effects';

  @override
  String get optionsFrameRateLimit => 'Frames per second';

  @override
  String get optionsRenderScale => '3D resolution';

  @override
  String get optionsRenderScaleValue => 'Auto (per device)';

  @override
  String get optionsUpscaling => '3D upscaling';

  @override
  String get optionsUpscalingValueNearest => 'Sharp pixels';

  @override
  String get optionsDepthOfField => 'Depth of field';

  @override
  String get optionsShadows => 'Shadows';

  @override
  String get optionsFogAndHalos => 'Fog and halos';

  @override
  String get optionsAmbientAnimation => 'Animated ambience';

  @override
  String get optionsWorldTime => 'World time';

  @override
  String get optionsWorldTimeValue => 'Real time';

  @override
  String get optionsMaster => 'Master volume';

  @override
  String get optionsSoundEffects => 'Sound effects';

  @override
  String get optionsInterfaceLanguage => 'Interface language';

  @override
  String get optionsFollowApplicationLanguage => 'Follow the app';

  @override
  String get optionsHighContrast => 'Increase contrast';

  @override
  String get optionsHaptics => 'Vibration';

  @override
  String get optionsHints => 'Show control hints';

  @override
  String get optionsLeftHandedTouchControls => 'Touch joystick on the right';

  @override
  String get optionsTouchRunMode => 'Touch running';

  @override
  String get optionsRunningModeGesture => 'Run with a wider gesture';

  @override
  String get optionsRunningModeWalkOnly => 'Walk only';

  @override
  String get optionsRunningModeAutomatic => 'Run automatically when allowed';

  @override
  String optionsResetTitle({required String category}) {
    return 'Reset $category?';
  }

  @override
  String get optionsResetControlsMessage =>
      'Touch running, joystick side, control hints and opacity will be reset. Keyboard and controller bindings will be kept.';

  @override
  String optionsResetMessage({required String category}) {
    return 'Only the settings in “$category” will be reset. Your save and other categories will be kept.';
  }

  @override
  String optionsRenderScalePercent({required int percent}) {
    return '$percent %';
  }

  @override
  String get optionsFsr => 'FSR 1 (AMD)';

  @override
  String optionsFrameRateValue({required int rate}) {
    return '$rate FPS';
  }

  @override
  String get nextPage => 'Next page';

  @override
  String get previousPage => 'Previous page';

  @override
  String get partyTradeWithItself => 'With itself';

  @override
  String get partyTradeChoosePartner => 'Choose a partner';

  @override
  String get confirm => 'Confirm';

  @override
  String get partyTradeTitle => 'Party trade';

  @override
  String get partyTradeCompleted => 'Trade completed.';

  @override
  String get partyTradeConfirmTrade => 'Confirm this trade?';

  @override
  String get partyTradeSelectPartner => 'Choose its partner from your party.';

  @override
  String get partyTradeChooseAnotherPartner =>
      'Choose another Pokémon as partner?';

  @override
  String get partyTradeSelectPokemon => 'Choose the Pokémon to trade.';

  @override
  String get partyTradeUnavailable => 'Trade is unavailable.';

  @override
  String get pcNextBox => 'Next box';

  @override
  String get pcPreviousBox => 'Previous box';

  @override
  String get pokemonSummary => 'Summary';

  @override
  String giftSentToPc({required String nickname}) {
    return '$nickname will be sent to the PC.';
  }

  @override
  String giftJoinsParty({required String nickname}) {
    return '$nickname will join your party.';
  }

  @override
  String get giftNewPokedexEntry => 'New Pokédex entry to add';

  @override
  String get giftTitle => 'A new companion';

  @override
  String get giftEgg => 'The Egg';

  @override
  String get pokemonEggEntrusted => 'An Egg entrusted to your party.';

  @override
  String get keyboardDelete => 'Delete';

  @override
  String get keyboardSpace => 'Space';

  @override
  String get credits => 'Credits';

  @override
  String get bagTargetIncompatible => 'Not compatible.';

  @override
  String get bagActionFailed => 'The action failed. Try again.';

  @override
  String get bagNoEligibleTarget => 'No companion can receive this item.';

  @override
  String get bagAddFavorite => 'Add to favorites';

  @override
  String get bagRemoveFavorite => 'Remove from favorites';

  @override
  String get bagFavorite => 'Favorite';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get information => 'Information';

  @override
  String get bagCannotUse => 'This item cannot be used here.';

  @override
  String get bagPocketEmpty => 'This pocket is empty.';

  @override
  String get bagEmpty => 'Your bag is empty.';

  @override
  String get bagPreviousPockets => 'Previous pockets';

  @override
  String get bagNextPockets => 'Next pockets';

  @override
  String get bagFavorites => 'Favorites';

  @override
  String get phone => 'Phone';

  @override
  String optionsResetBindings({required String device}) {
    return 'Only $device bindings will be reset. Other settings will be kept.';
  }

  @override
  String get optionsResetCategory => 'Reset this category';

  @override
  String get optionsNextCategory => 'Next category';

  @override
  String get optionsPreviousCategory => 'Previous category';

  @override
  String get optionsTouchSettings => 'Touch settings';

  @override
  String get optionsCategoriesTooltip => 'Options categories';

  @override
  String get partyNoCompatibleItem => 'No compatible item in the bag.';

  @override
  String get partyHeldItemsHelp =>
      'Giving takes one item from the bag. Replacing or taking returns the current item to the bag.';

  @override
  String get partyMove => 'Move';

  @override
  String get bagItem => 'Item';

  @override
  String get partyLead => 'Lead';

  @override
  String get pokemonFainted => 'Fainted';

  @override
  String get partySwapPositions => 'The two Pokémon will swap places.';

  @override
  String get partyChooseNewPosition => 'Choose the new position';

  @override
  String get partyEmpty => 'Your party is empty';

  @override
  String get partyActionFailed =>
      'The action could not be completed. Try again.';

  @override
  String get pokedexNotEncountered =>
      'This Pokémon has not been encountered yet.';

  @override
  String get pokedexDescriptionHeading => 'DESCRIPTION';

  @override
  String get pokedexSearchNoResults => 'Try another name, number or filter.';

  @override
  String get pokedexEmptyMessage => 'No entries available.';

  @override
  String get noResults => 'No results';

  @override
  String get pokedexEmpty => 'Empty Pokédex';

  @override
  String get pokedexCaughtFilter => 'Caught';

  @override
  String get pokedexSeenFilter => 'Seen';

  @override
  String get all => 'All';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get pokedexSearchHint => 'Name or number';

  @override
  String get pokedexCaught => 'Caught';

  @override
  String get pokedexSeen => 'Seen';

  @override
  String get pokedexUnknown => 'Unknown';

  @override
  String get profileCurrentLocation => 'Current location';

  @override
  String get profileEarnedBadges => 'Earned badges';

  @override
  String get profilePokemonCaught => 'Pokémon caught';

  @override
  String get profilePokemonSeen => 'Pokémon seen';

  @override
  String get profilePokedexTotal => 'Pokédex total';

  @override
  String get money => 'Money';

  @override
  String profilePortrait({required String name}) {
    return '$name’s portrait';
  }

  @override
  String get profileCardHeading => 'PLAYER CARD';

  @override
  String get mapPositionMissing => 'Position not provided.';

  @override
  String get mapLocationNotDiscovered =>
      'This location has not been discovered yet.';

  @override
  String get mapSelectLocation => 'Select a location.';

  @override
  String get mapLocationUnavailable =>
      'Location unavailable. Choose another location.';

  @override
  String get mapCloseSelection => 'Close selection';

  @override
  String get mapMultipleLocations => 'Several locations here';

  @override
  String get backToMap => 'Back to map';

  @override
  String get mapNoLocations => 'No locations available in this region.';

  @override
  String get mapUndiscoveredLocation => 'Undiscovered';

  @override
  String get mapDiscoveredLocation => 'Discovered';

  @override
  String get mapCurrentLocation => 'You are here';

  @override
  String get loadingReady => 'Ready';

  @override
  String get loadingPlacingPlayer => 'Placing player';

  @override
  String get loadingMountingMap => 'Mounting map';

  @override
  String get loadingAssets => 'Loading assets';

  @override
  String get loadingBuildingScene => 'Building scene';

  @override
  String get loadingPreparingWorld => 'Preparing world';

  @override
  String get loadingReadingSave => 'Reading save';

  @override
  String get loadingOpeningGame => 'Opening game';

  @override
  String get weatherNoCityFound => 'No city found.';

  @override
  String get weatherSearchUnavailable =>
      'Search unavailable. Please try later.';

  @override
  String get search => 'Search';

  @override
  String get weatherSearching => 'Searching…';

  @override
  String get weatherLocationSearchHint => 'City, region or country';

  @override
  String get weatherLocationTitle => 'Weather location';

  @override
  String get weatherDataAdapted => 'Weather data adapted for game rendering.';

  @override
  String get linkUnavailable => 'Link unavailable.';

  @override
  String get weatherRefreshInterval => 'Refresh every 20 minutes';

  @override
  String get weatherOffline => 'Offline · cached or game weather';

  @override
  String get weatherRefreshing => 'Refreshing…';

  @override
  String get weatherDetectLocation => 'Detected by IP when gameplay starts';

  @override
  String get weatherIpDisclosure => 'GeoJS and Open-Meteo receive your IP.';

  @override
  String get weatherApproximateLocation =>
      'Approximate IP location, without GPS.';

  @override
  String get weatherCompatibleGames => 'Real weather for supported games.';

  @override
  String get weatherUseIpLocation => 'Use IP location again';

  @override
  String get weatherChooseCity => 'Choose another city';

  @override
  String get weatherMyLocation => 'Weather at my location';

  @override
  String get contacts => 'Contacts';

  @override
  String get loadingActivatingMap => 'Activating the map';

  @override
  String get cancelFishing => 'Cancel fishing';

  @override
  String get page => 'Page';

  @override
  String pagePosition({
    required String label,
    required int current,
    required int total,
  }) {
    return '$label $current / $total';
  }

  @override
  String previousPageWithPosition({required String position}) {
    return 'Previous page · $position';
  }

  @override
  String nextPageWithPosition({required String position}) {
    return 'Next page · $position';
  }

  @override
  String pokemonNameAndLevel({required String name, required int level}) {
    return '$name · Lv. $level';
  }

  @override
  String pokemonNameAndNickname({
    required String nickname,
    required String name,
  }) {
    return '$nickname · $name';
  }

  @override
  String partyTradePokemon({required String name}) {
    return 'Pokémon: $name';
  }

  @override
  String partyTradePartner({required String name}) {
    return 'Partner: $name';
  }

  @override
  String get pokemonTabStats => 'Stats';

  @override
  String get actions => 'Actions';

  @override
  String shopUnitPrice({required int amount}) {
    return 'Unit price : $amount ₽';
  }

  @override
  String shopMoney({required int amount}) {
    return 'Money : $amount ₽';
  }

  @override
  String shopBalanceAfter({required int amount}) {
    return 'Balance after : $amount ₽';
  }

  @override
  String bagLearnMove({required String move}) {
    return 'Learn $move';
  }

  @override
  String bagLearnReplacingMove({
    required String move,
    required String forgottenMove,
  }) {
    return 'Learn $move — forget $forgottenMove';
  }

  @override
  String get regionalMapUnavailable => 'Regional map unavailable.';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapRecenter => 'Recenter';

  @override
  String get mapLocations => 'Locations';

  @override
  String bagMoney({required String amount}) {
    return 'Money : $amount';
  }

  @override
  String bagMoneyWithCurrency({
    required String amount,
    required String currency,
  }) {
    return 'Money : $amount $currency';
  }

  @override
  String pokedexProgress({
    required String seen,
    required String caught,
    required String total,
  }) {
    return 'Seen $seen · Caught $caught / $total';
  }

  @override
  String get weatherClear => 'Clear sky';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherDrizzle => 'Drizzle';

  @override
  String get weatherRain => 'Rain';

  @override
  String get weatherDownpour => 'Downpour';

  @override
  String get weatherStorm => 'Thunderstorm';

  @override
  String get weatherSnow => 'Snow';

  @override
  String get weatherBlizzard => 'Blizzard';

  @override
  String get weatherHail => 'Hail';

  @override
  String get weatherMist => 'Mist';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherDust => 'Dust';

  @override
  String get weatherSandstorm => 'Sandstorm';

  @override
  String get weatherPetals => 'Petals';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherWindy => 'Windy';

  @override
  String get weatherHeavySnow => 'Heavy snow';

  @override
  String get weatherSleet => 'Sleet';

  @override
  String get weatherTempest => 'Severe thunderstorm';

  @override
  String get weatherLeaves => 'Autumn leaves';

  @override
  String weatherReceived({required String weather}) {
    return 'Received weather : $weather';
  }

  @override
  String weatherCity({required String city}) {
    return 'City : $city';
  }

  @override
  String get journal => 'Journal';

  @override
  String get craftCollect => 'Collect';

  @override
  String get craftConfirmDeposit => 'Confirm deposit';

  @override
  String get craftReviewOrder => 'Review order';

  @override
  String get craftDecreaseQuantity => 'Less';

  @override
  String get craftIncreaseQuantity => 'More';

  @override
  String get puzzleTray => 'Tray';

  @override
  String get puzzleTitle => 'Image puzzle';

  @override
  String get puzzleInstructions =>
      'Select a piece, then its destination. Press R to rotate the piece.';

  @override
  String get puzzleImageUnavailable =>
      'The image could not be displayed. Exit and reopen the puzzle.';

  @override
  String get puzzleRotate => 'Rotate';

  @override
  String get puzzleReset => 'Restart';

  @override
  String get puzzleCheck => 'Check';

  @override
  String get puzzleFixed => 'fixed';

  @override
  String get puzzleSelected => 'selected';

  @override
  String get quit => 'Quit';

  @override
  String get mapFly => 'Fly';

  @override
  String get mapZoom => 'Zoom';

  @override
  String get englishLanguageName => 'English';

  @override
  String get frenchLanguageName => 'Français';

  @override
  String get controllerSouthButton => 'South button';

  @override
  String get controllerEastButton => 'East button';

  @override
  String get controllerWestButton => 'West button';

  @override
  String get controllerNorthButton => 'North button';

  @override
  String get controllerSelectButton => 'Select';

  @override
  String get controllerMenuButton => 'Menu';

  @override
  String get keyboardEnter => 'Enter';

  @override
  String craftPendingOrder({required int quantity, required String item}) {
    return 'Your order is being prepared: $quantity × $item. Come back another day.';
  }

  @override
  String craftReadyOrder({required int quantity, required String item}) {
    return 'Your order is ready: $quantity × $item.';
  }

  @override
  String craftRecipe({
    required String recipe,
    required String exchange,
    required int owned,
  }) {
    return '$recipe · $exchange · Bag: $owned';
  }

  @override
  String craftExchange({
    required int inputQuantity,
    required String input,
    required int outputQuantity,
    required String output,
  }) {
    return '$inputQuantity × $input → $outputQuantity × $output';
  }

  @override
  String craftQuantity({required int quantity, required int maximum}) {
    return 'Quantity: $quantity · Maximum available: $maximum';
  }

  @override
  String puzzleEmptySlot({required int index}) {
    return 'Empty slot $index';
  }

  @override
  String puzzlePiece({required int index}) {
    return 'Piece $index';
  }

  @override
  String puzzleFixedPiece({required int index}) {
    return 'Piece $index, fixed';
  }

  @override
  String dialogueSpeakerPortrait({required String speaker}) {
    return 'Portrait of $speaker';
  }

  @override
  String get startupReady => 'READY';

  @override
  String get startupPreparingJourney => 'PREPARING THE JOURNEY';

  @override
  String get startupPlayerPreferences => 'PLAYER PREFERENCES';

  @override
  String get startupFindingSave => 'FINDING THE SAVE';

  @override
  String get startupWorldAssets => 'MAPS AND WORLD ASSETS';

  @override
  String get startupPresentationProfile => 'PRESENTATION PROFILE';

  @override
  String get startupSplashBranding => 'PREPARING THE SPLASH';

  @override
  String get startupPreparingScene => 'PREPARING THE SCENE';

  @override
  String get startupMenuAndMusic => 'MENU AND MUSIC';

  @override
  String get craftPending =>
      'Your order is being prepared. Come back another day.';

  @override
  String get craftReady => 'Your order is ready.';

  @override
  String get battleNarrationPlayer => 'Player';

  @override
  String get battleNarrationEnemy => 'Opponent';

  @override
  String battleWildAppeared({required String target}) {
    return 'A wild $target appeared!';
  }

  @override
  String battleTrainerChallenges({required String actor}) {
    return 'Trainer $actor challenges you!';
  }

  @override
  String get battleUnknownTrainerChallenges => 'A Trainer challenges you!';

  @override
  String battleTrainerSends({required String actor, required String target}) {
    return 'Trainer $actor sent out $target!';
  }

  @override
  String battleUnknownTrainerSends({required String target}) {
    return 'The Trainer sent out $target!';
  }

  @override
  String battleSendOut({required String target}) {
    return 'Go, $target!';
  }

  @override
  String battleJoined({required String target}) {
    return '$target joined the battle!';
  }

  @override
  String get battleConfusionHurt => 'It hurt itself in its confusion!';

  @override
  String battleMoveUsed({required String actor, required String move}) {
    return '$actor used $move!';
  }

  @override
  String battleMoveDodged({required String target}) {
    return '$target avoided the attack!';
  }

  @override
  String battleMoveImmune({required String target}) {
    return 'It doesn’t affect $target…';
  }

  @override
  String get battleCriticalHit => 'A critical hit!';

  @override
  String get battleSuperEffective => 'It’s super effective!';

  @override
  String get battleNotVeryEffective => 'It’s not very effective…';

  @override
  String battleFainted({required String target}) {
    return '$target fainted!';
  }

  @override
  String battleItemUsed({
    required String actor,
    required String item,
    required String target,
  }) {
    return '$actor used $item on $target!';
  }

  @override
  String battleHpRecovered({required String target, required int amount}) {
    return '$target recovered $amount HP.';
  }

  @override
  String battleStatusCured({required String target}) {
    return '$target recovered from its status condition.';
  }

  @override
  String battlePpRecovered({required String move, required int amount}) {
    return '$move recovered $amount PP.';
  }

  @override
  String battleCaptureThrown({required String target}) {
    return 'A Poké Ball was thrown at $target!';
  }

  @override
  String battleCaptureCaught({required String target}) {
    return '$target was caught!';
  }

  @override
  String battleCaptureEscaped({required String target}) {
    return '$target broke free from the Poké Ball!';
  }

  @override
  String battleParalyzed({required String target}) {
    return '$target was paralyzed! It may be unable to move!';
  }

  @override
  String battleBurned({required String target}) {
    return '$target was burned!';
  }

  @override
  String battlePoisoned({required String target}) {
    return '$target was poisoned!';
  }

  @override
  String battleBadlyPoisoned({required String target}) {
    return '$target was badly poisoned!';
  }

  @override
  String battleFellAsleep({required String target}) {
    return '$target fell asleep!';
  }

  @override
  String battleFrozen({required String target}) {
    return '$target was frozen solid!';
  }

  @override
  String battleAlreadyHasStatus({required String target}) {
    return '$target already has a status condition.';
  }

  @override
  String battleCannotAct({required String target}) {
    return '$target can’t move!';
  }

  @override
  String battleBurnDamage({required String target}) {
    return '$target was hurt by its burn!';
  }

  @override
  String battlePoisonDamage({required String target}) {
    return '$target was hurt by poison!';
  }

  @override
  String battleStatusDamage({required String target}) {
    return '$target took damage!';
  }

  @override
  String battleProtectActivated({required String actor}) {
    return '$actor protected itself!';
  }

  @override
  String get battleProtectBlocked =>
      'The target protected itself from the attack!';

  @override
  String get battleProtectBroken => 'The protection was broken!';

  @override
  String battleRechargeRequired({required String actor}) {
    return '$actor must recharge!';
  }

  @override
  String battleRechargeTurnSpent({required String actor}) {
    return '$actor is catching its breath.';
  }

  @override
  String battleChargeStarted({required String actor}) {
    return '$actor began charging!';
  }

  @override
  String battleChargeReleased({required String actor}) {
    return '$actor unleashed its attack!';
  }

  @override
  String battleConfusionApplied({required String actor}) {
    return '$actor became confused!';
  }

  @override
  String battleConfusionActive({required String actor}) {
    return '$actor is confused!';
  }

  @override
  String battleConfusionEnded({required String actor}) {
    return '$actor snapped out of confusion!';
  }

  @override
  String get battleRainStarted => 'It started to rain.';

  @override
  String get battleSandstormStarted => 'A sandstorm kicked up.';

  @override
  String battleSandstormDamage({required String target}) {
    return '$target was buffeted by the sandstorm!';
  }

  @override
  String get battleWeatherExpired => 'The weather subsided.';

  @override
  String get battleTrickRoomStarted => 'The dimensions twisted.';

  @override
  String get battleFieldCleared => 'The field effect was cleared.';

  @override
  String get battleFieldExpired => 'The field effect wore off.';

  @override
  String get battleStealthRockSet =>
      'Pointed stones float around the opposing team!';

  @override
  String get battleStealthRockAlreadyPresent =>
      'Pointed stones are already in place.';

  @override
  String get battleStealthRockDamage =>
      'Pointed stones hurt the incoming Pokémon!';

  @override
  String get battleSpikesSet =>
      'Spikes were scattered around the opposing team!';

  @override
  String get battleSpikesAlreadyPresent =>
      'Spikes are already at their maximum.';

  @override
  String get battleSpikesDamage => 'Spikes hurt the incoming Pokémon!';

  @override
  String battleSwitched({
    required String actor,
    required String target,
    required String replacement,
  }) {
    return '$actor withdrew $target and sent out $replacement!';
  }

  @override
  String battleReplacementRequired({
    required String actor,
    required String target,
  }) {
    return '$actor must replace $target!';
  }

  @override
  String battleStatRaised({
    required String target,
    required String stat,
    required int amount,
  }) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$target’s $stat rose drastically!',
      two: '$target’s $stat rose sharply!',
      one: '$target’s $stat rose!',
    );
    return '$_temp0';
  }

  @override
  String battleStatLowered({
    required String target,
    required String stat,
    required int amount,
  }) {
    String _temp0 = intl.Intl.pluralLogic(
      amount,
      locale: localeName,
      other: '$target’s $stat fell drastically!',
      two: '$target’s $stat fell sharply!',
      one: '$target’s $stat fell!',
    );
    return '$_temp0';
  }

  @override
  String battleStatCannotRaise({required String target, required String stat}) {
    return '$target’s $stat won’t go any higher!';
  }

  @override
  String battleStatCannotLower({required String target, required String stat}) {
    return '$target’s $stat won’t go any lower!';
  }

  @override
  String battleStatName({required String stat}) {
    String _temp0 = intl.Intl.selectLogic(stat, {
      'attack': 'Attack',
      'defense': 'Defense',
      'specialAttack': 'Special Attack',
      'specialDefense': 'Special Defense',
      'speed': 'Speed',
      'accuracy': 'Accuracy',
      'other': 'Evasion',
    });
    return '$_temp0';
  }

  @override
  String get battleMoveFailed => 'But it failed!';

  @override
  String get battleFleeFailed => 'You couldn’t get away.';

  @override
  String get battleNarrationVictory => 'You won the battle!';

  @override
  String get battleNarrationDefeat =>
      'You have no Pokémon left that can fight!';

  @override
  String get battleNarrationFled => 'You got away safely!';

  @override
  String get postBattleVictoryMessage => 'Victory!';

  @override
  String get postBattleDefeatMessage => 'All your Pokémon fainted.';

  @override
  String get postBattleFledMessage => 'You got away safely!';

  @override
  String postBattleCapturedMessage({required String target}) {
    return '$target was caught.';
  }

  @override
  String postBattleCaptureParty({required String target}) {
    return '$target joined your party.';
  }

  @override
  String postBattleCaptureStorage({required String target}) {
    return '$target was sent to storage.';
  }

  @override
  String get postBattleCaptureUnavailable =>
      'There’s nowhere to send the captured Pokémon.';

  @override
  String postBattleExperienceMessage({
    required String target,
    required int amount,
  }) {
    return '$target gained $amount Exp. Points!';
  }

  @override
  String postBattleLevelUpMessage({
    required String target,
    required int amount,
  }) {
    return '$target grew to Lv. $amount!';
  }

  @override
  String postBattleMoveLearningMessage({
    required String target,
    required String move,
  }) {
    return '$target can learn $move.';
  }

  @override
  String postBattleMoveReplacementMessage({required String move}) {
    return 'Choose a move to replace with $move.';
  }

  @override
  String postBattleMoveLearnedMessage({required String move}) {
    return '$move was learned.';
  }

  @override
  String postBattleMoveReplacedMessage({
    required String previousMove,
    required String move,
  }) {
    return '$previousMove was replaced with $move.';
  }

  @override
  String postBattleMoveDeclinedMessage({required String move}) {
    return '$move wasn’t learned.';
  }

  @override
  String postBattleEvolutionPrompt({
    required String target,
    required String replacement,
  }) {
    return '$target wants to evolve into $replacement.';
  }

  @override
  String postBattleEvolutionAccepted({
    required String target,
    required String replacement,
  }) {
    return '$target evolved into $replacement.';
  }

  @override
  String postBattleEvolutionRefused({required String target}) {
    return '$target didn’t evolve.';
  }

  @override
  String postBattleTrainerDefeated({required String actor}) {
    return 'You defeated $actor!';
  }

  @override
  String postBattleMoneyMessage({required int amount}) {
    return 'You won ₽$amount!';
  }

  @override
  String postBattleItemMessage({required String item, required int amount}) {
    return 'You received $item ×$amount.';
  }

  @override
  String postBattleFlagMessage({required String target}) {
    return '$target was unlocked.';
  }

  @override
  String postBattleBadgeMessage({required String target}) {
    return 'You received the $target Badge.';
  }

  @override
  String postBattleAbilityMessage({required String move}) {
    return 'You can now use $move.';
  }

  @override
  String get postBattleLearn => 'Learn';

  @override
  String get postBattleDeclineMove => 'Don’t learn';

  @override
  String get postBattleEvolve => 'Evolve';

  @override
  String get postBattleDeclineEvolution => 'Decline';

  @override
  String get postBattleChoose => 'What will you do?';

  @override
  String get postBattleCompleted => 'Done.';

  @override
  String get postBattleNoResult => 'No battle result is available.';

  @override
  String get postBattleDecisionError =>
      'The post-battle decision couldn’t be applied.';

  @override
  String get postBattleMissingTransaction =>
      'The battle has no transaction ID.';

  @override
  String get postBattleAlreadyApplied =>
      'This battle result was already applied.';

  @override
  String get postBattleApplyFailed => 'The battle result couldn’t be applied.';

  @override
  String get postBattleMoveNotPending =>
      'There’s no move learning decision to make.';

  @override
  String get postBattleMoveInvalid => 'The move learning decision was invalid.';

  @override
  String get postBattleEvolutionNotPending =>
      'There’s no evolution decision to make.';

  @override
  String get postBattleEvolutionInvalid =>
      'The evolution decision was invalid.';

  @override
  String get postBattleRewardBagCapacity =>
      'Your Bag can’t hold all the rewards. The battle was cancelled. Make room before retrying it.';

  @override
  String get postBattleRewardQuantity =>
      'Your Bag can’t hold that many rewards. The battle was cancelled.';

  @override
  String get postBattleRewardMissingItemCatalog =>
      'The reward catalog is unavailable. The battle was cancelled.';

  @override
  String postBattleRewardUnknownItem({required String item}) {
    return 'Unknown item reward: $item.';
  }

  @override
  String get postBattleRewardInvalid =>
      'The item reward is invalid. The battle was cancelled.';

  @override
  String get postBattleRewardMissingTrainer =>
      'The Trainer’s rewards couldn’t be found.';

  @override
  String get postBattleRewardInvalidBattle =>
      'This type of battle can’t award rewards.';

  @override
  String get postBattleRewardMissingData =>
      'The post-battle progression data is incomplete.';

  @override
  String get runtimeFeedbackBicycleMissing =>
      'You do not have a bicycle you can use.';

  @override
  String get runtimeFeedbackTextVariableInvalid =>
      'This scene variable does not accept text.';

  @override
  String get runtimeFeedbackRequestClosed => 'This request has already ended.';

  @override
  String get runtimeFeedbackRequestChanged =>
      'The request changed before this response arrived.';

  @override
  String get runtimeFeedbackResponseNotText =>
      'This response does not contain text.';

  @override
  String get runtimeFeedbackResponseLengthInvalid =>
      'This response does not meet the text length requirements.';

  @override
  String get runtimeFeedbackTextSaveFailed =>
      'The response could not be saved.';

  @override
  String get runtimeFeedbackFlyDisabled => 'Fly is disabled in this game.';

  @override
  String get runtimeFeedbackFlyUnderwater =>
      'Use Dive to return to the surface before using Fly.';

  @override
  String get runtimeFeedbackFlyIndoors =>
      'You cannot use Fly indoors or in caves.';

  @override
  String get runtimeFeedbackFlyDestinationUnvisited =>
      'Visit this location before flying there.';

  @override
  String get runtimeFeedbackFlyPokemonRequired =>
      'A Pokémon that can battle must know Fly.';

  @override
  String get runtimeFeedbackFlyLocked => 'You have not unlocked Fly yet.';

  @override
  String get runtimeFeedbackFlyMapUnsupported =>
      'Fly is only available on supported 2D maps.';

  @override
  String get runtimeFeedbackFlyArrivalUnavailable =>
      'The arrival point for this location is unavailable.';

  @override
  String get runtimeFeedbackFlyDestinationUnavailable =>
      'You cannot fly to this destination.';

  @override
  String runtimeFeedbackFlyConfirm({required String place}) {
    return 'Fly to $place?';
  }

  @override
  String get runtimeFeedbackFlyRecoveryFailed =>
      'Travel failed and recovery could not be confirmed. Restart the game.';

  @override
  String get runtimeFeedbackFlyCancelled =>
      'Fly was cancelled. Your progress was kept.';

  @override
  String get runtimeFeedbackPartyBusy => 'The party is busy right now.';

  @override
  String get runtimeFeedbackTargetUnavailable =>
      'This target is no longer available.';

  @override
  String get runtimeFeedbackPartyLeadSaved => 'The new lead Pokémon was saved.';

  @override
  String get runtimeFeedbackPartyReorderSaved =>
      'Party reordered and progress saved.';

  @override
  String get runtimeFeedbackPartyCommandInvalid =>
      'This command is unavailable in the party menu.';

  @override
  String get runtimeFeedbackPartyReorderFailed =>
      'The party could not be reordered and saved.';

  @override
  String get runtimeFeedbackBagBusy => 'The bag is busy right now.';

  @override
  String get runtimeFeedbackBagItemDefinitionInvalid =>
      'This item’s definition is missing or invalid.';

  @override
  String get runtimeFeedbackBagStateChanged =>
      'The game state changed. Reopen the bag.';

  @override
  String get runtimeFeedbackBagItemRemoved =>
      'This item is no longer in the bag.';

  @override
  String get runtimeFeedbackBagContextualUse => 'Using the item in the world.';

  @override
  String get runtimeFeedbackBagContextualCancelled =>
      'Use cancelled. You kept the item.';

  @override
  String get runtimeFeedbackBagContextualUnavailable =>
      'This item cannot be used in the current situation. You kept it.';

  @override
  String get runtimeFeedbackBagContextualFailed =>
      'The item could not be used here. You kept it.';

  @override
  String get runtimeFeedbackBagContextualStateChanged =>
      'The game state changed. You kept the item.';

  @override
  String get runtimeFeedbackFishingUnsupported =>
      'Fishing is unsupported in this game mode.';

  @override
  String get runtimeFeedbackFishingUnavailable =>
      'Fishing is unavailable right now.';

  @override
  String get runtimeFeedbackFishingPreparing => 'Getting ready to fish.';

  @override
  String get runtimeFeedbackFishingMapUnsupported =>
      'You cannot fish on this map.';

  @override
  String get runtimeFeedbackFishingRodInvalid =>
      'This item is not a usable fishing rod.';

  @override
  String get runtimeFeedbackFishingRodMissing =>
      'This fishing rod is no longer in the bag.';

  @override
  String get runtimeFeedbackFishingFaceWater => 'Face the water to fish.';

  @override
  String get runtimeFeedbackFishingNoEncounter =>
      'You cannot catch anything here with this rod.';

  @override
  String get runtimeFeedbackFishingDismountSaveFailed =>
      'Getting off the bicycle could not be saved.';

  @override
  String get runtimeFeedbackFishingStartFailed =>
      'Fishing could not be started.';

  @override
  String get runtimeFeedbackBicycleUnsupported =>
      'The bicycle is only available on supported 2D maps.';

  @override
  String get runtimeFeedbackBicycleUnavailable =>
      'The bicycle is unavailable right now.';

  @override
  String get runtimeFeedbackBicycleChanged => 'Movement change saved.';

  @override
  String get runtimeFeedbackBicycleChangeUnavailable =>
      'The bicycle is unavailable here, its animations are incomplete, or saving failed.';

  @override
  String get runtimeFeedbackBicycleSaveFailed =>
      'The movement change could not be saved.';

  @override
  String get runtimeFeedbackEscapeRopeUnsupported =>
      'The Escape Rope is unsupported in this game mode.';

  @override
  String get runtimeFeedbackEscapeRopeUnavailable =>
      'The Escape Rope is unavailable right now.';

  @override
  String get runtimeFeedbackEscapeRopeReturned =>
      'You returned to the entrance. Progress saved.';

  @override
  String get runtimeFeedbackEscapeRopeExitBlocked =>
      'The exit is unavailable or blocked. You kept the Escape Rope.';

  @override
  String get runtimeFeedbackEscapeRopeSaveFailed =>
      'The return could not be completed and saved.';

  @override
  String get runtimeFeedbackRepelUnsupported =>
      'Repel is unavailable in this game mode.';

  @override
  String get runtimeFeedbackRepelAlreadyActive => 'A Repel is already active.';

  @override
  String get runtimeFeedbackRepelApplied => 'Repel is active. Progress saved.';

  @override
  String get runtimeFeedbackRepelSaveFailed =>
      'Repel could not be used and saved.';

  @override
  String get runtimeFeedbackHeldItemNoEffect =>
      'This item has no effect when held.';

  @override
  String get runtimeFeedbackHeldItemUnsupported =>
      'This held item’s effect is unsupported in battle.';

  @override
  String get runtimeFeedbackTargetDataIncomplete =>
      'This target’s data is incomplete.';

  @override
  String get runtimeFeedbackBagItemUsed => 'Item used and progress saved.';

  @override
  String get runtimeFeedbackBagItemSaveFailed =>
      'The item could not be used and saved.';

  @override
  String get runtimeFeedbackHeldItemTargetUnavailable =>
      'This target or item is no longer available.';

  @override
  String get runtimeFeedbackHeldItemMissing =>
      'This item is no longer in the bag.';

  @override
  String get runtimeFeedbackHeldItemNone => 'This Pokémon is holding no item.';

  @override
  String get runtimeFeedbackHeldItemUnchanged =>
      'This Pokémon is already holding this item.';

  @override
  String get runtimeFeedbackHeldItemBagCannotReceive =>
      'The currently held item cannot be returned to the bag.';

  @override
  String get runtimeFeedbackHeldItemBagFull =>
      'There is no room for this item in the bag. Make room before taking it.';

  @override
  String get runtimeFeedbackHeldItemBagCapacityUnknown =>
      'The item catalogue could not verify how much room is left in the bag.';

  @override
  String get runtimeFeedbackHeldItemRemoved =>
      'Held item removed and progress saved.';

  @override
  String get runtimeFeedbackHeldItemChanged =>
      'Held item changed and progress saved.';

  @override
  String get runtimeFeedbackHeldItemSaveFailed =>
      'The held item could not be changed and saved.';

  @override
  String get runtimeFeedbackMoveMachineIncompatible =>
      'This Pokémon cannot learn a move from this machine.';

  @override
  String get runtimeFeedbackMoveMachineReplaced =>
      'Move replaced and progress saved.';

  @override
  String get runtimeFeedbackMoveMachineLearned =>
      'Move learned and progress saved.';

  @override
  String get runtimeFeedbackMoveMachineForgetPrompt =>
      'Choose a move to forget.';

  @override
  String get runtimeFeedbackMoveMachineCancelled => 'Learning cancelled.';

  @override
  String get runtimeFeedbackMoveMachineCannotUse =>
      'This machine cannot be used here.';

  @override
  String get runtimeFeedbackMoveMachineSaveFailed =>
      'The move could not be learned and saved.';

  @override
  String get runtimeFeedbackEvolutionHeldItemInvalid =>
      'The held item does not allow this evolution.';

  @override
  String get runtimeFeedbackEvolutionUnavailable =>
      'This item does not trigger an evolution here.';

  @override
  String get runtimeFeedbackEvolutionAmbiguous =>
      'This combination can trigger multiple evolutions.';

  @override
  String get runtimeFeedbackEvolutionSaved =>
      'Evolution complete and progress saved.';

  @override
  String get runtimeFeedbackEvolutionSaveFailed =>
      'The evolution could not be applied and saved.';

  @override
  String get runtimeFeedbackHealCapsIncomplete =>
      'The party’s recovery data is incomplete.';

  @override
  String get runtimeFeedbackHealApplying => 'Healing…';

  @override
  String get runtimeFeedbackHealDisplayUnavailable =>
      'The healing display is unavailable on this map.';

  @override
  String get runtimeFeedbackServiceUnsupported =>
      'This service is unsupported in this game.';

  @override
  String get runtimeFeedbackServiceUnavailable =>
      'This service is unavailable right now.';

  @override
  String get runtimeFeedbackServiceClosed => 'The player service is closed.';

  @override
  String get runtimeFeedbackServiceNotOpen => 'No contextual service is open.';

  @override
  String get runtimeFeedbackServiceChanged =>
      'The service changed before this action arrived.';

  @override
  String get runtimeFeedbackServiceWrongRequest =>
      'This response belongs to a different request.';

  @override
  String get runtimeFeedbackServiceActionInvalid =>
      'This service does not accept this action.';

  @override
  String get runtimeFeedbackPcBoxUnavailable =>
      'This Box is no longer available.';

  @override
  String get runtimeFeedbackPokemonUnavailable =>
      'This Pokémon is no longer available.';

  @override
  String get runtimeFeedbackTradeUnavailable =>
      'This trade is no longer available.';

  @override
  String get runtimeFeedbackPcCommandInvalid =>
      'This command is unavailable on the PC.';

  @override
  String get runtimeFeedbackPcSaving => 'Saving PC changes…';

  @override
  String get runtimeFeedbackPcDeposited => 'Pokémon deposited in the Box.';

  @override
  String get runtimeFeedbackPcWithdrawn => 'Pokémon added to the party.';

  @override
  String get runtimeFeedbackPcSwapped => 'Pokémon swapped.';

  @override
  String get runtimeFeedbackPcMoved => 'Pokémon moved to another Box.';

  @override
  String get runtimeFeedbackPcSaveFailed =>
      'The PC changes could not be saved.';

  @override
  String get runtimeFeedbackPcTitle => 'Pokémon PC';

  @override
  String get runtimeFeedbackPcHelp => 'Organize your party and Boxes.';

  @override
  String get runtimeFeedbackPcNoDeposit => 'No Pokémon can be deposited.';

  @override
  String get runtimeFeedbackPcNoWithdraw => 'No Pokémon can be withdrawn.';

  @override
  String get runtimeFeedbackPcNoSwap => 'No valid swap is available.';

  @override
  String get runtimeFeedbackPcNoMove =>
      'There are no Pokémon to move from this Box.';

  @override
  String get runtimeFeedbackPcNoDestination => 'No other Box is available.';

  @override
  String get runtimeFeedbackHealInterrupted =>
      'Healing was interrupted before it could be saved.';

  @override
  String get runtimeFeedbackHealAlreadyHealthy =>
      'Your party is already fully healed.';

  @override
  String get runtimeFeedbackHealPartyHealed => 'Your party is fully healed.';

  @override
  String get runtimeFeedbackHealSaveFailed => 'Healing could not be saved.';

  @override
  String get runtimeFeedbackHealCommandInvalid =>
      'This command is unavailable at the healing service.';

  @override
  String get runtimeFeedbackHealTitle => 'Pokémon Center';

  @override
  String get runtimeFeedbackHealCompleted => 'Healing is complete.';

  @override
  String get runtimeFeedbackHealHelp =>
      'Restore HP and PP, and clear status conditions.';

  @override
  String get runtimeFeedbackShopItemUnavailable =>
      'This item is no longer available.';

  @override
  String get runtimeFeedbackShopCommandInvalid =>
      'This command is unavailable at the shop.';

  @override
  String get runtimeFeedbackShopChooseItem => 'Select an item.';

  @override
  String runtimeFeedbackShopPurchaseBonus({
    required int quantity,
    required String item,
  }) {
    final intl.NumberFormat quantityNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String quantityString = quantityNumberFormat.format(quantity);

    return 'Purchase complete. Bonus: $quantityString × $item.';
  }

  @override
  String get runtimeFeedbackShopPurchaseComplete => 'Purchase complete.';

  @override
  String get runtimeFeedbackShopSaleComplete => 'Sale complete.';

  @override
  String get runtimeFeedbackShopClosed => 'This shop is closed.';

  @override
  String get runtimeFeedbackShopInsufficientQuantity =>
      'You do not own enough of this item.';

  @override
  String get runtimeFeedbackShopMinimumQuantity => 'The minimum quantity is 1.';

  @override
  String get runtimeFeedbackShopMaximumQuantity =>
      'The maximum quantity has been reached.';

  @override
  String get runtimeFeedbackShopSaleUnavailable => 'This sale is unavailable.';

  @override
  String get runtimeFeedbackShopPurchaseUnavailable =>
      'This purchase is unavailable.';

  @override
  String get runtimeFeedbackShopPurchaseInvalid => 'Invalid purchase.';

  @override
  String get runtimeFeedbackShopItemUnknown => 'Unknown item.';

  @override
  String get runtimeFeedbackShopFundsInsufficient =>
      'You do not have enough money.';

  @override
  String get runtimeFeedbackShopStockInsufficient =>
      'There is not enough in stock.';

  @override
  String get runtimeFeedbackShopOwnedLimit =>
      'You already own the maximum quantity.';

  @override
  String get runtimeFeedbackShopBagFull =>
      'There is no room for this purchase in the bag. Make room and try again.';

  @override
  String get runtimeFeedbackShopStateChanged =>
      'The shop changed. Its stock was refreshed.';

  @override
  String get runtimeFeedbackShopSaleInvalid => 'Invalid sale.';

  @override
  String get runtimeFeedbackShopItemUnsellable => 'This item cannot be sold.';

  @override
  String get runtimeFeedbackShopItemImportant => 'Key items cannot be sold.';

  @override
  String get runtimeFeedbackShopItemNotAccepted =>
      'This shop does not buy this item.';

  @override
  String get runtimeFeedbackPcOperationInvalid => 'Invalid PC operation.';

  @override
  String get runtimeFeedbackPcPartySlotInvalid => 'Invalid party slot.';

  @override
  String get runtimeFeedbackPcBoxUnknown => 'Unknown Box.';

  @override
  String get runtimeFeedbackPcBoxSlotInvalid => 'Invalid Box slot.';

  @override
  String get runtimeFeedbackPcPartyFull => 'The party is full.';

  @override
  String get runtimeFeedbackPcBoxFull => 'This Box is full.';

  @override
  String get runtimeFeedbackPcFull => 'The PC is full.';

  @override
  String get runtimeFeedbackPcLastUsablePokemon =>
      'You cannot deposit your last Pokémon that can battle.';

  @override
  String get runtimeFeedbackBagItemMissing => 'You no longer have this item.';

  @override
  String get runtimeFeedbackBagItemWrongTarget =>
      'This item cannot be used on this target.';

  @override
  String get runtimeFeedbackBagItemNoEffect =>
      'This item would have no effect.';

  @override
  String get runtimeFeedbackBagItemUnsupported =>
      'This item’s effect is unsupported.';

  @override
  String get runtimeFeedbackBagKeyItemProtected =>
      'This key item cannot be consumed.';

  @override
  String get runtimeFeedbackTradeCatalogRequired =>
      'The party and its Pokémon catalogue are required for this trade.';

  @override
  String get runtimeFeedbackTradePokemonMismatch =>
      'This Pokémon does not match the trade request.';

  @override
  String get runtimeFeedbackTradeSaveFailed => 'The trade could not be saved.';

  @override
  String runtimeFeedbackTradeEvolution({
    required String name,
    required String species,
  }) {
    return '$name evolved into $species.';
  }

  @override
  String get runtimeFeedbackCraftSaveRequired =>
      'This workshop requires a save slot.';

  @override
  String get runtimeFeedbackCraftInventoryChanged =>
      'The bag changed. Close and reopen the workshop.';

  @override
  String get runtimeFeedbackCraftConfirmIngredients =>
      'Hand over the ingredients?';

  @override
  String get runtimeFeedbackCraftCollectBagFull =>
      'The bag is full. Your order is still available.';

  @override
  String get runtimeFeedbackCraftKeyItemProtected =>
      'This key item cannot be used as an ingredient.';

  @override
  String get runtimeFeedbackCraftUnavailable => 'This order is unavailable.';

  @override
  String get runtimeFeedbackCraftCollected => 'Order collected.';

  @override
  String get runtimeFeedbackCraftOrderSaved =>
      'Order placed. Come back another day.';

  @override
  String get runtimeFeedbackCraftSaveFailed =>
      'Saving failed. Your bag and order were kept.';

  @override
  String get runtimeFeedbackCraftInventoryBusy =>
      'The bag is being updated. Finish this interaction and try again.';

  @override
  String get runtimeFeedbackCraftSceneRequired =>
      'This workshop requires an active scene.';

  @override
  String get runtimeFeedbackPuzzleSaveRequired =>
      'This puzzle requires a save slot.';

  @override
  String get runtimeFeedbackPuzzleMediaUnavailable =>
      'The game’s media library is unavailable.';

  @override
  String get runtimeFeedbackPuzzleImageTooSmall =>
      'The image must have at least one pixel per puzzle tile.';

  @override
  String get runtimeFeedbackPuzzleChangedOnOpening =>
      'The puzzle changed as it opened. Open it again.';

  @override
  String get runtimeFeedbackPuzzleDefinitionChanged =>
      'The puzzle definition changed. Restore its original configuration.';

  @override
  String get runtimeFeedbackPuzzleChanged =>
      'The puzzle changed. Close this interaction and open it again.';

  @override
  String get runtimeFeedbackPuzzleIncomplete =>
      'The image is incomplete. Check each piece’s position and rotation.';

  @override
  String get runtimeFeedbackPuzzleDestinationOccupied =>
      'Move this piece to a free space or back to the tray.';

  @override
  String get runtimeFeedbackPuzzlePieceFixed => 'This piece is fixed in place.';

  @override
  String get runtimeFeedbackPuzzleActionUnavailable =>
      'This action is unavailable for this puzzle.';

  @override
  String get runtimeFeedbackPuzzleSaveFailed =>
      'Saving failed. Your last saved layout was kept. Try again or quit.';

  @override
  String get runtimeFeedbackActionInProgress =>
      'An action is already in progress.';

  @override
  String get runtimeFeedbackSaveInProgress => 'A save is already in progress.';

  @override
  String get runtimeFeedbackFavoritesBagChanged =>
      'The bag changed before this action arrived.';

  @override
  String get runtimeFeedbackFavoritesUnavailable =>
      'This item cannot be added to favourites.';

  @override
  String get runtimeFeedbackFavoritesSaveFailed =>
      'Favourites could not be saved. Try again.';

  @override
  String get runtimeFeedbackPlayerActionStale =>
      'This screen changed before the action arrived.';

  @override
  String get runtimeFeedbackRegionalMapCloseFirst =>
      'Close the regional map before using the menu.';

  @override
  String get runtimeFeedbackPlayerActionUnavailable =>
      'This player action is unavailable.';

  @override
  String get runtimeFeedbackNewGameSlotRequired =>
      'A profile and slot are required to start a new game.';

  @override
  String get runtimeFeedbackNoCompatibleSave =>
      'No compatible save is available to continue.';

  @override
  String get runtimeFeedbackLoadSlotRequired =>
      'A profile and slot are required to load a save.';

  @override
  String get runtimeFeedbackSelectedSaveUnavailable =>
      'The selected save is unavailable or incompatible.';

  @override
  String get runtimeFeedbackFinalSaveFailed =>
      'The final save could not be written.';

  @override
  String get runtimeFeedbackPartyMembersRequired =>
      'Select two available party members.';

  @override
  String get runtimeFeedbackPlayerCommandUnavailable =>
      'This command is unavailable on this screen.';

  @override
  String get runtimeFeedbackPlayerPreferencesRequired =>
      'Valid player preferences are required.';

  @override
  String get runtimeFeedbackSaveWriteFailed => 'The save could not be written.';

  @override
  String get runtimeFeedbackCreditsUnavailable =>
      'No end credits are available.';

  @override
  String get runtimeFeedbackSurfaceActionUnavailable =>
      'This action is not available on the current surface.';

  @override
  String get runtimeFeedbackPlayerResponseStale =>
      'This screen changed before the response arrived.';

  @override
  String get runtimeFeedbackReturnToHostFailed =>
      'The game could not return to the library.';

  @override
  String get runtimeFeedbackPlayerDataRefreshFailed =>
      'Player data could not be refreshed.';

  @override
  String get runtimeFeedbackSessionCloseFailed =>
      'The game session could not close cleanly.';

  @override
  String get runtimeFeedbackExplorationMapChanged =>
      'The map changed while loading. Restart exploration.';

  @override
  String get runtimeFeedbackNewGamePreparationChanged =>
      'The game content changed during setup. Start the new game again.';

  @override
  String get runtimeFeedbackNewGameSetupInvalid =>
      'The starting configuration is incomplete or inconsistent. The new game could not be started.';

  @override
  String get runtimeFeedbackNewGameContentChanged =>
      'The game content changed while loading. Start the new game again.';

  @override
  String get runtimeFeedbackNewGameResourceLimit =>
      'This map’s graphics exceed the Player’s resource budget. Report this code to the game creator.';

  @override
  String get runtimeFeedbackNewGameSaveReadFailed =>
      'Could not read saves. Check that the app can access its storage.';

  @override
  String get runtimeFeedbackNewGamePreloadFailed =>
      'The starting map’s data or assets could not be loaded. Reinstall the game if the issue persists.';

  @override
  String get runtimeFeedbackNewGameSceneFailed =>
      'The opening scene could not run. Report the code below to the game creator.';

  @override
  String get runtimeFeedbackNewGameSetupFailed =>
      'The starting configuration could not be applied. Report the code below to the game creator.';

  @override
  String get runtimeFeedbackSaveOpenFailed =>
      'The selected save could not be opened safely.';

  @override
  String get runtimeFeedbackSessionLaunchFailed =>
      'The game session could not launch.';

  @override
  String get runtimeFeedbackPlayerDataLoadFailed =>
      'Player data could not be loaded.';

  @override
  String get runtimeFeedbackSessionFailed => 'The player session failed.';

  @override
  String get runtimeFeedbackExplorationSaveUnavailable =>
      '3D exploration mode does not support saves yet.';

  @override
  String get runtimeFeedbackNoCompatibleGameSave =>
      'No compatible save is available for this game.';

  @override
  String get runtimeFeedbackPlayerMapUnavailable =>
      'This game does not provide a player map.';

  @override
  String get runtimeFeedbackUnusableSaveNotSelected =>
      'No save has been selected for recovery.';

  @override
  String get runtimeFeedbackServiceNotActive =>
      'No contextual service is active.';

  @override
  String get runtimeFeedbackBagRequiresPause =>
      'The bag is only available from the pause menu.';

  @override
  String get runtimeFeedbackBagItemCheckpointFailed =>
      'The item was used, but saving failed.';

  @override
  String get runtimeFeedbackSessionEventStreamFailed =>
      'The game’s event channel failed.';

  @override
  String get runtimeFeedbackSessionPrepareTimedOut =>
      'The game session took too long to prepare.';

  @override
  String get runtimeFeedbackSessionPrepareFailed =>
      'The game session could not be prepared.';

  @override
  String get runtimeFeedbackSessionStartTimedOut =>
      'The game session took too long to start.';

  @override
  String get runtimeFeedbackSessionStartFailed =>
      'The game session could not start.';

  @override
  String get runtimeFeedbackSessionSignalInvalid =>
      'The game sent an invalid session signal.';

  @override
  String get runtimeFeedbackSessionEndingMismatch =>
      'The ending event does not match this game session.';

  @override
  String get runtimeFeedbackSessionEndingInvalid =>
      'The ending event arrived before the game was ready.';

  @override
  String get runtimeFeedbackPreviousSessionCloseFailed =>
      'The previous game session did not close cleanly.';

  @override
  String get runtimeFeedbackStartupGamePreparationFailed =>
      'The game could not be prepared.';

  @override
  String get runtimeFeedbackStartupPreparationStartFailed =>
      'Game preparation could not start.';

  @override
  String get runtimeFeedbackStartupIdentityPreparationFailed =>
      'The game’s identity could not be prepared.';

  @override
  String get runtimeFeedbackStartupMapPreparationFailed =>
      'The first map could not be prepared.';

  @override
  String get runtimeFeedbackStartupPresentationLoadFailed =>
      'The game’s presentation could not be loaded.';

  @override
  String get runtimeFeedbackStartupSaveDiscoveryFailed =>
      'Saved games could not be checked safely.';

  @override
  String get runtimeFeedbackStartupPreferencesLoadFailed =>
      'Player preferences could not be loaded.';

  @override
  String get runtimeFeedbackStartupInstalledGamePreparationFailed =>
      'The installed game could not be prepared.';

  @override
  String get runtimeFeedbackOverworldBagFull => 'The bag is full…';

  @override
  String runtimeFeedbackOverworldItemReceived({
    required int quantity,
    required String item,
  }) {
    final intl.NumberFormat quantityNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String quantityString = quantityNumberFormat.format(quantity);

    return 'Received $quantityString × $item!';
  }

  @override
  String get runtimeFeedbackGiftReceived => 'You received a Pokémon!';

  @override
  String get runtimeFeedbackGiftNicknamePrompt => 'Choose a nickname.';

  @override
  String get runtimeFeedbackGiftNicknameAction => 'Give a nickname';

  @override
  String battleChooseAction({required String actor}) {
    return 'What will $actor do?';
  }

  @override
  String battleChooseReplacementAfterFaint({required String actor}) {
    return '$actor fainted. Choose a replacement.';
  }

  @override
  String get battleContinuePrompt => 'Press to continue.';

  @override
  String get battleFinished => 'The battle is over.';

  @override
  String get battleResolvingTurn => 'Resolving the turn…';

  @override
  String get battleNoReplacement => 'No replacement available.';

  @override
  String get battleNoLegalChoice => 'No action is available.';

  @override
  String battleChooseAttackTarget({required String actor}) {
    return 'Choose a target for $actor.';
  }

  @override
  String get battleChoosePokemon => 'Choose a Pokémon.';

  @override
  String get battleChooseReplacement => 'Choose a replacement.';

  @override
  String get battleNoSwitch => 'No Pokémon can switch in.';

  @override
  String get battleActiveOrFainted =>
      'Active and fainted Pokémon are unavailable.';

  @override
  String get battleChooseItem => 'Choose an item.';

  @override
  String get battleNoUsableItem => 'No item can be used this turn.';

  @override
  String get battleItemsDisabled => 'Unavailable items are dimmed.';

  @override
  String battleChooseItemTarget({required String item}) {
    return 'Choose a target for $item.';
  }

  @override
  String battleChooseItemMove({required String item}) {
    return 'Choose a move for $item.';
  }

  @override
  String get battleNoItemTarget => 'There is no valid target for this item.';

  @override
  String get battleFaintedOrFullHp =>
      'Fainted Pokémon and Pokémon at full HP are unavailable.';

  @override
  String get battleFullPpDisabled => 'Moves with full PP are dimmed.';

  @override
  String get battleWildTitle => 'Wild battle';

  @override
  String get battleTrainerTitle => 'Trainer battle';

  @override
  String get runtimeFeedbackFishingInterrupted => 'Fishing was interrupted.';

  @override
  String get runtimeFeedbackFishingCasting => 'Casting the line…';

  @override
  String get runtimeFeedbackFishingWaiting =>
      'The line is in the water… Press Back to cancel.';

  @override
  String get runtimeFeedbackFishingBite => 'You got a bite!';

  @override
  String get runtimeFeedbackFishingNoBite => 'Nothing bit…';

  @override
  String get runtimeFeedbackFishingEncounterUnavailable =>
      'This fishing encounter is no longer available.';

  @override
  String get runtimeFeedbackFishingCancelled => 'Fishing cancelled.';

  @override
  String get runtimeFeedbackFieldActionChanged =>
      'This action is no longer available.';

  @override
  String get runtimeFeedbackFieldCrossingUnavailable =>
      'This crossing is no longer available.';

  @override
  String get runtimeFeedbackFieldFlashUsed =>
      'Your Pokémon used Flash! The area is lit.';

  @override
  String get runtimeFeedbackFieldCutUsed => 'Your Pokémon used Cut!';

  @override
  String get runtimeFeedbackFieldStrengthActive =>
      'Strength is active on this map. Walk toward a boulder to push it.';

  @override
  String get runtimeFeedbackFieldRockSmashUsed =>
      'Your Pokémon used Rock Smash!';

  @override
  String get runtimeFeedbackFieldDivePassageUnavailable =>
      'This Dive passage is no longer available.';

  @override
  String get runtimeFeedbackWaterRequiresSurf =>
      'A Pokémon that knows Surf is needed to travel on water.';

  @override
  String get runtimeFeedbackUnderwaterRequiresDive =>
      'Use Dive to reach this underwater terrain.';

  @override
  String get runtimeFeedbackDiveRequiresUnderwater =>
      'Dive is available on underwater terrain.';

  @override
  String get runtimeFeedbackIncompatibleMovementTerrain =>
      'This terrain has incompatible movement modes.';

  @override
  String get runtimeFeedbackSurfMissingPokemon =>
      'It looks like you could surf on this water.';

  @override
  String get runtimeFeedbackSurfLocked =>
      'A Pokémon in your party knows Surf. You have yet to unlock it outside battle.';

  @override
  String get runtimeFeedbackSurfConfirm => 'Would you like to use Surf?';

  @override
  String get runtimeFeedbackNarrativePending =>
      'The story outcome is still pending.';

  @override
  String get runtimeFeedbackNarrativeUnavailable =>
      'The event could not start.';

  @override
  String get runtimeFeedbackNarrativeResultUnavailable =>
      'The story outcome could not be applied.';

  @override
  String get runtimeFeedbackCannotEndGame => 'The game could not finish.';

  @override
  String get runtimeFeedbackGiftFailed =>
      'The Pokémon gift could not be received.';

  @override
  String get runtimeFeedbackTransitionFailed =>
      'The transition could not complete.';

  @override
  String get runtimeFeedbackTransitionPassageMissing =>
      'The transition could not complete. The passage is missing.';

  @override
  String get runtimeFeedbackInvalidMapConnection => 'Connection invalid';

  @override
  String get runtimeFeedbackMapConnectionBlocked => 'Connection blocked';

  @override
  String get runtimeFeedbackSceneUnavailable => 'Scene V1 impossible.';

  @override
  String get runtimeFeedbackSceneCannotContinue => 'The scene cannot continue.';

  @override
  String get runtimeFeedbackDialogueMissing =>
      'The dialogue could not be found.';

  @override
  String get runtimeFeedbackMapPassageUnavailable =>
      'This passage is unavailable right now.';

  @override
  String get runtimeFeedbackTeleportFailed => 'Teleportation failed.';

  @override
  String get runtimeFeedbackNeighboringMapTransferFailed =>
      'Travel to the neighboring map failed.';

  @override
  String get runtimeFeedbackContactUnavailable =>
      'This contact is unavailable.';

  @override
  String get runtimeFeedbackPuzzleSceneRequired =>
      'This puzzle requires an active scene.';

  @override
  String battleMoveDamageSummary({
    required String actor,
    required String move,
    required int amount,
  }) {
    return '$actor used $move and dealt $amount damage.';
  }

  @override
  String get runtimeFeedbackFieldMoveCut => 'Cut';

  @override
  String get runtimeFeedbackFieldMoveStrength => 'Strength';

  @override
  String get runtimeFeedbackFieldMoveRockSmash => 'Rock Smash';

  @override
  String get runtimeFeedbackFieldMoveWaterfall => 'Waterfall';

  @override
  String get runtimeFeedbackFieldMoveWhirlpool => 'Whirlpool';

  @override
  String get runtimeFeedbackFieldObstacleCutConfirm =>
      'This tree can be cut down. Would you like to use Cut?';

  @override
  String get runtimeFeedbackFieldObstacleStrengthConfirm =>
      'This boulder can be pushed. Would you like to use Strength?';

  @override
  String get runtimeFeedbackFieldObstacleRockSmashConfirm =>
      'This rock can be smashed. Would you like to use Rock Smash?';

  @override
  String get runtimeFeedbackFieldObstacleCutMissing =>
      'This tree blocks the way. A Pokémon that can use Cut is needed.';

  @override
  String get runtimeFeedbackFieldObstacleStrengthMissing =>
      'This boulder blocks the way. A Pokémon that can use Strength is needed.';

  @override
  String get runtimeFeedbackFieldObstacleRockSmashMissing =>
      'This rock blocks the way. A Pokémon that can use Rock Smash is needed.';

  @override
  String runtimeFeedbackFieldObstacleMoveLocked({required String move}) {
    return 'A Pokémon in your party knows $move. You have yet to unlock it outside battle.';
  }

  @override
  String get runtimeFeedbackFieldObstacleStrengthReady =>
      'Strength is active. Walk toward this boulder to push it.';

  @override
  String runtimeFeedbackFieldTraversalConfirm({required String move}) {
    return 'Would you like to use $move to cross here?';
  }

  @override
  String runtimeFeedbackFieldTraversalMoveMissing({required String move}) {
    return 'A Pokémon that can use $move is needed.';
  }

  @override
  String runtimeFeedbackFieldTraversalMoveLocked({required String move}) {
    return 'You have yet to unlock $move outside battle.';
  }

  @override
  String get runtimeFeedbackFieldTraversalSurfRequired =>
      'Use Surf before crossing here.';

  @override
  String get runtimeFeedbackFieldTraversalWrongDirection =>
      'Face the direction of the passage to cross it.';

  @override
  String get runtimeFeedbackFieldTraversalObstructed =>
      'The passage or its exit is blocked.';

  @override
  String get runtimeFeedbackFieldTraversalWaterRequired =>
      'This passage must be on water.';

  @override
  String get runtimeFeedbackFieldDiveConfirmDown =>
      'Would you like to use Dive to go underwater?';

  @override
  String get runtimeFeedbackFieldDiveConfirmUp =>
      'Would you like to use Dive to return to the surface?';

  @override
  String get runtimeFeedbackFieldDiveDisabled =>
      'Dive is disabled in this game.';

  @override
  String get runtimeFeedbackFieldDiveMoveMissing =>
      'A Pokémon that can use Dive is needed.';

  @override
  String get runtimeFeedbackFieldDiveMoveLocked =>
      'You have yet to unlock Dive outside battle.';

  @override
  String get runtimeFeedbackFieldDiveSurfRequired =>
      'Use Surf to dive from the surface.';

  @override
  String get runtimeFeedbackFieldDiveObstructed =>
      'The Dive destination or return point is blocked.';

  @override
  String get runtimeFeedbackFieldDiveDestinationUnavailable =>
      'This Dive spot is not connected to an available destination.';

  @override
  String get runtimeFeedbackFieldFlashConfirm =>
      'It’s dark here. Would you like to use Flash to light the area?';

  @override
  String get runtimeFeedbackFieldFlashMoveMissing =>
      'It’s dark here. A Pokémon that can use Flash is needed.';

  @override
  String get runtimeFeedbackFieldFlashMoveLocked =>
      'A Pokémon knows Flash. You have yet to unlock it outside battle.';

  @override
  String get runtimeFeedbackHeadbuttMoveMissing =>
      'A Pokémon that can use Headbutt is needed.';

  @override
  String get runtimeFeedbackHeadbuttTreeConsumed =>
      'No more Pokémon are hiding in this tree right now.';

  @override
  String get runtimeFeedbackHeadbuttWrongPosition =>
      'Stand on foot in front of this tree to use Headbutt.';

  @override
  String get runtimeFeedbackHeadbuttMapUnsupported =>
      'Object encounters are available on supported 2D maps.';

  @override
  String get runtimeFeedbackHeadbuttUnavailable =>
      'No encounter is available at this tree right now.';

  @override
  String get runtimeFeedbackHeadbuttConfirm =>
      'Would you like to use Headbutt on this tree?';

  @override
  String get runtimeFeedbackInteractiveEncounterEmpty => 'No Pokémon appeared…';

  @override
  String get runtimeFeedbackInteractiveEncounterUnavailable =>
      'This encounter is no longer available.';

  @override
  String get runtimeFeedbackRepelExpired => 'The Repel wore off.';

  @override
  String get runtimeFeedbackRepelRenew =>
      'Would you like to use another Repel of the same kind?';

  @override
  String get runtimeFeedbackRepelRenewed => 'Repel is active again.';

  @override
  String get runtimeFeedbackRepelStockUnavailable =>
      'This Repel is no longer available.';

  @override
  String get runtimeFeedbackRepelProgressSaveFailed =>
      'Progress could not be saved.';

  @override
  String get runtimeFeedbackSpatialNeighborUnavailable =>
      'A neighboring map could not be displayed.';

  @override
  String get runtimeFeedbackSpatialInteractionUnavailable =>
      'This passage or dialogue could not be opened.';

  @override
  String get runtimeFeedbackMovingPlatformUnavailable =>
      'The platform could not be moved.';

  @override
  String get runtimeFeedbackEntranceAnimationMissing =>
      'This entrance has no animation.';

  @override
  String get runtimeFeedbackEntranceAnimationUnavailable =>
      'This entrance’s animation is unavailable.';

  @override
  String get runtimeFeedbackElementAnimationUpdateFailed =>
      'The animation could not be updated.';

  @override
  String get runtimeFeedbackSpatialSceneTextInputUnsupported =>
      'Scene text input is unavailable in 3D.';

  @override
  String get runtimeFeedbackSpatialSceneRegionalMapUnsupported =>
      'The regional map is unavailable during 3D scenes.';

  @override
  String get runtimeFeedbackSceneRewardCalendarUnavailable =>
      'The calendar for this reward is unavailable. Reopen the game and try again.';
}
