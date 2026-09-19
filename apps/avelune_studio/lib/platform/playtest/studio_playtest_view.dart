import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'studio_playtest_session.dart';

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
  });

  final ProjectSession session;
  final ProjectMapEntry entry;
  final String expectedRevision;
  final MapWorkspacePort port;
  final VoidCallback onClose;
  final StudioPlaytestSession? testSession;

  @override
  State<StudioPlaytestView> createState() => _StudioPlaytestViewState();
}

class _StudioPlaytestViewState extends State<StudioPlaytestView> {
  late Future<PlayableMapGame> _loading = _load();
  PlayableMapGame? _game;
  late final _saves = widget.testSession ?? StudioPlaytestSession();
  bool _busy = false;
  String? _message;

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
          'Cliquez dans la carte · flèches pour marcher · Entrée pour interagir',
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
              onPressed: _busy ? null : _save,
            ),
            StudioButton(
              label: 'Reprendre le test',
              icon: Icons.restore,
              secondary: true,
              onPressed: _busy || !_saves.hasSave ? null : _resume,
            ),
            StudioButton(
              label: 'Nouvelle partie',
              icon: Icons.restart_alt,
              secondary: true,
              onPressed: _busy ? null : _newGame,
            ),
            if (_message != null) Text(_message!),
          ],
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
            return ClipRect(
              child: GameWidget<PlayableMapGame>(
                key: ObjectKey(game),
                game: game,
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
