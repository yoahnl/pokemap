import 'package:map_core/map_core_domain.dart';

import '../../../platform/rendering/contracts/presentation_workspace_visuals.dart';
import '../application/presentation_edit_session.dart';

class PresentationVisualSession {
  Object? _key;
  PresentationWorkspaceVisuals? _current;
  final _releases = <Future<void>>{};
  Object? _releaseError;
  StackTrace? _releaseStack;
  bool _closed = false;
  Future<void>? _disposal;
  PresentationWorkspaceVisuals? get current => _current;

  PresentationWorkspaceVisuals? synchronize({
    required PresentationMediaWorkspaceVisuals factory,
    required String? activeId,
    required PresentationEditSession? session,
  }) {
    if (_closed) return null;
    final key = (
      activeId,
      session?.base?.revision,
      session?.mediaCatalog,
      session?.imports.map((media) => media.media.id).join(','),
    );
    if (_key == key) return _current;
    final next = factory.createPresentationVisuals(
      revision: session?.base?.revision ?? 'draft',
      catalog: session?.mediaCatalog ?? ProjectMediaCatalog(),
      imports: session?.imports ?? [],
    );
    final previous = _current;
    _key = key;
    _current = next;
    if (previous != null) _release(previous);
    return next;
  }

  void _release(PresentationWorkspaceVisuals visuals) {
    late final Future<void> releasing;
    releasing = Future<void>.sync(visuals.close).then<void>(
      (_) => _releases.remove(releasing),
      onError: (Object error, StackTrace stack) {
        _releases.remove(releasing);
        if (_releaseError == null) {
          _releaseError = error;
          _releaseStack = stack;
        }
      },
    );
    _releases.add(releasing);
  }

  Future<void> close() {
    if (_disposal != null) return _disposal!;
    _closed = true;
    final previous = _current;
    _current = null;
    _key = null;
    if (previous != null) _release(previous);
    return _disposal = _finishClosing();
  }

  Future<void> _finishClosing() async {
    await Future.wait(_releases);
    if (_releaseError case final error?) {
      Error.throwWithStackTrace(error, _releaseStack!);
    }
  }
}
