import 'package:map_core/map_core_domain.dart';

String terrainManagementTitle({required bool duplicate}) => duplicate
    ? 'Dupliquer le terrain ou chemin'
    : 'Renommer le terrain ou chemin';

String terrainManagementDescription({
  required bool duplicate,
  required bool draft,
  required String name,
}) => duplicate
    ? '${draft ? 'Brouillon enregistré' : 'Version publiée'} : $name. Une nouvelle préparation indépendante sera créée, sans publication. Les PNG restent partagés et les cartes gardent leur terrain actuel.'
    : 'Seul le nom ${draft ? 'de ce brouillon' : 'de la publication et de ses préparations liées'} change. Aucun raccord modifié n’est publié.';

String terrainDraftSubtitle(
  ProjectSmartTileAuthoringDraft draft, {
  String? status,
  bool compatible = true,
}) {
  final assigned = draft.rules
      .where((rule) => rule.candidates.isNotEmpty)
      .length;
  return '${status ?? 'Brouillon enregistré'} · $assigned / ${draft.rules.length} raccords${compatible ? '' : ' · Raccords avancés en lecture seule'}';
}
