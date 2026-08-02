import 'package:pub_semver/pub_semver.dart';

enum EditorUpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  handingOff,
  blockedByUnsavedWork,
  installing,
  restarting,
  failed,
  unsupported,
}

final class EditorUpdateRelease {
  const EditorUpdateRelease({
    required this.version,
    required this.tag,
    required this.publishedAt,
    required this.releaseNotesUri,
  });

  final Version version;
  final String tag;
  final DateTime publishedAt;
  final Uri releaseNotesUri;
}

final class EditorUpdateFailure {
  const EditorUpdateFailure({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

final class EditorUpdateState {
  const EditorUpdateState._({
    required this.phase,
    required this.currentVersion,
    required this.userInitiated,
    this.availableRelease,
    this.failure,
  });

  factory EditorUpdateState.available({
    required Version currentVersion,
    required EditorUpdateRelease release,
    required bool userInitiated,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.available,
      currentVersion: currentVersion,
      availableRelease: release,
      userInitiated: userInitiated,
    );
  }

  factory EditorUpdateState.idle({Version? currentVersion}) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.idle,
      currentVersion: currentVersion,
      userInitiated: false,
    );
  }

  factory EditorUpdateState.checking({
    required Version? currentVersion,
    required bool userInitiated,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.checking,
      currentVersion: currentVersion,
      userInitiated: userInitiated,
    );
  }

  factory EditorUpdateState.upToDate({required Version currentVersion}) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.upToDate,
      currentVersion: currentVersion,
      userInitiated: true,
    );
  }

  factory EditorUpdateState.handingOff({
    required Version currentVersion,
    required EditorUpdateRelease release,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.handingOff,
      currentVersion: currentVersion,
      availableRelease: release,
      userInitiated: true,
    );
  }

  factory EditorUpdateState.blockedByUnsavedWork({
    required Version currentVersion,
    required EditorUpdateRelease release,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.blockedByUnsavedWork,
      currentVersion: currentVersion,
      availableRelease: release,
      userInitiated: true,
    );
  }

  factory EditorUpdateState.installing({
    required Version currentVersion,
    required EditorUpdateRelease release,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.installing,
      currentVersion: currentVersion,
      availableRelease: release,
      userInitiated: true,
    );
  }

  factory EditorUpdateState.restarting({
    required Version currentVersion,
    required EditorUpdateRelease release,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.restarting,
      currentVersion: currentVersion,
      availableRelease: release,
      userInitiated: true,
    );
  }

  factory EditorUpdateState.failed({
    required Version? currentVersion,
    required EditorUpdateFailure failure,
    required bool userInitiated,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.failed,
      currentVersion: currentVersion,
      failure: failure,
      userInitiated: userInitiated,
    );
  }

  factory EditorUpdateState.unsupported({
    Version? currentVersion,
  }) {
    return EditorUpdateState._(
      phase: EditorUpdatePhase.unsupported,
      currentVersion: currentVersion,
      userInitiated: false,
    );
  }

  final EditorUpdatePhase phase;
  final Version? currentVersion;
  final EditorUpdateRelease? availableRelease;
  final EditorUpdateFailure? failure;
  final bool userInitiated;
}

final class EditorNativeUpdaterCapabilities {
  const EditorNativeUpdaterCapabilities({
    required this.supportsDeferredInstall,
    required this.supportsTypedErrors,
    required this.supportsByteProgress,
  });

  static const windowsV1 = EditorNativeUpdaterCapabilities(
    supportsDeferredInstall: false,
    supportsTypedErrors: false,
    supportsByteProgress: false,
  );

  static const macosV1 = EditorNativeUpdaterCapabilities(
    supportsDeferredInstall: false,
    supportsTypedErrors: true,
    supportsByteProgress: false,
  );

  final bool supportsDeferredInstall;
  final bool supportsTypedErrors;
  final bool supportsByteProgress;
}
