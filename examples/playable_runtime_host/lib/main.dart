import 'package:file_picker/file_picker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Playable Runtime Host',
    home: _ProjectLoaderPage(),
  ));
}

class _ProjectLoaderPage extends StatefulWidget {
  const _ProjectLoaderPage();

  @override
  State<_ProjectLoaderPage> createState() => _ProjectLoaderPageState();
}

class _ProjectLoaderPageState extends State<_ProjectLoaderPage> {
  final _mapIdController = TextEditingController();
  String _projectFilePath = '';
  PlayableMapGame? _game;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _mapIdController.dispose();
    super.dispose();
  }

  Future<void> _pickProjectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      dialogTitle: 'Sélectionner project.json',
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty || !mounted) return;
    setState(() {
      _projectFilePath = path;
      _error = null;
    });
  }

  Future<void> _load() async {
    final projectFilePath = _projectFilePath;
    final mapId = _mapIdController.text.trim();

    if (projectFilePath.isEmpty) {
      setState(() => _error = 'Sélectionnez un fichier project.json.');
      return;
    }
    if (mapId.isEmpty) {
      setState(() => _error = 'Saisissez un identifiant de map.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _game = null;
    });

    try {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      if (!mounted) return;
      setState(() {
        _game = PlayableMapGame(bundle: bundle, projectFilePath: projectFilePath);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() => setState(() {
        _game = null;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_mapIdController.text.trim()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _reset,
          ),
        ),
        body: GameWidget(game: game),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Playable Runtime Host')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Projet', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _ProjectFileField(
              path: _projectFilePath,
              onPick: _loading ? null : _pickProjectFile,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _mapIdController,
              decoration: const InputDecoration(
                labelText: 'Map ID',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _loading ? null : _load(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _load,
              child: Text(_loading ? 'Chargement…' : 'Lancer'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectFileField extends StatelessWidget {
  const _ProjectFileField({required this.path, required this.onPick});

  final String path;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                path.isEmpty ? 'Aucun fichier sélectionné' : path,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: path.isEmpty ? Theme.of(context).hintColor : null,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: onPick,
              child: const Text('Parcourir…'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
