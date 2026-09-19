import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

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
  });

  final ProjectSession session;
  final ProjectMapEntry entry;
  final String expectedRevision;
  final MapWorkspacePort port;
  final VoidCallback onClose;

  @override
  State<StudioPlaytestView> createState() => _StudioPlaytestViewState();
}

class _StudioPlaytestViewState extends State<StudioPlaytestView> {
  late final Future<PlayableMapGame> _loading = _load();
  PlayableMapGame? _game;
  final _saves = StudioPlaytestSaveRepository();

  Future<PlayableMapGame> _load() async {
    final document = await widget.port.loadMap(widget.session, widget.entry);
    if (document.revision != widget.expectedRevision) {
      throw StateError(
        'La carte a changé sur disque. Revenez et rechargez-la.',
      );
    }
    final projectPath = p.join(widget.session.directoryPath, 'project.json');
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: widget.entry.id,
    );
    if (bundle.map != document.map) {
      throw StateError('La carte a changé pendant la préparation du test.');
    }
    if (!mounted) throw StateError('Test fermé');
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: projectPath,
      saveRepository: _saves,
      initialMapActivationReason: MapActivationReason.initialBoot,
    );
    _game = game;
    return game;
  }

  @override
  void dispose() {
    _game?.pauseEngine();
    _saves.delete();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          StudioButton(label: 'Retour à la carte', onPressed: widget.onClose),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '${widget.entry.name} · révision ${widget.expectedRevision.substring(0, 8)} · sauvegardes de test temporaires',
            ),
          ),
        ],
      ),
      const Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'Cliquez dans la carte · flèches pour marcher · Entrée pour interagir',
        ),
      ),
      Expanded(
        child: FutureBuilder<PlayableMapGame>(
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
            return GameWidget<PlayableMapGame>(
              game: game,
              autofocus: true,
              errorBuilder: (context, error) =>
                  Center(child: Text('Erreur du test : $error')),
            );
          },
        ),
      ),
    ],
  );
}

class StudioPlaytestSaveRepository implements GameSaveRepository {
  GameState? _state;

  @override
  Future<void> save(GameState state) async => _state = state;

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async => _state = null;
}
