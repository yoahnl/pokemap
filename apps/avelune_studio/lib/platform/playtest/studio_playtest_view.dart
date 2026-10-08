import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'studio_playtest_session.dart';
import 'studio_playtest_start.dart';
import 'studio_spatial_playtest.dart';
import 'studio_spatial_playtest_view.dart';
import '../../features/pokemon/data/studio_project_item_icons.dart';

export 'studio_playtest_session.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

class StudioPlaytestView extends StatefulWidget {
  const StudioPlaytestView({
    super.key,
    required this.session,
    required this.entry,
    required this.expectedRevision,
    required this.port,
    required this.onClose,
    this.testSession,
    this.prepareProjectAssets,
  });

  final ProjectSession session;
  final ProjectMapEntry entry;
  final String expectedRevision;
  final MapWorkspacePort port;
  final VoidCallback onClose;
  final StudioPlaytestSession? testSession;
  final Future<void> Function(String projectRoot)? prepareProjectAssets;

  @override
  State<StudioPlaytestView> createState() => _StudioPlaytestViewState();
}

class _StudioPlaytestViewState extends State<StudioPlaytestView> {
  late Future<Object> _loading = _load();
  PlayableMapGame? _game;
  SpatialExplorationSession? _spatial;
  StudioSpatialPlaytest? _spatialPlaytest;
  late final _saves = widget.testSession ?? StudioPlaytestSession();
  bool _busy = false;
  String? _message;
  bool _spatialPaused = false;
  bool _ready = false;
  Completer<void>? _spatialMountReady;

