import 'dart:async';

import 'package:map_authoring/map_authoring_presentation_editing.dart';
import 'package:map_core/map_core_domain.dart';

import '../application/presentation_preview_transport.dart';

class PresentationEditingSessions {
  final _sessions = <String, PresentationTimelineEditingController>{};

  final transport = PresentationPreviewTransport();
  final _invalidFields = <String, Set<String>>{};
  Set<String> invalidFieldsFor(String id) =>
      _invalidFields.putIfAbsent(id, () => <String>{});
  PresentationCinematicAsset? _installed;
  Object? _previewOwner;
  Future<void> Function(PresentationCinematicAsset, {required bool portrait})?
  _prepare;
  Future<void> Function()? _release;
  bool _disposed = false;

  void bindPreview(
    Object owner, {
    required void Function(PresentationPreviewTransport) bind,
    required Future<void> Function(
      PresentationCinematicAsset, {
      required bool portrait,
    })
    prepare,
    required Future<void> Function() release,
  }) {
    if (_disposed || identical(_previewOwner, owner)) return;
    if (_release case final previous?) unawaited(previous());
    _previewOwner = owner;
    _prepare = prepare;
    _release = release;
    _installed = null;
    bind(transport);
  }

  bool installPreview(
    Object owner,
    PresentationCinematicAsset asset, {
    required bool portrait,
  }) {
    if (_disposed ||
        !identical(_previewOwner, owner) ||
        identical(_installed, asset)) {
      return false;
    }
    final same = _installed?.id == asset.id;
    _installed = asset;
    transport.install(asset, preserveTime: same);
    forAsset(asset);
    final prepare = _prepare;
    if (prepare != null) unawaited(prepare(asset, portrait: portrait));
    return true;
  }

  Future<void> suspendPreview(Object owner) async {
    if (_disposed || !identical(_previewOwner, owner)) return;
    transport.pause();
    await _release?.call();
  }

  Future<void> releasePreview(Object owner) async {
    if (!identical(_previewOwner, owner)) return;
    await _releasePreview();
  }

  Future<void> _releasePreview() async {
    final release = _release;
    _release = null;
    _prepare = null;
    _previewOwner = null;
    _installed = null;
    transport.clear();
    await release?.call();
  }

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
    if (_disposed) return;
    _disposed = true;
    unawaited(_releasePreview());
    transport.dispose();
    for (final session in _sessions.values) {
      session.dispose();
    }
    _sessions.clear();
  }
}
