import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'studio_playtest_session.dart';
import 'studio_playtest_start.dart';
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
  late final _saves = widget.testSession ?? StudioPlaytestSession();
  bool _busy = false;
  String? _message;

  Future<Object> _load() async {
    final document = await widget.port.loadMap(widget.session, widget.entry);
    if (document.revision != widget.expectedRevision) {
      throw StateError(
        'La carte a changé sur disque. Revenez et rechargez-la.',
      );
    }
    final projectPath = p.join(widget.session.directoryPath, 'project.json');
    if (!mounted) throw StateError('Test fermé');
    if (document.map.spatialScene != null) {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: widget.entry.id,
      );
      if (bundle.map != document.map) {
        throw StateError('La carte a changé pendant la préparation du test.');
      }
      final exploration = await SpatialExplorationSession.load(bundle);
      if (!mounted) {
        exploration.dispose();
        throw StateError('Test fermé');
      }
      setState(() => _spatial = exploration);
      return exploration;
    }
    final prepareProjectAssets = widget.prepareProjectAssets;
    if (prepareProjectAssets != null) {
      await prepareProjectAssets(widget.session.directoryPath);
    } else {
      await StudioProjectItemIcons.shared.prepare(
        widget.session.directoryPath,
        shouldContinue: () => mounted,
      );
    }
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
    return game;
  }

  @override
  void dispose() {
    _game?.pauseEngine();
    _spatial?.dispose();
    if (widget.testSession == null) _saves.delete();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final saved = await _game?.saveGame() ?? false;
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
    await _saves.delete();
    if (!mounted) return;
    setState(() {
      _loading = _load();
      _busy = false;
      _message = 'Nouvelle partie : état de test réinitialisé.';
    });
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
                '${widget.entry.name} · révision ${widget.expectedRevision.substring(0, 8)} · ${_spatial == null ? 'sauvegardes de test temporaires' : 'Exploration 3D · test initial'}',
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
              : 'Cliquez dans la carte · flèches / ZQSD pour marcher · Maj pour courir',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (_spatial == null)
              StudioButton(
                label: 'Enregistrer le test',
                icon: Icons.save_outlined,
                secondary: true,
                onPressed: _busy ? null : _save,
              ),
            if (_spatial == null)
              StudioButton(
                label: 'Reprendre le test',
                icon: Icons.restore,
                secondary: true,
                onPressed: _busy || !_saves.hasSave ? null : _resume,
              ),
            if (_spatial == null)
              StudioButton(
                label: 'Nouvelle partie',
                icon: Icons.restart_alt,
                secondary: true,
                onPressed: _busy ? null : _newGame,
              ),
            if (_spatial case final exploration?)
              StudioSpatialExplorationControls(movement: exploration.movement),
            if (_message != null) Text(_message!),
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
            final game = snapshot.data;
            if (game == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (game is SpatialExplorationSession) {
              return ClipRect(
                child: SpatialExplorationView(
                  key: ObjectKey(game),
                  session: game,
                ),
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
  const StudioSpatialExplorationControls({super.key, required this.movement});
  final SpatialMovementController movement;
  @override
  State<StudioSpatialExplorationControls> createState() =>
      _StudioSpatialExplorationControlsState();
}

class _StudioSpatialExplorationControlsState
    extends State<StudioSpatialExplorationControls> {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      StudioButton(
        label: 'Réinitialiser la position',
        icon: Icons.restart_alt,
        secondary: true,
        onPressed: () => setState(widget.movement.reset),
      ),
      StudioButton(
        label: widget.movement.paused ? 'Reprendre' : 'Pause',
        secondary: true,
        onPressed: () =>
            setState(() => widget.movement.setPaused(!widget.movement.paused)),
      ),
      StudioButton(
        label: widget.movement.allowDiagonalMovement
            ? 'Diagonales activées'
            : 'Diagonales désactivées',
        secondary: true,
        onPressed: () => setState(
          () => widget.movement.setDiagonalMovement(
            !widget.movement.allowDiagonalMovement,
          ),
        ),
      ),
    ],
  );
}
