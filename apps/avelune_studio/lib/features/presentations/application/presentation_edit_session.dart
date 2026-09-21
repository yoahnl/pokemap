import 'package:map_core/map_core_domain.dart';
import '../domain/presentation_port.dart';

class PresentationEditSession {
  const PresentationEditSession({
    required this.asset,
    required this.dirty,
    required this.revision,
    required this.mediaCatalog,
    this.base,
    this.folderId,
    this.readOnlyReason,
    this.link,
    this.imports = const [],
  });
  final PresentationCinematicAsset asset;
  final PresentationSourceSnapshot? base;
  final bool dirty;
  final int revision;
  final String? folderId, readOnlyReason;
  final PresentationSceneLink? link;
  final ProjectMediaCatalog mediaCatalog;
  final List<PresentationStagedMedia> imports;
}

class PresentationWorkingSession {
  PresentationWorkingSession(this.asset, this.projection, this.base)
    : saved = base?.asset,
      folderId = base?.entry?.folderId;
  PresentationCinematicAsset asset;
  PresentationCinematicAsset? saved;
  PresentationSourceSnapshot? base;
  PresentationDraftProjection projection;
  String? folderId, readOnlyReason;
  PresentationSceneLink? link;
  int revision = 0;
  final undo = <(PresentationCinematicAsset, String?)>[],
      redo = <(PresentationCinematicAsset, String?)>[];
  final imports = <PresentationStagedMedia>[];
  bool get dirty =>
      asset != saved ||
      imports.isNotEmpty ||
      link != null ||
      folderId != base?.entry?.folderId;
  PresentationEditSession get snapshot => PresentationEditSession(
    asset: asset,
    base: base,
    dirty: dirty,
    revision: revision,
    folderId: folderId,
    readOnlyReason: readOnlyReason,
    link: link,
    mediaCatalog: projection.mediaCatalog,
    imports: List.unmodifiable(imports),
  );
  void change(PresentationCinematicAsset next) {
    if (next == asset) return;
    undo.add((asset, folderId));
    redo.clear();
    asset = next;
    revision++;
  }
}
