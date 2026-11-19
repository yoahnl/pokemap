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
}
