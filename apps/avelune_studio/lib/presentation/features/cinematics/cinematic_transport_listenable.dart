import 'package:flutter/foundation.dart';

import '../../../features/cinematics/application/cinematic_preview_transport.dart';

class CinematicTransportListenable implements Listenable {
  const CinematicTransportListenable(this.transport);
  final CinematicPreviewTransport transport;

  @override
  void addListener(VoidCallback listener) => transport.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      transport.removeListener(listener);
}
