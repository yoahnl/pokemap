import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
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

  test('going from verification straight to smoke loading keeps the bar and steps monotonic', () {
    const stages = [
      GameInstallStage.inspecting,
      GameInstallStage.checkingCompatibility,
      GameInstallStage.checkingStorage,
      GameInstallStage.snapshotting,
      GameInstallStage.extracting,
      GameInstallStage.verifying,
      GameInstallStage.smokeLoading,
      GameInstallStage.promoting,
      GameInstallStage.updatingLibrary,
      GameInstallStage.completed,
    ];
    final presentations = [
      for (final stage in stages)
        HubInstallProgressPresentation.from(
          _progress(stage),
          elapsed: Duration.zero,
        ),
    ];
    for (var index = 1; index < presentations.length; index++) {
      expect(
        presentations[index].fraction,
        greaterThanOrEqualTo(presentations[index - 1].fraction),
      );
      for (final milestone in HubInstallMilestone.values) {
        expect(
          presentations[index].milestones[milestone.index].state.index,
          greaterThanOrEqualTo(
            presentations[index - 1].milestones[milestone.index].state.index,
          ),
        );
      }
    }
    PlayerProgressStepState state(
      GameInstallStage stage,
      HubInstallMilestone milestone,
    ) => presentations[stages.indexOf(stage)].milestones[milestone.index].state;
    expect(
      state(GameInstallStage.smokeLoading, HubInstallMilestone.verification),
      PlayerProgressStepState.completed,
    );
    expect(
      state(GameInstallStage.smokeLoading, HubInstallMilestone.validation),
      PlayerProgressStepState.active,
    );
    expect(
      state(GameInstallStage.promoting, HubInstallMilestone.validation),
      PlayerProgressStepState.completed,
    );
  });
}
