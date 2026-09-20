import 'package:map_core/map_core_domain.dart';
import '../domain/cinematic_port.dart';

class CinematicEditSession {
  const CinematicEditSession({
    required this.asset,
    required this.dirty,
    required this.revision,
    this.readOnlyReason,
    this.folderId,
  });
  final CinematicAsset asset;
  final bool dirty;
  final int revision;
  final String? readOnlyReason, folderId;
}

class CinematicWorkingSession {
  CinematicWorkingSession(this.asset, this.base) : saved = base?.asset;
  CinematicAsset asset;
  CinematicAsset? saved;
  CinematicSourceSnapshot? base;
  final undo = <CinematicAsset>[], redo = <CinematicAsset>[];
  int revision = 0;
  String? readOnlyReason, folderId;
  bool get dirty => asset != saved;
  CinematicEditSession get snapshot => CinematicEditSession(
    asset: asset,
    dirty: dirty,
    revision: revision,
    readOnlyReason: readOnlyReason,
    folderId: folderId ?? base?.entry?.folderId,
  );
  void change(CinematicAsset next) {
    if (next == asset) return;
    undo.add(asset);
    redo.clear();
    asset = next;
    revision++;
  }

  void restore(bool forward) {
    final from = forward ? redo : undo, to = forward ? undo : redo;
    if (from.isEmpty) return;
    to.add(asset);
    asset = from.removeLast();
    revision++;
  }
}
