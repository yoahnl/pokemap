import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'battle_se_manifest.dart';
import 'battle_recipe_sound_source_native.dart'
    if (dart.library.js_interop) 'battle_recipe_sound_source_web.dart'
    as recipe_source;
import '../../player/runtime_audio_mixer.dart';

/// Joue un son de combat nommé — BETA-BAT-014.
///
/// Les noms sont ceux des timings du catalogue RMXP (`089-Attack01`, …) et les
/// quatre sons système de la référence (`hit`, `hitplus`, `hitlow`, `down`).
/// Le volume et le pitch sont des pourcentages, comme dans la donnée RMXP :
/// 100 est la valeur neutre.
typedef BattleSfxPlayer = void Function(
  String seName, {
  required int volume,
  required int pitch,
});

/// L'implémentation de production, sur les assets embarqués du runtime.
///
/// Tir-et-oubli : chaque coup crée son lecteur et le libère à la fin, parce
/// qu'un son de combat est court et que deux coups doivent pouvoir se
/// chevaucher. Un nom absent du manifeste joue silencieusement et n'est
/// signalé qu'une fois — c'est le comportement de la référence, où un fichier
/// introuvable journalise une erreur unique sans casser l'animation.
final class FlameAudioBattleSfxPlayer {
  FlameAudioBattleSfxPlayer({
    this.maxConcurrentVoices,
    Map<String, String> manifest = battleSeManifest,
    RuntimeAudioMixer? mixer,
    AudioPlayer Function()? playerFactory,
  }) : _manifest = manifest,
       _mixer = mixer,
       _playerFactory = playerFactory ?? AudioPlayer.new;

  static const String _assetPrefix =
      'packages/map_runtime/assets/audio/battle/se/';

  final Map<String, String> _manifest;
  final RuntimeAudioMixer? _mixer;
  final AudioPlayer Function() _playerFactory;
  final Set<String> _reportedMisses = <String>{};
  final Set<AudioPlayer> _livePlayers = <AudioPlayer>{};
  final Set<BattlePreparedRecipeSound> _recipeSounds = {};
  static const _maxRecipeSounds = 8;
  static const _maxRecipeSoundBytes = 8 * 1024 * 1024;
  int? maxConcurrentVoices;
  bool get _atVoiceLimit =>
      maxConcurrentVoices != null &&
      _livePlayers.length >= maxConcurrentVoices!;
  var _disposed = false;

  /// BETA-BAT-018 : un cache d'assets PARTAGÉ entre tous les lecteurs.
  ///
  /// Chaque `play` créait son AudioCache : le fichier était re-préparé à
  /// chaque coup et une préchauffe n'aurait profité à personne. Le cache
  /// partagé rend la préchauffe effective et les lectures suivantes chaudes.
  static final AudioCache _sharedAssetCache = AudioCache(prefix: '');

  /// Prépare les sons nommés AVANT le premier coup — appelé sous le noir de
  /// la pré-transition. Best-effort : un échec laisse le chemin paresseux
  /// existant faire son travail, en silence.
  Future<void> precache(Iterable<String> seNames) async {
    if (_disposed) return;
    final assetPaths = seNames
        .map((seName) => _manifest[seName])
        .whereType<String>()
        .map((fileName) => '$_assetPrefix$fileName')
        .toSet()
        .toList(growable: false);
    if (assetPaths.isEmpty) return;
    try {
      await _sharedAssetCache.loadAll(assetPaths);
    } on Object catch (error) {
      debugPrint('[battle-sfx] precache failed: $error');
    }
  }

