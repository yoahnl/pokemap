import 'package:map_core/map_core.dart';

import 'runtime_intro_sequence_controller.dart';
import 'runtime_presentation_media_selection.dart';
import 'runtime_player_models.dart';
import 'runtime_project_typography_loader.dart';

/// The startup shell is deliberately separate from [RuntimePlayerPhase].
///
/// Session phases remain owned by `RuntimePlayerCoordinator`; this enum only
/// covers the work that happens before, and while entering, that session.
enum RuntimeStartupPhase {
  preparing,
  splash,
  intro,
  titlePrompt,
  titleMenu,
  launchingSession,
  recoverableError,
  completed,
  lifecyclePaused,
}

enum RuntimeStartupAction {
  skipSplash,
  skipIntro,
  continueFromPoster,
  replayIntro,
  pressStart,
  retryPreparation,
}

enum RuntimeStartupCommandStatus { accepted, stale, unavailable, cancelled }

final class RuntimeStartupCommand {
  const RuntimeStartupCommand({
    required this.action,
    required this.snapshotRevision,
  }) : assert(snapshotRevision >= 0);

  final RuntimeStartupAction action;
  final int snapshotRevision;
}

final class RuntimeStartupCommandResult {
  const RuntimeStartupCommandResult({required this.status, this.safeMessage});

  final RuntimeStartupCommandStatus status;
  final String? safeMessage;
}

/// Stable identifiers used by player UI localization, never timer labels.
enum RuntimeStartupPreparationStage {
  manifestAndIdentity,
  playerPreferences,
  saveDiscovery,
  initialMap,
  presentationProfile,
  splashBranding,
  introAndPoster,
  titleMenuAndMusic,
}

final class RuntimeStartupDiagnostic {
  const RuntimeStartupDiagnostic({
    required this.code,
    required this.safeMessage,
  })  : assert(code != ''),
        assert(safeMessage != '');

  final String code;
  final String safeMessage;
}

/// A blocking startup failure contains only player-safe information.
final class RuntimeStartupFailure {
  const RuntimeStartupFailure({
    required this.code,
    required this.safeMessage,
  })  : assert(code != ''),
        assert(safeMessage != '');

  final String code;
  final String safeMessage;
}

final class RuntimeHostSplashBranding {
  const RuntimeHostSplashBranding({
    required this.displayName,
    required this.signature,
    this.logoAssetId,
    this.primaryColorHex = '#F2D9B2',
    this.secondaryColorHex = '#9E79D7',
    this.backgroundColorHex = '#02040A',
    this.minimumDisplayDuration = const Duration(milliseconds: 7200),
    this.exitTransitionDuration = const Duration(milliseconds: 1296),
    this.finalCurtainDuration = const Duration(milliseconds: 280),
  })  : assert(displayName != ''),
        assert(signature != '');

  final String displayName;
  final String signature;
  final String? logoAssetId;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String backgroundColorHex;
  final Duration minimumDisplayDuration;
  final Duration exitTransitionDuration;
  final Duration finalCurtainDuration;
}

/// A resolved install/project asset. The project-facing identifier remains
/// available for diagnostics while the URI is supplied by a host adapter.
final class RuntimeResolvedAsset {
  const RuntimeResolvedAsset({
    required this.assetId,
    required this.resolvedUri,
    required this.mediaType,
  })  : assert(assetId != ''),
        assert(mediaType != '');

  final String assetId;
  final Uri resolvedUri;
  final String mediaType;

  String get playbackLocation => resolvedUri.scheme == 'file'
      ? resolvedUri.toFilePath()
      : resolvedUri.toString();

  RuntimeStartupPresentationAsset get presentationAsset =>
      RuntimeStartupPresentationAsset(
        assetId: assetId,
        mediaType: mediaType,
      );
}

/// Player-facing asset metadata. Concrete filesystem or network locations stay
/// inside the coordinator and its host resolver boundary.
final class RuntimeStartupPresentationAsset {
  const RuntimeStartupPresentationAsset({
    required this.assetId,
    required this.mediaType,
  })  : assert(assetId != ''),
        assert(mediaType != '');

  final String assetId;
  final String mediaType;
}

/// Immutable media metadata prepared before the title is shown.
final class RuntimeStartupPresentationMetadata {
  const RuntimeStartupPresentationMetadata({
    this.author = '',
    this.description,
  });

  final String author;
  final String? description;
}

/// Immutable media metadata prepared before the title is shown.
final class RuntimeStartupResolvedPresentation {
  const RuntimeStartupResolvedPresentation({
    this.metadata = const RuntimeStartupPresentationMetadata(),
    this.orientation = RuntimePresentationOrientation.landscape,
    this.profile,
    this.hostLogo,
    this.introVideo,
    this.introPoster,
    this.titleHero,
    this.titleLogo,
    this.titleMusic,
    this.titlePromptVideo,
    this.titlePromptPoster,
    this.titleMenuVideo,
    this.titleMenuPoster,
    this.typography,
  });

