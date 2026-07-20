import 'package:map_core/map_core.dart';

abstract interface class FlameCinematicFxHost {
  void showCinematicFx(String assetId, {required double intensity});
  void hideCinematicFx(String assetId);
  void clearCinematicFx();
}

final class FlameCinematicFxPlaybackAdapter {
  FlameCinematicFxPlaybackAdapter({required this.host});

  final FlameCinematicFxHost host;
  final Map<String, double> _activeFx = {};

  Set<String> get activeFxIds => Set.unmodifiable(_activeFx.keys);

  Future<void> execute(CinematicMediaPlaybackCommand command) async {
    switch (command.kind) {
      case CinematicMediaPlaybackCommandKind.spawnFx:
        final assetId = command.assetId;
        if (assetId == null) throw StateError('FX command has no asset.');
        final intensity = command.intensity ?? 0.5;
        _activeFx[assetId] = intensity;
        host.showCinematicFx(assetId, intensity: intensity);
      case CinematicMediaPlaybackCommandKind.cancelFx:
        final assetId = command.assetId;
        if (assetId == null) return;
        _activeFx.remove(assetId);
        host.hideCinematicFx(assetId);
      case CinematicMediaPlaybackCommandKind.restore:
        restore(const {});
      case CinematicMediaPlaybackCommandKind.play:
      case CinematicMediaPlaybackCommandKind.stopChannel:
      case CinematicMediaPlaybackCommandKind.fadeChannel:
        return;
    }
  }

  void restore(Set<String> activeFxIds) {
    host.clearCinematicFx();
    _activeFx.clear();
    for (final assetId in activeFxIds) {
      _activeFx[assetId] = 0.5;
      host.showCinematicFx(assetId, intensity: 0.5);
    }
  }
}
