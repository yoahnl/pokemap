import 'package:flame_3d/graphics.dart';

final _spatialRendererInitialization = SpatialRendererInitialization(
  initialize: GpuBackend.initialize,
);

Future<void> initializeSpatialRenderer() =>
    _spatialRendererInitialization.initialize();

final class SpatialRendererInitialization {
  SpatialRendererInitialization({required Future<void> Function() initialize})
    : _initialize = initialize;

  final Future<void> Function() _initialize;
  Future<void>? _initialization;

  Future<void> initialize() {
    final current = _initialization;
    if (current != null) return current;
    final initialization = Future<void>.sync(_initialize)
        .catchError((Object error, StackTrace stackTrace) {
          _initialization = null;
          Error.throwWithStackTrace(error, stackTrace);
        });
    _initialization = initialization;
    return initialization;
  }
}
