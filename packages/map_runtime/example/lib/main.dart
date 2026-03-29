import 'package:file_picker/file_picker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  runApp(const MaterialApp(home: LoaderPage()));
}

class LoaderPage extends StatefulWidget {
  const LoaderPage({super.key});

  @override
  State<LoaderPage> createState() => _LoaderPageState();
}

class _LoaderPageState extends State<LoaderPage> {
  final TextEditingController _mapId = TextEditingController();
  String _manifestPath = '';
  String? _error;
  PlayableMapGame? _game;
  bool _busy = false;
  bool _collisionOverlayVisible = false;
  bool _behaviorDebugVisible = false;

  Future<void> _pickProjectJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      dialogTitle: 'Choisir project.json',
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _manifestPath = path;
      _error = null;
    });
  }

  Future<void> _load() async {
    if (_manifestPath.isEmpty) {
      setState(() => _error = 'Sélectionnez un fichier project.json.');
      return;
    }
    setState(() {
      _error = null;
      _game = null;
      _busy = true;
    });
    try {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: _manifestPath,
        mapId: _mapId.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _game = PlayableMapGame(bundle: bundle, projectFilePath: _manifestPath);
        _game!.setCollisionOverlayVisible(_collisionOverlayVisible);
        _game!.setBehaviorDebugOverlayVisible(_behaviorDebugVisible);
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _mapId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_mapId.text.trim()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _game = null),
          ),
        ),
        body: Stack(
          children: [
            GameWidget(game: game),
            Positioned(
              right: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Collisions',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _collisionOverlayVisible,
                            onChanged: (next) {
                              setState(() => _collisionOverlayVisible = next);
                              game.setCollisionOverlayVisible(next);
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Behaviors',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _behaviorDebugVisible,
                            onChanged: (next) {
                              setState(() => _behaviorDebugVisible = next);
                              game.setBehaviorDebugOverlayVisible(next);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('map_runtime preview')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Projet', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _manifestPath.isEmpty
                            ? 'Aucun fichier sélectionné'
                            : _manifestPath,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _manifestPath.isEmpty
                              ? Theme.of(context).hintColor
                              : null,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.tonal(
                      onPressed: _busy ? null : _pickProjectJson,
                      child: const Text('Parcourir…'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _mapId,
              decoration: const InputDecoration(
                labelText: 'Identifiant de la map (map id)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _load,
              child: Text(_busy ? 'Chargement…' : 'Charger la map'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
