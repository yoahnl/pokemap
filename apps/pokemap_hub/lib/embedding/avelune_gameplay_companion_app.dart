import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart' as player_ui;
import 'package:map_runtime/map_runtime.dart';

import 'avelune_gameplay_companion.dart';

class AveluneGameplayCompanionApp extends StatefulWidget {
  const AveluneGameplayCompanionApp({super.key});

  @override
  State<AveluneGameplayCompanionApp> createState() => _AveluneGameplayCompanionAppState();
}

class _AveluneGameplayCompanionAppState extends State<AveluneGameplayCompanionApp> {
  final _remote = AveluneGameplayCompanionRemote();
  final _controllerIds = ValueNotifier<Set<String>>(const {'owner-input-relay'});
  late final _controller = _RemotePlayerController(_remote);
  String? _presentationKey;
  Future<player_ui.RuntimePlayerPresentation>? _presentation;
  String? _readySurface;

  @override
  void initState() {
    super.initState();
    unawaited(_remote.attach());
  }

  @override
  void dispose() {
    _controller.dispose();
    _remote.dispose();
    _controllerIds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _remote,
    builder: (context, _) {
      final snapshot = _remote.value;
      final configuration = snapshot?.presentation ?? const <String, Object?>{};
      final key = jsonEncode(configuration);
      if (_presentationKey != key) {
        _presentationKey = key;
        _readySurface = null;
        unawaited(_remote.surfaceReady(ready: false));
        _presentation = _resolvePresentation(configuration);
      }
      final preferences = snapshot?.player?.preferences ?? snapshot?.player?.defaultPreferences;
      final locale = Locale((preferences?.locale ?? configuration['locale'] as String? ?? 'fr').split(RegExp('[-_]')).first);
      final reducedMotion = configuration['reducedMotion'] == true;
      final base = configuration['dark'] == true
          ? player_ui.PokeMapPlayerTheme.dark(reducedMotion: reducedMotion)
          : player_ui.PokeMapPlayerTheme.light(reducedMotion: reducedMotion);
      return FutureBuilder<player_ui.RuntimePlayerPresentation>(
        future: _presentation,
        builder: (context, resolved) {
          final presentation = resolved.data;
          final resolvedReady = resolved.connectionState == ConnectionState.done && presentation != null;
          final surface = snapshot == null ? null : '${snapshot.sessionId}:$key';
          final dataReady = snapshot?.mode == AveluneGameplayCompanionMode.menu && snapshot?.player != null ||
              snapshot?.mode == AveluneGameplayCompanionMode.battle && snapshot?.battle != null;
          if (resolvedReady && dataReady && surface != null && _readySurface != surface) {
            _readySurface = surface;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _readySurface == surface && _presentationKey == key && _remote.value?.sessionId == snapshot?.sessionId) {
                unawaited(_remote.surfaceReady());
              }
            });
          }
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: player_ui.PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates: player_ui.PokeMapPlayerLocalizations.localizationsDelegates,
            theme: presentation?.applyTo(base) ?? base,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: !resolvedReady || snapshot == null
                    ? const SizedBox.expand()
                    : _surface(snapshot, presentation),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _surface(AveluneGameplayCompanionSnapshot snapshot, player_ui.RuntimePlayerPresentation presentation) {
    switch (snapshot.mode) {
      case AveluneGameplayCompanionMode.menu:
        if (snapshot.player == null) return const SizedBox.expand();
        return AbsorbPointer(
          absorbing: _remote.busy || !snapshot.companionAttached,
          child: player_ui.PokeMapPlayerSessionView(
            key: ValueKey('companion-player-${snapshot.sessionId}'),
            controller: _controller,
            titlePresentation: presentation.title,
            pauseMenuLabels: presentation.pauseMenuLabels,
            pausePresentation: presentation.pausePresentation,
            pauseRootActionsOnly: true,
            gameSceneBuilder: (_) => const SizedBox.expand(),
            touchControlsAvailable: false,
            controllerInputEnabled: true,
            controllerInputEvents: _remote.inputs,
            relayedControllerInput: true,
            connectedControllerIds: _controllerIds,
            hapticFeedback: () async {},
            beforePauseAction: () async {
              try {
                await _remote.send('pause', {'snapshotRevision': _controller.snapshot.revision});
                return _remote.value?.sessionId == snapshot.sessionId && _remote.value?.mode == AveluneGameplayCompanionMode.menu;
              } on PlatformException {
                return false;
              }
            },
            onControlProfileChanged: (profile) => _remote.send('controlProfile', profile.toJson()),
          ),
        );
      case AveluneGameplayCompanionMode.battle:
        final battle = snapshot.battle;
        if (battle == null) return const SizedBox.expand();
        return AbsorbPointer(
          absorbing: _remote.busy || !snapshot.companionAttached,
          child: player_ui.PlayerBattleOverlay(
            snapshot: battle,
            display: player_ui.PlayerBattleDisplay.commandsOnly,
            onCommand: (command) => unawaited(_sendBattle(command)),
          ),
        );
      case AveluneGameplayCompanionMode.waiting:
      case AveluneGameplayCompanionMode.blocked:
        return const SizedBox.expand();
    }
  }

  Future<void> _sendBattle(BattlePresentationCommand command) async {
    try {
      await _remote.send('battle', {
        'snapshotRevision': command.snapshotRevision,
        'expectedMode': command.expectedMode.name,
        'action': command is BattleBackCommand ? 'back' : 'select',
        if (command is BattleSelectEntryCommand) 'entryIndex': command.entryIndex,
      });
    } on PlatformException catch (error) {
      debugPrint('Avelune companion battle command: ${error.code}');
    }
  }

  Future<player_ui.RuntimePlayerPresentation> _resolvePresentation(Map<String, Object?> configuration) async {
    final profile = configuration['profile'] == null ? null : ProjectPresentationProfile.fromJson(_map(configuration['profile']));
    final files = configuration['images'] == null ? <String, dynamic>{} : _map(configuration['images']);
    final fonts = configuration['fonts'] == null ? <String, dynamic>{} : _map(configuration['fonts']);
    final requests = <ProjectTypographyRole, RuntimeProjectFontRequest>{};
    for (final entry in fonts.entries) {
      final role = ProjectTypographyRole.values.byName(entry.key);
      final font = _map(entry.value);
      final uri = font['uri'] is String ? Uri.tryParse(font['uri'] as String) : null;
      requests[role] = RuntimeProjectFontRequest(
        file: uri?.scheme == 'file' ? File.fromUri(uri!) : null,
        family: font['family'] as String?,
        fallbackFamilies: (font['fallback'] as List).cast<String>(),
      );
    }
    final typography = await const RuntimeProjectTypographyLoader().load(requests);
    RuntimeStartupPresentationAsset? asset(String key) {
      final id = configuration[key] as String?;
      return id == null ? null : RuntimeStartupPresentationAsset(assetId: id, mediaType: 'image/*');
    }
    final presentation = RuntimeStartupResolvedPresentation(
      profile: profile,
      metadata: RuntimeStartupPresentationMetadata(author: configuration['author'] as String? ?? '', description: configuration['description'] as String?),
      orientation: configuration['orientation'] == null ? RuntimePresentationOrientation.landscape : RuntimePresentationOrientation.values.byName(configuration['orientation'] as String),
      titleHero: asset('titleHero'), titleLogo: asset('titleLogo'), menuBackground: asset('menuBackground'),
      typography: typography,
    );
    return player_ui.RuntimePlayerPresentation.fromRuntime(presentation, imageForAsset: (asset) {
      final path = files[asset?.assetId];
      final uri = path is String ? Uri.tryParse(path) : null;
      return uri?.scheme == 'file' ? FileImage(File.fromUri(uri!)) : null;
    });
  }
}

class _RemotePlayerController implements player_ui.RuntimePlayerViewController, player_ui.RuntimePlayerBagFavoritesController {
  _RemotePlayerController(this.remote) {
    remote.addListener(_changed);
  }

