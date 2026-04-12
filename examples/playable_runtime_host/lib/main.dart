import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'src/in_game_menu.dart';
import 'src/runtime_pokedex_loader.dart';

// Point d'entrée minimal du host runtime.
// On garde un MaterialApp très simple, puis toute la navigation se fait
// depuis la page de chargement et le menu in-game.
void main() {
  runApp(const MaterialApp(
    title: 'Playable Runtime Host',
    home: _ProjectLoaderPage(),
  ));
}

// Cette page joue deux rôles très ciblés :
// 1. charger un projet et une map runtime ;
// 2. exposer les surfaces minimales de debug/save/menu utiles aux phases 9-10.
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
    // Le ticker d'overlay est strictement local au host et doit toujours être
    // arrêté quand la page sort, pour éviter toute fuite de rafraîchissement.
    _runtimeInfoTicker?.cancel();
    super.dispose();
  }

  // Les préférences locales du host ne font pas partie de la save gameplay.
  // Elles servent seulement à rouvrir rapidement le dernier projet dans l'outil
  // d'hébergement runtime.
  String _prefsFilePath() {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return _prefsFileName;
    }
    return '$home/$_prefsFileName';
  }

  // La restauration des préférences est volontairement best-effort :
  // on veut retrouver vite le dernier projet, sans jamais bloquer le chargement
  // si le fichier local est absent ou invalide.
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

  // On persiste seulement le chemin du projet et la map choisie, pas l'état
  // gameplay. La vraie sauvegarde gameplay reste dans le pipeline phase 9.
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

  // Cette lecture du manifest sert uniquement à alimenter le host :
  // on récupère la liste des maps disponibles sans toucher au save system.
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

  // Le ticker force un refresh léger de l'overlay runtime pour afficher
  // les informations de debug et de save qui évoluent pendant la session.
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

  // Le host laisse l'utilisateur choisir explicitement un project.json.
  // Cela reste séparé de toute logique de menu in-game ou de save gameplay.
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

  // Ce chargement construit uniquement le bundle runtime et l'instance de jeu.
  // Il ne modifie pas la structure métier des saves.
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
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      if (!mounted) return;
      final nextGame = PlayableMapGame(
        bundle: bundle,
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

  // Retour au chargeur de projet.
  // On ne détruit pas de données persistées, on ferme juste la session runtime.
  void _reset() => setState(() {
        _stopRuntimeInfoTicker();
        _game = null;
        _error = null;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });

  // Les boutons historiques du host réutilisent désormais le même flux que
  // l'écran "Sauvegarde" du menu in-game, pour garder une seule source de
  // vérité côté runtime.
  Future<void> _saveGame() async {
    await _performSaveRequest();
  }

  Future<void> _loadGame() async {
    await _performLoadRequest();
  }

  // Ce helper centralise la sauvegarde gameplay existante.
  // Il renvoie un résultat structuré pour que le menu in-game et l'overlay
  // historique affichent exactement le même statut utilisateur.
  Future<InGameMenuActionResult> _performSaveRequest() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return const InGameMenuActionResult(
        error: 'Sauvegarde indisponible',
      );
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final saved = await game.saveGame();
      if (!mounted) {
        return const InGameMenuActionResult();
      }
      final info = game.saveLoadInfo;
      final status = saved
          ? 'Sauvegarde OK · ${info.mapId} (${info.playerX}, ${info.playerY})'
          : 'Sauvegarde impossible';
      setState(() {
        _saveLoadStatus = status;
      });
      return InGameMenuActionResult(status: status);
    } catch (e) {
      if (!mounted) {
        return const InGameMenuActionResult();
      }
      final error = 'Erreur sauvegarde: $e';
      setState(() {
        _saveLoadError = error;
      });
      return InGameMenuActionResult(error: error);
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  // Même principe pour le chargement :
  // on garde un seul chemin d'exécution pour l'overlay runtime et le menu.
  Future<InGameMenuActionResult> _performLoadRequest() async {
    final game = _game;
    if (game == null || _saveLoadBusy) {
      return const InGameMenuActionResult(
        error: 'Chargement indisponible',
      );
    }
    setState(() {
      _saveLoadBusy = true;
      _saveLoadError = null;
      _saveLoadStatus = null;
    });
    try {
      final loaded = await game.loadGame();
      if (!mounted) return const InGameMenuActionResult();
      if (!loaded) {
        const error = 'Aucune sauvegarde trouvée ou chargement impossible';
        setState(() {
          _saveLoadError = error;
        });
        return const InGameMenuActionResult(error: error);
      }
      final info = game.saveLoadInfo;
      final status =
          'Chargement OK · ${info.mapId} (${info.playerX}, ${info.playerY})';
      setState(() {
        _surfingEnabled = info.movementMode == MovementMode.surf.name;
        _saveLoadStatus = status;
      });
      return InGameMenuActionResult(status: status);
    } catch (e) {
      if (!mounted) return const InGameMenuActionResult();
      final error = 'Erreur chargement: $e';
      setState(() {
        _saveLoadError = error;
      });
      return InGameMenuActionResult(error: error);
    } finally {
      if (mounted) {
        setState(() => _saveLoadBusy = false);
      }
    }
  }

  // Le menu phase 10 vit dans le host runtime existant, sans nouveau framework.
  // On pousse simplement une route Flutter classique au-dessus du GameWidget.
  Future<void> _openInGameMenu() async {
    final game = _game;
    if (game == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return InGameMenuPage(
            gameStateSnapshotBuilder: () => game.gameStateSnapshot,
            pokedexLoader: () => loadRuntimePokedexEntries(
              projectFilePath: _projectFilePath,
            ),
            onSaveRequested: _performSaveRequest,
            onLoadRequested: _performLoadRequest,
            onCloseRequested: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Deux états d'interface seulement :
    // 1. soit une session runtime est active et on affiche le jeu ;
    // 2. soit on reste sur le chargeur de projet.
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
          actions: [
            // Le menu in-game est volontairement minimal :
            // un seul bouton ouvre les écrans lecture seule de la phase 10.
            IconButton(
              key: const Key('runtime-menu-button'),
              icon: const Icon(Icons.menu),
              onPressed: _openInGameMenu,
            ),
          ],
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
                      Text(
                        'FPS: ${game.currentFps.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.lightGreenAccent),
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
