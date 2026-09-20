import 'dart:io';

import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

class StudioCinematicMedia implements CinematicMediaPlaybackPort {
  StudioCinematicMedia({
    required this.projectRoot,
    required Iterable<CinematicMediaAsset> assets,
    FlameCinematicAudioDriver? audioDriver,
  }) : _assets = {for (final asset in assets) asset.id: asset} {
    _adapter = FlameCinematicMediaPlaybackAdapter(
      mediaAssets: _assets.values,
      resolvePath: (asset) =>
          _resolved[asset.id] ??
          (throw StateError('Média non résolu : ${asset.label}')),
      fx: FlameCinematicFxPlaybackAdapter(host: _UnavailableFxHost()),
      audioDriver: audioDriver,
    );
  }
  final String projectRoot;
  final Map<String, CinematicMediaAsset> _assets;
  final Map<String, String> _resolved = {};
  late final FlameCinematicMediaPlaybackAdapter _adapter;

  @override
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint() =>
      _adapter.captureCheckpoint();

  @override
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint) =>
      _adapter.restore(checkpoint);

  @override
  Future<void> execute(CinematicMediaPlaybackCommand command) async {
    if (command.kind == CinematicMediaPlaybackCommandKind.play) {
      final asset = _assets[command.assetId];
      if (asset == null) {
        throw StateError('Ce média ne figure plus dans le projet.');
      }
      final relative = path.normalize(asset.relativePath);
      if (path.isAbsolute(relative) ||
          relative == '..' ||
          relative.startsWith('../')) {
        throw StateError(
          'Le média doit rester dans le projet : ${asset.label}.',
        );
      }
      final root = await Directory(projectRoot).resolveSymbolicLinks();
      final file = File(path.join(root, relative));
      final resolved = await file.resolveSymbolicLinks();
      if (!path.isWithin(root, resolved)) {
        throw StateError('Le média sort du projet : ${asset.label}.');
      }
      _resolved[asset.id] = resolved;
    }
    await _adapter.execute(command);
  }
}

class _UnavailableFxHost implements FlameCinematicFxHost {
  @override
  void showCinematicFx(
    String assetId, {
    required double intensity,
  }) => throw StateError(
    'L’effet « $assetId » nécessite le rendu du runtime. Testez la scène pour le voir.',
  );
  @override
  void hideCinematicFx(String assetId) {}
  @override
  void clearCinematicFx() {}
}