  final AveluneGameplayCompanionRemote remote;
  final _snapshots = StreamController<RuntimePlayerSnapshot>.broadcast(sync: true);
  RuntimePlayerSnapshot? _last;

  @override
  RuntimePlayerSnapshot get snapshot => remote.value?.player ?? RuntimePlayerSnapshot(revision: 0, phase: RuntimePlayerPhase.boot, gameTitle: 'Avelune');

  @override
  Stream<RuntimePlayerSnapshot> get snapshots => _snapshots.stream;

  void _changed() {
    final next = remote.value?.player;
    if (next != null && !identical(next, _last)) {
      _last = next;
      _snapshots.add(next);
    }
  }

  @override
  Future<RuntimePlayerCommandResult> dispatch(RuntimePlayerCommand command) => _send('player', RuntimeCompanionPresentationCodec.encodePlayerCommand(command));

  @override
  Future<RuntimePlayerCommandResult> requestBack({required int snapshotRevision}) => _send('back', {'snapshotRevision': snapshotRevision});

  @override
  Future<RuntimePlayerCommandResult> setBagItemFavorite({required String itemId, required bool favorite, required int snapshotRevision}) =>
      _send('favorite', {'snapshotRevision': snapshotRevision, 'itemId': itemId, 'favorite': favorite});

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(RuntimeWorldServiceCommand command) async => const RuntimeWorldServiceCommandResult(
    status: RuntimeWorldServiceCommandStatus.unavailable,
    safeMessage: 'Ce service se contrôle sur l’écran principal.',
  );

  Future<RuntimePlayerCommandResult> _send(String kind, Map<String, Object?> payload) async {
    try {
      await remote.send(kind, payload);
      return RuntimePlayerCommandResult(status: RuntimePlayerCommandStatus.accepted, saveReceipt: remote.value?.player?.saveReceipt);
    } on PlatformException catch (error) {
      return RuntimePlayerCommandResult(
        status: switch (error.code) {
          'staleSession' || 'staleRevision' || 'staleMode' || 'stale' => RuntimePlayerCommandStatus.stale,
          'unavailable' || 'companionDetached' || 'companionUnavailable' || 'runtimeBusy' => RuntimePlayerCommandStatus.unavailable,
          'cancelled' => RuntimePlayerCommandStatus.cancelled,
          _ => RuntimePlayerCommandStatus.failed,
        },
        safeMessage: error.message,
      );
    }
  }

  void dispose() {
    remote.removeListener(_changed);
    unawaited(_snapshots.close());
  }
}

Map<String, dynamic> _map(Object? value) => RuntimeCompanionPresentationCodec.normalizeMap(value);