  final RuntimeStartupPresentationMetadata metadata;
  final RuntimePresentationOrientation orientation;
  final ProjectPresentationProfile? profile;
  final RuntimeStartupPresentationAsset? hostLogo;
  final RuntimeStartupPresentationAsset? introVideo;
  final RuntimeStartupPresentationAsset? introPoster;
  final RuntimeStartupPresentationAsset? titleHero;
  final RuntimeStartupPresentationAsset? titleLogo;
  final RuntimeStartupPresentationAsset? titleMusic;
  final RuntimeStartupPresentationAsset? titlePromptVideo;
  final RuntimeStartupPresentationAsset? titlePromptPoster;
  final RuntimeStartupPresentationAsset? titleMenuVideo;
  final RuntimeStartupPresentationAsset? titleMenuPoster;
  final RuntimeLoadedTypography? typography;
}

/// Immutable state consumed by the future generic player UI shell.
final class RuntimeStartupSnapshot {
  RuntimeStartupSnapshot({
    required this.revision,
    required this.phase,
    required this.progress,
    required this.currentStage,
    required this.isPreparationReady,
    required this.isMinimumElapsed,
    required this.isLifecycleActive,
    this.suspendedPhase,
    this.introPhase = RuntimeIntroPhase.idle,
    this.isTransitioning = false,
    this.presentation,
    this.failure,
    this.playerSnapshot,
    List<RuntimeStartupDiagnostic> diagnostics =
        const <RuntimeStartupDiagnostic>[],
    this.introCanReplay = false,
  }) : diagnostics = List<RuntimeStartupDiagnostic>.unmodifiable(diagnostics) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must be non-negative');
    }
    if (progress < 0 || progress > 1) {
      throw ArgumentError.value(
          progress, 'progress', 'must be between 0 and 1');
    }
    if (phase == RuntimeStartupPhase.lifecyclePaused && isLifecycleActive) {
      throw ArgumentError('A lifecycle-paused snapshot cannot be active.');
    }
    if (phase != RuntimeStartupPhase.lifecyclePaused &&
        suspendedPhase != null) {
      throw ArgumentError(
        'Only a lifecycle-paused snapshot may expose a suspended phase.',
      );
    }
  }

  final int revision;
  final RuntimeStartupPhase phase;
  final double progress;
  final RuntimeStartupPreparationStage currentStage;
  final bool isPreparationReady;
  final bool isMinimumElapsed;
  final bool isLifecycleActive;
  final RuntimeStartupPhase? suspendedPhase;
  final RuntimeIntroPhase introPhase;
  final bool isTransitioning;
  final RuntimeStartupResolvedPresentation? presentation;
  final List<RuntimeStartupDiagnostic> diagnostics;
  final RuntimeStartupFailure? failure;
  final RuntimePlayerSnapshot? playerSnapshot;
  final bool introCanReplay;

  bool get canSkipSplash => false;

  bool get canSkipIntro =>
      isLifecycleActive &&
      !isTransitioning &&
      phase == RuntimeStartupPhase.intro &&
      (introPhase == RuntimeIntroPhase.playing ||
          introPhase == RuntimeIntroPhase.paused);

  bool get canContinueFromPoster =>
      isLifecycleActive &&
      !isTransitioning &&
      phase == RuntimeStartupPhase.intro &&
      introPhase == RuntimeIntroPhase.poster;

  bool get canReplayIntro =>
      isLifecycleActive &&
      !isTransitioning &&
      introCanReplay &&
      (introPhase == RuntimeIntroPhase.poster ||
          phase == RuntimeStartupPhase.titlePrompt ||
          phase == RuntimeStartupPhase.titleMenu);

  bool get canPressStart =>
      isLifecycleActive &&
      !isTransitioning &&
      phase == RuntimeStartupPhase.titlePrompt;

  bool get canRetry =>
      isLifecycleActive && phase == RuntimeStartupPhase.recoverableError;

  RuntimeStartupSnapshot next({
    RuntimeStartupPhase? phase,
    double? progress,
    RuntimeStartupPreparationStage? currentStage,
    bool? isPreparationReady,
    bool? isMinimumElapsed,
    bool? isLifecycleActive,
    RuntimeStartupPhase? suspendedPhase,
    bool clearSuspendedPhase = false,
    RuntimeIntroPhase? introPhase,
    bool? isTransitioning,
    RuntimeStartupResolvedPresentation? presentation,
    RuntimeStartupFailure? failure,
    bool clearFailure = false,
    RuntimePlayerSnapshot? playerSnapshot,
    List<RuntimeStartupDiagnostic>? diagnostics,
    bool? introCanReplay,
  }) {
    return RuntimeStartupSnapshot(
      revision: revision + 1,
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      currentStage: currentStage ?? this.currentStage,
      isPreparationReady: isPreparationReady ?? this.isPreparationReady,
      isMinimumElapsed: isMinimumElapsed ?? this.isMinimumElapsed,
      isLifecycleActive: isLifecycleActive ?? this.isLifecycleActive,
      suspendedPhase:
          clearSuspendedPhase ? null : suspendedPhase ?? this.suspendedPhase,
      introPhase: introPhase ?? this.introPhase,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      presentation: presentation ?? this.presentation,
      failure: clearFailure ? null : failure ?? this.failure,
      playerSnapshot: playerSnapshot ?? this.playerSnapshot,
      diagnostics: diagnostics ?? this.diagnostics,
      introCanReplay: introCanReplay ?? this.introCanReplay,
    );
  }
}
