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
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'src/in_game_menu.dart';
import 'src/in_game_heal_flow.dart';
import 'src/in_game_pc_page.dart';
import 'src/in_game_shop_page.dart';
import 'src/bundled_runtime_project.dart';
import 'src/evaluation/interactive/interactive_evaluation_bridge.dart';
import 'src/evaluation/interactive/interactive_evaluation_config.dart';
import 'src/evaluation/interactive/player_service_automation_port.dart';
import 'src/runtime_demo_party_seed.dart';
import 'src/runtime_gamepad_bridge.dart';
import 'src/runtime_gamepad_presence.dart';
import 'src/runtime_ios_project_picker.dart';
import 'src/runtime_battle_command_overlay_visibility.dart';
import 'src/runtime_launch_save.dart';
import 'src/runtime_launch_options.dart';
import 'src/runtime_party_builder.dart';
import 'src/runtime_player_options.dart';
import 'src/runtime_pokedex_loader.dart';
import 'src/runtime_project_picker.dart';
import 'src/runtime_project_launch_map.dart';
import 'src/runtime_projects_directory.dart';
import 'src/runtime_touch_controls.dart';
import 'src/runtime_touch_controls_visibility.dart';

void _runtimeHostLog(String message) {
  debugPrint('[runtime_host] $message');
}

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
  List<ShopDefinition> _availableShops = const [];
  ProjectManifest? _projectManifest;
  String? _selectedMapId;
  PlayableMapGame? _game;
  String? _error;
  bool _loading = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showFpsOverlay = false;
  bool _showRuntimeDebugPanel = true;
  bool _touchControlsHiddenByUser = false;
  RuntimePlayerOptions _playerOptions = const RuntimePlayerOptions();
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
  late final PlayerServiceAutomationPort? _playerServiceAutomationPort =
      interactiveEvaluationConfig.enabled
          ? PlayerServiceAutomationPort()
          : null;
  InteractiveEvaluationBridge? _interactiveBridge;

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
    unawaited(_disposeInteractiveBridge());
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
    if (interactiveEvaluationConfig.enabled) {
      await _restoreInteractiveEvaluationProject();
      return;
    }
    try {
      final file = File(_prefsFilePath());
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final restoredOptions = RuntimePlayerOptions.fromJson(
            decoded['playerOptions'],
          );
          if (mounted) {
            setState(() {
              _playerOptions = restoredOptions;
              _touchControlsHiddenByUser = !restoredOptions.showTouchControls;
            });
          }
          final savedProjectPath =
              (decoded['projectFilePath'] as String?)?.trim();
          final savedMapId = (decoded['mapId'] as String?)?.trim();
          if (savedProjectPath != null &&
              savedProjectPath.isNotEmpty &&
              await File(savedProjectPath).exists() &&
              mounted) {
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
            return;
          }
        }
      }
    } catch (_) {
      // Restauration best-effort: on ignore silencieusement les prefs invalides.
    }
    await _restoreBundledProject();
  }

  Future<void> _restoreInteractiveEvaluationProject() async {
    final relativeProjectFile = interactiveEvaluationConfig.projectFile!;
    final projectFile = await _findInteractiveProjectFile(relativeProjectFile);
    if (projectFile == null || !mounted) {
      _runtimeHostLog(
        'interactive project not found relativePath=$relativeProjectFile',
      );
      if (mounted) {
        setState(() {
          _error = 'Projet interactif introuvable : $relativeProjectFile';
        });
      }
      return;
    }
    _runtimeHostLog('interactive project resolved path=${projectFile.path}');
    setState(() {
      _projectFilePath = projectFile.path;
      _selectedMapId = null;
    });
    await _loadProjectMapsFromManifest(projectFile.path);
    await _loadPartyBuilderOptions(projectFile.path);
    if (!mounted || _selectedMapId == null) return;
    await _load();
  }

  Future<File?> _findInteractiveProjectFile(String relativePath) async {
    final visited = <String>{};
    final seeds = <Directory>[
      Directory.current.absolute,
      File(Platform.resolvedExecutable).parent.absolute,
    ];
    for (final seed in seeds) {
      var candidate = seed;
      while (visited.add(candidate.path)) {
        final projectFile = File('${candidate.path}/$relativePath');
        if (await projectFile.exists()) return projectFile.absolute;
        final parent = candidate.parent;
        if (parent.path == candidate.path) break;
        candidate = parent;
      }
    }
    return null;
  }

  Future<void> _restoreBundledProject() async {
    final bundledProject = await const BundledRuntimeProject().resolve();
    if (bundledProject == null || !mounted) return;
    _runtimeHostLog('bundled project resolved path=$bundledProject');
    setState(() {
      _projectFilePath = bundledProject;
      _selectedMapId = null;
    });
    await _loadProjectMapsFromManifest(bundledProject);
    await _loadPartyBuilderOptions(bundledProject);
  }

  // Host session and presentation options remain local preferences, never
  // gameplay state. The versioned gameplay save stays in its own pipeline.
  Future<void> _persistLastSession() async {
    if (interactiveEvaluationConfig.enabled) return;
    try {
      final file = File(_prefsFilePath());
      final payload = <String, dynamic>{
        'projectFilePath': _projectFilePath,
        'mapId': _selectedMapId,
        'playerOptions': _playerOptions.toJson(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Persistance best-effort: ne bloque jamais le flux utilisateur.
    }
  }

  // Cette lecture alimente le host et résout la map de lancement : une vraie
  // save versionnée, puis New Game, puis seulement les préférences legacy.
  Future<void> _loadProjectMapsFromManifest(
    String projectFilePath, {
    String? preferredMapId,
  }) async {
    _runtimeHostLog('manifest read start projectFilePath=$projectFilePath');
    try {
      final raw = await File(projectFilePath).readAsString();
      _runtimeHostLog('manifest read ok bytes=${raw.length}');
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _runtimeHostLog(
          'manifest read ignored rootType=${decoded.runtimeType}',
        );
        if (!mounted) return;
        setState(() {
          _availableMaps = const [];
          _availableShops = const [];
          _projectManifest = null;
        });
        return;
      }
      final manifest = ProjectManifest.fromJson(decoded);
      _runtimeHostLog(
        'manifest parsed maps=${manifest.maps.length} tilesets=${manifest.tilesets.length} scenarios=${manifest.scenarios.length}',
      );
      final versionedLaunchSave = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFilePath,
      );
      final selection = resolveRuntimeHostProjectMapSelection(
        manifest,
        versionedLaunchMapId: versionedLaunchSave?.currentMapId,
        preferredMapId: preferredMapId,
      );
      final maps = selection.maps;
      final nextSelected = selection.selectedMapId;
      if (!mounted) return;
      setState(() {
        _availableMaps = maps;
        _availableShops = manifest.shops;
        _projectManifest = manifest;
        _selectedMapId = nextSelected;
      });
      _runtimeHostLog(
        'manifest maps ready selectedMapId=$nextSelected availableMapIds=${maps.map((m) => m.id).join(',')}',
      );
    } catch (e, stackTrace) {
      _runtimeHostLog(
        'manifest read failed projectFilePath=$projectFilePath error=$e',
      );
      debugPrintStack(
        label: '[runtime_host] manifest read stack',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _availableMaps = const [];
        _availableShops = const [];
        _projectManifest = null;
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
    final docsDir = await _getProjectsDirectory();
    return importRuntimeProjectToRuntimeProjectsDirectory(
      projectJsonPath: projectJsonPath,
      projectsDirectory: docsDir,
    );
  }

  Future<Directory> _getProjectsDirectory() async {
    if (kIsWeb) {
      return Directory('');
    }
    return ensureRuntimeProjectsDirectory(
      getDocumentsDirectory: getApplicationDocumentsDirectory,
    );
  }

  Future<void> _pickProjectFile() async {
    _runtimeHostLog('project picker start');
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
        _runtimeHostLog('project picker result ignored: widget unmounted');
        return;
      }
      if (result.didCancel) {
        _runtimeHostLog('project picker cancelled');
        return;
      }
      if (!result.didSelectProject) {
        _runtimeHostLog('project picker failed message=${result.errorMessage}');
        setState(() => _error = result.errorMessage);
        return;
      }
      final projectJsonPath = result.projectJsonPath!;
      _runtimeHostLog(
          'project picker selected projectJsonPath=$projectJsonPath');
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
      _runtimeHostLog(
          'project picker completed projectJsonPath=$_projectFilePath');
    } catch (e, stackTrace) {
      _runtimeHostLog('project picker exception error=$e');
      debugPrintStack(
        label: '[runtime_host] project picker stack',
        stackTrace: stackTrace,
      );
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
    final selectedMapId = (_selectedMapId ?? '').trim();
    var mapId = selectedMapId;

    if (projectFilePath.isEmpty) {
      _runtimeHostLog('map load blocked: empty projectFilePath');
      setState(() => _error = 'Sélectionnez un dossier projet valide.');
      return;
    }
    if (selectedMapId.isEmpty) {
      _runtimeHostLog(
          'map load blocked: empty mapId projectFilePath=$projectFilePath');
      setState(() => _error = 'Saisissez un identifiant de map.');
      return;
    }

    _runtimeHostLog(
      'map load start projectFilePath=$projectFilePath mapId=$mapId',
    );
    await _disposeInteractiveBridge();
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _game = null;
    });

    try {
      // A versioned launch save is gameplay state, unlike host preferences.
      // Resolve it before the bundle so PlayableMapGame receives the map that
      // actually owns the restored position/state.
      _runtimeHostLog('launch save load start');
      final launchSaveData = await loadRuntimeHostLaunchSaveData(
        projectFilePath: projectFilePath,
      );
      final restoredMapId = launchSaveData?.currentMapId.trim();
      if (restoredMapId != null && restoredMapId.isNotEmpty) {
        mapId = restoredMapId;
      }
      _runtimeHostLog(
        'launch save load ${launchSaveData == null ? 'missing: will use project/legacy fallback' : 'ok: mapId=$mapId'}',
      );
      _runtimeHostLog('bundle load start mapId=$mapId');
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: mapId,
      );
      _runtimeHostLog(
        'bundle load ok map=${bundle.map.id} size=${bundle.map.size.width}x${bundle.map.size.height} layers=${bundle.map.layers.length} entities=${bundle.map.entities.length} tilesets=${bundle.tilesetAbsolutePathsById.length}',
      );
      // Phase A privilégie un vrai état joueur versionné quand le projet en
      // fournit un. Le seed de démo historique reste un fallback pratique pour
      // les projets génériques qui n'ont pas encore de save de lancement.
      final allowsSyntheticLaunchSeed = allowsRuntimeHostSyntheticLaunchSeed(
        newGame: bundle.manifest.newGame,
        versionedLaunchSave: launchSaveData,
      );
      final selectedManualPartySeed =
          allowsSyntheticLaunchSeed ? _buildManualPartySeed() : null;
      _runtimeHostLog(
        'party seed source=${selectedManualPartySeed == null ? 'auto/demo' : 'manual'} seedDemoPokemon=$_seedDemoPokemon syntheticAllowed=$allowsSyntheticLaunchSeed',
      );
      final launchDemoSeed =
          selectedManualPartySeed == null && allowsSyntheticLaunchSeed
              ? await buildRuntimeHostLaunchDemoPartySeed(
                  seedDemoPokemon: _seedDemoPokemon,
                  projectFilePath: projectFilePath,
                )
              : null;
      if (!mounted) return;
      final launchSaveOverride = selectedManualPartySeed == null
          ? null
          : buildRuntimeHostLaunchDemoSaveData(
              mapId: mapId,
              seed: selectedManualPartySeed,
            );
      final demoLaunchFallback = launchDemoSeed == null
          ? null
          : buildRuntimeHostLaunchDemoSaveData(
              mapId: mapId,
              seed: launchDemoSeed,
            );
      final launchPlan = resolveRuntimeHostLaunchPlan(
        newGame: bundle.manifest.newGame,
        versionedLaunchSave: launchSaveData,
        manualLaunchOverride: launchSaveOverride,
        demoLaunchFallback: demoLaunchFallback,
      );
      final nextGame = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: launchPlan.saveData,
        initialMapActivationReason: launchPlan.initialMapActivationReason,
      );
      nextGame.setPlayerServiceRuntimeController(
        PlayerServiceRuntimeController(
          currentGameState: () => nextGame.playerServiceGameStateSnapshot,
          host: _RuntimePlayerServiceOverlayHost(
            contextBuilder: () => context,
            isMounted: () => mounted,
            automationPort: _playerServiceAutomationPort,
          ),
          commitAndSave: nextGame.commitAndSavePlayerServiceState,
          setInputLocked: (locked) => nextGame.setExternalInputLock(
            RuntimeExternalInputLock.playerService,
            locked: locked,
          ),
          loadRecoveryCaps: (state) => loadRuntimePlayerServiceRecoveryCaps(
            gameState: state,
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
          ),
          conditionContext: ScriptEvaluationContext(
            narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
              bundle.manifest.facts,
            ),
          ),
        ),
      );
      _runtimeHostLog('game instance created mapId=$mapId');
      setState(() {
        _game = nextGame;
        _saveLoadStatus = null;
        _saveLoadError = null;
      });
      // Interactive evaluation never enables the expensive collision layers.
      nextGame.setCollisionOverlayVisible(
        interactiveEvaluationConfig.enabled ? false : _showCollisionOverlay,
      );
      nextGame.setNpcCollisionDebugOverlayVisible(
        interactiveEvaluationConfig.enabled
            ? false
            : _showNpcCollisionDebugOverlay,
      );
      nextGame.setFpsOverlayVisible(_showFpsOverlay);
      nextGame.setSurfingEnabled(_surfingEnabled);
      nextGame.setBattleFlutterCommandOverlayPreferred(
        _prefersBattleFlutterCommandOverlay,
      );
      nextGame.setDialogueTextSpeed(_playerOptions.dialogueTextSpeed);
      if (interactiveEvaluationConfig.enabled) {
        await WidgetsBinding.instance.endOfFrame;
        await nextGame.loaded.timeout(const Duration(seconds: 60));
        if (!mounted || !identical(_game, nextGame)) return;
        _interactiveBridge = await InteractiveEvaluationBridge.attach(
          config: interactiveEvaluationConfig,
          game: nextGame,
          project: bundle.manifest,
          projectRoot: Directory(bundle.projectRootDirectory),
          services: _playerServiceAutomationPort!,
        );
      }
      _startRuntimeInfoTicker();
      await _persistLastSession();
      _runtimeHostLog('map load completed mapId=$mapId');
    } catch (e, stackTrace) {
      _runtimeHostLog('map load failed mapId=$mapId error=$e');
      debugPrintStack(
        label: '[runtime_host] map load stack',
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
      _runtimeHostLog('map load finished loading=false mapId=$mapId');
    }
  }

  // Retour au chargeur de projet.
  // On ne détruit pas de données persistées, on ferme juste la session runtime.
  Future<void> _reset() async {
    await _disposeInteractiveBridge();
    if (!mounted) return;
    setState(() {
      _stopRuntimeInfoTicker();
      _game = null;
      _error = null;
      _saveLoadStatus = null;
      _saveLoadError = null;
    });
  }

  Future<void> _disposeInteractiveBridge() async {
    final bridge = _interactiveBridge;
    _interactiveBridge = null;
    await bridge?.dispose();
  }

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
    await runWithRuntimePauseMenuInputLock(
      setExternalInputLock: game.setExternalInputLock,
      openMenu: () async {
        final manifest = _projectManifest;
        var recoveryCaps = const RuntimePlayerServiceRecoveryCaps(
          maxHpByPartyIndex: <int, int>{},
        );
        if (manifest != null) {
          try {
            recoveryCaps = await loadRuntimePlayerServiceRecoveryCaps(
              gameState: game.gameStateSnapshot,
              projectRootDirectory: File(_projectFilePath).parent.path,
              pokemonConfig: manifest.pokemon,
            );
          } catch (error) {
            _runtimeHostLog('player service recovery caps failed: $error');
          }
        }
        if (!mounted) return;
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (routeContext) {
              return InGameMenuPage(
                gameStateSnapshotBuilder: () => game.gameStateSnapshot,
                pokedexLoader: () => loadRuntimePokedexEntries(
                  projectFilePath: _projectFilePath,
                ),
                onSaveRequested: _performSaveRequest,
                onLoadRequested: _performLoadRequest,
                playerOptions: _playerOptions,
                projectMaps: _availableMaps,
                shops: _availableShops,
                recoveryCaps: recoveryCaps,
                onPlayerStateCommitted: game.commitAndSavePlayerServiceState,
                supportsTouchControls: _supportsTouchControls,
                onOptionsChanged: _updatePlayerOptions,
                onQuitRequested: () {
                  Navigator.of(routeContext).pop();
                  _reset();
                },
                onCloseRequested: () => Navigator.of(routeContext).pop(),
              );
            },
          ),
        );
      },
    );
  }

  void _updatePlayerOptions(RuntimePlayerOptions options) {
    if (!mounted) {
      return;
    }
    setState(() {
      _playerOptions = options;
      _touchControlsHiddenByUser = !options.showTouchControls;
    });
    _game?.setDialogueTextSpeed(options.dialogueTextSpeed);
    unawaited(_persistLastSession());
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
                  setState(() {
                    _touchControlsHiddenByUser = !_touchControlsHiddenByUser;
                    _playerOptions = _playerOptions.copyWith(
                      showTouchControls: !_touchControlsHiddenByUser,
                    );
                  });
                  unawaited(_persistLastSession());
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

final class _RuntimePlayerServiceOverlayHost
    implements PlayerServiceOverlayHost {
  const _RuntimePlayerServiceOverlayHost({
    required this.contextBuilder,
    required this.isMounted,
    required this.automationPort,
  });

  final BuildContext Function() contextBuilder;
  final bool Function() isMounted;
  final PlayerServiceAutomationPort? automationPort;

  @override
  Future<PlayerServiceHostResult> openShop(
    PlayerServiceShopRequest request,
  ) {
    return _open(
      title: request.resolvedState.storefrontLabel,
      gameState: request.gameState,
      bodyBuilder: (state, stageState, currentState, close) => InGameShopPage(
        gameState: state,
        shops: <ShopDefinition>[request.shop],
        onStateCommitted: stageState,
        currentGameState: currentState,
        conditionContext: request.conditionContext,
        automationPort: automationPort,
        onAutomationClose: close,
      ),
    );
  }

  @override
  Future<PlayerServiceHostResult> openPc(PlayerServicePcRequest request) {
    return _open(
      title: 'PC Pokémon',
      gameState: request.gameState,
      bodyBuilder: (state, stageState, _, close) => InGamePcPage(
        gameState: state,
        onStateCommitted: stageState,
        automationPort: automationPort,
        onAutomationClose: close,
      ),
    );
  }

  @override
  Future<PlayerServiceHostResult> openHealCenter(
    PlayerServiceHealRequest request,
  ) =>
      _open(
        title: 'Centre Pokémon',
        gameState: request.gameState,
        bodyBuilder: (state, stageState, _, close) => InGameHealFlow(
          gameState: state,
          recoveryCaps: request.recoveryCaps,
          onStateCommitted: stageState,
          automationPort: automationPort,
          onAutomationClose: close,
        ),
      );

  Future<PlayerServiceHostResult> _open({
    required String title,
    required GameState gameState,
    required _PlayerServiceBodyBuilder bodyBuilder,
  }) async {
    if (!isMounted()) {
      throw StateError('The runtime host is no longer mounted.');
    }
    final result = await Navigator.of(contextBuilder()).push<GameState>(
      MaterialPageRoute<GameState>(
        builder: (_) => _RuntimePlayerServiceRoute(
          title: title,
          initialGameState: gameState,
          bodyBuilder: bodyBuilder,
        ),
      ),
    );
    return result == null
        ? const PlayerServiceHostResult.cancelled()
        : PlayerServiceHostResult.completed(result);
  }
}

typedef _PlayerServiceBodyBuilder = Widget Function(
  GameState gameState,
  Future<void> Function(GameState state) stageState,
  GameState Function() currentGameState,
  Future<void> Function() close,
);

final class _RuntimePlayerServiceRoute extends StatefulWidget {
  const _RuntimePlayerServiceRoute({
    required this.title,
    required this.initialGameState,
    required this.bodyBuilder,
  });

  final String title;
  final GameState initialGameState;
  final _PlayerServiceBodyBuilder bodyBuilder;

  @override
  State<_RuntimePlayerServiceRoute> createState() =>
      _RuntimePlayerServiceRouteState();
}

final class _RuntimePlayerServiceRouteState
    extends State<_RuntimePlayerServiceRoute> {
  late GameState _gameState = widget.initialGameState;

  Future<void> _stageState(GameState state) async {
    if (!mounted) return;
    setState(() => _gameState = state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: widget.bodyBuilder(
              _gameState,
              _stageState,
              () => _gameState,
              () async {
                if (!mounted) return;
                Navigator.of(context).pop(_gameState);
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('player-service-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    key: const Key('player-service-complete'),
                    onPressed: () => Navigator.of(context).pop(_gameState),
                    child: const Text('Terminer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
