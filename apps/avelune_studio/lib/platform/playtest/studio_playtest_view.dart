import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_story/map_story.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;

import 'studio_playtest_session.dart';
import 'studio_playtest_start.dart';
import '../../features/playtest/contracts/studio_playtest_controls.dart';
import 'studio_playtest_player_view.dart';
import 'studio_spatial_playtest.dart';
import 'studio_spatial_playtest_view.dart';
import '../../features/pokemon/data/studio_project_item_icons.dart';
import '../../features/verification/application/studio_failure_diagnosis.dart';

export 'studio_playtest_session.dart';
export '../../features/playtest/contracts/studio_playtest_controls.dart';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

part 'studio_playtest_view_commands.dart';
part 'studio_playtest_view_loading.dart';

class StudioPlaytestView extends StatefulWidget {
  const StudioPlaytestView({
    super.key,
    required this.session,
    required this.entry,
    required this.expectedRevision,
    required this.port,
    required this.onClose,
    this.testSession,
    this.previewVisuals,
    this.prepareProjectAssets,
    this.spatialViewBuilder,
    this.controls,
  });

  final StudioPlaytestControls? controls;
  final ProjectSession session;
  final ProjectMapEntry entry;
  final String expectedRevision;
  final MapWorkspacePort port;
  final VoidCallback onClose;
  final StudioPlaytestSession? testSession;
  final ValueListenable<SpatialVisualPatch>? previewVisuals;
  final Future<void> Function(String projectRoot)? prepareProjectAssets;
  final Widget Function(
    BuildContext context,
    StudioSpatialPlaytest playtest,
    VoidCallback onReady,
    void Function(Object) onError,
  )?
  spatialViewBuilder;

  @override
  State<StudioPlaytestView> createState() => _StudioPlaytestViewState();
}

class _StudioPlaytestViewState extends State<StudioPlaytestView>
    with _StudioPlaytestRuntimeLoading, _StudioPlaytestSessionCommands {
  late StudioPlaytestControls _controls;

  @override
  void initState() {
    super.initState();
    _controls = widget.controls ?? StudioPlaytestControls();
    _attachControls();
  }

  @override
  void didUpdateWidget(StudioPlaytestView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controls, widget.controls)) {
      _controls.detach(this);
      _controls = widget.controls ?? StudioPlaytestControls();
      _attachControls();
    }
  }

  void _attachControls() {
    _controls.attach(
      this,
      status: () => StudioPlaytestStatus(
        ready: _ready,
        busy: _busy,
        hasSave: _saves.hasSave,
        paused: _spatialPaused,
        spatial: _spatialPlaytest != null,
        diagonal: _spatial?.movement.allowDiagonalMovement ?? false,
        message: _message,
      ),
      requestClose: () => widget.onClose(),
      save: _save,
      resume: _resume,
      newGame: _newGame,
      togglePause: _toggleSpatialPause,
      setSpeed: (speed) => _game?.setTestSpeed(speed),
      toggleDiagonal: () {
        final playtest = _spatialPlaytest;
        final spatial = _spatial;
        if (playtest == null ||
            spatial == null ||
            !playtest.runtime.inputAuthority.value.acceptsOverworldInput) {
          return;
        }
        setState(
          () => spatial.movement.setDiagonalMovement(
            !spatial.movement.allowDiagonalMovement,
          ),
        );
      },
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _controls.statusChanged();
  }

  @override
  void dispose() {
    _controls.detach(this);
    _preSessionInteractions?.close();
    unawaited(_preSessionSubscription?.cancel());
    _game?.pauseEngine();
    _finishSpatialMount(StateError('Test fermé'));
    unawaited(_spatialPlaytest?.dispose());
    final services = _playerServices;
    final deleteSaves = widget.testSession == null;
    unawaited(() async {
      await services?.dispose();
      if (deleteSaves) await _saves.delete();
    }());
    super.dispose();
  }

  Widget _launchFailure(BuildContext context, Object error) {
    final diagnosis = diagnoseLaunchFailure(error);
    return Center(child: Text('${diagnosis.summary}\n${diagnosis.detail}'));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Object>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _launchFailure(context, snapshot.error!);
      }
      if (_preSessionRequest case final request?) {
        return Localizations.override(
          context: context,
          delegates: PokeMapPlayerLocalizations.localizationsDelegates,
          child: Theme(
            data: Theme.of(context).brightness == Brightness.dark
                ? PokeMapPlayerTheme.dark()
                : PokeMapPlayerTheme.light(),
            child: PlayerSceneInteractionSurface(
              request: request,
              onResult: (result) {
                final resolution = _preSessionInteractions?.resolve(result);
                if (resolution?.isAccepted == true && mounted) {
                  if (result is SceneCancelledInteractionResult) {
                    widget.onClose();
                    return;
                  }
                  setState(() => _preSessionRequest = null);
                }
              },
            ),
          ),
        );
      }
      final game = snapshot.connectionState == ConnectionState.done
          ? snapshot.data
          : (_spatial == null ? null : _spatialPlaytest);
      if (game == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (game is StudioSpatialPlaytest) {
        if (!identical(game, _spatialPlaytest)) {
          return const Center(child: CircularProgressIndicator());
        }
        void ready() {
          if (mounted && identical(game, _spatialPlaytest)) {
            _finishSpatialMount();
          }
        }

        void failed(Object error) {
          if (mounted && identical(game, _spatialPlaytest)) {
            _finishSpatialMount(error);
          }
        }

        final builder = widget.spatialViewBuilder;
        if (builder != null) {
          return builder(context, game, ready, failed);
        }
        return StudioSpatialPlaytestView(
          key: ObjectKey(game),
          runtime: game.runtime,
          previewVisuals: widget.previewVisuals,
          onReady: ready,
          onError: failed,
        );
      }
      return StudioPlaytestPlayerView(
        key: ObjectKey(game),
        game: game as PlayableMapGame,
        bundle: _playerBundle!,
        services: _playerServices!,
      );
    },
  );
}

class StudioPlaytestSaveRepository extends StudioPlaytestSession {}
