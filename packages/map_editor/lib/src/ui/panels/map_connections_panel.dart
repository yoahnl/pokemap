import 'package:flutter/widgets.dart';

import '../../features/editor/presentation/world_map/world_map_connections_inspector.dart';

class MapConnectionsPanel extends StatelessWidget {
  const MapConnectionsPanel({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) => const WorldMapConnectionsInspector();
}
