import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_models.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('available state requires release metadata', () {
    final release = EditorUpdateRelease(
      version: Version.parse('0.3.1'),
      tag: 'pokemap-v0.3.1',
      publishedAt: DateTime.utc(2026, 8, 3),
      releaseNotesUri: Uri.parse(
        'https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.1',
      ),
    );

    final state = EditorUpdateState.available(
      currentVersion: Version.parse('0.3.0'),
      release: release,
      userInitiated: false,
    );

    expect(state.phase, EditorUpdatePhase.available);
    expect(state.availableRelease, same(release));
    expect(state.failure, isNull);
  });

  test('native updater capabilities keep deferred install opt-in', () {
    expect(
      EditorNativeUpdaterCapabilities.windowsV1.supportsDeferredInstall,
      isFalse,
    );
    expect(
      EditorNativeUpdaterCapabilities.windowsV1.supportsTypedErrors,
      isFalse,
    );
    expect(
      EditorNativeUpdaterCapabilities.macosV1.supportsByteProgress,
      isFalse,
    );
  });

  test('unsupported state does not carry release or failure metadata', () {
    final state = EditorUpdateState.unsupported(
      currentVersion: Version.parse('0.3.0'),
    );

    expect(state.phase, EditorUpdatePhase.unsupported);
    expect(state.availableRelease, isNull);
    expect(state.failure, isNull);
  });
}
