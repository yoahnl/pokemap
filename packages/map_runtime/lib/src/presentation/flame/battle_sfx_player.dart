import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'battle_se_manifest.dart';

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
    Map<String, String> manifest = battleSeManifest,
  }) : _manifest = manifest;

  static const String _assetPrefix =
      'packages/map_runtime/assets/audio/battle/se/';

  final Map<String, String> _manifest;
  final Set<String> _reportedMisses = <String>{};
  final Set<AudioPlayer> _livePlayers = <AudioPlayer>{};
  var _disposed = false;

  void play(String seName, {required int volume, required int pitch}) {
    if (_disposed) return;
    final fileName = _manifest[seName];
    if (fileName == null) {
      if (_reportedMisses.add(seName)) {
        debugPrint('[battle-sfx] no embedded asset for "$seName"');
      }
      return;
    }
    final player = AudioPlayer()
      ..audioCache = AudioCache(prefix: '');
    _livePlayers.add(player);
    player.onPlayerComplete.first.whenComplete(() => _release(player));
    () async {
      try {
        await player.setReleaseMode(ReleaseMode.release);
        if (pitch != 100 && pitch > 0) {
          await player.setPlaybackRate(pitch / 100);
        }
        await player.play(
          AssetSource('$_assetPrefix$fileName'),
          volume: (volume.clamp(0, 100)) / 100,
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

  Future<void> _release(AudioPlayer player) async {
    if (!_livePlayers.remove(player)) return;
    try {
      await player.dispose();
    } on Object {
      // La libération d'un lecteur déjà mort n'a rien à signaler.
    }
  }

  /// Coupe et libère toutes les voix encore vivantes.
  Future<void> dispose() async {
    _disposed = true;
    final players = _livePlayers.toList();
    _livePlayers.clear();
    for (final player in players) {
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
}