  Future<Object> _load({bool restoreSpatialSave = false}) async {
    final document = await widget.port.loadMap(widget.session, widget.entry);
    if (document.revision != widget.expectedRevision) {
      throw StateError(
        'La carte a changé sur disque. Revenez et rechargez-la.',
      );
    }
    final projectPath = p.join(widget.session.directoryPath, 'project.json');
    if (!mounted) throw StateError('Test fermé');
    if (document.map.spatialScene != null) {
      var bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: widget.entry.id,
      );
      if (bundle.map != document.map) {
        throw StateError('La carte a changé pendant la préparation du test.');
      }
      StudioSpatialPlaytest.validateHero(bundle);
      await _prepareProjectAssets();
      if (!mounted) throw StateError('Test fermé');
      bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: widget.entry.id,
      );
      if (bundle.map != document.map) {
        throw StateError('La carte a changé pendant la préparation du test.');
      }
      final playtest = await StudioSpatialPlaytest.prepare(
        bundle: bundle,
        projectFilePath: projectPath,
        projectRevision: widget.expectedRevision,
        saves: _saves,
        restore: restoreSpatialSave,
        mountSession: (runtime) async {
          if (!mounted) throw StateError('Test fermé');
          final ready = Completer<void>();
          _spatialMountReady = ready;
          setState(() => _spatial = runtime.session);
          await ready.future;
        },
        unmountSession: (runtime) async {
          if (mounted && identical(_spatialPlaytest?.runtime, runtime)) {
            setState(() => _spatial = null);
          }
        },
      );
      if (!mounted) {
        await playtest.dispose();
        throw StateError('Test fermé');
      }
      _spatialPlaytest = playtest;
      try {
        await playtest.runtime.load((_) {});
      } catch (_) {
        await playtest.dispose();
        if (identical(_spatialPlaytest, playtest)) _spatialPlaytest = null;
        rethrow;
      }
      if (!mounted) throw StateError('Test fermé');
      setState(() {
        _spatial = playtest.runtime.session;
        _ready = true;
      });
      return playtest;
    }
    await _prepareProjectAssets();
    if (!mounted) throw StateError('Test fermé');
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: widget.entry.id,
    );
    if (bundle.map != document.map) {
      throw StateError('La carte a changé pendant la préparation du test.');
    }
    final initialGameState = await prepareStudioPlaytestStart(
      bundle,
      projectPath,
    );
    if (!mounted) throw StateError('Test fermé');
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: projectPath,
      initialGameState: initialGameState,
      saveRepository: _saves,
      initialMapActivationReason: MapActivationReason.initialBoot,
    );
    _game = game;
    setState(() => _ready = true);
    return game;
  }

  Future<void> _prepareProjectAssets() async {
    final prepareProjectAssets = widget.prepareProjectAssets;
    if (prepareProjectAssets != null) {
      await prepareProjectAssets(widget.session.directoryPath);
    } else {
      await StudioProjectItemIcons.shared.prepare(
        widget.session.directoryPath,
        shouldContinue: () => mounted,
      );
    }
  }

  @override
  void dispose() {
    _game?.pauseEngine();
    _finishSpatialMount(StateError('Test fermé'));
    unawaited(_spatialPlaytest?.dispose());
    if (widget.testSession == null) _saves.delete();
    super.dispose();
  }

  void _finishSpatialMount([Object? error]) {
    final ready = _spatialMountReady;
    if (ready == null || ready.isCompleted) return;
    if (error == null) {
      ready.complete();
    } else {
      ready.completeError(error);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    var saved = false;
    try {
      saved = _spatialPlaytest == null
          ? await _game?.saveGame() ?? false
          : await _spatialPlaytest!.save();
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = saved
          ? 'Test enregistré en mémoire pour cette session.'
          : 'Terminez l’interaction avant d’enregistrer le test.';
    });
  }

  Future<void> _resume() async {
    setState(() => _busy = true);
    if (_spatialPlaytest != null) {
      final previous = _spatialPlaytest!;
      setState(() {
        _spatialPlaytest = null;
        _spatial = null;
        _ready = false;
        _loading = Future<Object>.sync(() async {
          await previous.dispose();
          return _load(restoreSpatialSave: true);
        });
        _spatialPaused = false;
        _busy = false;
        _message = 'Sauvegarde du test reprise.';
      });
      return;
    }
    final loaded = await _game?.loadGame() ?? false;
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = loaded
          ? 'Sauvegarde du test reprise.'
          : 'Reprise impossible pendant cette interaction ou après ce changement.';
    });
  }

  Future<void> _newGame() async {
    setState(() => _busy = true);
    _game?.pauseEngine();
    _game = null;
    final spatial = _spatialPlaytest;
    _spatialPlaytest = null;
    _spatial = null;
    _ready = false;
    await spatial?.dispose();
    await _saves.delete();
    if (!mounted) return;
    setState(() {
      _loading = _load();
      _busy = false;
      _spatialPaused = false;
      _message = 'Nouvelle partie : état de test réinitialisé.';
    });
  }

  Future<void> _toggleSpatialPause() async {
    final runtime = _spatialPlaytest?.runtime;
    if (runtime == null) return;
    if (_spatialPaused) {
      await runtime.resume();
    } else {
      await runtime.pause();
    }
    if (mounted) setState(() => _spatialPaused = !_spatialPaused);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            StudioButton(
              label: 'Retour à la carte',
              icon: Icons.arrow_back,
              onPressed: widget.onClose,
              secondary: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${widget.entry.name} · révision ${widget.expectedRevision.substring(0, 8)} · sauvegardes de test temporaires',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          _spatial == null
              ? 'Cliquez dans la carte · flèches pour marcher · Entrée pour interagir'
              : 'Cliquez dans la carte · flèches / ZQSD pour marcher · Maj pour courir · Entrée pour interagir · Échap pour interrompre la scène',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            StudioButton(
              label: 'Enregistrer le test',
              icon: Icons.save_outlined,
              secondary: true,
              onPressed: _busy || !_ready ? null : _save,
            ),
            StudioButton(
              label: 'Reprendre le test',
              icon: Icons.restore,
              secondary: true,
              onPressed: _busy || !_ready || !_saves.hasSave ? null : _resume,
            ),
            StudioButton(
              label: 'Nouvelle partie',
              icon: Icons.restart_alt,
              secondary: true,
              onPressed: _busy || !_ready ? null : _newGame,
            ),
            if (_spatialPlaytest != null)
              StudioButton(
                label: _spatialPaused ? 'Reprendre' : 'Pause',
                secondary: true,
                onPressed: _busy || !_ready ? null : _toggleSpatialPause,
              ),
            if (_spatial case final spatial?)
              ListenableBuilder(
                listenable: Listenable.merge([
                  spatial.mapRevision,
                  _spatialPlaytest!.runtime.inputAuthority,
                ]),
                builder: (context, _) => StudioButton(
                  label: spatial.movement.allowDiagonalMovement
                      ? 'Diagonales activées'
                      : 'Diagonales désactivées',
                  secondary: true,
                  onPressed:
                      _busy ||
                          !_ready ||
                          !_spatialPlaytest!
                              .runtime
                              .inputAuthority
                              .value
                              .acceptsOverworldInput
                      ? null
                      : () => setState(() {
                          spatial.movement.setDiagonalMovement(
                            !spatial.movement.allowDiagonalMovement,
                          );
                        }),
                ),
              ),
            if (_message != null)
              Text(_message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<Object>(
          future: _loading,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Le test ne peut pas démarrer : ${snapshot.error}'),
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
              return StudioSpatialPlaytestView(
                key: ObjectKey(game),
                runtime: game.runtime,
                onReady: _finishSpatialMount,
                onError: _finishSpatialMount,
              );
            }
            return ClipRect(
              child: GameWidget<PlayableMapGame>(
                key: ObjectKey(game),
                game: game as PlayableMapGame,
                autofocus: true,
                errorBuilder: (context, error) =>
                    Center(child: Text('Erreur du test : $error')),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class StudioPlaytestSaveRepository extends StudioPlaytestSession {}

class StudioSpatialExplorationControls extends StatefulWidget {
  const StudioSpatialExplorationControls({
    super.key,
    required this.movement,
    this.session,
  });
  final SpatialMovementController movement;
  final SpatialExplorationSession? session;
  @override
  State<StudioSpatialExplorationControls> createState() =>
      _StudioSpatialExplorationControlsState();
}

class _StudioSpatialExplorationControlsState
    extends State<StudioSpatialExplorationControls> {
  SpatialMovementController get movement =>
      widget.session?.movement ?? widget.movement;
  @override
  Widget build(BuildContext context) => widget.session == null
      ? controls(context)
      : ListenableBuilder(
          listenable: Listenable.merge([
            widget.session!.mapRevision,
            widget.session!.transitioning,
          ]),
          builder: (context, child) => controls(context),
        );

  Widget controls(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      StudioButton(
        label: 'Réinitialiser la position',
        icon: Icons.restart_alt,
        secondary: true,
        onPressed: (widget.session?.transitioning.value ?? false)
            ? null
            : () => setState(() {
                widget.session?.closeDialogue();
                widget.session?.dialoguePaused = false;
                if (widget.session case final session?) {
                  session.resetPosition();
                } else {
                  movement.reset();
                }
              }),
      ),
      StudioButton(
        label: (widget.session?.dialoguePaused ?? movement.paused)
            ? 'Reprendre'
            : 'Pause',
        secondary: true,
        onPressed: () => setState(() {
          final paused = !(widget.session?.dialoguePaused ?? movement.paused);
          widget.session?.dialoguePaused = paused;
          movement.setPaused(
            (widget.session?.presentationPaused ?? paused) ||
                (widget.session?.interactionActive.value ?? false) ||
                (widget.session?.transitioning.value ?? false),
          );
        }),
      ),
      StudioButton(
        label: movement.allowDiagonalMovement
            ? 'Diagonales activées'
            : 'Diagonales désactivées',
        secondary: true,
        onPressed: () => setState(
          () => movement.setDiagonalMovement(!movement.allowDiagonalMovement),
        ),
      ),
    ],
  );
}