  void play(String seName, {required int volume, required int pitch}) {
    if (_disposed || _atVoiceLimit) return;
    final fileName = _manifest[seName];
    if (fileName == null) {
      if (_reportedMisses.add(seName)) {
        debugPrint('[battle-sfx] no embedded asset for "$seName"');
      }
      return;
    }
    final player = _playerFactory()..audioCache = _sharedAssetCache;
    _livePlayers.add(player);
    player.onPlayerComplete.first.then<void>(
      (_) => _release(player),
      onError: (Object error, StackTrace stackTrace) => _release(player),
    );
    () async {
      try {
        await player.setReleaseMode(ReleaseMode.release);
        if (pitch != 100 && pitch > 0) {
          await player.setPlaybackRate(pitch / 100);
        }
        final sourceVolume = volume.clamp(0, 100) / 100;
        await _register(player, sourceVolume);
        if (_disposed || !_livePlayers.contains(player)) return;
        await player.play(
          AssetSource('$_assetPrefix$fileName'),
          volume: _volume(sourceVolume),
        );
      } on Object catch (error) {
        // Un échec de lecture ne doit jamais casser le tour : la référence
        // joue l'animation en silence dans ce cas.
        if (_reportedMisses.add(seName)) {
          debugPrint('[battle-sfx] playback failed for "$seName": $error');
        }
        await _release(player);
      }
    }();
  }

  /// Joue un fichier audio du PROJET, tir-et-oubli — BETA-BAT-016.
  ///
  /// Le son de début de combat est un chemin projet, pas un asset embarqué :
  /// même cycle de vie que les sons nommés, même tolérance aux échecs.
  void playProjectFile(String absolutePath) {
    if (_disposed || _atVoiceLimit) return;
    final player = _playerFactory()..audioCache = AudioCache(prefix: '');
    _livePlayers.add(player);
    player.onPlayerComplete.first.then<void>(
      (_) => _release(player),
      onError: (Object error, StackTrace stackTrace) => _release(player),
    );
    () async {
      try {
        await player.setReleaseMode(ReleaseMode.release);
        await _register(player, 1);
        if (_disposed || !_livePlayers.contains(player)) return;
        await player.play(DeviceFileSource(absolutePath), volume: _volume(1));
      } on Object catch (error) {
        if (_reportedMisses.add(absolutePath)) {
          debugPrint(
            '[battle-sfx] project file playback failed "$absolutePath": '
            '$error',
          );
        }
        await _release(player);
      }
    }();
  }

  Future<BattlePreparedRecipeSound> prepareRecipeSound(
    Uint8List bytes,
    String mediaType,
  ) async => beginRecipeSound(bytes, mediaType).ready;

  BattleRecipeSoundPreparation beginRecipeSound(
    Uint8List bytes,
    String mediaType,
  ) {
    if (_disposed ||
        _atVoiceLimit ||
        _recipeSounds.length >= _maxRecipeSounds) {
      throw StateError('Battle sound player cannot prepare another voice');
    }
    if (bytes.isEmpty ||
        bytes.length > _maxRecipeSoundBytes ||
        !const {'audio/wav', 'audio/ogg', 'audio/mpeg'}.contains(mediaType)) {
      throw const FormatException('Invalid recipe sound');
    }
    final snapshot = Uint8List.fromList(bytes).asUnmodifiableView();
    final player = _playerFactory();
    _livePlayers.add(player);
    final sound = BattlePreparedRecipeSound._(this, player);
    _recipeSounds.add(sound);
    player.onPlayerComplete.first
        .then<void>(
          (_) => sound._completeNaturally(),
          onError: (Object error, StackTrace stackTrace) => sound.dispose(),
        )
        .catchError((Object error) {
          debugPrint('[battle-sfx] recipe sound cleanup failed: $error');
        });
    sound._preparation = sound._prepare(snapshot, mediaType);
    return BattleRecipeSoundPreparation._(sound);
  }

  Future<void> _release(AudioPlayer player) async {
    if (!_livePlayers.remove(player)) return;
    _mixer?.unregister(player);
    try {
      await player.dispose();
    } on Object {
      // La libération d'un lecteur déjà mort n'a rien à signaler.
    }
  }

  /// Coupe et libère toutes les voix encore vivantes.
  Future<void> dispose() async {
    _disposed = true;
    for (final sound in _recipeSounds.toList()) {
      await sound.dispose();
    }
    final players = _livePlayers.toList();
    _livePlayers.clear();
    for (final player in players) {
      _mixer?.unregister(player);
      try {
        await player.stop();
        await player.dispose();
      } on Object {
        // Idem : rien à faire d'un lecteur déjà libéré.
      }
    }
  }

