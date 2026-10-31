import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:pokemap_hub/presentation/features/installation/widgets/hub_install_progress.dart';

GameInstallProgress _progress(
  GameInstallStage stage, {
  int completedBytes = 0,
  int totalBytes = 0,
}) => GameInstallProgress(
  stage: stage,
  completedFiles: 0,
  totalFiles: 0,
  completedBytes: completedBytes,
  totalBytes: totalBytes,
  cancellable: true,
);

double _fraction(GameInstallProgress progress) =>
    HubInstallProgressPresentation.from(
      progress,
      elapsed: Duration.zero,
    ).fraction;

void main() {
  test('the unmeasured snapshot inspection never moves the bar backwards', () {
    final copied = _fraction(
      _progress(
        GameInstallStage.snapshotting,
        completedBytes: 100,
        totalBytes: 100,
      ),
    );
    final inspecting = _fraction(_progress(GameInstallStage.snapshotting));

    expect(inspecting, greaterThanOrEqualTo(copied));
    expect(
      inspecting,
      lessThanOrEqualTo(_fraction(_progress(GameInstallStage.extracting))),
    );
  });
}
