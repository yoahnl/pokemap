import 'package:avelune_render_contracts/avelune_render_contracts.dart';
import 'package:map_runtime/map_runtime.dart';

final class FakeDoorRenderer
    implements DestinationRenderPort<RuntimeMapBundle> {
  FakeDoorRenderer({this.prepare, this.frame});

  final Future<Object?> Function(
    RuntimeMapBundle destination,
    bool Function() isCurrent,
  )?
  prepare;
  final Future<void> Function(int request)? frame;
  int preparations = 0;
  int frameRequests = 0;

  @override
  Future<DestinationReadiness> prepareDestination(
    RuntimeMapBundle destination,
    bool Function() isCurrent,
  ) async {
    preparations++;
    try {
      final readiness = await prepare?.call(destination, isCurrent);
      return readiness is DestinationReadiness
          ? readiness
          : const DestinationPrepared();
    } on Object catch (error, stackTrace) {
      return DestinationPreparationFailed(error, stackTrace);
    }
  }

  @override
  Future<FrameAcknowledgement> nextFrame() async {
    final request = ++frameRequests;
    await frame?.call(request);
    return FrameAcknowledgement.flutterFrameSubmitted;
  }
}