  @visibleForTesting
  int get livePlayerCount => _livePlayers.length;

  double _volume(double sourceVolume) =>
      _mixer?.mix.volumeFor(
        RuntimeAudioRoute.battleEffects,
        sourceVolume: sourceVolume,
      ) ??
      sourceVolume;

  Future<void> _register(AudioPlayer player, double sourceVolume) async {
    if (_disposed || !_livePlayers.contains(player)) return;
    await _mixer?.register(
      channel: player,
      route: RuntimeAudioRoute.battleEffects,
      sourceVolume: sourceVolume,
      setVolume: player.setVolume,
      applyImmediately: false,
    );
  }
}

final class BattleRecipeSoundPreparation {
  BattleRecipeSoundPreparation._(this._sound) : ready = _awaitReady(_sound) {
    unawaited(ready.then<void>((_) {}, onError: (Object _) {}));
  }

  final BattlePreparedRecipeSound _sound;
  final Future<BattlePreparedRecipeSound> ready;

  static Future<BattlePreparedRecipeSound> _awaitReady(
    BattlePreparedRecipeSound sound,
  ) async {
    try {
      await sound._preparation;
      return sound;
    } catch (_) {
      await sound.dispose();
      rethrow;
    }
  }

  Future<void> cancel() => _sound.dispose();
}

final class BattlePreparedRecipeSound {
  BattlePreparedRecipeSound._(this._owner, this._player);

  final FlameAudioBattleSfxPlayer _owner;
  final AudioPlayer _player;
  final Completer<void> _cancelSignal = Completer<void>();
  late final Future<void> _preparation;
  recipe_source.BattleRecipeSoundSource? _source;
  Future<void>? _starting;
  Future<void>? _disposal;
  bool _cancelled = false;
  bool _started = false;
  bool _completedNaturally = false;
  final Completer<void> _finished = Completer<void>();

  bool get completedNaturally => _completedNaturally;
  Future<void> get finished => _finished.future;

  Future<void> _completeNaturally() {
    if (!_cancelled && _started) _completedNaturally = true;
    return dispose();
  }

  void _checkActive() {
    if (_cancelled || _owner._disposed) {
      throw StateError('Battle recipe sound was cancelled');
    }
  }

  Future<void> _prepare(Uint8List bytes, String mediaType) async {
    _source = await recipe_source.BattleRecipeSoundSource.create(
      bytes,
      mediaType,
    );
    _checkActive();
    await _waitForPlayer(_player.setReleaseMode(ReleaseMode.release));
    _checkActive();
    await _waitForPlayer(_player.setSource(_source!.source));
    _checkActive();
  }

  Future<void> start() {
    if (_cancelled || _owner._disposed || _started) {
      return Future.error(StateError('Battle recipe sound cannot be started'));
    }
    _started = true;
    final starting = _start();
    _starting = starting;
    return starting.catchError((Object error, StackTrace stackTrace) async {
      await dispose();
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> _start() async {
    await _waitForPlayer(_owner._register(_player, 1));
    _checkActive();
    await _waitForPlayer(_player.setVolume(_owner._volume(1)));
    _checkActive();
    await _waitForPlayer(_player.resume());
  }

  Future<void> dispose() {
    final existing = _disposal;
    if (existing != null) return existing;
    _cancelled = true;
    _finished.complete();
    _cancelSignal.complete();
    return _disposal = _dispose();
  }

  Future<void> _waitForPlayer(Future<void> operation) => Future.any([
    operation,
    _cancelSignal.future.then((_) {
      throw StateError('Battle recipe sound was cancelled');
    }),
  ]);

  Future<void> _dispose() async {
    await _settle(_preparation);
    await _settle(_starting);
    _owner._mixer?.unregister(_player);
    await _settle(Future.sync(_player.stop));
    await _settle(Future.sync(_player.dispose));
    try {
      await _source?.dispose();
    } finally {
      _owner._recipeSounds.remove(this);
      _owner._livePlayers.remove(_player);
    }
  }

  Future<void> _settle(Future<void>? future) async {
    await future?.then<void>((_) {}, onError: (Object _) {});
  }
}
