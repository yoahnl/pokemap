import 'package:map_authoring/map_authoring_presentation_editing.dart';
import 'package:map_core/map_core_domain.dart';

class PresentationEditingSessions {
  final _sessions = <String, PresentationTimelineEditingController>{};

  PresentationTimelineEditingController forAsset(
    PresentationCinematicAsset asset,
  ) {
    final session = _sessions.putIfAbsent(
      asset.id,
      () => PresentationTimelineEditingController(asset: asset),
    );
    session.configureAsset(asset);
    return session;
  }

  void dispose() {
    for (final session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
  }
}
