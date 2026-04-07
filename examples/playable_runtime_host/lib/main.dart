import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
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
  String _projectFilePath = '';
  List<ProjectMapEntry> _availableMaps = const [];
  String? _selectedMapId;
  PlayableMapGame? _game;
  String? _error;
  bool _loading = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showFpsOverlay = false;
  bool _surfingEnabled = false;
  bool _saveLoadBusy = false;
  String? _saveLoadStatus;
  String? _saveLoadError;
  Timer? _runtimeInfoTicker;

  static const _prefsFileName = '.playable_runtime_host_prefs.json';

  @override
  void initState() {
    super.initState();
    _restoreLastSession();
  }

  @override
  void dispose() {
    _runtimeInfoTicker?.cancel();
    super.dispose();
  }

  String _prefsFilePath() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return _prefsFileName;
    }
    return '$home/$_prefsFileName';
  }

  Future<void> _restoreLastSession() async {
    try {
      final file = File(_prefsFilePath());
      if (!await file.exists()) {
        return;
      }
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final savedProjectPath = (decoded['projectFilePath'] as String?)?.trim();
      final savedMapId = (decoded['mapId'] as String?)?.trim();
      if (savedProjectPath == null || savedProjectPath.isEmpty) {
        return;
      }
      if (!await File(savedProjectPath).exists()) {
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _projectFilePath = savedProjectPath;
        _selectedMapId = savedMapId != null && savedMapId.isNotEmpty
            ? savedMapId
            : _selectedMapId;
      });
      await _loadProjectMapsFromManifest(
        savedProjectPath,
        preferredMapId: savedMapId,
      );
    } catch (_) {
      // Restauration best-effort: on ignore silencieusement les prefs invalides.
    }
  }

  Future<void> _persistLastSession() async {
    try {
      final file = File(_prefsFilePath());
      final payload = <String, dynamic>{
        'projectFilePath': _projectFilePath,
        'mapId': _selectedMapId,
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Persistance best-effort: ne bloque jamais le flux utilisateur.
    }
  }

  Future<void> _loadProjectMapsFromManifest(
    String projectFilePath, {
    String? preferredMapId,
  }) async {
    try {
      final raw = await File(projectFilePath).readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        if (!mounted) return;
        setState(() {
          _availableMaps = const [];
        });
        return;
      }
      final manifest = ProjectManifest.fromJson(decoded);
      final maps = List<ProjectMapEntry>.of(manifest.maps)
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          if (byOrder != 0) return byOrder;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      String? nextSelected = _selectedMapId;
      final preferred = preferredMapId?.trim();
      if (preferred != null &&
          preferred.isNotEmpty &&
          maps.any((m) => m.id == preferred)) {
        nextSelected = preferred;
      } else if (nextSelected == null ||
          nextSelected.isEmpty ||
          !maps.any((m) => m.id == nextSelected)) {
        nextSelected = maps.isEmpty ? null : maps.first.id;
      }
      if (!mounted) return;
      setState(() {
        _availableMaps = maps;
        _selectedMapId = nextSelected;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableMaps = const [];
      });
    }
  }

  void _startRuntimeInfoTicker() {
    _runtimeInfoTicker?.cancel();
    _runtimeInfoTicker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) {
        if (!mounted || _game == null) {
          return;
        }
        setState(() {});
      },
    );
  }

  void _stopRuntimeInfoTicker() {
    _runtimeInfoTicker?.cancel();
    _runtimeInfoTicker = null;
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
    await _loadProjectMapsFromManifest(path);
    await _persistLastSession();
  }

  Future<void> _load() async {
    final projectFilePath = _projectFilePath;
    final mapId = (_selectedMapId ?? '').trim();

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
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      if (!mounted) return;
      final nextGame = PlayableMapGame(
        bundle: loadedBundle,
        projectFilePath: projectFilePath,
      );
      setState(() {
        _game = nextGame;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });
      nextGame.setCollisionOverlayVisible(_showCollisionOverlay);
      nextGame
          .setNpcCollisionDebugOverlayVisible(_showNpcCollisionDebugOverlay);
      nextGame.setFpsOverlayVisible(_showFpsOverlay);
      nextGame.setSurfingEnabled(_surfingEnabled);
      _startRuntimeInfoTicker();
      await _persistLastSession();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() => setState(() {
        _stopRuntimeInfoTicker();
        _game = null;
        _error = null;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });

  Future<void> _saveGame() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return;
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final saved = await game.saveGame();
      if (!mounted) return;
      final info = game.saveLoadInfo;
      setState(() {
        _saveLoadStatus = saved
            ? 'Sauvegarde OK · ${info.mapId} (${info.playerX}, ${info.playerY})'
            : 'Sauvegarde impossible';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveLoadError = 'Erreur sauvegarde: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  Future<void> _loadGame() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return;
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final loaded = await game.loadGame();
      if (!mounted) return;
      if (loaded) {
        final info = game.saveLoadInfo;
        setState(() {
          _surfingEnabled = info.movementMode == MovementMode.surf.name;
          _saveLoadStatus =
              'Chargement OK · ${info.mapId} (${info.playerX}, ${info.playerY})';
        });
      } else {
        setState(() {
          _saveLoadError = 'Aucune sauvegarde trouvée ou chargement impossible';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveLoadError = 'Erreur chargement: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game != null) {
      final info = game.saveLoadInfo;
      return Scaffold(
        appBar: AppBar(
          title: Text((_selectedMapId ?? '').trim()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _reset,
          ),
        ),
        body: Stack(
          children: [
            GameWidget(game: game),
            Positioned(
              top: 12,
              right: 12,
              child: Card(
                color: Colors.black.withValues(alpha: 0.55),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            value: _showCollisionOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _showCollisionOverlay = v);
                                    game.setCollisionOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'FPS',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showFpsOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _showFpsOverlay = v);
                                    game.setFpsOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Surf',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _surfingEnabled,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(() => _surfingEnabled = v);
                                    game.setSurfingEnabled(v);
                                  },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'NPC hitbox',
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showNpcCollisionDebugOverlay,
                            onChanged: _saveLoadBusy
                                ? null
                                : (v) {
                                    setState(
                                      () => _showNpcCollisionDebugOverlay = v,
                                    );
                                    game.setNpcCollisionDebugOverlayVisible(v);
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Map: ${info.mapId}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Pos: (${info.playerX}, ${info.playerY})  Face: ${info.facing}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Mode: ${info.movementMode}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed: _saveLoadBusy ? null : _saveGame,
                            child: const Text('Sauvegarder'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saveLoadBusy ? null : _loadGame,
                            child: const Text('Charger'),
                          ),
                        ],
                      ),
                      if (_saveLoadStatus != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saveLoadStatus!,
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ],
                      if (_saveLoadError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _saveLoadError!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
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
            if (_availableMaps.isEmpty)
              const TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Map',
                  hintText:
                      'Chargez un project.json valide pour lister les maps',
                  border: OutlineInputBorder(),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedMapId,
                decoration: const InputDecoration(
                  labelText: 'Map',
                  border: OutlineInputBorder(),
                ),
                items: _availableMaps
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.id,
                        child: Text('${entry.name} (${entry.id})'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedMapId = value);
                        _persistLastSession();
                      },
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
