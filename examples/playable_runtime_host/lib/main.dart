import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gamepads/gamepads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import 'src/in_game_menu.dart';
import 'src/runtime_demo_party_seed.dart';
import 'src/runtime_gamepad_bridge.dart';
import 'src/runtime_gamepad_presence.dart';
import 'src/runtime_ios_project_picker.dart';
import 'src/runtime_battle_command_overlay_visibility.dart';
import 'src/runtime_launch_save.dart';
import 'src/runtime_launch_options.dart';
import 'src/runtime_party_builder.dart';
import 'src/runtime_pokedex_loader.dart';
import 'src/runtime_project_picker.dart';
import 'src/runtime_touch_controls.dart';
import 'src/runtime_touch_controls_visibility.dart';

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
  bool _showRuntimeDebugPanel = true;
  bool _touchControlsHiddenByUser = false;
  bool _hasConnectedGamepad = false;
  bool _surfingEnabled = false;
  bool _seedDemoPokemon = true;
  List<RuntimePartyBuilderPokemonOption> _partyBuilderOptions = const [];
  List<RuntimeDemoPartyPokemonSeed> _manualPartyMembers = const [];
  String? _partyBuilderError;
  bool _saveLoadBusy = false;
  String? _saveLoadStatus;
  String? _saveLoadError;
  Timer? _runtimeInfoTicker;
  Timer? _gamepadPresenceTimer;
  StreamSubscription<NormalizedGamepadEvent>? _runtimeGamepadSubscription;
  final RuntimeGamepadPresence _runtimeGamepadPresence =
      RuntimeGamepadPresence();

  static const _prefsFileName = '.playable_runtime_host_prefs.json';

  @override
  void initState() {
    super.initState();
    _bindGamepadInputsIfNeeded();
    _startGamepadPresenceRefreshIfNeeded();
    _restoreLastSession();
  }

  @override
  void dispose() {
    // Le ticker d'overlay est strictement local au host et doit toujours être
    // arrêté quand la page sort, pour éviter toute fuite de rafraîchissement.
    _runtimeInfoTicker?.cancel();
    _gamepadPresenceTimer?.cancel();
    _runtimeGamepadSubscription?.cancel();
    super.dispose();
  }

  bool get _supportsTouchControls =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get _prefersBattleFlutterCommandOverlay => true;

  void _syncBattleCommandOverlayPreference() {
    _game?.setBattleFlutterCommandOverlayPreferred(
      _prefersBattleFlutterCommandOverlay,
    );
  }

  void _bindGamepadInputsIfNeeded() {
    if (kIsWeb || _runtimeGamepadSubscription != null) {
      return;
    }
    final bridge = RuntimeGamepadBridge();
    _runtimeGamepadSubscription = Gamepads.normalizedEvents.listen(
      (event) {
        final game = _game;
        if (!_hasConnectedGamepad && mounted) {
          setState(() => _hasConnectedGamepad = true);
          _syncBattleCommandOverlayPreference();
        }
        if (game == null) {
          return;
        }
        final runtimeEvents = event.button != null
            ? bridge.handleButton(
                gamepadId: event.gamepadId,
                button: event.button!,
                value: event.value,
              )
            : bridge.handleAxis(
                gamepadId: event.gamepadId,
                axis: event.axis!,
                value: event.value,
              );
        for (final runtimeEvent in runtimeEvents) {
          game.handleRuntimeInputEvent(runtimeEvent);
        }
      },
      onError: (_) {},
    );
  }

  void _startGamepadPresenceRefreshIfNeeded() {
    if (!_supportsTouchControls || _gamepadPresenceTimer != null) {
      return;
    }
    _refreshConnectedGamepadState();
    _gamepadPresenceTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshConnectedGamepadState(),
    );
  }

  Future<void> _refreshConnectedGamepadState() async {
    if (!_supportsTouchControls || !mounted) {
      return;
    }
    try {
      final hasConnectedGamepad =
          await _runtimeGamepadPresence.hasConnectedGamepads();
      if (!mounted || _hasConnectedGamepad == hasConnectedGamepad) {
        return;
      }
      setState(() => _hasConnectedGamepad = hasConnectedGamepad);
      _syncBattleCommandOverlayPreference();
    } catch (_) {
      // Best-effort seulement : une erreur de détection de manette ne doit
      // jamais bloquer le host ni le runtime.
    }
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
      await _loadPartyBuilderOptions(savedProjectPath);
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

  Future<void> _loadPartyBuilderOptions(String projectFilePath) async {
    try {
      final options = await loadRuntimeHostPartyBuilderOptions(
        projectFilePath: projectFilePath,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _partyBuilderOptions = options;
        _partyBuilderError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _partyBuilderOptions = const [];
        _partyBuilderError = 'Pokemon indisponibles: $e';
      });
    }
  }

  void _addManualPartyMember(RuntimeDemoPartyPokemonSeed member) {
    if (_manualPartyMembers.length >= kRuntimeDemoMaxPartySize) {
      return;
    }
    setState(() {
      _manualPartyMembers = <RuntimeDemoPartyPokemonSeed>[
        ..._manualPartyMembers,
        member,
      ];
    });
  }

  void _removeManualPartyMember(int index) {
    if (index < 0 || index >= _manualPartyMembers.length) {
      return;
    }
    final nextMembers = List<RuntimeDemoPartyPokemonSeed>.of(
      _manualPartyMembers,
    )..removeAt(index);
    setState(() => _manualPartyMembers = List.unmodifiable(nextMembers));
  }

  RuntimeDemoPartySeed? _buildManualPartySeed() {
    if (_manualPartyMembers.isEmpty) {
      return null;
    }
    return RuntimeDemoPartySeed(
      members: List<RuntimeDemoPartyPokemonSeed>.unmodifiable(
        _manualPartyMembers.take(kRuntimeDemoMaxPartySize),
      ),
    );
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

  Future<String> _ensureProjectCopiedToDocuments(String projectJsonPath) async {
    final projectDir = Directory(p.dirname(projectJsonPath));
    final projectName = p.basename(projectDir.path);
    final docsDir = await _getProjectsDirectory();
    final targetDir = Directory(p.join(docsDir.path, projectName));
    final mapsDir = Directory(p.join(targetDir.path, 'maps'));

    await _copyDirectory(projectDir, targetDir);

    if (!await mapsDir.exists()) {
      throw Exception(
        'Le dossier maps/ est manquant après copie. '
        'Source: ${projectDir.path}, Cible: ${targetDir.path}',
      );
    }

    return p.join(targetDir.path, 'project.json');
  }

  Future<Directory> _getProjectsDirectory() async {
    if (kIsWeb) {
      return Directory('');
    }
    String docsPath;
    if (Platform.isIOS) {
      final docDir = await getApplicationDocumentsDirectory();
      docsPath = docDir.path;
    } else {
      docsPath = Platform.environment['HOME'] ?? '.';
    }
    final projectsDir = Directory(p.join(docsPath, 'playable_projects'));
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir;
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    await for (final entity in source.list(recursive: true)) {
      final relativePath = p.relative(entity.path, from: source.path);
      final newPath = p.join(target.path, relativePath);
      if (entity is File) {
        final newFile = File(newPath);
        await newFile.parent.create(recursive: true);
        await entity.copy(newPath);
      } else if (entity is Directory) {
        final newDir = Directory(newPath);
        await newDir.create(recursive: true);
      }
    }
  }

  Future<void> _pickProjectFile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = !kIsWeb && Platform.isIOS
          ? await pickRuntimeProjectDirectoryOnIos()
          : await pickRuntimeProjectDirectory(
              pickDirectoryPath: () {
                return getDirectoryPath(
                  confirmButtonText: 'Choisir',
                  initialDirectory: Platform.environment['HOME'],
                );
              },
              importProjectJsonPath: _ensureProjectCopiedToDocuments,
            );
      if (!mounted) {
        return;
      }
      if (result.didCancel) {
        return;
      }
      if (!result.didSelectProject) {
        setState(() => _error = result.errorMessage);
        return;
      }
      final projectJsonPath = result.projectJsonPath!;
      setState(() {
        _projectFilePath = projectJsonPath;
        _error = null;
        _partyBuilderOptions = const [];
        _manualPartyMembers = const [];
        _partyBuilderError = null;
      });
      await _loadProjectMapsFromManifest(projectJsonPath);
      await _loadPartyBuilderOptions(projectJsonPath);
      await _persistLastSession();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = 'Erreur projet: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Ce chargement construit uniquement le bundle runtime et l'instance de jeu.
  // Il ne modifie pas la structure métier des saves.
  Future<void> _load() async {
    final projectFilePath = _projectFilePath;
    final mapId = (_selectedMapId ?? '').trim();

    if (projectFilePath.isEmpty) {
      setState(() => _error = 'Sélectionnez un dossier projet valide.');
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
      // Phase A privilégie un vrai état joueur versionné quand le projet en
      // fournit un. Le seed de démo historique reste un fallback pratique pour
      // les projets génériques qui n'ont pas encore de save de lancement.
      final launchSaveData = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFilePath,
      );
      final manualPartySeed = _buildManualPartySeed();
      final launchDemoSeed = manualPartySeed == null
          ? await buildRuntimeHostLaunchDemoPartySeed(
              seedDemoPokemon: launchSaveData == null && _seedDemoPokemon,
              projectFilePath: projectFilePath,
            )
          : null;
      if (!mounted) return;
      final launchSaveOverride = manualPartySeed == null
          ? null
          : buildRuntimeHostLaunchDemoSaveData(
              mapId: mapId,
              seed: manualPartySeed,
            );
      final nextGame = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: launchSaveOverride ??
            launchSaveData ??
            (launchDemoSeed == null
                ? null
                : buildRuntimeHostLaunchDemoSaveData(
                    mapId: mapId,
                    seed: launchDemoSeed,
                  )),
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
      nextGame.setBattleFlutterCommandOverlayPreferred(
        _prefersBattleFlutterCommandOverlay,
      );
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

  bool _handleBattleCommandOverlayEntrySelected(
    PlayableMapGame game,
    BattleCommandOverlaySnapshot snapshot,
    int index,
  ) {
    return switch (snapshot.mode) {
      BattleCommandOverlayMode.root => game.selectBattleRootEntry(index),
      BattleCommandOverlayMode.fight ||
      BattleCommandOverlayMode.continueOnly =>
        game.selectBattleChoiceEntry(
          index,
        ),
      BattleCommandOverlayMode.bag => game.selectBattleBagEntry(index),
      BattleCommandOverlayMode.pokemon => game.selectBattlePartyEntry(index),
      BattleCommandOverlayMode.bagMedicineTarget =>
        game.selectBattleMedicineTargetEntry(index),
    };
  }

  Widget _buildBattleCommandOverlay(
    PlayableMapGame game,
    BattleCommandOverlaySnapshot snapshot,
  ) {
    return Positioned.fill(
      child: BattleMobileCommandOverlay(
        snapshot: snapshot,
        onEntrySelected: (index) {
          _handleBattleCommandOverlayEntrySelected(game, snapshot, index);
        },
        onBack: snapshot.canGoBack
            ? () {
                game.backFromBattleOverlay();
              }
            : null,
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
      final touchControlsVisibility = resolveRuntimeTouchControlsVisibility(
        supportsTouchControls: _supportsTouchControls,
        userHidden: _touchControlsHiddenByUser,
        hasConnectedGamepad: _hasConnectedGamepad,
        isBattleActive: game.isBattleUiActive,
      );
      return Scaffold(
        appBar: AppBar(
          title: Text((_selectedMapId ?? '').trim()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _reset,
          ),
          actions: [
            if (touchControlsVisibility.showToggleButton)
              IconButton(
                key: const Key('runtime-touch-controls-toggle-button'),
                tooltip: touchControlsVisibility.toggleTooltip,
                icon: Icon(
                  touchControlsVisibility.userHidden
                      ? Icons.touch_app_outlined
                      : Icons.touch_app,
                ),
                onPressed: () {
                  setState(
                    () => _touchControlsHiddenByUser =
                        !_touchControlsHiddenByUser,
                  );
                },
              ),
            IconButton(
              key: const Key('runtime-debug-panel-toggle-button'),
              tooltip: _showRuntimeDebugPanel
                  ? 'Masquer le panneau debug'
                  : 'Afficher le panneau debug',
              icon: Icon(
                _showRuntimeDebugPanel
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(
                    () => _showRuntimeDebugPanel = !_showRuntimeDebugPanel);
              },
            ),
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
            ValueListenableBuilder<BattleCommandOverlaySnapshot?>(
              valueListenable: game.battleCommandOverlayListenable,
              builder: (context, snapshot, child) {
                final showFlutterOverlay =
                    shouldShowRuntimeBattleCommandOverlay(
                  supportsTouchControls: _supportsTouchControls,
                  hasConnectedGamepad: _hasConnectedGamepad,
                  isBattleActive: game.isBattleUiActive,
                  hasSnapshot: snapshot != null,
                );
                if (!showFlutterOverlay || snapshot == null) {
                  return const SizedBox.shrink();
                }
                return _buildBattleCommandOverlay(game, snapshot);
              },
            ),
            if (touchControlsVisibility.showControls)
              Positioned.fill(
                child: RuntimeTouchControls(
                  dispatch: game.handleRuntimeInputEvent,
                ),
              ),
            if (_showRuntimeDebugPanel)
              Positioned(
                top: 12,
                right: 12,
                child: Card(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                                      game.setNpcCollisionDebugOverlayVisible(
                                          v);
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
                          style:
                              const TextStyle(color: Colors.lightGreenAccent),
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
      body: SingleChildScrollView(
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
                  hintText: 'Chargez un projet valide pour lister les maps',
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
            RuntimeDemoSeedToggle(
              value: _seedDemoPokemon,
              onChanged: _loading
                  ? null
                  : (value) => setState(() => _seedDemoPokemon = value),
            ),
            const SizedBox(height: 16),
            RuntimePartyBuilderPanel(
              options: _partyBuilderOptions,
              members: _manualPartyMembers,
              enabled: !_loading,
              onAdd: _addManualPartyMember,
              onRemove: _removeManualPartyMember,
            ),
            if (_partyBuilderError != null) ...[
              const SizedBox(height: 8),
              _ErrorBanner(message: _partyBuilderError!),
            ],
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
                path.isEmpty ? 'Aucun projet sélectionné' : path,
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
