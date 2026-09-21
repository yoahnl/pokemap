import 'package:flutter/foundation.dart';
import '../../../features/presentations/application/presentation_preview_transport.dart';

class PresentationTransportListenable implements Listenable {
  const PresentationTransportListenable(this.transport);
  final PresentationPreviewTransport transport;
  @override
  void addListener(VoidCallback listener) => transport.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      transport.removeListener(listener);
}
